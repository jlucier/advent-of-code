with open('input.txt', 'r') as f:
    polymer = f.read()

def check_rules(c1, c2):
    return c1.lower() == c2.lower() and c1 != c2

i = 0
new_polymer = list()
while True:
    c1, c2 = polymer[i:i+2]
    # same type and opposite case (i.e. not the same char)
    if check_rules(c1,c2):
        i += 2
    else:
        if len(new_polymer) > 0 and check_rules(new_polymer[-1], c1):
            del new_polymer[-1]
        else:
            new_polymer.append(c1)
        i += 1

    if i >= len(polymer) - 1:
        break

print(len(new_polymer))
