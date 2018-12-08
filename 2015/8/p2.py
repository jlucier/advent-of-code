with open('input.txt', 'r') as f:
    code = 0
    new = 0
    for l in map(lambda l: l.strip(), f):
        l = l.strip()
        code += len(l)
        new += len(l) + l[1:-1].count('"') + l.count('\\')
        new += 4

print(new - code)
