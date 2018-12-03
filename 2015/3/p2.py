with open('input.txt', 'r') as f:
    directions = f.read()

pos = [0,0]
robo_pos = [0,0]
homes = {tuple(pos)}
for i,d in enumerate(directions):
    curr = pos if i % 2 == 0 else robo_pos
    if d == '^':
        curr[1] += 1
    elif d == 'v':
        curr[1] -= 1
    elif d == '>':
        curr[0] += 1
    elif d == '<':
        curr[0] -= 1

    homes.add(tuple(curr))

print(len(homes))
