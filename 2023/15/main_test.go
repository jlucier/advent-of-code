package main

import (
	"testing"
)

func TestHash(t *testing.T) {
	s := "HASH"
	exp := 52
	v := hash(s)
	if v != exp {
		t.Fatalf("Expected hash('HASH') = 52, got %d", v)
	}
}
