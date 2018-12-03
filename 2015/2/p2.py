with open('input.txt', 'r') as f:
    dims = list(map(lambda s: s.strip(), f.readlines()))

total = 0
for present in dims:
    l,w,h = list(map(int, present.split('x')))
    total += 2 * min(l+w, l+h, w+h) + l*w*h

print(total)
