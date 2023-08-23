# Plotting impact coordinates:
# - x axis is longitude
# - y axis is latitude
# - plot is animated over time

import re
import numpy as np
from math import pi
from time import time
import matplotlib.pyplot as plt
import matplotlib as mpl
from matplotlib.animation import FuncAnimation

# Configuration
speedup_factor = 10
zoom_factor = 1
run_colors = ["blue", "green", "orange", "purple", "brown", "pink", "gray"]

mpl.rcParams["axes.prop_cycle"] = mpl.cycler(color=run_colors)  # set run colors

# Read data
log_file = "impact/impact.log"
with open(log_file, "r") as f:
    lines = f.readlines()
    if lines[0].startswith("time"):
        lines.pop(0)  # remove header line

runs = []

time_col = 0
lat_col = 1
lng_col = 2

for line in lines:
    if line.startswith("---"):
        # start a new run
        runs.append({"name": re.search(r"--- (.*)", line).group(1), "points": []})
        continue
    # add data to current run
    cols = line.split(",")
    runs[-1]["points"].append(
        (float(cols[time_col]), float(cols[lat_col]), float(cols[lng_col]))
    )

# Make all lat/lng values relative to that run's last point
for run in runs:
    if not run["points"]:
        continue
    last_point = run["points"][-1]
    last_lat, last_lng = last_point[lat_col], last_point[lng_col]
    for i, point in enumerate(run["points"]):
        run["points"][i] = (
            point[time_col],
            point[lat_col] - last_lat,
            point[lng_col] - last_lng,
        )

start = time()
data_start_time = min(run["points"][0][time_col] for run in runs)
log_time_range = max(run["points"][-1][time_col] for run in runs) - data_start_time

fig, ax = plt.subplots()

# Calculate x and y limits
# get the maximum deviation of any data points of any run from the center
max_deviation = max(
    max(abs(point[lat_col]), abs(point[lng_col]))
    for run in runs
    for point in run["points"]
)
# use that, plus a little wiggle room, to calculate the bounds
lim_offset = max_deviation * 1.1 / zoom_factor
ax.set_xlim(-lim_offset, lim_offset)
ax.set_ylim(-lim_offset, lim_offset)

# Draw center lines
ax.axhline(y=0, color="lightgray", zorder=-1)
ax.axvline(x=0, color="lightgray", zorder=-1)

# Set custom ticks
# convert lat/lng values to meters from center
planet_radius = 600000
planet_circumference = 2 * planet_radius * pi
lat_lng_to_m = planet_circumference / 360
xticks = np.linspace(-lim_offset, lim_offset, 9)
yticks = np.linspace(-lim_offset, lim_offset, 9)
xticklabels = [int(tick * lat_lng_to_m) for tick in xticks]
yticklabels = [int(tick * lat_lng_to_m) for tick in yticks]
ax.set_xticks(xticks, labels=xticklabels)
ax.set_yticks(yticks, labels=yticklabels)

# Set axis labels
ax.set_xlabel("Longitude (m)")
ax.set_ylabel("Latitude (m)")

lines = []
newest_points = []
# Plot runs (empty for now)
for run in runs:
    (line,) = ax.plot([], [])
    # newest point color will get overwritten later
    (newest_point,) = ax.plot([], [], color="black", marker="x", markersize=7)
    lines.append(line)
    newest_points.append(newest_point)

ax.legend(lines, [run["name"] for run in runs])


def get_values_until_time(time):
    # Return list of runs, containing lists of point tuples,
    # that are before the given time
    return_runs = []
    for run in runs:
        return_runs.append([])
        for point in run["points"]:
            if data_start_time + time >= point[time_col]:
                return_runs[-1].append(point)
            else:
                break
    return return_runs


def update(frame):
    real_time_since_start = time() - start
    sped_up_time = real_time_since_start * speedup_factor

    # stop the animation when we've reached the end of the data
    if sped_up_time > log_time_range:
        animation.event_source.stop()
        return

    runs = get_values_until_time(sped_up_time)
    for run, line, newest_point in zip(runs, lines, newest_points):
        if len(run) == 0:
            continue
        line.set_data(
            [point[lng_col] for point in run],
            [point[lat_col] for point in run],
        )
        # plot newest points as crosses in the same color as the line
        newest_point.set_data([run[-1][lng_col]], [run[-1][lat_col]])
        newest_point.set_color(line.get_color())

    ax.set_title(
        f"{sped_up_time:.1f}/{log_time_range:.1f} seconds "
        f"(sped up {speedup_factor}x)"
    )

    return line, newest_points


animation = FuncAnimation(fig=fig, func=update, interval=1, cache_frame_data=False)

plt.show()
