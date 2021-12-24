package utils

import (
  "io/ioutil"
  "strings"
)

func ReadLines(filename string) []string {
  var ret []string
  buf, err := ioutil.ReadFile(filename)

  if err != nil {
    panic(err)
  }

  for _, v := range strings.Split(string(buf), "\n") {
    if v != "" {
      ret = append(ret, v)
    }
  }
  return ret
}


func Sum(s []int) int {
  tot := 0
  for _, v := range s {
    tot += v
  }
  return tot
}
