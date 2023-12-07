package main

import (
	"fmt"
	"regexp"
	"strings"

	"aoc/utils"
)

type Translation struct {
	destStart int
	srcStart  int
	length    int
}

type Mapping struct {
	name   string
	ranges []Translation
}

type Range struct {
	start  int
	length int
}

// Translate a single integer through the mapping
func (self *Mapping) translate(src int) int {
	out := src
	for _, rn := range self.ranges {
		if utils.Between(src, rn.srcStart, rn.srcStart+rn.length) {
			out += rn.destStart - rn.srcStart
			break
		}
	}

	return out
}

// Translate a range through the mapping
func (self *Mapping) translateRange(startRange Range) []Range {
	inRanges := []Range{startRange}
	var outRanges []Range
	for len(inRanges) > 0 {
		inp := inRanges[0]
		inRanges = inRanges[1:]

		match := false
		for _, rn := range self.ranges {
			if utils.Between(inp.start, rn.srcStart, rn.srcStart+rn.length) ||
				utils.Between(inp.start+inp.length-1, rn.srcStart, rn.srcStart+rn.length) {
				// fmt.Println("overlap", inp, rn)
				// overlap
				overlapStart := utils.Max(inp.start, rn.srcStart)
				overlapLen := utils.Min(inp.start+inp.length, rn.srcStart+rn.length) - overlapStart
				outRanges = append(outRanges, Range{
					// do the translation of the start point because it's within range
					overlapStart + (rn.destStart - rn.srcStart),
					overlapLen,
				})

				// handle extra untranslated parts if needed
				if inp.start < rn.srcStart {
					inRanges = append(inRanges, Range{
						inp.start,
						rn.srcStart - inp.start,
					})
				}
				if inp.start+inp.length > rn.srcStart+rn.length {
					inRanges = append(inRanges, Range{
						rn.srcStart + rn.length,
						(inp.start + inp.length) - (rn.srcStart + rn.length),
					})
				}
				match = true
				break
			}
		}
		if !match {
			outRanges = append(outRanges, inp)
		}
	}

	// fmt.Println("translated", outRanges)
	return outRanges
}

func parseInput(fname string) ([]int, []Mapping) {
	lines := utils.ReadLines(fname)

	numRe := regexp.MustCompile("[0-9]+")
	seeds := utils.StrsToInts(numRe.FindAllString(lines[0], -1))
	var mappings []Mapping

	for _, ln := range lines[1:] {
		if ln == "\n" {
			continue
		}

		if strings.Contains(ln, ":") {
			// defines new map
			mappings = append(mappings, Mapping{ln, []Translation{}})
		} else {
			// adds to mapping
			m := &mappings[len(mappings)-1]
			rn := utils.StrsToInts(numRe.FindAllString(ln, -1))
			m.ranges = append(m.ranges, Translation{rn[0], rn[1], rn[2]})
		}
	}

	return seeds, mappings
}

func p1(fname string) {
	seeds, mappings := parseInput(fname)

	for _, m := range mappings {
		for i, v := range seeds {
			seeds[i] = m.translate(v)
		}
	}

	m, _ := utils.MinMax(seeds)
	fmt.Println("p1:", m)
}

func p2(fname string) {
	seeds, mappings := parseInput(fname)
	// seeds converted from ranges
	var sRanges []Range
	for i := 0; i < len(seeds); i += 2 {
		sRanges = append(sRanges, Range{seeds[i], seeds[i+1]})
	}
	// fmt.Println(sRanges)

	for _, m := range mappings {
		var newRanges []Range
		// fmt.Println(m, "begin", sRanges)
		for _, r := range sRanges {
			newRanges = append(newRanges, m.translateRange(r)...)
		}
		sRanges = newRanges
	}

	// fmt.Println("p2:", sRanges)
	minLoc := sRanges[0].start
	for _, outRng := range sRanges[1:] {
		minLoc = utils.Min(minLoc, outRng.start)
	}
	fmt.Println("p2:", minLoc)
}

func main() {
	f := "~/sync/dev/aoc_inputs/2023/5/input.txt"
	p1(f)
	p2(f)
}
