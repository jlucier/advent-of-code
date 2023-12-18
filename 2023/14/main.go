package main

import (
	"fmt"
	"strings"

	"aoc/utils"
)

// Roll rocks to the right to left
// ..OO#..O  ->  OO..#O..
func rollLine(ln string) string {
	newLn := []byte(ln)

	toMove := 0
	for i := 0; i < len(ln); i++ {
		c := newLn[i]
		switch c {
		case '#':
			toMove = 0
		case 'O':
			if toMove > 0 {
				newLn[i-toMove] = c
				newLn[i] = '.'
			}
		case '.':
			toMove++
		}
	}
	return string(newLn)
}

func rollAll(lines []string) []string {
	newLines := make([]string, len(lines))
	for i, ln := range lines {
		newLines[i] = rollLine(ln)
	}
	return newLines
}

func calcNorthWeight(lines []string) int {
	tot := 0
	for i, ln := range lines {
		tot += strings.Count(ln, "O") * (len(lines) - i)
	}
	return tot
}

func p1(fname string) {
	// roll rocks north, tally load
	lines := utils.ReadLines(fname)

	// transpose makes north left, south right, east down, west up
	lines = rollAll(utils.Transpose(lines))

	// transpose back to get original coordinate system
	lines = utils.Transpose(lines)

	// calculate
	fmt.Println("p1:", calcNorthWeight(lines))
}

func p2(fname string) {
	n := 1_000_000_000
	lines := utils.ReadLines(fname)
	var states []string
	uniqS := utils.EmptySet[string]()

	for ci := 0; ci < n; ci++ {
		// north
		// transpose makes north left, south right, east down, west up
		lines = rollAll(utils.Transpose(lines))

		// west
		// transpose back puts us in original, this will roll west
		lines = rollAll(utils.Transpose(lines))

		// south
		// transpose makes north left, south right, east down, west up
		// reverse makes south left, north right, east down, west up
		lines = rollAll(utils.ReverseAll(utils.Transpose(lines)))

		// east
		// this undoes last operation, north up, south down, west left, east right
		lines = utils.Transpose(utils.ReverseAll(lines))
		// this rolls east and returns to og
		lines = utils.ReverseAll(rollAll(utils.ReverseAll(lines)))

		currS := strings.Join(lines, "\n")
		states = append(states, currS)

		if uniqS.Contains(currS) {
			cycleLen := 0
			for i := ci - 1; i >= 0; i-- {
				if states[i] == states[ci] {
					cycleLen = ci - i
					break
				}
			}

			remain := n - ci - 1
			// reset state to what it will be when we finish
			lines = strings.Split(states[ci-cycleLen+remain%cycleLen], "\n")
			break
		}
		uniqS.Add(currS)
	}

	fmt.Println("p2:", calcNorthWeight(lines))
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/14/input.txt"
	p1(fname)
	p2(fname)
}
