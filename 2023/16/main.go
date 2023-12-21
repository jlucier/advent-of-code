package main

import (
	"fmt"

	"aoc/utils"
)

type Beam struct {
	pos utils.V2
	dir utils.V2
}

func parseMap(fname string) [][]byte {
	lines := utils.ReadLines(fname)

	mp := make([][]byte, len(lines))
	for i, ln := range lines {
		mp[i] = []byte(ln)
	}
	return mp
}

func inBounds(v *utils.V2, mp [][]byte) bool {
	return v.Y < len(mp) && v.Y >= 0 && v.X < len(mp[0]) && v.X >= 0
}

func printWithCoord(mp [][]byte, c utils.V2) {
	for y, ln := range mp {
		if c.Y == y {
			rc := utils.Red(string(ln[c.X]))
			if c.X+1 >= len(ln) {
				fmt.Printf("%s%s\n", string(ln[:c.X]), rc)
			} else {
				fmt.Printf("%s%s%s\n", string(ln[:c.X]), rc, string(ln[c.X+1:]))
			}
		} else {
			fmt.Println(string(ln))
		}
	}
}

func walk(mp [][]byte, start Beam) int {
	RIGHT := utils.V2{X: 1, Y: 0}
	LEFT := utils.V2{X: -1, Y: 0}
	UP := utils.V2{X: 0, Y: -1}
	DOWN := utils.V2{X: 0, Y: 1}

	energized := make(map[utils.V2]int)
	seen := utils.EmptySet[Beam]()
	beams := []Beam{start}

	for len(beams) > 0 {
		bm := beams[0]
		beams = beams[1:]

		if !inBounds(&bm.pos, mp) {
			continue
		}
		if seen.Contains(bm) {
			continue
		}
		seen.Add(bm)
		energized[bm.pos] += 1
		nextC := mp[bm.pos.Y][bm.pos.X]

		var next []Beam

		switch nextC {
		case '.':
			next = append(next, Beam{
				bm.pos.Add(&bm.dir),
				bm.dir,
			})
		case '/':
			switch bm.dir {
			case RIGHT:
				next = append(next, Beam{bm.pos.Add(&UP), UP})
			case LEFT:
				next = append(next, Beam{bm.pos.Add(&DOWN), DOWN})
			case DOWN:
				next = append(next, Beam{bm.pos.Add(&LEFT), LEFT})
			case UP:
				next = append(next, Beam{bm.pos.Add(&RIGHT), RIGHT})
			}
		case '\\':
			switch bm.dir {
			case RIGHT:
				next = append(next, Beam{bm.pos.Add(&DOWN), DOWN})
			case LEFT:
				next = append(next, Beam{bm.pos.Add(&UP), UP})
			case DOWN:
				next = append(next, Beam{bm.pos.Add(&RIGHT), RIGHT})
			case UP:
				next = append(next, Beam{bm.pos.Add(&LEFT), LEFT})
			}
		case '-':
			if bm.dir == LEFT || bm.dir == RIGHT {
				next = append(next, Beam{
					bm.pos.Add(&bm.dir),
					bm.dir,
				})
			} else {
				next = append(next, Beam{bm.pos.Add(&LEFT), LEFT}, Beam{bm.pos.Add(&RIGHT), RIGHT})
			}
		case '|':
			if bm.dir == UP || bm.dir == DOWN {
				next = append(next, Beam{
					bm.pos.Add(&bm.dir),
					bm.dir,
				})
			} else {
				next = append(next, Beam{bm.pos.Add(&UP), UP}, Beam{bm.pos.Add(&DOWN), DOWN})
			}
		}

		for _, newBm := range next {
			if !inBounds(&newBm.pos, mp) {
				continue
			}
			beams = append(beams, newBm)
		}
	}
	return len(energized)
}

func p1(mp [][]byte) {
	fmt.Println("p1:", walk(mp, Beam{
		utils.V2{X: 0, Y: 0},
		utils.V2{X: 1, Y: 0},
	}))
}

func p2(mp [][]byte) {
	maxE := 0
	// rows
	for i := range mp {
		eL := walk(mp, Beam{
			utils.V2{X: 0, Y: i}, // start coord
			utils.V2{X: 1, Y: 0}, // dir
		})
		maxE = utils.Max(eL, maxE)

		eR := walk(mp, Beam{
			utils.V2{X: len(mp[0]) - 1, Y: i}, // start coord
			utils.V2{X: -1, Y: 0},             // dir
		})
		maxE = utils.Max(eR, maxE)
	}

	// cols
	for i := range mp[0] {
		eT := walk(mp, Beam{
			utils.V2{X: i, Y: 0}, // start coord
			utils.V2{X: 0, Y: 1}, // dir
		})
		maxE = utils.Max(eT, maxE)

		eB := walk(mp, Beam{
			utils.V2{X: i, Y: len(mp) - 1}, // start coord
			utils.V2{X: 0, Y: -1},          // dir
		})
		maxE = utils.Max(eB, maxE)
	}
	fmt.Println("p2:", maxE)
}

func main() {
	mp := parseMap("~/sync/dev/aoc_inputs/2023/16/input.txt")
	p1(mp)
	p2(mp)
}
