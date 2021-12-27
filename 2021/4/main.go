package main

import (
  "fmt"
  "strings"

  "aoc/utils"
)

// helpers

type Board [5][5]int

func colSlice(i int, b *Board) []int {
  var slice []int
  for _, r := range b {
    slice = append(slice, r[i])
  }
  return slice
}

func makeBoards(lines []string) []Board {
  boards := make([]Board, len(lines)/5)
  for i, l := range lines {
    for j, n := range utils.StrsToInts(splitWs(l)) {
      boards[i/5][i%5][j] = n
    }
  }
  return boards
}

func splitWs(str string) []string {
  var res []string
  for _, s := range strings.Split(str, " ") {
    if s != "" && s != " " {
      res = append(res, s)
    }
  }
  return res
}

func boardDone(nums *utils.IntSet, b *Board) bool {
  for _, r := range b {
    if nums.ContainsAll(r[:]) {
      return true
    }
  }
  for i := 0; i < 5; i++ {
    if nums.ContainsAll(colSlice(i, b)) {
      return true
    }
  }
  return false
}

func unmarkedSquares(nums *utils.IntSet, b *Board) []int {
  var ret []int
  for _, r := range b {
    for _, n := range r {
      if !nums.Contains(n) {
        ret = append(ret, n)
      }
    }
  }
  return ret
}

// parts

func part1() {
  lines := utils.ReadLines("inp.txt")

  nums := utils.StrsToInts(strings.Split(lines[0], ","))
  curr_nums := utils.NewIntSet()
  boards := makeBoards(lines[1:])

  for _, n := range nums {
    curr_nums.Add(n)
    for b, board := range boards {
      if boardDone(curr_nums, &board) {
        fmt.Println("DONE:", b+1, "score:", n*utils.Sum(unmarkedSquares(curr_nums, &board)))
        return
      }
    }
  }
}

func part2() {
  lines := utils.ReadLines("inp.txt")
  nums := utils.StrsToInts(strings.Split(lines[0], ","))
  curr_nums := utils.NewIntSet()
  boards := makeBoards(lines[1:])

  remaning := len(boards)
  for _, n := range nums {
    curr_nums.Add(n)
    var new_boards []Board

    for b, board := range boards {
      if boardDone(curr_nums, &board) {
        remaning -= 1
        if remaning == 0 {
          fmt.Println("DONE:", b+1, "score:", n*utils.Sum(unmarkedSquares(curr_nums, &board)))
          return
        }
      } else {
        new_boards = append(new_boards, board)
      }
    }
    boards = new_boards
  }
}

func main() {
  part2()
}
