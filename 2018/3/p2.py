import numpy as np

fabric = np.zeros((1000, 1000), np.int)

with open('input.txt', 'r') as f:
    claims = list(map(lambda l: l.strip(), f.readlines()))

for c in claims:
    pad = list(map(int, c[c.index('@') + 1 : c.index(':')].split(',')))
    size = list(map(int, c[c.index(':') + 1:].split('x')))

    fabric[pad[0]:pad[0]+size[0], pad[1]:pad[1]+size[1]] += 1

for c in claims:
    c_id = c[1:c.index('@') -1]
    pad = list(map(int, c[c.index('@') + 1 : c.index(':')].split(',')))
    size = list(map(int, c[c.index(':') + 1:].split('x')))

    if np.all(fabric[pad[0]:pad[0]+size[0], pad[1]:pad[1]+size[1]] == 1):
        print c_id
        break
