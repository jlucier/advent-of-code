package main

import (
	"testing"
)

func TestP1(t *testing.T) {
	inps := []string{
		"8A004A801A8002F478",
		"620080001611562C8802118E34",
		"C0015000016115A2E0802F182340",
		"A0016C880162017C3686B18A3D4780",
		"38006F45291200",
		"EE00D40C823060",
	}
	sums := []uint64{16, 12, 23, 31, 9, 14}
	for i, pck := range inps {
		pck = hexTo4Bin(pck)
		p, _ := parse(pck, -1)

		v := sumVersion(p[0])
		if v != sums[i] {
			t.Errorf("(%s) expected %d, got: %d", pck, sums[i], v)
		}
	}
}

func TestP2(t *testing.T) {
	inps := []string{
		"C200B40A82",
		"04005AC33890",
		"880086C3E88112",
		"CE00C43D881120",
		"D8005AC2A8F0",
		"F600BC2D8F",
		"9C005AC2F8F0",
		"9C0141080250320F1802104A08",
	}
	ans := []uint64{
		3, 54, 7, 9, 1, 0, 0, 1,
	}

	for i, pck := range inps {
		p, _ := parse(hexTo4Bin(pck), -1)

		v := evaluate(p[0])
		if v != ans[i] {
			t.Errorf("(%s) expected %d, got: %d (case %d)", pck, ans[i], v, i)
		}
	}
}
