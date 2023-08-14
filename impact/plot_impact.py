# Plot lat/lng data. The data is animated in time, currently every 2ms.
# Could be improved by using the time data to animate the data in real time.

import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import pandas as pd

data = pd.read_csv('impact.log')
times = data['time'].values # currently unused
lats = data['lat'].values
lngs = data['lng'].values

fig, ax = plt.subplots()

# set ax limits to be 120% of the range of the data
lats_min, lats_max = min(lats), max(lats)
lats_range = lats_max - lats_min
ymin, ymax = lats_min - lats_range * 0.1, lats_max + lats_range * 0.1
ax.set_ylim(ymin, ymax)
lngs_min, lngs_max = min(lngs), max(lngs)
lngs_range = lngs_max - lngs_min
xmin, xmax = lngs_min - lngs_range * 0.1, lngs_max + lngs_range * 0.1
ax.set_xlim(xmin, xmax)
ax.set_aspect(aspect='equal', adjustable='datalim')

# plot central lines at impact position
central_lat = lats[-1]
ax.axhline(y=central_lat, color='gray')
central_lng = lngs[-1]
ax.axvline(x=central_lng, color='gray')

line, = ax.plot(lngs, lats, linewidth=2, color='blue', linestyle='solid')

def init():
    line.set_data([], [])
    return line,

def update(frame):
    line.set_data(lngs[:frame], lats[:frame])
    ax.set_title(f'Time: {times[frame]:.2f}')
    
animation = FuncAnimation(fig=fig, func=update, frames=len(lats), init_func=init, interval=5)

plt.show()
