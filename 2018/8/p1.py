with open('input.txt', 'r') as f:
    nums = list(map(int, f.read().split()))

def sum_meta(i):
    children = nums[i]
    num_meta = nums[i+1]
    curr_sum = 0
    j = i + 2
    for _ in range(children):
        j, s = sum_meta(j)
        curr_sum += s

    return j+num_meta, curr_sum + sum(nums[j:j+num_meta])

_, s = sum_meta(0)
print(s)
