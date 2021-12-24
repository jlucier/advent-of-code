package utils

import (
	"io/ioutil"
	"strconv"
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

func StrsToInts(str []string) []int {
	var res []int
	for _, s := range str {
		n, err := strconv.Atoi(s)
		if err != nil {
			panic(err)
		}
		res = append(res, n)
	}
	return res
}

var exists = struct{}{}

type IntSet struct {
	m map[int]struct{}
}

func NewIntSet() *IntSet {
	s := &IntSet{}
	s.m = make(map[int]struct{})
	return s
}

func (s *IntSet) Add(value int) {
	s.m[value] = exists
}

func (s *IntSet) Remove(value int) {
	delete(s.m, value)
}

func (s *IntSet) Contains(value int) bool {
	_, c := s.m[value]
	return c
}

func (s *IntSet) ContainsAll(nums []int) bool {
	for _, v := range nums {
		if !s.Contains(v) {
			return false
		}
	}
	return true
}
