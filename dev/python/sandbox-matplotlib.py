# sandbox-matplotlib.py: Sample Python code using Matplot library.

# Q: Can Conjure's Python client display a plot?
# A: Yes.


# Sample code from: https://www.w3schools.com/python/matplotlib_pyplot.asp

import matplotlib.pyplot as plt
import numpy as np

xpoints = np.array([0, 6])
ypoints = np.array([0, 250])

xpoints # array([0, 6])
ypoints # array([  0, 250])

plt.plot(xpoints, ypoints)
plt.show()

