package main

import (
	"fmt"
	"math"
	"strings"

	"aoc/utils"
)

type Galaxy struct {
	row int
	col int
}

func (self *Galaxy) AbsDiff(other *Galaxy) (int, int) {
	return int(math.Abs(float64(self.row - other.row))), int(math.Abs(float64(self.col - other.col)))
}

type Universe struct {
	grid     [][]int
	galaxies []Galaxy
}

func (self *Universe) Print() {

	for _, row := range self.grid {
		var b strings.Builder
		for _, i := range row {
			if i == 0 {
				b.WriteByte('.')
			} else {
				b.WriteByte('#')
			}
		}
		fmt.Println(b.String())
	}
}

func (self *Universe) CalculateGalaxies(expansionFactor int) {
	rows := utils.EmptySet[int]()
	cols := utils.EmptySet[int]()

	// calculate the rows / cols that need expanding

	colSums := make([]int, len(self.grid[0]))
	for i, gr := range self.grid {
		rowSum := 0
		for j, v := range gr {
			rowSum += v
			colSums[j] += v
		}

		if rowSum == 0 {
			rows.Add(i)
		}
	}
	for i, c := range colSums {
		if c == 0 {
			cols.Add(i)
		}
	}

	// Now do galaxies
	self.galaxies = []Galaxy{}
	mult := utils.Max(expansionFactor-1, 1)
	addedRows := 0
	for i, r := range self.grid {
		if rows.Contains(i) {
			addedRows++
			continue
		}
		adjI := i + addedRows*mult

		addedCols := 0
		for j, v := range r {
			if cols.Contains(j) {
				addedCols++
				continue
			}
			adjJ := j + addedCols*mult

			if v == 1 {
				self.galaxies = append(self.galaxies, Galaxy{adjI, adjJ})
			}
		}
	}
}

func (self *Universe) SumDist() int {
	sumDist := 0
	for i, g1 := range self.galaxies {
		for _, g2 := range self.galaxies[i+1:] {
			r, c := g1.AbsDiff(&g2)
			sumDist += r + c
		}
	}

	return sumDist
}

func parseUniverse(fname string) Universe {
	lines := utils.ReadLines(fname)
	uni := Universe{make([][]int, len(lines)), []Galaxy{}}

	for i, ln := range lines {
		uni.grid[i] = make([]int, len(ln))
		for j, c := range ln {
			if c == '#' {
				uni.grid[i][j] = 1
			}
		}
	}
	return uni
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/11/input.txt"
	uni := parseUniverse(fname)
	// uni.Print()

	uni.CalculateGalaxies(1)
	fmt.Println("p1:", uni.SumDist())

	uni.CalculateGalaxies(1_000_000)
	fmt.Println("p2:", uni.SumDist())
}
