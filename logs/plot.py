import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.animation import FuncAnimation


def update_plot(frames, subplots):
    # Read the CSV file with pandas
    try:
        df = pd.read_csv("landingburn.log")
    except FileNotFoundError:
        try:
            df = pd.read_csv("logs/landingburn.log")
        except FileNotFoundError:
            print("Could not find landingburn.log")
            return

    # Clear the previous plot
    plt.clf()

    # Set the x-axis as the first column ("time")
    x = df["time"]

    # Make dictionary
    subplots_columns = []
    for column in df.columns[1:]:
        found = False
        # if column is in a group and not at the first index, add it to the subplot that already contains the column
        for group in subplots:
            for i, col in enumerate(group):
                if column == col and i >= 1:
                    # add to existing subplot: find the subplot that contains any of the columns in the group
                    for subplot in subplots_columns:
                        if any(col in subplot for col in group):
                            subplot.append(column)
                            found = True
                            break
                    break
            if found:
                break
        # create a new subplot for the column
        else:
            subplots_columns.append([column])
            
    # Create the subplots
    for i, subplot in enumerate(subplots_columns):
        # Create the subplot
        ax = plt.subplot(len(subplots_columns), 1, i + 1)
        # Set the title
        ax.set_title(", ".join(subplot))
        # Set the y-axis as the column
        y = df[subplot]
        
        # Column-specific formatting
        # if column is throttle, cap between 0 and 1
        if "throttle" in subplot:
            y = y.clip(0, 1)
        # if column is altitude, add a horizontal line at 0
        if "altitude" in subplot:
            ax.axhline(0, color="black")
            
        # Plot the data
        plt.plot(x, y)
        # Set the x-axis label
        plt.xlabel("Time (s)")
        # Set the y-axis label
        plt.ylabel("Value")
        # Set the legend
        plt.legend(subplot, loc="upper left")


# Create the figure and axes for the initial plot
fig, ax = plt.subplots()
fig.set_tight_layout(True)

# Define the column groupings for each subplot as tuples
subplots = [
    ["altitude", "burn altitude", "interp burn altitude"],
]

# Call the update_plot function using FuncAnimation with subplots argument
ani = FuncAnimation(fig, update_plot, fargs=(subplots,), interval=500)

# Show the animated plot
try:
    plt.show()
except KeyboardInterrupt:
    print("Plot interrupted")
