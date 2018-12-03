with open('input.txt', 'r') as f:
    inp = f.read().strip()

floor = 0
for i, mv in enumerate(inp):
    floor += 1 if mv == '(' else -1
    if floor < 0:
        print(i + 1)
        break
