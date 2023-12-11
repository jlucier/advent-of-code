package main

import (
	"fmt"
	"math"
	"regexp"
	"strings"

	"aoc/utils"
)

func numWinners(ln string) int {
	re := regexp.MustCompile("[0-9]+")
	winners := utils.EmptySet[string]()
	mine := utils.EmptySet[string]()

	// remove prefix
	ln = ln[strings.Index(ln, ":")+1:]
	dividerIdx := strings.Index(ln, "|")
	winningNums := ln[:dividerIdx-1]
	myNums := ln[dividerIdx+1:]

	for _, m := range re.FindAllStringIndex(winningNums, -1) {
		winners.Add(winningNums[m[0]:m[1]])
	}
	for _, m := range re.FindAllStringIndex(myNums, -1) {
		mine.Add(myNums[m[0]:m[1]])
	}

	mine.IntersectionUpdate(winners.Values())
	return mine.Size()
}

func p1(fname string) {
	lines := utils.ReadLines(fname)

	score := 0
	for _, ln := range lines {
		score += int(math.Pow(2, float64(numWinners(ln))-1))
	}

	fmt.Println("p1:", score)
}

func p2(fname string) {
	cards := utils.ReadLines(fname)

	counts := make([]int, len(cards))
	for i, c := range cards {
		counts[i] += 1
		score := numWinners(c)
		for j := 1; j < score+1; j++ {
			counts[i+j] += counts[i]
		}
	}

	fmt.Println("p2:", utils.Sum(counts))
}

func main() {
	p1("input.txt")
	p2("input.txt")
}
