package main

import (
  "fmt"
  "sort"
  "strings"

  "aoc/utils"
)

type LineStatus int

const (
  Good LineStatus = iota
  Corrupt
  Incomplete
)

var corruptScore = map[byte]int {
  ')': 3,
  ']': 57,
  '}': 1197,
  '>': 25137,
}
var incScore = map[byte]int {
  '(': 1,
  '[': 2,
  '{': 3,
  '<': 4,
}
var pairs = map[byte]byte {
  '(':')',
  '[':']',
  '{':'}',
  '<':'>',
}

func walkLine(l string) (LineStatus, int) {
  var stack []byte
  for _, s := range strings.Split(l, "") {
    c := s[0]
    _, ok := pairs[c]
    if ok {
      // open
      stack = append(stack, c)
      continue
    }

    // close?
    clse, _ := pairs[stack[len(stack)-1]]
    if c == clse {
      stack = stack[:len(stack)-1]
    } else {
      return Corrupt, corruptScore[c]
    }
  }

  if len(stack) > 0 {
    // inc
    inc := 0
    for i := len(stack)-1; i >= 0; i-- {
      inc = inc * 5 + incScore[stack[i]]
    }
    return Incomplete, inc
  }
  return Good, 0
}

func main() {
  lines := utils.ReadLines("inp.txt")
  corr := 0
  var inc []int
  for _, l := range lines {
    res, c := walkLine(l)
    switch res {
      case Corrupt:
        corr += c
      case Incomplete:
        inc = append(inc, c)
    }
  }
  sort.Ints(inc)
  fmt.Println("corr", corr, "inc", inc[len(inc)/2])
}
