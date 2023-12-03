package main

import (
	"fmt"
	"strconv"
	"strings"

	"aoc/utils"
)

type packet struct {
	version uint64
	id      uint64
	value   uint64
	sub     []packet
}

func binToDec(bs string) uint64 {
	i, _ := strconv.ParseUint(bs, 2, 64)
	return i
}

func hexTo4Bin(s string) string {
	b := strings.Builder{}

	for _, c := range s {
		i, _ := strconv.ParseUint(string(c), 16, 8)
		bs := strconv.FormatUint(i, 2)
		if len(bs) < 4 {
			for i := 0; i < 4-len(bs); i++ {
				b.WriteByte('0')
			}
		}
		b.WriteString(bs)
	}
	return b.String()
}

func parseLiteral(s string) (uint64, int) {
	b := strings.Builder{}
	i := 0
	for {
		first := s[i]
		b.WriteString(s[i+1 : i+5])
		i += 5
		if first == '0' {
			break
		}
	}
	return binToDec(b.String()), i
}

func parse(raw string, n int) ([]packet, int) {
	consumed_bits := 0
	var pcks []packet

	for len(raw) >= 7 && (n < 0 || n > 0) {
		var result packet
		result.version = binToDec(raw[:3])
		n--
		result.id = binToDec(raw[3:6])
		remain := raw[6:]
		used := 6
		allZero := true
		for _, b := range remain {
			allZero = allZero && b == '0'
		}
		if allZero {
			break
		}

		if result.id == 4 {
			v, u := parseLiteral(remain)
			used += u
			result.value = v
		} else {
			used += 1
			// length type
			if remain[0] == '0' {
				l := int(binToDec(remain[1:16]))
				used += l + 15
				remain = remain[16:]
				sub, _ := parse(remain[:l], -1)
				result.sub = sub
			} else {
				l := binToDec(remain[1:12])
				remain := remain[12:]
				used += 11
				sub, bits := parse(remain, int(l))
				used += bits
				result.sub = sub
			}
		}

		raw = raw[used:]
		consumed_bits += used
		pcks = append(pcks, result)
	}
	return pcks, consumed_bits
}

func sumVersion(pck packet) uint64 {
	tot := pck.version
	for _, sp := range pck.sub {
		tot += sumVersion(sp)
	}
	return tot
}

func evaluate(pck packet) uint64 {
	switch pck.id {
	case 0:
		// sum
		t := uint64(0)
		for _, sp := range pck.sub {
			t += evaluate(sp)
		}
		return t

	case 1:
		// prod
		t := uint64(1)
		for _, sp := range pck.sub {
			t *= evaluate(sp)
		}
		return t

	case 2:
		// min
		t := ^uint64(0)
		for _, sp := range pck.sub {
			t = utils.Min(t, evaluate(sp))
		}
		return t

	case 3:
		// max
		t := uint64(0)
		for _, sp := range pck.sub {
			t = utils.Max(t, evaluate(sp))
		}
		return t

	case 5:
		// gt
		if evaluate(pck.sub[0]) > evaluate(pck.sub[1]) {
			return 1
		}
		return 0

	case 6:
		// lt
		if evaluate(pck.sub[0]) < evaluate(pck.sub[1]) {
			return 1
		}
		return 0

	case 7:
		// eq
		if evaluate(pck.sub[0]) == evaluate(pck.sub[1]) {
			return 1
		}
		return 0

	case 4:
		// literal
		return pck.value

	default:
		panic("Wut")
	}
}

func main() {
	pck := hexTo4Bin(utils.ReadLines("inp.txt")[0])
	pcks, _ := parse(pck, -1)
	pack := pcks[0]

	fmt.Println("p1:", sumVersion(pack))
	fmt.Println("p2:", evaluate(pack))
}
