package main

import (
	"fmt"
	"regexp"
	"strings"

	"aoc/utils"
)

const (
	NO_PULSE = -1
	LOW      = 0
	HIGH     = 1
)

type Node struct {
	name      string
	typ       string
	outputs   []string
	flipState int
	conjState map[string]int
}

func (self *Node) isStartingState() bool {
	switch self.typ {
	case "%":
		return self.flipState == LOW
	case "&":
		s := 0
		for _, v := range self.conjState {
			s += v
		}
		return s == 0
	default:
		return true
	}
}

func (self *Node) Reset() {
	self.flipState = LOW
	for k := range self.conjState {
		self.conjState[k] = LOW
	}
}

func (self *Node) Receive(p Pulse) int {
	switch self.typ {
	case "%":
		if p.val == HIGH {
			return NO_PULSE
		}
		if self.flipState == HIGH {
			self.flipState = LOW
		} else {
			self.flipState = HIGH
		}
		return self.flipState

	case "&":
		self.conjState[p.src] = p.val
		allHigh := true
		for _, pv := range self.conjState {
			allHigh = allHigh && pv == HIGH
		}
		if allHigh {
			return LOW
		}
		return HIGH
	case "broadcaster":
		return p.val
	default:
		panic("Bad")
	}
}

type Pulse struct {
	src  string
	dest string
	val  int
}

func parse(fname string) ([]Node, map[string]int) {
	lines := utils.ReadLines(fname)
	lnRe := regexp.MustCompile("([%&]*)([a-z]+) -> (.*)")

	var nodes []Node
	nameMap := make(map[string]int)

	for _, ln := range lines {
		m := lnRe.FindStringSubmatch(ln)
		typ := m[1]
		if m[2] == "broadcaster" {
			typ = "broadcaster"
		}

		nodes = append(nodes, Node{
			name:      m[2],
			typ:       typ,
			outputs:   strings.Split(m[3], ", "),
			flipState: 0,
		})
		nameMap[m[2]] = len(nodes) - 1
	}

	// populate conj bois
	for i, n := range nodes {
		if n.typ != "&" {
			continue
		}

		nodes[i].conjState = make(map[string]int)

		for _, other := range nodes {
			if other.name == n.name {
				continue
			}

			for _, o := range other.outputs {
				if o == n.name {
					nodes[i].conjState[other.name] = 0
					break
				}
			}
		}
	}

	return nodes, nameMap
}

type Result struct {
	low     int
	high    int
	gotHigh bool
}

func run(nodes []Node, nameMap map[string]int, lookFor string) Result {
	res := Result{low: 1, high: 0}
	queue := []Pulse{{"button", "broadcaster", LOW}}

	for len(queue) > 0 {
		p := queue[0]
		queue = queue[1:]

		i, ok := nameMap[p.dest]
		if !ok {
			continue
		}

		n := &nodes[i]
		rv := n.Receive(p)
		if n.name == lookFor && rv == HIGH {
			res.gotHigh = true
			return res
		}

		if rv == NO_PULSE {
			continue
		}

		for _, next := range n.outputs {
			if rv == HIGH {
				res.high++
			} else {
				res.low++
			}
			queue = append(queue, Pulse{
				src:  n.name,
				dest: next,
				val:  rv,
			})
		}
	}
	return res
}

func p1(fname string) {
	nodes, nameMap := parse(fname)

	cycleTot := Result{}
	var cycle []Result

	for i := 0; i < 1000; i++ {
		r := run(nodes, nameMap, "")

		cycleTot.low += r.low
		cycleTot.high += r.high
		cycle = append(cycle, r)

		allOg := true
		for i := range nodes {
			allOg = allOg && nodes[i].isStartingState()
		}

		if allOg {
			break
		}
	}

	rem := 1000 % len(cycle)
	low := cycleTot.low * (1000 / len(cycle))
	high := cycleTot.high * (1000 / len(cycle))

	for i := 0; i < rem; i++ {
		low += cycle[i].low
		high += cycle[i].high
	}

	fmt.Println("p1:", len(cycle), low*high)
}

type Req struct {
	name   string
	output int
}

func findRx(nodes []Node) int {
	for i := range nodes {
		n := &nodes[i]
		for _, o := range n.outputs {
			if o == "rx" {
				return i
			}
		}
	}
	return -1
}

func p2(fname string) {
	nodes, nameMap := parse(fname)
	lookFor := make(map[string]int)
	lookFor["kk"] = 0
	lookFor["gl"] = 0
	lookFor["bb"] = 0
	lookFor["mr"] = 0

	for l := range lookFor {
		for i := range nodes {
			nodes[i].Reset()
		}

		for i := 0; i < 10000; i++ {
			r := run(nodes, nameMap, l)
			if r.gotHigh {
				lookFor[l] = i + 1
				break
			}
		}
	}

	presses := 1
	for _, v := range lookFor {
		presses *= v
	}
	fmt.Println("p2:", presses)
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/20/input.txt"
	p1(fname)
	p2(fname)
}
