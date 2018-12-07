import numpy as np

with open('input.txt', 'r') as f:
    locations = list()
    for l in f.readlines():
        locations.append(list(map(int, np.array(l.split(',')))))

    locations = np.array(locations)

low = np.min(locations, axis=0) - 1
high = np.max(locations, axis=0) + 1
locations -= low

grid = np.empty((high[0] - low[0], high[1] - low[1]), np.bool)
for i in range(grid.shape[0]):
    for j in range(grid.shape[1]):
        grid[i,j] = np.sum(np.abs(locations - np.array([i,j]))) < 10000

print(np.sum(grid))
