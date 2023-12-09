package main

import (
	"fmt"
	"regexp"

	"aoc/utils"
)

func parseSequences(fname string) [][]int {
	lines := utils.ReadLines(fname)
	re := regexp.MustCompile("[^\\s]+")

	seqs := make([][]int, len(lines))
	for i, ln := range lines {
		seqs[i] = utils.StrsToInts(re.FindAllString(ln, -1))
	}

	return seqs
}

func seqDone(seq []int) bool {
	for _, v := range seq {
		if v != 0 {
			return false
		}
	}
	return true
}

func extrapolate(seq []int) int {
	fmt.Println()
	curr := make([]int, len(seq))
	copy(curr, seq)
	var lastNums []int

	for !seqDone(curr) {
		fmt.Println(curr)
		lastNums = append(lastNums, curr[len(curr)-1])
		next := make([]int, len(curr)-1)
		for i := 0; i < len(curr)-1; i++ {
			next[i] = curr[i+1] - curr[i]
		}
		curr = next
	}

	lastLast := 0
	for i := len(lastNums) - 1; i >= 0; i-- {
		lastNums[i] += lastLast
		lastLast = lastNums[i]
	}
	fmt.Println(lastNums)
	return lastNums[0]
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/9/input.txt"
	seqs := parseSequences(fname)
	p1 := 0
	p2 := 0
	for _, s := range seqs {
		p1 += extrapolate(s)
		p2 += extrapolate(utils.Reversed(s))
	}
	fmt.Println("p1:", p1)
	fmt.Println("p2:", p2)
}
