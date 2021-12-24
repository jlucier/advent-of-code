package main

import (
  "fmt"
  "math"

  "aoc/utils"
)


// helpers

func onefreq(nums []string) []float64 {
  bits := len(nums[0])
  freq := make([]float64, bits)
  tot := float64(len(nums))

  for _, n := range nums {
    for i := 0; i < bits; i++ {
      if n[i] == '1' {
        freq[i] += 1 / tot
      }
    }
  }

  return freq
}

func bintodec(num string) int {
  ret := 0
  for i, c := range num {
    if c == '1' {
      ret += int(math.Pow(2, float64(len(num) - 1 - i)))
    }
  }
  return ret
}

func filter(nums []string, i int, cmp byte) []string {
  var ret []string

  for _, v := range nums {
    if v[i] == cmp {
      ret = append(ret, v)
    }
  }
  return ret
}

func findnum(nums []string, max bool) string {
  freq := onefreq(nums)
  remaining := nums

  b := 0
  for len(remaining) > 1 {
    var filt byte
    if freq[b] >= 0.5 {
     if max {
        filt = '1'
      } else {
        filt = '0'
      }
    } else {
     if max {
        filt = '0'
      } else {
        filt = '1'
      }
    }

    remaining = filter(remaining, b, filt)
    b += 1
    freq = onefreq(remaining)
  }

  return remaining[0]
}


// parts

func part1() {
  lines := utils.ReadLines("inp.txt")
  bits := len(lines[0])

  freq := onefreq(lines)

  gamma := 0
  epsilon := 0
  for i, c := range freq {
    dec := int(math.Pow(2, float64(bits - 1 - i)))
    if c > 0.5 {
      gamma += 1 * dec
    } else {
      epsilon += 1 * dec
    }
  }
  fmt.Println("gamma:", gamma, "epsilon:", epsilon)
  fmt.Println("mult:", gamma * epsilon)
}

func part2() {
  lines := utils.ReadLines("inp.txt")

  oxygen := bintodec(findnum(lines, true))
  co2 := bintodec(findnum(lines, false))

  fmt.Println("oxy:", oxygen, "co2:", co2)
  fmt.Println("res:", oxygen * co2)
}

func main() {
  part2()
}
