package main

import (
  "fmt"
  "strings"

  "aoc/utils"
)

type Cache map[[2]int]int

func calcfish(age int, days int, cache Cache) int {
  v, ok := cache[[2]int{age, days}]
  if ok {
    return v
  }

  tot := 1
  for days > age {
    days -= age+1
    age = 6
    res := calcfish(8, days, cache)
    cache[[2]int{8, days}] = res
    tot += res
  }

  return tot
}

func main() {
  content := utils.ReadLines("inp.txt")[0]
  fish := utils.StrsToInts(strings.Split(content, ","))

  tot := 0
  cache := Cache{}
  for _, f := range fish {
    tot += calcfish(f, 80, cache)
  }

  fmt.Println("count:", tot)
}
