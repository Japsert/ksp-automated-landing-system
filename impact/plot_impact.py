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
    lines = f.readlines()[1:]  # skip header

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

start = time()
data_start_time = min(run["points"][0][time_col] for run in runs)
log_time_range = max(run["points"][-1][time_col] for run in runs) - data_start_time

fig, ax = plt.subplots()

# Calculate center and bounds
center_lat = runs[0]["points"][-1][lat_col]  # take first run's last point as center
center_lng = runs[0]["points"][-1][lng_col]

# Calculate x and y limits
# get the maximum deviation of any data points of any run from the center
max_deviation = max(
    max(abs(point[lat_col] - center_lat), abs(point[lng_col] - center_lng))
    for run in runs
    for point in run["points"]
)
# use that, plus a little wiggle room, to calculate the bounds
lim_offset = max_deviation * 1.1 / zoom_factor
xmax = center_lng + lim_offset
ymin = center_lat - lim_offset
ymax = center_lat + lim_offset
xmin = center_lng - lim_offset
ax.set_xlim(xmin, xmax)
ax.set_ylim(ymin, ymax)

# Draw center lines
ax.axhline(center_lat, color="lightgray", zorder=-1)
ax.axvline(center_lng, color="lightgray", zorder=-1)

# Set custom ticks
# convert lat/lng values to meters from center
planet_radius = 600000
planet_circumference = 2 * planet_radius * pi
lat_lng_to_m = planet_circumference / 360
xticks = np.linspace(xmin, xmax, 9)
yticks = np.linspace(ymin, ymax, 9)
xticklabels = [int((tick - center_lng) * lat_lng_to_m) for tick in xticks]
yticklabels = [int((tick - center_lat) * lat_lng_to_m) for tick in yticks]
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
    (newest_point,) = ax.plot([], [], "rx", markersize=7)
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
        # plot newest points as red crosses
        newest_point.set_data([run[-1][lng_col]], [run[-1][lat_col]])

    ax.set_title(
        f"{sped_up_time:.1f}/{log_time_range:.1f} seconds "
        "(sped up {speedup_factor}x)"
    )

    return line, newest_points


animation = FuncAnimation(fig=fig, func=update, interval=1, cache_frame_data=False)

plt.show()
