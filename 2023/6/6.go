package main

import (
	"fmt"
	"regexp"

	"aoc/utils"
)

type Race struct {
	time     int
	bestDist int
}

func (self *Race) CalculateDist(pressTime int) int {
	return pressTime * (self.time - pressTime)
}

func (self *Race) Outcomes() []int {
	outcomes := make([]int, self.time+1)
	for i := 0; i <= self.time; i++ {
		outcomes[i] = self.CalculateDist(i)
	}
	return outcomes
}

func (self *Race) WaysToWin() int {
	wins := 0
	for _, o := range self.Outcomes() {
		if o > self.bestDist {
			wins++
		}
	}
	return wins
}

func p1(fname string) {
	lines := utils.ReadLines(fname)
	re := regexp.MustCompile("[0-9]+")
	times := utils.StrsToInts(re.FindAllString(lines[0], -1))
	dists := utils.StrsToInts(re.FindAllString(lines[1], -1))
	races := make([]Race, len(times))

	for i := 0; i < len(times); i++ {
		races[i] = Race{times[i], dists[i]}
	}
	waysToWin := 1
	for _, r := range races {
		waysToWin *= r.WaysToWin()
	}

	fmt.Println("p1:", waysToWin)
}

func p2(fname string) {
	lines := utils.ReadLines(fname)
	re := regexp.MustCompile("[^0-9]+")
	time := utils.StrToInt(re.ReplaceAllString(lines[0], ""))
	dist := utils.StrToInt(re.ReplaceAllString(lines[1], ""))
	race := Race{time, dist}
	fmt.Println("p2:", race.WaysToWin())
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/6/input.txt"
	p1(fname)
	p2(fname)
}
