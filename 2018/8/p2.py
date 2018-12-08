with open('input.txt', 'r') as f:
    nums = list(map(int, f.read().split()))

def node_value(i):
    children = nums[i]
    num_meta = nums[i+1]
    child_vals = []
    j = i + 2
    for _ in range(children):
        j, v = node_value(j)
        child_vals.append(v)

    my_meta = nums[j:j+num_meta]
    j += num_meta

    if children == 0:
        return j, sum(my_meta)

    curr_val = 0
    for m in my_meta:
        if 0 < m <= children:
            curr_val += child_vals[m-1]

    return j, curr_val

_, v = node_value(0)
print(v)
