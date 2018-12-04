bad_strs = ['ab', 'cd', 'pq', 'xy']
vowels = {'a','e','i','o','u'}

good = 0
with open('input.txt', 'r') as f:
    for w in map(lambda l: l.strip(), f.readlines()):
        if any(b in w for b in bad_strs):
            continue

        vowel_count = 0
        double = False
        for i in range(len(w)):
            if w[i] in vowels:
                vowel_count += 1
            if i + 1 < len(w) and w[i] == w[i+1]:
                double = True

        if double and vowel_count >= 3:
            good += 1

print(good)
