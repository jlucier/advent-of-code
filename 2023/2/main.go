package main

import (
	"fmt"
	"strconv"
	"strings"

	"aoc/utils"
)

type rgb struct {
	red   int
	green int
	blue  int
}

type game struct {
	id      int
	reveals []rgb
}

func (gm *game) Maxes() rgb {
	maxes := rgb{0, 0, 0}
	for _, rv := range gm.reveals {
		maxes.red = utils.Max(maxes.red, rv.red)
		maxes.green = utils.Max(maxes.green, rv.green)
		maxes.blue = utils.Max(maxes.blue, rv.blue)
	}

	return maxes
}

func parseGame(ln string) game {
	var gm game

	halves := strings.Split(ln, ": ")
	id, err := strconv.Atoi(strings.Split(halves[0], " ")[1])
	if err != nil {
		panic(err)
	}
	gm.id = id

	for _, rv := range strings.Split(halves[1], "; ") {
		var dat rgb
		for _, colorStr := range strings.Split(rv, ", ") {
			parts := strings.Split(colorStr, " ")
			i, err := strconv.Atoi(parts[0])
			if err != nil {
				panic(err)
			}

			switch parts[1] {
			case "red":
				dat.red = i
			case "green":
				dat.green = i
			case "blue":
				dat.blue = i
			default:
				panic("Bad bad")
			}

		}

		gm.reveals = append(gm.reveals, dat)
	}

	return gm
}

func p1() {
	lines := utils.ReadLines("input.txt")
	constraints := rgb{12, 13, 14}

	total := 0
	for _, ln := range lines {
		gm := parseGame(ln)

		maxes := gm.Maxes()
		if maxes.red > constraints.red ||
			maxes.green > constraints.green ||
			maxes.blue > constraints.blue {
			continue
		}

		// passes
		total += gm.id
	}

	fmt.Println("Total:", total)
}

func p2() {
	lines := utils.ReadLines("input.txt")

	total := 0
	for _, ln := range lines {
		gm := parseGame(ln)

		maxes := gm.Maxes()
		total += maxes.red * maxes.green * maxes.blue
	}

	fmt.Println("Total:", total)
}

func main() {
	p2()
}
