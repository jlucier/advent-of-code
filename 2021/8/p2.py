"""
  0:      1:      2:      3:      4:
 aaaa    ....    aaaa    aaaa    ....
b    c  .    c  .    c  .    c  b    c
b    c  .    c  .    c  .    c  b    c
 ....    ....    dddd    dddd    dddd
e    f  .    f  e    .  .    f  .    f
e    f  .    f  e    .  .    f  .    f
 gggg    ....    gggg    gggg    ....

  5:      6:      7:      8:      9:
 aaaa    aaaa    aaaa    aaaa    aaaa
b    .  b    .  .    c  b    c  b    c
b    .  b    .  .    c  b    c  b    c
 dddd    dddd    ....    dddd    dddd
.    f  e    f  .    f  e    f  .    f
.    f  e    f  .    f  e    f  .    f
 gggg    gggg    ....    gggg    gggg

"""


def process_line(line) -> int:
    d, r = line.strip().split(" | ")
    digits = d.split(" ")
    readouts = r.split(" ")

    scrambled = {}

    for d in map(frozenset, digits):
        if len(d) == 2:
            scrambled[d] = 1
        elif len(d) == 3:
            scrambled[d] = 7
        elif len(d) == 4:
            scrambled[d] = 4
        elif len(d) == 7:
            scrambled[d] = 8

    curr_n_to_s = {v: k for k, v in scrambled.items()}
    digit = ""
    for r in map(frozenset, readouts):
        if r in scrambled:
            digit += str(scrambled[r])
            continue

        if len(r) == 5:
            if r > curr_n_to_s[1]:
                digit += "3"
            elif len(r & curr_n_to_s[4]) == 3:
                digit += "5"
            else:
                digit += "2"

        elif len(r) == 6:
            if r > curr_n_to_s[4]:
                digit += "9"
            elif r > curr_n_to_s[1]:
                digit += "0"
            else:
                digit += "6"

    return int(digit)

def main():
    with open("inp.txt") as f:
        lines = f.readlines()

    tot = 0
    for l in lines:
        tot += process_line(l)
    print("Answer:", tot)

if __name__ == "__main__":
    main()
