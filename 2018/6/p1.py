from collections import Counter
import numpy as np

with open('input.txt', 'r') as f:
    locations = list()
    for l in f.readlines():
        locations.append(list(map(int, np.array(l.split(',')))))

    locations = np.array(locations)

low = np.min(locations, axis=0) - 1
high = np.max(locations, axis=0) + 1
locations -= low

grid = np.empty((high[0] - low[0], high[1] - low[1]), np.int)
grid[:,:] = -1
for i in range(grid.shape[0]):
    for j in range(grid.shape[1]):
        dists = np.sum(np.abs(locations - np.array([i,j])), axis=1)
        u, indices, counts = np.unique(dists, return_index=True, return_counts=True)

        if counts[0] == 1:
            # one unique smallest distance
            grid[i,j] = indices[0]

ignore_indices = set()
ignore_indices.update(np.unique(grid[0,:]))
ignore_indices.update(np.unique(grid[-1,:]))
ignore_indices.update(np.unique(grid[:,0]))
ignore_indices.update(np.unique(grid[:,-1]))

for i in ignore_indices:
    grid[grid == i] = -1

c = Counter(grid.flatten())
for index, count in c.most_common():
    if index != -1:
        print(count)
        break
