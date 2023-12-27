package main

import (
	"fmt"
	"regexp"
	"strconv"

	"aoc/utils"
)

type Dig struct {
	dir   utils.V2
	count int
}

func parseP1(fname string) []Dig {
	re := regexp.MustCompile("([A-Z]) ([0-9]+) ")
	lines := utils.ReadLines(fname)
	digs := make([]Dig, len(lines))

	for i, ln := range lines {
		m := re.FindStringSubmatch(ln)
		dir := utils.V2{}
		switch m[1][0] {
		case 'R':
			dir = utils.V2{X: 1, Y: 0}
		case 'L':
			dir = utils.V2{X: -1, Y: 0}
		case 'U':
			dir = utils.V2{X: 0, Y: -1}
		case 'D':
			dir = utils.V2{X: 0, Y: 1}

		}
		digs[i] = Dig{dir, utils.StrToInt(m[2])}
	}
	return digs
}

func parseP2(fname string) []Dig {
	re := regexp.MustCompile("\\(#([a-z0-9]+)\\)")
	lines := utils.ReadLines(fname)
	digs := make([]Dig, len(lines))

	for i, ln := range lines {
		m := re.FindStringSubmatch(ln)
		dir := utils.V2{}
		switch m[1][5] {
		case '0':
			dir = utils.V2{X: 1, Y: 0}
		case '2':
			dir = utils.V2{X: -1, Y: 0}
		case '3':
			dir = utils.V2{X: 0, Y: -1}
		case '1':
			dir = utils.V2{X: 0, Y: 1}

		}
		v, _ := strconv.ParseInt(m[1][:5], 16, 32)
		digs[i] = Dig{dir, int(v)}
	}
	return digs
}

func corners(plan []Dig) ([]utils.V2, int) {
	length := 0
	pos := utils.V2{}
	allPos := []utils.V2{}

	for _, d := range plan {
		length += d.count
		vec := d.dir.Mul(d.count)
		pos = pos.Add(&vec)
		allPos = append(allPos, pos)
	}
	return allPos, length
}

func shoelace(points []utils.V2) float64 {
	// https://en.wikipedia.org/wiki/Shoelace_formula
	area := 0
	for i, v := range points {
		if i == len(points)-1 {
			i = 0
		} else {
			i += 1
		}
		area += (v.Y + points[i].Y) * (v.X - points[i].X)
	}
	return float64(area) / 2
}

func solve(plan []Dig) int {
	points, length := corners(plan)
	area := shoelace(points)
	// picks: https://en.wikipedia.org/wiki/Pick%27s_theorem
	interior := area - float64(length)/2 + 1
	return length + int(interior)
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/18/input.txt"

	fmt.Println("p1:", solve(parseP1(fname)))
	fmt.Println("p2:", solve(parseP2(fname)))
}
