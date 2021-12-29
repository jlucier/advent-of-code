package main

import (
  "fmt"
  "strings"
  "math"

  "aoc/utils"
)

//   0:      1:      2:      3:      4:
//  aaaa    ....    aaaa    aaaa    ....
// b    c  .    c  .    c  .    c  b    c
// b    c  .    c  .    c  .    c  b    c
//  ....    ....    dddd    dddd    dddd
// e    f  .    f  e    .  .    f  .    f
// e    f  .    f  e    .  .    f  .    f
//  gggg    ....    gggg    gggg    ....
//
//   5:      6:      7:      8:      9:
//  aaaa    aaaa    aaaa    aaaa    aaaa
// b    .  b    .  .    c  b    c  b    c
// b    .  b    .  .    c  b    c  b    c
//  dddd    dddd    ....    dddd    dddd
// .    f  e    f  .    f  e    f  .    f
// .    f  e    f  .    f  e    f  .    f
//  gggg    gggg    ....    gggg    gggg


var numToSegs = [][]int {
  0: {0, 1, 2, 4, 5, 6},
  1: {2, 5},
  2: {0, 2, 3, 4, 6},
  3: {0, 2, 3, 5, 6},
  4: {1, 2, 3, 5},
  5: {0, 1, 3, 5, 6},
  6: {0, 1, 3, 4, 5, 6},
  7: {0, 2, 5},
  8: {0, 1, 2, 3, 4, 5, 6},
  9: {0, 1, 2, 3, 5, 6},
}

var lenToNums = map[int][]int{
  2: {1},
  3: {7},
  4: {4},
  5: {2, 3, 5},
  6: {0, 6, 9},
  7: {8},
}


type LetterSet[]utils.StrSet

func parse(lines []string) ([][]string, [][]string) {
  var readouts [][]string
  var digits [][]string

  for _, l := range lines {
    tokens := strings.Split(l, " | ")
    digits = append(digits, strings.Split(tokens[0], " "))
    readouts = append(readouts, strings.Split(tokens[1], " "))
  }
  return digits, readouts
}

func part1() {
  lines := utils.ReadLines("inp.txt")
  _, readouts := parse(lines)

  count := 0
  ez := utils.NewIntSet()
  ez.AddAll([]int{2,3,4,7})
  for _, r := range readouts {
    for _, d := range r {
      if ez.Contains(len(d)) {
        count++
      }
    }
  }
  fmt.Println("ez:", count)
}


func copyLetterSet(ls LetterSet) LetterSet {
  newLs := LetterSet{}
  for _, v := range ls {
    newLs = append(newLs, v.Copy())
  }
  return newLs
}

func prop(segOpts LetterSet, allDigits[]string ) (bool, LetterSet) {
  minS := 0
  minSize := math.Inf(1)
  ones := 0
  for s, letters := range segOpts{
    if len(letters) == 0 {
      return false, segOpts
    } else if len(letters) == 1 {
      ones++
      continue
    } else if float64(len(letters)) < minSize {
      minS = s
      minSize = float64(len(letters))
    }
  }

  if ones == len(segOpts) {
    // check if this works for all numbers
    for _, dig := range allDigits {
      if readNum(segOpts, dig) == -1 {
        return false, segOpts
      }
    }
    return true, segOpts
  }

  for v := range segOpts[minS] {
    // pretend we just fix this boi to a value

    newOpts := copyLetterSet(segOpts)
    newOpts[minS] = utils.NewStrSet().Add(v)

    // remove v from all others
    for ns, letters := range newOpts {
      if ns == minS {
        continue
      }
      letters.Remove(v)
    }

    win, opts := prop(newOpts, allDigits)
    if win {
      return win, opts
    }
  }
  return false, segOpts
}

func readNum(segToL LetterSet, digit string) int {
  atlas := map[string]int{}
  for s, ltrs := range segToL {
    atlas[ltrs.Values()[0]] = s
  }

  numSegs := utils.NewIntSet()
  for _, s := range strings.Split(digit, "") {
    numSegs.Add(atlas[s])
  }

  for n, segs := range numToSegs {
    ss := utils.NewIntSet().AddAll(segs)
    if ss.Equals(numSegs) {
      return n
    }
  }
  return -1
}

func processLine(digits []string , readouts []string) int {
  // map numbers to the segments lit up
  letters := strings.Split("abcdefg", "")
  segOptions := LetterSet{}
  for i := 0; i < 7; i++ {
    segOptions = append(segOptions, utils.NewStrSet().AddAll(letters))
  }

  observed := LetterSet{}
  for i := 0; i < 10; i++ {
    observed = append(observed, utils.NewStrSet())
  }

  updateFromDigit := func(d string) {
    letters := strings.Split(d,"")
    nums, _ := lenToNums[len(d)]
    for _, n := range nums {
      observed[n].AddAll(letters)
    }
  }

  // observe what segments could represent which numbers

  for _, d := range digits {
    updateFromDigit(d)
  }
  for _, d := range readouts {
    updateFromDigit(d)
  }

  // limit options for segments based on the observed
  for n, segs := range numToSegs {
    for _, s := range segs {
      segOptions[s].Intersect(observed[n])
    }
  }

  var allDigits []string
  for _, d := range digits {
    allDigits = append(allDigits, d)
  }
  for _, d := range readouts {
    allDigits = append(allDigits, d)
  }

  // propagate constraints
  _, opts := prop(segOptions, allDigits)

  num := 0
  for i, r := range readouts {
    c := readNum(opts, r)
    num += c * int(math.Pow10(len(readouts) - 1 - i))
  }
  return num
}


func part2() {
  lines := utils.ReadLines("inp.txt")
  // lines := []string{"acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf"}
  digits, readouts := parse(lines)

  tot := 0
  for i := 0; i < len(lines); i++ {
    tot += processLine(digits[i], readouts[i])
  }

  fmt.Println("Answer:", tot)
}

func main() {
  part2()
}
