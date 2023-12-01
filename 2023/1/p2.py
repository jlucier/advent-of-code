import re
from pathlib import Path


word_subs = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]

def main():
    p = Path("inp1.txt")
    s = p.read_text()

    out = []
    i = 0
    while i < len(s):
        matched = False
        for num, w in enumerate(word_subs):
            if s.startswith(w, i):
                # safe to increase by this amount since the words overlap at most 1 letter
                i += len(w) - 1
                out.append(str(num))
                matched = True

        if not matched:
            out.append(s[i])
            i += 1


    remaining = "".join(out)
    s = re.sub(r"[a-z]", "", remaining)


    lines = s.splitlines()
    total = 0
    for i, ln in enumerate(lines):
        total += int(f"{ln[0]}{ln[-1]}")
    print(total)

if __name__ == "__main__":
    main()
