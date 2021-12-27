package main

import (
  "fmt"
  "sort"
  "strings"

  "aoc/utils"
)

type Grid [][]int
type Point [2]int
type Basin []Point
type BasinArr []Basin

func (s BasinArr) Len() int {
    return len(s)
}
func (s BasinArr) Swap(i, j int) {
    s[i], s[j] = s[j], s[i]
}
func (s BasinArr) Less(i, j int) bool {
    return len(s[i]) < len(s[j])
}

func loadGrid(fname string) Grid {
  lines := utils.ReadLines(fname)

  var grid Grid
  for _, l := range lines {
    grid = append(grid, utils.StrsToInts(strings.Split(l, "")))
  }
  return grid
}

func findLowPoints(grid Grid) []Point {
  var points []Point
  for j, r := range grid {
    for i, v := range r {
      if !(
        (j > 0 && v >= grid[j-1][i]) ||
        (j < len(grid)-1 && v >= grid[j+1][i]) ||
        (i > 0 && v >= grid[j][i-1]) ||
        (i < len(grid[0])-1 && v >= grid[j][i+1])) {
        points = append(points, Point{j,i})
      }
    }
  }
  return points
}

func lesserNeighbors(grid Grid, y int, x int, visited [][]bool) int {
  v := grid[y][x]
  lessers := 0
  if y > 0 && grid[y-1][x] < v && !visited[y-1][x] {
    lessers++
  }
  if y < len(grid)-1 && grid[y+1][x] < v && !visited[y+1][x] {
    lessers++
  }
  if x > 0 && grid[y][x-1] < v && !visited[y][x-1]{
    lessers++
  }
  if x < len(grid[0])-1 && grid[y][x+1] < v && !visited[y][x+1] {
    lessers++
  }
  return lessers
}

func walkBasin(y int, x int, grid Grid) Basin {
  visited := make([][]bool, len(grid))
  for i := range visited {
    visited[i] = make([]bool, len(grid[0]))
  }

  var points []Point
  queue := []Point{{y,x}}

  for len(queue) > 0 {
    p := queue[0]
    i := p[0]
    j := p[1]
    v := grid[i][j]

    queue = queue[1:]
    if v == 9 || visited[i][j] || lesserNeighbors(grid, i, j, visited) > 0 {
      continue
    }
    visited[p[0]][p[1]] = true
    points = append(points, p)

    if i > 0 && grid[i-1][j] > v {
      queue = append(queue, Point{i-1, j})
    }
    if i < len(grid)-1 && grid[i+1][j] > v {
      queue = append(queue, Point{i+1, j})
    }
    if j > 0 && grid[i][j-1] > v {
      queue = append(queue, Point{i, j-1})
    }
    if j < len(grid[0])-1 && grid[i][j+1] > v {
      queue = append(queue, Point{i, j+1})
    }
  }

  return points
}

func printBasin(grid Grid, basin []Point) {
  for i, r := range grid {
    for j, v := range r {
      hit := false
      for _, p := range basin {
        np := Point{i, j}
        if p == np {
          hit = true
          fmt.Printf("\x1b[31m%d\033[0m", v)
        }
      }
      if !hit {
        fmt.Print(v)
      }
    }
    fmt.Println()
  }
}

func part1() {
  grid := loadGrid("inp.txt")

  points := findLowPoints(grid)
  risk := 0
  for _, p := range points {
    risk += grid[p[0]][p[1]] + 1
  }

  fmt.Println("risk", risk)
}

func part2() {
  grid := loadGrid("inp.txt")
  points := findLowPoints(grid)

  var basins BasinArr
  for _, p := range points {
    basins = append(basins, walkBasin(p[0], p[1], grid))
  }

  sort.Sort(sort.Reverse(basins))

  tot := 1
  for i, b := range basins {
    if i > 2 {
      break
    }
    // fmt.Println("\nbasin:", i, len(b))
    tot *= len(b)
    // printBasin(grid, b)
  }

  fmt.Println("tot", tot)
}

func main() {
  part2()
}
