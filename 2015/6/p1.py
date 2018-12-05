import ast
from itertools import product
import numpy as np

grid = np.zeros((1000, 1000), np.bool)

with open('input.txt', 'r') as f:
    for l in map(lambda l: l.strip(), f.readlines()):
        cmd = l.split(' ')
        tl = None
        br = ast.literal_eval(cmd[-1])
        val = None

        if cmd[0] == 'turn':
            val = cmd[1] == 'on'
            tl = ast.literal_eval(cmd[2])
        else:
            # toggle
            tl = ast.literal_eval(cmd[1])

        grid[tl[0]:br[0]+1, tl[1]:br[1]+1] = val if val is not None else np.logical_not(grid[tl[0]:br[0]+1, tl[1]:br[1]+1])

print(np.sum(grid))
