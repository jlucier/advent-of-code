package main

import (
	"fmt"
	"regexp"
	"strings"

	"aoc/utils"
)

func hash(s string) int {
	val := 0
	for _, c := range s {
		val += int(byte(c))
		val *= 17
		val %= 256
	}
	return val
}

type Lens struct {
	key string
	val int
}

type BadMap struct {
	boxes [][]Lens
}

func NewBadMap() BadMap {
	return BadMap{
		make([][]Lens, 256),
	}
}

func (self *BadMap) Add(lens Lens) {
	hv := hash(lens.key)
	box := self.boxes[hv]

	for i, ol := range box {
		if ol.key == lens.key {
			box[i] = lens
			return
		}
	}

	self.boxes[hv] = append(box, lens)
}

func (self *BadMap) Remove(lens Lens) {
	hv := hash(lens.key)
	box := self.boxes[hv]

	for i, ol := range box {
		if ol.key == lens.key {
			if i+1 >= len(box) {
				self.boxes[hv] = box[:i]
			} else {
				self.boxes[hv] = append(box[:i], box[i+1:]...)
			}
			return
		}
	}
}

func p1(instructions []string) {
	tot := 0

	for _, inst := range instructions {
		tot += hash(inst)
	}
	fmt.Println("p1:", tot)
}

func p2(instructions []string) {
	re := regexp.MustCompile("([a-z]+)([-=])(\\d+)?")
	bm := NewBadMap()

	for _, inst := range instructions {
		matches := re.FindStringSubmatch(inst)
		lens := Lens{
			matches[1],
			0,
		}
		op := matches[2]

		if matches[3] != "" {
			lens.val = utils.StrToInt(matches[3])
		}

		switch op {
		case "-":
			bm.Remove(lens)
		case "=":
			bm.Add(lens)
		}
	}

	tot := 0
	for bi, box := range bm.boxes {
		for li, lens := range box {
			tot += (bi + 1) * (li + 1) * lens.val
		}
	}

	fmt.Println("p2:", tot)
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/15/input.txt"
	instructions := strings.Split(utils.ReadLines(fname)[0], ",")
	p1(instructions)
	p2(instructions)
}
