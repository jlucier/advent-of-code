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
    b.WriteString(s[i+1:i+5])
    i += 5
    if first == '0' {
      break
    }
  }
  return binToDec(b.String()), i
}

func parse(packet string, n int) uint64 {
  tot := uint64(0)
  for len(packet) >= 11 && (n < 0 || n > 0){
    version := binToDec(packet[:3])
    fmt.Println("n", n, "len", len(packet), "v", version)
    n--
    tot += version
    typ := binToDec(packet[3:6])
    remain := packet[6:]
    used := 6

    if typ == 4 {
      i, u := parseLiteral(remain)
      used += u
      fmt.Println("lit", i)
    } else {
      used += 1
      // length type
      if remain[0] == '0' {
        l := int(binToDec(remain[1:16]))
        fmt.Println("sublen", l)
        used += l+15
        remain = remain[16:]
        tot += parse(remain[:l], -1)
        fmt.Println("done sl", l)
      } else {
        l := binToDec(remain[1:12])
        remain := remain[12:]
        used += 11
        used += len(remain)
        fmt.Println("num packs", l)
        tot += parse(remain, int(l))
        fmt.Println("done npack", l)
      }
    }
    packet = packet[used:]
  }
  return tot
}

func main() {
  pck := hexTo4Bin(utils.ReadLines("inp.txt")[0])
  fmt.Println(parse(pck, -1))
}
