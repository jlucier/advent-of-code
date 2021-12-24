package main

import (
  "fmt"
  "strconv"
  "strings"

  "aoc/utils"
)

func main() {
  depth := 0
  pos := 0
  aim := 0

  commands, err := utils.ReadLines("inp.txt")

  if err != nil {
    panic(err)
  }

  for _, com := range commands {
    tokens := strings.Split(com, " ")

    if len(tokens) != 2 {
      fmt.Errorf("unexpected len: %i", len(tokens))
      panic("wut")
    }

    n, err := strconv.Atoi(tokens[1])

    if err != nil {
      panic(err)
    }

    switch c := tokens[0]; c {
      case "forward":
        pos += n
        depth += aim * n
      case "up":
        aim -= n
      case "down":
        aim += n
    }
  }

  fmt.Println("Pos:", pos, "Depth:", depth)
  fmt.Println("Mult:", depth * pos)
}
