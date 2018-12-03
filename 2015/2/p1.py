with open('input.txt', 'r') as f:
    dims = list(map(lambda s: s.strip(), f.readlines()))

total = 0
for present in dims:
    l,w,h = list(map(int, present.split('x')))
    total += 2*l*w + 2*w*h + 2*h*l + min(l*w, w*h, h*l)

print(total)
