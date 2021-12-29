package main

import (
  "fmt"
  "math"
  "strings"
  "time"

  "aoc/utils"
)

type Polymer struct {
  elemCounts map[string]int
  pairCounts map[string]int
}
type Rules map[string]byte
type SCount struct {
  token string
  count int
}

func incCount(m map[string]int, v string, inc int) int {
  _, ok := m[v]
  if ok {
    m[v] += inc
  } else {
    m[v] = inc
  }
  return m[v]
}


func NewPolymer() *Polymer {
  p := &Polymer{}
  p.elemCounts = make(map[string]int)
  p.pairCounts = make(map[string]int)
  return p
}

func (s *Polymer) MinMaxElem() (SCount, SCount) {
  max := SCount{}
  min := math.Inf(1)
  var minS string
  for s, c := range s.elemCounts {
    max.count = utils.Max(max.count, c)
    if max.count == c {
      max.token = s
    }
    min = math.Min(float64(c), min)
    if float64(c) == min {
      minS = s
    }
  }

  return SCount{minS, int(min)}, max
}


func (s *Polymer) Step(rules Rules) {
  items := make([]SCount, len(s.pairCounts))
  i := 0
  for p, c := range s.pairCounts {
    items[i] = SCount{p, c}
    i++
  }

  for _, sc := range items {
    p, c := sc.token, sc.count
    ins, ok := rules[p]
    if ok {
      incCount(s.elemCounts, string(ins), c)
      if s.pairCounts[p] <= c {
        delete(s.pairCounts, p)
      } else {
        s.pairCounts[p] -= c
      }
      incCount(s.pairCounts, string([]byte{p[0], ins}), c)
      incCount(s.pairCounts, string([]byte{ins, p[1]}), c)
    }
  }
}

func (s *Polymer) GetAnswer() int {
  min, max := s.MinMaxElem()
  return max.count - min.count
}

func parseInput(filename string) (*Polymer, Rules) {
  lines := utils.ReadLines(filename)

  rules := make(Rules)
  for _, l := range lines[1:] {
    tokens := strings.Split(l, " -> ")
    rules[tokens[0]] = tokens[1][0]
  }

  p := NewPolymer()
  pline := lines[0]
  for i := 0; i < len(pline); i++ {
    incCount(p.elemCounts, string(pline[i]), 1)

    // cound pair
    if i < len(pline)-1 {
      pair := pline[i:i+2]
      incCount(p.pairCounts, pair, 1)
    }
  }
  return p, rules
}

func main() {
  start := time.Now()
  polymer, rules := parseInput("inp.txt")
  p1 := 0
  for i := 0; i < 40; i++ {
    polymer.Step(rules)
    if i == 9 {
      p1 = polymer.GetAnswer()
    }
  }
  fmt.Println("p1", p1, "p2", polymer.GetAnswer())
  end := time.Now()
  fmt.Println(end.Sub(start))
}
