freq = 0

with open('input.txt', 'r') as f:
    for change in f.readlines():
        freq += int(change)

print(freq)
