import re
from pathlib import Path


def main():
    s = Path("~/sync/dev/aoc_inputs/2024/3.txt").expanduser().read_text()

    p1 = 0
    p2 = 0
    curr_do = -1
    last_do = True
    dos_donts = list(re.finditer(r"do(n't)*\(\)", s))
    for m in re.finditer(r"mul\((\d+),(\d+)\)", s):
        while curr_do < len(dos_donts) and (
            curr_do < 0 or dos_donts[curr_do].span()[0] < m.span()[0]
        ):
            if curr_do >= 0:
                last_do = dos_donts[curr_do].groups()[0] is None
            curr_do += 1

        a, b = m.groups()
        mul = int(a) * int(b)
        p1 += mul
        p2 += mul if last_do else 0

    print(p1)
    print(p2)


if __name__ == "__main__":
    main()
