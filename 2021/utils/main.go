package utils

import (
	"fmt"
	"io/ioutil"
	"math"
	"sort"
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

func MinMax(s []int) (int, int) {
  min := 0
  max := 0
  for _, v := range s {
    min = Min(min, v)
    max = Max(max, v)
  }
  return min, max
}

func Range(s int, e int) []int {
  var ret []int
  for i := s; i < e; i++ {
    ret = append(ret, i)
  }
  return ret
}

func Max(a, b int) int {
	return int(math.Max(float64(a), float64(b)))
}

func Min(a, b int) int {
	return int(math.Min(float64(a), float64(b)))
}

func Clamp(val, min, max int) int {
  return Min(Max(val, min), max)
}

func CountWhere(s []int, v int) int {
	count := 0
	for _, n := range s {
		if n == v {
			count++
		}
	}
	return count
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

func IntsToStrs(ints []int) []string {
	var res []string
  for _, v := range ints {
    res = append(res, fmt.Sprint(v))
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

func (s *IntSet) Size() int {
  return len(s.m)
}

func (s *IntSet) Add(value int) *IntSet {
	s.m[value] = exists
	return s
}

func (s *IntSet) AddAll(values[] int) *IntSet {
  for _, v := range values {
    s.Add(v)
  }
	return s
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

func (s *IntSet) Values() []int {
  var vals []int
  for k := range s.m {
    vals = append(vals, k)
  }
  return vals
}

func (s *IntSet) Intersect(other *IntSet) {
  for v := range s.m {
    if !other.Contains(v) {
      s.Remove(v)
    }
  }
}

func (s *IntSet) Copy() *IntSet {
  return NewIntSet().AddAll(s.Values())
}

func (s *IntSet) ToStr() string {
  v := s.Values()
  sort.Ints(v)
  return fmt.Sprint("IntSet{", strings.Join(IntsToStrs(v), ", "), "}")
}

func (s *IntSet) Equals(other *IntSet) bool {
  return s.ContainsAll(other.Values()) && other.ContainsAll(s.Values())
}

// StrSet

type StrSet struct {
	m map[string]struct{}
}

func NewStrSet() *StrSet {
	s := &StrSet{}
	s.m = make(map[string]struct{})
	return s
}

func (s *StrSet) Size() int {
  return len(s.m)
}

func (s *StrSet) Add(value string) *StrSet {
	s.m[value] = exists
	return s
}

func (s *StrSet) AddAll(values[] string) *StrSet {
  for _, v := range values {
    s.Add(v)
  }
	return s
}

func (s *StrSet) Remove(value string) {
	delete(s.m, value)
}

func (s *StrSet) Contains(value string) bool {
	_, c := s.m[value]
	return c
}

func (s *StrSet) ContainsAll(nums []string) bool {
	for _, v := range nums {
		if !s.Contains(v) {
			return false
		}
	}
	return true
}

func (s *StrSet) Values() []string {
  var vals []string
  for k := range s.m {
    vals = append(vals, k)
  }
  return vals
}

func (s *StrSet) Intersect(other *StrSet) {
  for v := range s.m {
    if !other.Contains(v) {
      s.Remove(v)
    }
  }
}

func (s *StrSet) Copy() *StrSet {
  return NewStrSet().AddAll(s.Values())
}

func (s *StrSet) ToStr() string {
  v := s.Values()
  sort.Strings(v)
  return fmt.Sprint("StrSet{", strings.Join(v, ", "), "}")
}

func (s *StrSet) Equals(other *StrSet) bool {
  return s.ContainsAll(other.Values()) && other.ContainsAll(s.Values())
}
