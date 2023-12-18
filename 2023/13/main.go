package main

import (
	"fmt"

	"aoc/utils"
)

func parseFile(fname string) [][]string {
	lines := utils.ReadAllLines(fname)

	var result [][]string
	result = append(result, []string{})

	for _, ln := range lines {
		lastI := len(result) - 1
		if ln == "" {
			result = append(result, []string{})
		} else {
			result[lastI] = append(result[lastI], ln)
		}
	}
	return result
}

// Find the row index for which the map is mirrored between index and index + 1
func findMirror(m []string) int {
	for i := 0; i < len(m)-1; i++ {
		match := true
		for d := 0; d < i+1; d++ {
			if i+1+d < len(m) && m[i-d] != m[i+1+d] {
				match = false
				break
			}
		}
		if match {
			return i
		}
	}
	return -1
}

func p1(maps [][]string) {
	tot := 0
	for _, m := range maps {
		row := findMirror(m)
		if row >= 0 {
			tot += (row + 1) * 100
		} else {
			col := findMirror(utils.Transpose(m))
			tot += col + 1
		}
	}

	fmt.Println("p1:", tot)
}

type Coord struct {
	row int
	col int
}

func findDiffs(m []string) [][]Coord {
	mismatches := make([][]Coord, len(m))

	for i := 0; i < len(m)-1; i++ {
		for d := 0; d < i+1; d++ {
			if i+1+d >= len(m) {
				break
			}

			for ci := 0; ci < len(m[0]); ci++ {
				if m[i-d][ci] != m[i+1+d][ci] {
					mismatches[i] = append(mismatches[i], Coord{i - d, ci})
				}
			}
		}
	}

	return mismatches
}

func findSingleDiff(m []string) int {
	for i, d := range findDiffs(m) {
		if len(d) == 1 {
			return i
		}
	}
	return -1
}

func p2(maps [][]string) {
	tot := 0

	for _, m := range maps {
		row := findSingleDiff(m)
		if row >= 0 {
			tot += (row + 1) * 100
		} else {
			col := findSingleDiff(utils.Transpose(m))
			tot += col + 1
		}
	}

	fmt.Println("p2:", tot)
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/13/input.txt"
	maps := parseFile(fname)

	p1(maps)
	p2(maps)
}
