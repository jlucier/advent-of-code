count_2 = 0
count_3 = 0

with open('input.txt', 'r') as f:
    for box_id in f.readlines():
        freq_count = {}
        for l in box_id:
            freq_count[l] = freq_count.get(l, 0) + 1

        count_2 += int(any(map(lambda v: v == 2, freq_count.values())))
        count_3 += int(any(map(lambda v: v == 3, freq_count.values())))

print(count_2 * count_3)
