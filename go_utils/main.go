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

const (
	RED_CODE    = "\x1b[31m"
	GREEN_CODE  = "\x1b[32m"
	ORANGE_CODE = "\x1b[33m"
	BLUE_CODE   = "\x1b[36m"
	NO_CODE     = "\033[0m"
)

func RedInt(v int) string {
	return fmt.Sprintf("%s%d%s", RED_CODE, v, NO_CODE)
}

func Red(s string) string {
	return fmt.Sprintf("%s%s%s", RED_CODE, s, NO_CODE)
}

func GreenInt(v int) string {
	return fmt.Sprintf("%s%d%s", GREEN_CODE, v, NO_CODE)
}

func Green(s string) string {
	return fmt.Sprintf("%s%s%s", GREEN_CODE, s, NO_CODE)
}

func BlueInt(v int) string {
	return fmt.Sprintf("%s%d%s", BLUE_CODE, v, NO_CODE)
}

func Blue(s string) string {
	return fmt.Sprintf("%s%s%s", BLUE_CODE, s, NO_CODE)
}

// Expand a ~ in the path
func ExpandUser(filename string) string {
	if strings.HasPrefix(filename, "~/") {
		home, _ := os.UserHomeDir()
		filename = filepath.Join(home, filename[2:])
	}
	return filename
}

// Read all non-empty lines from file
func ReadLines(filename string) []string {
	lines := ReadAllLines(filename)
	var ret []string
	for _, ln := range lines {
		if ln != "" {
			ret = append(ret, ln)
		}
	}
	return ret
}

// Read all lines from file, including empty
func ReadAllLines(filename string) []string {
	filename = ExpandUser(filename)
	buf, err := os.ReadFile(filename)
	if err != nil {
		panic(err)
	}
	return ParseLines(string(buf))
}

func ParseLines(buf string) []string {
	var ret []string
	for _, v := range strings.Split(buf, "\n") {
		ret = append(ret, v)
	}
	// should be a last empty string in there, remove it
	return ret[:len(ret)-1]
}

// Slice stuff

// Transpose rows into cols
// [abc,def] -> [ad,be,cf]
func Transpose(m []string) []string {
	tmp := make([]strings.Builder, len(m[0]))
	for _, ln := range m {
		for j, c := range ln {
			tmp[j].WriteRune(c)
		}
	}

	result := make([]string, len(tmp))
	for i, b := range tmp {
		result[i] = b.String()
	}
	return result
}

func ReverseAll(m []string) []string {
	tmp := make([]string, len(m[0]))
	for i, ln := range m {
		tmp[i] = string(Reversed([]byte(ln)))
	}
	return tmp
}

func Filter[T comparable](a []T, predicate func(T, int) bool) []T {
	var out []T
	for i, v := range a {
		if predicate(v, i) {
			out = append(out, v)
		}
	}
	return out
}

func SliceEq[T comparable](a []T, b []T) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func Reversed[T any](in []T) []T {
	out := make([]T, len(in))
	for i := 0; i < len(out); i++ {
		out[i] = in[len(in)-i-1]
	}
	return out
}

func Insert[T any](slice []T, i int, v T) []T {
	if i >= len(slice) {
		return append(slice, v)
	}
	ret := append(slice[:i+1], slice[i:]...)
	ret[i] = v
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

// Misc

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

func EmptySet[T comparable]() Set[T] {
	return Set[T]{
		make(map[T]struct{}),
	}
}

func NewSet[T comparable](vals []T) Set[T] {
	s := Set[T]{
		make(map[T]struct{}, len(vals)),
	}
	for _, v := range vals {
		s.Add(v)
	}
	return s
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

func (s *Set[T]) RemoveAll(vals []T) {
	for _, v := range vals {
		s.Remove(v)
	}
}

func (s *Set[T]) Contains(value T) bool {
	_, c := s.m_map[value]
	return c
}

func (s *Set[T]) ContainsAll(vals []T) bool {
	for _, v := range vals {
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
func (s *Set[T]) IntersectionUpdate(other []T) {
	os := NewSet(other)
	for v := range s.m_map {
		if !os.Contains(v) {
			s.Remove(v)
		}
	}
}

func (s *Set[T]) Intersection(other []T) Set[T] {
	res := NewSet(other)
	res.IntersectionUpdate(s.Values())
	return res
}

func (s *Set[T]) DifferenceUpdate(other []T) {
	s.RemoveAll(other)
}

func (s *Set[T]) Difference(other []T) Set[T] {
	res := NewSet(s.Values())
	res.DifferenceUpdate(other)
	return res
}

func (s *Set[T]) Copy() Set[T] {
	ret := EmptySet[T]()
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
	return s.Size() == other.Size() &&
		s.ContainsAll(other.Values())
}

// Vector

type V2 struct {
	X int
	Y int
}

func (self *V2) Add(other *V2) V2 {
	return V2{
		self.X + other.X,
		self.Y + other.Y,
	}
}

func (self *V2) Sub(other *V2) V2 {
	return V2{
		self.X - other.X,
		self.Y - other.Y,
	}
}

func (self *V2) Mag() float64 {
	return math.Sqrt(float64(self.X*self.X + self.Y*self.Y))
}
