package main

import (
  "fmt"
  "strconv"
  "strings"

  "aoc/utils"
)

// helper

type Fold struct {
  axis string
  index int
}

// solution

func parseInput(filename string) (utils.PointSet, []Fold) {
  lines := utils.ReadLines(filename)
  points := utils.NewPointSet()
  var folds []Fold
  for _, l := range lines {
    if strings.HasPrefix(l, "fold") {
      tokens := strings.Split(l, " ")
      comps := strings.Split(tokens[2], "=")
      i, _ := strconv.Atoi(comps[1])
      folds = append(folds, Fold{comps[0], i})
    } else {
      comps := utils.StrsToInts(strings.Split(l, ","))
      points.Add(utils.Point{comps[0], comps[1]})
    }
  }
  return points, folds
}

func printGrid(ps utils.PointSet) {
  maxX := 0
  maxY := 0
  for p := range ps {
    maxX = utils.Max(p[0], maxX)
    maxY = utils.Max(p[1], maxY)
  }

  grid := make([][]string, maxY+1)
  for i := 0; i <= maxY; i++ {
    grid[i] = make([]string, maxX+1)
    for j := 0; j <= maxX; j++ {
      grid[i][j] = "."
    }
  }

  for p := range ps {
    grid[p[1]][p[0]] = "#"
  }

  lines := make([]string, len(grid))
  for i, r := range grid {
    lines[i] = strings.Join(r, "")
  }
  fmt.Println(strings.Join(lines, "\n"))
}

func fold(ps utils.PointSet, f Fold) {
  pi := 0
  if f.axis == "y" {
    pi = 1
  }

  for p := range ps {
    val := p[pi]
    if val < f.index {
      continue
    }
    ps.Remove(p)
    newp := utils.Point{p[0], p[1]}
    newp[pi] = f.index - (val - f.index)
    ps.Add(newp)
  }
}

func main() {
  points, folds := parseInput("inp.txt")
  for i, f := range folds {
    fold(points, f)
    if i == 0 {
      fmt.Println("after 1", len(points))
    }
  }
  printGrid(points)
}
