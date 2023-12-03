package main

import (
	"fmt"
	"math"
	"regexp"

	"aoc/utils"
)

type PuzzleNum struct {
	row    int
	col    int
	length int
	value  int
}

type Point struct {
	sym string
	row int
	col int
}

type Schematic struct {
	nums    []PuzzleNum
	gears   []Point
	symbols []Point
}

func parseSchematic(fname string) Schematic {
	lines := utils.ReadLines(fname)
	var schem Schematic

	numRegex := regexp.MustCompile("[0-9]+")
	gearRegex := regexp.MustCompile("\\*")
	otherRegex := regexp.MustCompile("[^0-9.]")

	for i, ln := range lines {
		// nums
		for _, idx := range numRegex.FindAllStringIndex(ln, -1) {
			schem.nums = append(schem.nums, PuzzleNum{
				i,                                 // row
				idx[0],                            // col
				idx[1] - idx[0],                   // length
				utils.StrToInt(ln[idx[0]:idx[1]]), // value
			})
		}

		// symbols
		for _, idx := range otherRegex.FindAllStringIndex(ln, -1) {
			schem.symbols = append(schem.symbols, Point{ln[idx[0] : idx[0]+1], i, idx[0]})
		}

		// gears
		for _, idx := range gearRegex.FindAllStringIndex(ln, -1) {
			schem.gears = append(schem.gears, Point{ln[idx[0] : idx[0]+1], i, idx[0]})
		}
	}

	return schem
}

func p1(schem *Schematic) int {
	sumP1 := 0
	for _, n := range schem.nums {
		for _, sym := range append(schem.gears, schem.symbols...) {
			if math.Abs(float64(sym.row-n.row)) <= 1 &&
				utils.Between(sym.col, n.col-1, n.col+n.length+1) {
				sumP1 += n.value
				break
			}
		}
	}

	return sumP1
}

func p2(schem *Schematic) int {
	sumP2 := 0
	for _, sym := range schem.gears {
		var near []int

		for _, n := range schem.nums {
			if math.Abs(float64(sym.row-n.row)) <= 1 &&
				utils.Between(sym.col, n.col-1, n.col+n.length+1) {
				near = append(near, n.value)
			}
		}

		if len(near) == 2 {
			sumP2 += near[0] * near[1]
		}
	}
	return sumP2
}

func main() {
	schem := parseSchematic("input.txt")
	fmt.Println("p1:", p1(&schem))
	fmt.Println("p2:", p2(&schem))
}
