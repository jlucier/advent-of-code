package main

import (
	"fmt"
	"strconv"
	"strings"

	"aoc/utils"
)

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

func parse(packet string, n int) (uint64, int) {
	tot := uint64(0)
	consumed_bits := 0

	for len(packet) >= 11 && (n < 0 || n > 0) {
		version := binToDec(packet[:3])
		n--
		tot += version
		typ := binToDec(packet[3:6])
		remain := packet[6:]
		used := 6

		if typ == 4 {
			_, u := parseLiteral(remain)
			used += u
		} else {
			used += 1
			// length type
			if remain[0] == '0' {
				l := int(binToDec(remain[1:16]))
				used += l + 15
				remain = remain[16:]
				vsum, _ := parse(remain[:l], -1)
				tot += vsum
			} else {
				l := binToDec(remain[1:12])
				remain := remain[12:]
				used += 11
				vsum, bits := parse(remain, int(l))
				tot += vsum
				used += bits
			}
		}

		packet = packet[used:]
		consumed_bits += used
	}
	return tot, consumed_bits
}

func p1() {
	pck := hexTo4Bin(utils.ReadLines("inp.txt")[0])
	answer, _ := parse(pck, -1)
	fmt.Println(answer)
}

func main() {
	p1()
}
