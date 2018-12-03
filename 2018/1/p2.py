with open('input.txt', 'r') as f:
    changes = list(map(int, f.readlines()))

freq = 0
past_freqs = {0}
i = 0

while True:
    freq += changes[i]
    if freq in past_freqs:
        break
    past_freqs.add(freq)
    i  = (i+1) % len(changes)

print(freq)
