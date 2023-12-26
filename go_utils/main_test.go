package utils

import (
	"testing"
)

func TestIntersection(t *testing.T) {
	a := NewSet([]int{1, 2, 3, 4, 5})
	b := NewSet([]int{4, 5})
	c := a.Intersection(b.Values())
	exp := NewSet([]int{4, 5})

	if !c.Equals(&exp) {
		t.Fatalf("Intesection expected %v got %v", exp, c)
	}
}

func TestIntersectionUpdate(t *testing.T) {
	a := NewSet([]int{1, 2, 3, 4, 5})
	b := NewSet([]int{4, 5})
	a.IntersectionUpdate(b.Values())
	exp := NewSet([]int{4, 5})

	if !a.Equals(&exp) {
		t.Fatalf("Intesection update expected %v got %v", exp, a)
	}
}

func TestDifference(t *testing.T) {
	a := NewSet([]int{1, 2, 3, 4, 5})
	b := NewSet([]int{4, 5})
	c := a.Difference(b.Values())
	exp := NewSet([]int{1, 2, 3})

	if !c.Equals(&exp) {
		t.Fatalf("Difference expected %v got %v", exp, c)
	}
}

func TestDifferenceUpdate(t *testing.T) {
	a := NewSet([]int{1, 2, 3, 4, 5})
	b := NewSet([]int{4, 5})
	a.DifferenceUpdate(b.Values())
	exp := NewSet([]int{1, 2, 3})

	if !a.Equals(&exp) {
		t.Fatalf("Difference expected %v got %v", exp, a)
	}
}

func TestTranspose(t *testing.T) {
	in := []string{
		"abc",
		"def",
	}
	exp := []string{
		"ad",
		"be",
		"cf",
	}

	res := Transpose(in)
	if !SliceEq(exp, res) {
		t.Fatalf("Transpose %v expected %v got %v", in, exp, res)
	}
}

func TestV2Sub(t *testing.T) {
	a := V2{1, 1}
	b := V2{0, 1}
	exp := V2{1, 0}
	c := a.Sub(&b)
	if c != exp {
		t.Fatalf("Wrong vsub %v - %v expected %v got %v", a, b, exp, c)
	}
}

func TestV2Unit(t *testing.T) {
	a := V2{0, 10}
	exp := V2{0, 1}
	if a.Unit() != exp {
		t.Fatalf("Wrong unit for %v expected %v got %v", a, exp, a.Unit())
	}
}
