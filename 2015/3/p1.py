with open('input.txt', 'r') as f:
    directions = f.read()

pos = [0,0]
homes = {tuple(pos)}
for d in directions:
    if d == '^':
        pos[1] += 1
    elif d == 'v':
        pos[1] -= 1
    elif d == '>':
        pos[0] += 1
    elif d == '<':
        pos[0] -= 1

    homes.add(tuple(pos))

print(len(homes))
