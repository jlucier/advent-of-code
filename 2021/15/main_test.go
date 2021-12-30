package main

import (
  "testing"

  "aoc/utils"
)

func BenchmarkPath(b *testing.B) {
  grid := utils.ParseIntGrid(utils.ReadLines("inp.txt"), "")
  big := makePart2Grid(grid)
  bestPath(big)
}
