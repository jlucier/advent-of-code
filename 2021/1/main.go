package main

import (
  "fmt"
  "strconv"
  "aoc/utils"
)

func main() {
  lines := utils.ReadLines("inp1.txt")

  var readings[] int

  for _, s := range lines {
    if s == "" {
      break
    }

    n, err := strconv.Atoi(s)

    if err != nil {
      panic(err)
    }

    readings = append(readings, n)
  }


  curr := utils.Sum(readings[:3])
  increases := 0

  for i := 1; i < len(readings) - 2; i++ {

    tot := utils.Sum(readings[i:i+3])

    if curr != -1 {
      if tot > curr {
        increases += 1
      }
    }

    curr = tot
  }

  fmt.Println("res: ", increases)
}
