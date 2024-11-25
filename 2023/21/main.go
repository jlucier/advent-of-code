package main

import (
	"fmt"

	"aoc/utils"
)

func parse(fname string) utils.Grid[byte] {
	lines := utils.ReadLines(fname)
	gd := make([][]byte, len(lines))
	for i, ln := range lines {
		gd[i] = []byte(ln)
	}

	return utils.Grid[byte]{Cells: gd}
}

func findStart(gd *utils.Grid[byte]) utils.V2 {
	for i, row := range gd.Cells {
		for j, v := range row {
			if v == 'S' {
				return utils.V2{X: j, Y: i}
			}
		}
	}
	return utils.V2{}
}

type Path struct {
	curr   utils.V2
	length int
}

func p1(gd *utils.Grid[byte]) {
	s := findStart(gd)
	steps := 64

	queue := []Path{{s, 0}}
	seen := utils.EmptySet[Path]()
	count := 0

	for len(queue) > 0 {
		n := queue[0]
		queue = queue[1:]
		seen.Add(n)

		if n.length == steps {
			count++
		} else if n.length > steps {
			continue
		}

		for _, c := range gd.Neighbors(n.curr, false) {
			next := Path{c, n.length + 1}
			if !seen.Contains(next) && gd.At(c) == '.' && n.length+1 <= steps {
				queue = append(queue, next)
				seen.Add(next)
			}
		}
	}

	fmt.Println("p1:", count+1)
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/21/input.txt"
	gd := parse(fname)
	p1(&gd)
}
