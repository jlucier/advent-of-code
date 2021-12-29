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
type Point [2]int

type PointSet struct {
  m map[Point]interface{}
}

func NewPointSet() *PointSet {
  ps := &PointSet{}
  ps.m = make(map[Point]interface{})
  return ps
}

func (s *PointSet) Add(p Point) *PointSet {
  s.m[p] = struct{}{}
  return s
}

func (s *PointSet) Remove(p Point) {
  delete(s.m, p)
}

func (s *PointSet) Size() int {
  return len(s.m)
}

func (s *PointSet) Values() []Point {
  var points []Point
  for p := range s.m {
    points = append(points, p)
  }
  return points
}

// solution

func parseInput(filename string) (*PointSet, []Fold) {
  lines := utils.ReadLines(filename)
  points := NewPointSet()
  var folds []Fold
  for _, l := range lines {
    if strings.HasPrefix(l, "fold") {
      tokens := strings.Split(l, " ")
      comps := strings.Split(tokens[2], "=")
      i, _ := strconv.Atoi(comps[1])
      folds = append(folds, Fold{comps[0], i})
    } else {
      comps := utils.StrsToInts(strings.Split(l, ","))
      points.Add(Point{comps[0], comps[1]})
    }
  }
  return points, folds
}

func printGrid(ps *PointSet) {
  maxX := 0
  maxY := 0
  points := ps.Values()
  for _, p := range points {
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

  for _, p := range points {
    grid[p[1]][p[0]] = "#"
  }

  lines := make([]string, len(grid))
  for i, r := range grid {
    lines[i] = strings.Join(r, "")
  }
  fmt.Println(strings.Join(lines, "\n"))
}

func fold(ps *PointSet, f Fold) {
  pi := 0
  if f.axis == "y" {
    pi = 1
  }

  for _, p := range ps.Values() {
    val := p[pi]
    if val < f.index {
      continue
    }
    ps.Remove(p)
    newp := Point{p[0], p[1]}
    newp[pi] = f.index - (val - f.index)
    ps.Add(newp)
  }
}

func main() {
  points, folds := parseInput("inp.txt")
  for i, f := range folds {
    fold(points, f)
    if i == 0 {
      fmt.Println("after 1", points.Size())
    }
  }
  printGrid(points)
}
