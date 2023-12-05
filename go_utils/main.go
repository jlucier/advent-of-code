package utils

import (
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type numeric interface {
	int | float64 | uint64
}

func RedInt(v int) string {
	return fmt.Sprintf("\x1b[31m%d\033[0m", v)
}

func Red(s string) string {
	return fmt.Sprintf("\x1b[31m%s\033[0m", s)
}

func ReadLines(filename string) []string {
	if strings.HasPrefix(filename, "~/") {
		home, _ := os.UserHomeDir()
		filename = filepath.Join(home, filename[2:])
	}

	var ret []string
	buf, err := os.ReadFile(filename)

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

func Sum[T numeric](s []T) T {
	var tot T
	for _, v := range s {
		tot += v
	}
	return tot
}

func MinMax[T numeric](s []T) (T, T) {
	min := s[0]
	max := s[0]
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

func Max[T numeric](a, b T) T {
	return T(math.Max(float64(a), float64(b)))
}

func Min[T numeric](a, b T) T {
	return T(math.Min(float64(a), float64(b)))
}

func Clamp[T numeric](val, min, max T) T {
	return Min(Max(val, min), max)
}

// Return true if a <= val < b
func Between[T numeric](val, a, b T) bool {
	return val >= a && val < b
}

func CountWhere[T comparable](s []T, v T) int {
	count := 0
	for _, n := range s {
		if n == v {
			count++
		}
	}
	return count
}

func StrToInt(str string) int {
	v, err := strconv.Atoi(str)
	if err != nil {
		panic(fmt.Sprintf("%s is not int-able", str))
	}
	return v
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

// Data structures

var exists = struct{}{}

type Set[T comparable] struct {
	m_map map[T]struct{}
}

func NewSet[T comparable]() Set[T] {
	return Set[T]{
		make(map[T]struct{}),
	}
}

func (s *Set[T]) Size() int {
	return len(s.m_map)
}

func (s *Set[T]) Add(value T) *Set[T] {
	s.m_map[value] = exists
	return s
}

func (s *Set[T]) AddAll(values []T) *Set[T] {
	for _, v := range values {
		s.Add(v)
	}
	return s
}

func (s *Set[T]) Remove(value T) {
	delete(s.m_map, value)
}

func (s *Set[T]) Contains(value T) bool {
	_, c := s.m_map[value]
	return c
}

func (s *Set[T]) ContainsAll(nums []T) bool {
	for _, v := range nums {
		if !s.Contains(v) {
			return false
		}
	}
	return true
}

func (s *Set[T]) Values() []T {
	var vals []T
	for k := range s.m_map {
		vals = append(vals, k)
	}
	return vals
}

// Modify the set such that is only contains elements in common with other
func (s *Set[T]) Intersect(other Set[T]) {
	for v := range s.m_map {
		if !other.Contains(v) {
			s.Remove(v)
		}
	}
}

func (s *Set[T]) Copy() Set[T] {
	ret := NewSet[T]()
	ret.AddAll(s.Values())
	return ret
}

func (s *Set[T]) ToStr() string {
	var b strings.Builder
	i := 0
	for v := range s.m_map {
		fmt.Fprint(&b, v)
		if i+1 < s.Size() {
			b.WriteString(", ")
		}
		i++
	}
	return fmt.Sprint("Set{", b.String(), "}")
}

func (s *Set[T]) Equals(other *Set[T]) bool {
	return s.ContainsAll(other.Values()) && other.ContainsAll(s.Values())
}
