package main

import (
	"fmt"
	"math"
	"regexp"

	"aoc/utils"
)

func waysToWin(time, bestDist int) int {
	secondTerm := math.Sqrt(math.Pow(float64(time), 2) - 4.0*float64(bestDist+1))
	root1 := (float64(time) - secondTerm) / 2
	root2 := (float64(time) + secondTerm) / 2
	return int(math.Floor(root2)-math.Ceil(root1)) + 1
}

func p1(fname string) {
	lines := utils.ReadLines(fname)
	re := regexp.MustCompile("[0-9]+")
	times := utils.StrsToInts(re.FindAllString(lines[0], -1))
	dists := utils.StrsToInts(re.FindAllString(lines[1], -1))

	wins := 1
	for i := 0; i < len(times); i++ {
		wins *= waysToWin(times[i], dists[i])
	}
	fmt.Println("p1:", wins)
}

func p2(fname string) {
	lines := utils.ReadLines(fname)
	re := regexp.MustCompile("[^0-9]+")
	time := utils.StrToInt(re.ReplaceAllString(lines[0], ""))
	dist := utils.StrToInt(re.ReplaceAllString(lines[1], ""))
	fmt.Println("p2:", waysToWin(time, dist))
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/6/input.txt"
	p1(fname)
	p2(fname)
}
