good = 0

with open('input.txt', 'r') as f:
    for w in map(lambda l: l.strip(), f.readlines()):
        repeat = False
        has_pair = False
        pairs = dict()

        for i in range(len(w) - 1):
            if i + 2 < len(w) and w[i] == w[i+2]:
                repeat = True

            pair = w[i:i+2]
            if pair in pairs and pairs[pair] != i - 1:
                has_pair = True
            elif pair not in pairs:
                pairs[pair] = i

        if has_pair and repeat:
            good += 1

print(good)
