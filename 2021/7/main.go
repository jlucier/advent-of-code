package main

import (
  "fmt"
  "math"
  "sort"
  "strings"

  "aoc/utils"
)

func part1(nums []int) {
  // find the median, I guess that's the one with lowest cost
  sort.Ints(nums)

  best := nums[len(nums) / 2]

  cost := 0
  for _, pos := range nums {
    cost += int(math.Abs(float64(pos - best)))
  }

  fmt.Println("best:", best, "cost:", cost)
}

func part2(nums []int) {
  min, max := utils.MinMax(nums)

  bestCost := math.Inf(1)
  best := 0

  for _, candidate := range utils.Range(min, max) {
    tot := 0
    for _, pos := range nums {
      dist := int(math.Abs(float64(pos - candidate)))
      tot += dist * (dist + 1) / 2
    }

    if float64(tot) < bestCost {
      bestCost = float64(tot)
      best = candidate
    }
  }
  fmt.Println("best:", best, "cost:", int(bestCost))
}

func main() {
  nums := utils.StrsToInts(strings.Split(utils.ReadLines("inp.txt")[0], ","))
  part2(nums)
}
