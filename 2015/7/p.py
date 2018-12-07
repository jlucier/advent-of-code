from numbers import Number
import numpy as np

wire_vals = dict()

num = input('1 or 2? (default 1) ')
num = int(num) if num else num
with open('input{}.txt'.format(num), 'r') as f:
    for l in f.readlines():
        tokens = l.strip().split()

        if len(tokens) == 3:
            # like: 123 -> x
            try:
                wire_vals[tokens[-1]] = np.uint16(int(tokens[0]))
            except ValueError:
                wire_vals[tokens[-1]] = tokens[0]

        elif len(tokens) == 4:
            # like: NOT x -> h
            wire_vals[tokens[-1]] = tokens[:2]

        else:
            # like: x AND y -> z
            wire_vals[tokens[-1]] = tokens[:3]

def compute_node(name):
    if name not in wire_vals:
        return np.uint16(name)

    if isinstance(wire_vals[name], Number):
        return wire_vals[name]

    elif isinstance(wire_vals[name], str):
        wire_vals[name] = compute_node(wire_vals[name])
        return wire_vals[name]

    elif isinstance(wire_vals[name], list):
        val = None
        if len(wire_vals[name]) == 2:
            # like: NOT x -> h
            val = ~ compute_node(wire_vals[name][1])
        elif len(wire_vals[name]) == 3:
            # like: x AND y -> z
            if wire_vals[name][1] == 'AND':
                val = compute_node(wire_vals[name][0]) & compute_node(wire_vals[name][2])
            elif wire_vals[name][1] == 'OR':
                val = compute_node(wire_vals[name][0]) | compute_node(wire_vals[name][2])
            elif wire_vals[name][1] == 'LSHIFT':
                val = compute_node(wire_vals[name][0]) << int(wire_vals[name][2])
            elif wire_vals[name][1] == 'RSHIFT':
                val = compute_node(wire_vals[name][0]) >> int(wire_vals[name][2])

        wire_vals[name] = val
        return val

print(compute_node('a'))
