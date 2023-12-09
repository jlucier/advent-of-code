package main

import (
	"fmt"
	"regexp"

	"aoc/utils"
)

type StartNode struct {
	node     string
	offset   int
	cycleLen int
}

type Data struct {
	directions string
	graph      map[string][]string
}

func (self *Data) traverseFrom(node string, startSteps int, allZ bool) (int, string) {
	steps := startSteps

	endCond := func() bool {
		if allZ {
			return node == "ZZZ"
		}
		return node[len(node)-1] == 'Z'
	}

	for ; !endCond() || steps == startSteps; steps++ {
		opts := self.graph[node]
		next := self.directions[steps%len(self.directions)]

		if next == 'L' {
			node = opts[0]
		} else {
			node = opts[1]
		}
	}
	return steps - startSteps, node
}

func parseGraph(fname string) Data {
	lines := utils.ReadLines(fname)

	data := Data{
		lines[0],
		make(map[string][]string),
	}
	re := regexp.MustCompile("[0-9A-Z]+")

	for i := 1; i < len(lines); i++ {
		parts := re.FindAllString(lines[i], -1)
		data.graph[parts[0]] = parts[1:]
	}
	return data
}

func p1(fname string) {
	data := parseGraph(fname)
	steps, _ := data.traverseFrom("AAA", 0, true)
	fmt.Println("p1:", steps)
}

func p2(fname string) {
	data := parseGraph(fname)
	var startNodes []StartNode
	for node := range data.graph {
		if node[len(node)-1] == 'A' {
			sn := StartNode{node, 0, 0}
			off, endCond := data.traverseFrom(node, 0, false)
			sn.offset = off
			cycle, _ := data.traverseFrom(endCond, off, false)
			sn.cycleLen = cycle
			startNodes = append(startNodes, sn)
		}
	}

	// turns out, the inputs are nice and prime so this just works
	tot := 1
	for _, sn := range startNodes {
		tot *= sn.offset / len(data.directions)
	}
	fmt.Println("p2:", tot*len(data.directions))
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/8/input.txt"
	// p1(fname)
	p2(fname)
}
