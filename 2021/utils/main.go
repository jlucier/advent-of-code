package utils

import (
  "io/ioutil"
  "strings"
)

func ReadLines(filename string) ([]string, error) {
  var ret []string
  buf, err := ioutil.ReadFile(filename)

  if err != nil {
    return ret, err
  }

  for _, v := range strings.Split(string(buf), "\n") {
    ret = append(ret, v)
  }
  return ret, nil
}


func Sum(s []int) int {
  tot := 0
  for _, v := range s {
    tot += v
  }
  return tot
}
