package main

import (
  "fmt"
  "math"
  "sort"

  "aoc/utils"
)

// help

type PointCost struct {
  pos utils.Point
  cost int
}

type PCArr []*PointCost

func (s PCArr) Len() int {
  return len(s)
}

func (s PCArr) Swap(i, j int) {
    s[i], s[j] = s[j], s[i]
}
func (s PCArr) Less(i, j int) bool {
    return s[i].cost < s[j].cost
}

// soln

func bestPath(grid utils.IntGrid) *PointCost {
  numElems := len(grid) * len(grid[0])
  pcs := make(map[utils.Point]*PointCost, numElems)

  for i := 0; i < len(grid); i++ {
    for j := 0; j < len(grid); j++ {
      c := math.MaxInt64
      if i == 0 && j == 0 {
        c = 0
      }
      p := utils.Point{j,i}
      pcs[p] = &PointCost{p, c}
    }
  }

  end := utils.Point{len(grid[0])-1, len(grid)-1}
  queue := PCArr{pcs[utils.Point{0, 0}]}
  for len(queue) > 0{
    curr := queue[0]
    queue = queue[1:]

    if curr.pos == end {
      return curr
    }

    for _, p := range grid.Neighbors(curr.pos) {
      pc, _ := pcs[p]
      c := curr.cost + grid[p[1]][p[0]]
      if c < pc.cost {
        pc.cost = c
        queue = append(queue, pc)
      }
    }

    sort.Sort(queue)
  }
  return pcs[end]
}

func makePart2Grid(grid utils.IntGrid) utils.IntGrid {
  // make bigger grid
  ogH := grid.Height()
  ogW := grid.Width()
  big := make(utils.IntGrid, len(grid) * 5)
  for i := range big {
    big[i] = make([]int, len(grid[0]) * 5)
    for j := range big[0] {
      v := grid[i%ogH][j%ogW] + i/ogH + j/ogW
      if v > 9 {
        v = v % 10 + 1
      }
      big[i][j] = v
    }
  }
  return big
}


func main() {
  grid := utils.ParseIntGrid(utils.ReadLines("inp.txt"), "")
  big := makePart2Grid(grid)

  // part1
  fmt.Println("part1", bestPath(grid).cost)
  fmt.Println("part2", bestPath(big).cost)
  // fmt.Println(big.ToStrf(func(p utils.Point, v int) string {
  //   if p[0] < len(grid) && p[1] < len(grid[0]) {
  //     return utils.RedInt(v)
  //   }
  //   return strconv.Itoa(v)
  // }))
  // fmt.Println(big.ToStr())
}
