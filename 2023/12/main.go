package main

import (
	"fmt"
	"strings"

	"aoc/utils"
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

// NFA solution inspired by others
// https://github.com/clrfl/AdventOfCode2023/blob/master/12/explanation.ipynb
func solve(row []byte, constraints []int) int {
	var sb strings.Builder
	sb.WriteByte('.')
	for _, c := range constraints {
		for i := 0; i < c; i++ {
			sb.WriteByte('#')
		}
		sb.WriteByte('.')
	}

	states := sb.String()
	endStates := []int{len(states) - 1, len(states) - 2}
	currStates := make(map[int]int)
	currStates[0] = 1

	for _, char := range row {
		nextStates := make(map[int]int)

		for s, count := range currStates {
			switch states[s] {
			case '.':
				if char == '#' {
					if s+1 < len(states) {
						nextStates[s+1] += count
					}
				} else {
					nextStates[s] += count
					if char == '?' && s+1 < len(states) {
						nextStates[s+1] += count
					}
				}
			case '#':
				if s+1 >= len(states) {
					continue
				}

				if char == '?' {
					nextStates[s+1] += count
				} else {
					// non-? char, advance if the next state is that char
					// (means: if we're #, next is ., only advance if .)
					if states[s+1] == char {
						nextStates[s+1] += count
					}
				}
			}
		}
		currStates = nextStates
	}

	tot := 0
	for _, es := range endStates {
		tot += currStates[es]
	}
	return tot
}

func makeP2Inp(r []byte, c []int) ([]byte, []int) {
	p2r := make([]byte, len(r)*5+4)
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

	return p2r, p2c
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/12/input.txt"
	puzz := parseInput(fname)

	p1tot := 0
	p2tot := 0
	for i, r := range puzz.rows {
		c := puzz.constraints[i]
		p1tot += solve(r, c)
		p2r, p2c := makeP2Inp(r, c)
		p2tot += solve(p2r, p2c)
	}

	fmt.Println("p1:", p1tot)
	fmt.Println("p2:", p2tot)
}
