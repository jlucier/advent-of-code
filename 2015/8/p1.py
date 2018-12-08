with open('input.txt', 'r') as f:
    code = 0
    mem = 0
    for l in map(lambda l: l.strip(), f):
        l = l.strip()
        code += len(l)
        l = l[1:-1]
        l = l.replace('\\"', '*').replace('\\\\','*')

        while True:
            i = l.find('\\x')
            if i < 0:
                break
            l = l[:i] + '*' + l[i+4:]

        mem += len(l)

print(code - mem)
