from pathlib import Path


fname = Path("~/sync/dev/aoc_inputs/2023/20/input.txt").expanduser()

nodes: list[str] = []
styles: list[str] = []

for ln in fname.read_text().splitlines():
    h1, h2 = ln.split(" -> ")

    name = h1
    typ = ""
    if h1.startswith("%") or h1.startswith("&"):
        typ = h1[0]
        name = h1[1:]

    shape = {"%": "triangle", "&": "box", "": "oval"}[typ]
    styles.append(f"{name} [shape={shape}]")
    nodes.append(f"{name} -> {h2}")

Path("out.dot").write_text(
    "digraph {\n" + "\n".join(styles) + "\n" + "\n".join(nodes) + "\n}"
)
