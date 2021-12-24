package main

import (
  "fmt"
  "io/ioutil"
  "strings"
  "strconv"
)

func sum(s []int) int {
  tot := 0
  for _, v := range s {
    tot += v
  }
  return tot
}

func main() {
  data, err := ioutil.ReadFile("inp1.txt")

  if err != nil {
    panic(err)
  }

  content := string(data)

  var readings[] int

  for _, s := range strings.Split(content, "\n") {
    if s == "" {
      break
    }

    n, err := strconv.Atoi(s)

    if err != nil {
      panic(err)
    }

    readings = append(readings, n)
  }


  curr := sum(readings[:3])
  increases := 0

  for i := 1; i < len(readings) - 2; i++ {

    tot := sum(readings[i:i+3])

    if curr != -1 {
      if tot > curr {
        increases += 1
      }
    }

    curr = tot
  }

  fmt.Println("res: ", increases)
}
