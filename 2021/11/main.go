package main

import (
  "fmt"
  "strings"
  "strconv"

  "aoc/utils"
)

type Grid [][]int

var adjRange = []int{-1, 0, 1}

func loadGrid(lines []string) Grid {
  var grid Grid
  for _, l := range lines {
    grid = append(grid, utils.StrsToInts(strings.Split(l, "")))
  }
  return grid
}

func printGrid(grid Grid) {
  var lines []string
  for _, r := range grid {
    var l []string
    for _, v := range r {
      if v == 0 {
        l = append(l, fmt.Sprintf("\x1b[31m%d\033[0m", v))
      } else {
        l = append(l, strconv.Itoa(v))
      }
    }
    lines = append(lines, strings.Join(l, ""))
  }
  fmt.Println(strings.Join(lines, "\n"))
}

func stepGrid(grid Grid) int {
  for i, r := range grid {
    for j := range r {
      grid[i][j] += 1
    }
  }

  flashCount := 0
  for {
    flash := false
    for i, r := range grid {
      for j, v := range r {
        if v > 9 {
          grid[i][j] = 0
          flash = true
          flashCount++

          for _, di := range adjRange {
            for _, dj := range adjRange {
              x := i + di
              y := j + dj
              if (x < 0 || x >= len(grid)) || (y < 0 || y >= len(grid[0])) {
                continue
              }
              // this will also catch the case where we're re-updating the current spot
              if grid[x][y] == 0 {
                continue
              }

              grid[x][y] += 1
            }
          }
        }
      }
    }

    if !flash {
      break
    }
  }
  return flashCount
}

func main() {
  lines := utils.ReadLines("inp.txt")
  grid := loadGrid(lines)
  totFlash := 0
  i := 0
  for ; ; i++ {
    res := stepGrid(grid)
    if i < 100 {
      totFlash += res
    }
    if res == 100 {
      break
    }
  }
  fmt.Println("tot(at 100)", totFlash, "first all flash", i+1)
}
