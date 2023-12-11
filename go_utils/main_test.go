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
