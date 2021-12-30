package utils

import (
  "fmt"
  "io/ioutil"
  "math"
  "sort"
  "strconv"
  "strings"
)

func RedInt(v int) string {
  return fmt.Sprintf("\x1b[31m%d\033[0m", v)
}

func Red(s string) string {
  return fmt.Sprintf("\x1b[31m%s\033[0m", s)
}

func ReadLines(filename string) []string {
  var ret []string
  buf, err := ioutil.ReadFile(filename)

  if err != nil {
    panic(err)
  }

  for _, v := range strings.Split(string(buf), "\n") {
    if v != "" {
      ret = append(ret, v)
    }
  }
  return ret
}

func Sum(s []int) int {
  tot := 0
  for _, v := range s {
    tot += v
  }
  return tot
}

func MinMax(s []int) (int, int) {
  min := 0
  max := 0
  for _, v := range s {
    min = Min(min, v)
    max = Max(max, v)
  }
  return min, max
}

func Range(s int, e int) []int {
  var ret []int
  for i := s; i < e; i++ {
    ret = append(ret, i)
  }
  return ret
}

func Max(a, b int) int {
  return int(math.Max(float64(a), float64(b)))
}

func Min(a, b int) int {
  return int(math.Min(float64(a), float64(b)))
}

func Clamp(val, min, max int) int {
  return Min(Max(val, min), max)
}

func CountWhere(s []int, v int) int {
  count := 0
  for _, n := range s {
    if n == v {
      count++
    }
  }
  return count
}

func StrsToInts(str []string) []int {
  var res []int
  for _, s := range str {
    n, err := strconv.Atoi(s)
    if err != nil {
      panic(err)
    }
    res = append(res, n)
  }
  return res
}

func IntsToStrs(ints []int) []string {
  var res []string
  for _, v := range ints {
    res = append(res, fmt.Sprint(v))
  }
  return res
}

var exists = struct{}{}

type IntSet map[int]struct{}

func NewIntSet() IntSet {
  return make(IntSet)
}

func (s IntSet) Add(value int) IntSet {
  s[value] = exists
  return s
}

func (s IntSet) AddAll(values[] int) IntSet {
  for _, v := range values {
    s.Add(v)
  }
  return s
}

func (s IntSet) Remove(value int) {
  delete(s, value)
}

func (s IntSet) Contains(value int) bool {
  _, c := s[value]
  return c
}

func (s IntSet) ContainsAll(nums []int) bool {
  for _, v := range nums {
    if !s.Contains(v) {
      return false
    }
  }
  return true
}

func (s IntSet) Values() []int {
  var vals []int
  for k := range s {
    vals = append(vals, k)
  }
  return vals
}

func (s IntSet) Intersect(other IntSet) {
  for v := range s {
    if !other.Contains(v) {
      s.Remove(v)
    }
  }
}

func (s IntSet) Copy() IntSet {
  return NewIntSet().AddAll(s.Values())
}

func (s IntSet) ToStr() string {
  v := s.Values()
  sort.Ints(v)
  return fmt.Sprint("IntSet{", strings.Join(IntsToStrs(v), ", "), "}")
}

func (s IntSet) Equals(other IntSet) bool {
  return s.ContainsAll(other.Values()) && other.ContainsAll(s.Values())
}

// StrSet

type StrSet map[string]struct{}

func NewStrSet() StrSet {
  return make(StrSet)
}

func (s StrSet) Add(value string) StrSet {
  s[value] = exists
  return s
}

func (s StrSet) AddAll(values[] string) StrSet {
  for _, v := range values {
    s.Add(v)
  }
  return s
}

func (s StrSet) Remove(value string) {
  delete(s, value)
}

func (s StrSet) Contains(value string) bool {
  _, c := s[value]
  return c
}

func (s StrSet) ContainsAll(nums []string) bool {
  for _, v := range nums {
    if !s.Contains(v) {
      return false
    }
  }
  return true
}

func (s StrSet) Values() []string {
  var vals []string
  for k := range s {
    vals = append(vals, k)
  }
  return vals
}

func (s StrSet) Intersect(other StrSet) {
  for v := range s {
    if !other.Contains(v) {
      s.Remove(v)
    }
  }
}

func (s StrSet) Copy() StrSet {
  return NewStrSet().AddAll(s.Values())
}

func (s StrSet) ToStr() string {
  v := s.Values()
  sort.Strings(v)
  return fmt.Sprint("StrSet{", strings.Join(v, ", "), "}")
}

func (s StrSet) Equals(other StrSet) bool {
  return s.ContainsAll(other.Values()) && other.ContainsAll(s.Values())
}


// Point / Grid

type Point [2]int
type IntGrid [][]int

func ParseIntGrid(lines[]string, sep string) IntGrid {
  grid := make(IntGrid, len(lines))
  for i, l := range lines {
    grid[i] = StrsToInts(strings.Split(l, sep))
  }
  return grid
}

func (s IntGrid) Height() int {
  return len(s)
}

func (s IntGrid) Width() int {
  if len(s) == 0 {
    return 0
  }
  return len(s[0])
}

func (s IntGrid) Neighbors(p Point) []Point {
  var neighbors []Point
  x := p[0]
  y := p[1]
  if x > 0 {
    neighbors = append(neighbors, Point{x-1, y})
  }
  if y > 0 {
    neighbors = append(neighbors, Point{x, y-1})
  }
  if x < s.Width()-1 {
    neighbors = append(neighbors, Point{x+1, y})
  }
  if y < s.Height()-1 {
    neighbors = append(neighbors, Point{x, y+1})
  }
  return neighbors
}

func (s IntGrid) ToStrf(format func(Point, int) string) string {
  lines := make([]string, len(s))
  for i, r := range s {
    var l []string
    for j, v := range r {
      l = append(l, format(Point{i, j}, v))
    }
    lines[i] = strings.Join(l, "")
  }
  return strings.Join(lines, "\n")
}

func (s IntGrid) ToStr() string {
  return s.ToStrf(func(p Point, v int) string {
    return strconv.Itoa(v)
  })
}

type PointSet map[Point]interface{}

func NewPointSet() PointSet {
  ps := make(PointSet)
  return ps
}

func (s PointSet) Add(p Point) PointSet {
  s[p] = exists
  return s
}

func (s PointSet) AddAll(points []Point ) PointSet {
  for _, p := range points {
    s.Add(p)
  }
  return s
}

func (s PointSet) Remove(p Point) {
  delete(s, p)
}

func (s PointSet) Contains(value Point) bool {
  _, c := (s)[value]
  return c
}

func (s PointSet) Values() []Point {
  var points []Point
  for p := range s {
    points = append(points, p)
  }
  return points
}

func (s PointSet) Intersect(other *PointSet) {
  for v := range s {
    if !other.Contains(v) {
      s.Remove(v)
    }
  }
}

func (s PointSet) Copy() PointSet {
  return NewPointSet().AddAll(s.Values())
}

