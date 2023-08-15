# Plotting impact coordinates:
# - x axis is longitude
# - y axis is latitude
# - plot is animated over time

import numpy as np
from math import pi
from time import time
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.animation import FuncAnimation

# Configuration
speedup_factor = 10
zoom_factor = 1

# Read data
data = pd.read_csv("impact/impact.log")
times = data["time"].values
lats = data["lat"].values
lngs = data["lng"].values
start = time()
data_start_time = times[0]
log_time_range = times[-1] - times[0]

fig, ax = plt.subplots()

# Calculate center and bounds
center_lat = lats[-1]
center_lng = lngs[-1]

# Calculate x and y limits
# get the maximum deviation of any data points from the center
max_deviation = max(max(abs(lats - center_lat)), max(abs(lngs - center_lng)))
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

(line,) = ax.plot([], [])
(newest_point,) = ax.plot([], [], "rx", markersize=7)


def get_values_until_time(time):
    values = []
    for i, t in enumerate(times):
        if data_start_time + time > t:
            values.append((lngs[i], lats[i]))
        else:
            return values


def update(frame):
    # loop through the data until the time is after the current time
    real_time_since_start = time() - start
    sped_up_time = real_time_since_start * speedup_factor

    # stop the animation when we've reached the end of the data
    if sped_up_time > log_time_range:
        animation.event_source.stop()
        return

    points_to_plot = get_values_until_time(sped_up_time)
    if points_to_plot:
        xdata, ydata = zip(*points_to_plot)
        line.set_data(xdata, ydata)
        # plot the newest point in red
        newest_point.set_data([xdata[-1]], [ydata[-1]])

    ax.set_title(
        f"{sped_up_time:.1f}/{log_time_range:.1f} seconds (sped up {speedup_factor}x)"
    )
    return line, newest_point


animation = FuncAnimation(fig=fig, func=update, interval=1, cache_frame_data=False)

plt.show()
