package main

import (
	"testing"
)

func TestRoll(t *testing.T) {
	in := []string{
		"....O#....",
		".OOO#....#",
		".....##...",
		".OO#..O..O",
		"......OO#.",
	}
	out := []string{
		"O....#....",
		"OOO.#....#",
		".....##...",
		"OO.#OO....",
		"OO......#.",
	}

	for i := range in {
		ans := rollLine(in[i])
		if out[i] != ans {
			t.Fatalf("Roll %s expected %s got %s", in[i], out[i], ans)
		}
	}

}
