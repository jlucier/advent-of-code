package main

import (
  "testing"
)

func TestStuff(t *testing.T) {
  pcks := []string{
    "8A004A801A8002F478",
    "620080001611562C8802118E34",
    "C0015000016115A2E0802F182340",
    "A0016C880162017C3686B18A3D4780",
  }
  sums := []uint64 {16, 12, 23, 31}
  for i, pck := range pcks {
    pck = hexTo4Bin(pck)
    v := parse(pck, -1)
    if v != sums[i] {
      t.Errorf("(%s) expected %d, got: %d", pck, sums[i], v)
    }
  }
}
