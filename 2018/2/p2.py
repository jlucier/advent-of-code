def one_diff(id1, id2):
    return sum(map(lambda t: t[0] != t[1], zip(id1, id2))) == 1

with open('input.txt', 'r') as f:
    ids = list(map(lambda s: s.strip(), f.readlines()))

for i in range(len(ids)):
    for j in range(i+1, len(ids)):
        if one_diff(ids[i], ids[j]):
            for k in range(len(ids[i])):
                if ids[i][k] != ids[j][k]:
                    print(ids[i][:k] + ids[i][k+1:])
                    break
