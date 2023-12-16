package main

import (
	"fmt"
	"strings"

	"aoc/utils"
)

const (
	WORKING = "."
	BROKEN  = "#"
	UNKNOWN = "?"
)

type Puzzle struct {
	rows        [][]byte
	constraints [][]int
}

func parseInput(fname string) Puzzle {
	lines := utils.ReadLines(fname)
	puzzle := Puzzle{
		make([][]byte, len(lines)),
		make([][]int, len(lines)),
	}

	for i, ln := range lines {
		halves := strings.Split(ln, " ")
		puzzle.rows[i] = []byte(halves[0])
		puzzle.constraints[i] = utils.StrsToInts(strings.Split(halves[1], ","))
	}
	return puzzle
}

func getGroupsDamaged(row []byte) []int {
	var groups []int

	groupLen := 0
	for _, c := range row {
		if c == '#' {
			groupLen++
		} else if groupLen > 0 {
			groups = append(groups, groupLen)
			groupLen = 0
		}
	}
	if groupLen > 0 {
		groups = append(groups, groupLen)
		groupLen = 0
	}
	return groups
}

func solve(row []byte, constraints []int) int {
	firstQ := -1

	for i, c := range row {
		if c == '?' {
			firstQ = i
			break
		}
	}

	if firstQ < 0 {
		// check constraints
		if utils.SliceEq(getGroupsDamaged(row), constraints) {
			return 1
		}
		return 0
	}

	// recurse
	ways := 0
	tmp := make([]byte, len(row))
	copy(tmp, row)

	tmp[firstQ] = '.'
	ways += solve(tmp, constraints)

	tmp[firstQ] = '#'
	ways += solve(tmp, constraints)
	return ways
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/12/ex.txt"
	puzz := parseInput(fname)

	p1tot := 0
	p2tot := 0
	for i, r := range puzz.rows {
		c := puzz.constraints[i]
		p1tot += solve(r, c)

		p2r := make([]byte, (len(r)+1)*5)
		p2c := make([]int, len(c)*5)

		ridx := 0
		cidx := 0
		for j := 0; j < 5; j++ {
			for _, v := range r {
				p2r[ridx] = v
				ridx++
			}
			if j < 4 {
				p2r[ridx] = '?'
				ridx++
			}

			for _, v := range c {
				p2c[cidx] = v
				cidx++
			}
		}
		fmt.Println("p2", string(p2r), p2c)
		// p2tot += solve(p2r, p2c)
	}

	fmt.Println("p1:", p1tot)
	fmt.Println("p2:", p2tot)
}
