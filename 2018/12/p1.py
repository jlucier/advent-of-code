from collections import deque

with open('input.txt', 'r') as f:
    lines = f.readlines()
    curr_gen = lines[0].strip()
    curr_gen = curr_gen[curr_gen.index(': ') + 2:]
    curr_gen = deque(curr_gen)
    rules = dict(l.strip().split(' => ') for l in lines[2:])

def pad_gen(n=3):
    curr_gen.extendleft('.'*n)
    curr_gen.extend('.'*n)
    return n


total_pad = pad_gen(20)
for _ in range(20):
    last_gen_vals = deque([], maxlen=5)
    for i in range(4):
        last_gen_vals.appendleft(curr_gen[i])

    for i in range(4, len(curr_gen)):
        last_gen_vals.append(curr_gen[i])
        curr_gen[i-2] = rules.get(''.join(last_gen_vals), '.')
    total_pad += pad_gen()

print(sum(map(lambda t: t[0] - total_pad if t[1] == '#' else 0, enumerate(curr_gen))))
