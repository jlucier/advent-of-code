package main

import (
	"fmt"
	"strings"

	"aoc/utils"
)

// Data strcutures

type Point struct {
	x int
	y int
}

type Line struct {
	p1 Point
	p2 Point
}

func (l *Line) IsDiagonal() bool {
	return !(l.p1.x == l.p2.x || l.p1.y == l.p2.y)
}

func (l *Line) MaxX() int {
	return utils.Max(l.p1.x, l.p2.x)
}

func (l *Line) MinX() int {
	return utils.Min(l.p1.x, l.p2.x)
}

func (l *Line) MaxY() int {
	return utils.Max(l.p1.y, l.p2.y)
}

func (l *Line) MinY() int {
	return utils.Min(l.p1.y, l.p2.y)
}

func (l *Line) Coords() [][2]int {
	var coords [][2]int
	x := l.p1.x
	y := l.p1.y
  dx := 1
  dy := 1
  if l.p2.x < l.p1.x {
    dx = -1
  }
  if l.p2.y < l.p1.y {
    dy = -1
  }

	n := utils.Max(l.MaxY()-l.MinY(), l.MaxX()-l.MinX())

	diag := l.IsDiagonal()
	for i := 0; i <= n; i++ {
		coords = append(coords, [2]int{y, x})
    if diag || l.p1.x == l.p2.x {
      y += dy
    }
    if diag || l.p1.y == l.p2.y {
      x += dx
    }
	}

	return coords
}

// helpers

func parseLine(s string) Line {
	tokens := strings.Split(s, " -> ")
	if len(tokens) != 2 {
		panic("WTF")
	}

	p1 := utils.StrsToInts(strings.Split(tokens[0], ","))
	p2 := utils.StrsToInts(strings.Split(tokens[1], ","))
	return Line{Point{p1[0], p1[1]}, Point{p2[0], p2[1]}}
}

func makeBoard(ls []string, diag bool) ([][]int, []Line) {
	var lines []Line

	maxX := 0
	maxY := 0
	for _, l := range ls {
		line := parseLine(l)
		if !diag && line.IsDiagonal() {
			continue
		}
		maxX = utils.Max(maxX, line.MaxX())
		maxY = utils.Max(maxY, line.MaxY())
		lines = append(lines, line)
	}

	var board [][]int
	for i := 0; i <= maxY; i++ {
		board = append(board, make([]int, maxX+1))
	}

	for _, l := range lines {
		for _, c := range l.Coords() {
			board[c[0]][c[1]] += 1
		}
	}
	return board, lines
}

func solve(diag bool) {
	ls := utils.ReadLines("inp.txt")
	board, _ := makeBoard(ls, diag)
	count := 0
	for _, r := range board {
		for _, v := range r {
			if v >= 2 {
				count += 1
			}
		}
	}
	// for _, r := range board {
	// 	fmt.Println(r)
	// }
	fmt.Println("count:", count)
}

func part1() {
	solve(false)
}

func part2() {
	solve(true)
}

func main() {
	part2()
}
