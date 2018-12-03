with open('input.txt', 'r') as f:
    inp = f.read().strip()

floor = 0
for mv in inp:
    floor += 1 if mv == '(' else -1
print(floor)
