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
	winners := utils.NewSet[string]()
	mine := utils.NewSet[string]()

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

	mine.Intersect(winners)
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
	// TODO this is really slow. I think we can bank the answers to which
	// cards get added when processing cardI, the iteratively "expand" until
	// you run out rather than constantly having to reprocess

	// var answers map[int][]int
	// // make answer crib
	// for cardI, ln := range cards {
	// 	score := numWinners(ln)
	// 	answers[cardI] = make([]int, score)
	// 	for i := 1; i < score+1; i++ {
	// 		answers[cardI][i-1] = cardI + i
	// 	}
	// }

	numProcessed := 0
	cardQueue := utils.Range(0, len(cards))

	for len(cardQueue) > 0 {
		cardI := cardQueue[0]
		cardQueue = cardQueue[1:]
		numProcessed++

		score := numWinners(cards[cardI])

		for i := 1; i < score+1; i++ {
			cardQueue = append(cardQueue, cardI+i)
		}
	}
	fmt.Println("p2:", numProcessed)
}

func main() {
	p1("input.txt")
	p2("input.txt")
}
