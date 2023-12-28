package main

import (
	"fmt"
	"regexp"
	"strings"

	"aoc/utils"
)

const MAX_VAL = 4000

type Part map[string]int

func (self *Part) Total() int {
	tot := 0
	for _, v := range *self {
		tot += v
	}
	return tot
}

type Rule struct {
	attr string
	cmp  string
	val  int
	next string
}

// Return the range of values that satisfy this rule
func (self *Rule) GetRange() utils.V2 {
	switch self.cmp {
	case "<":
		return utils.V2{X: 1, Y: self.val}
	case ">":
		return utils.V2{X: self.val + 1, Y: MAX_VAL + 1}
	default:
		panic("Bad")
	}
}

// Update a range based on this rule's constraint
func (self *Rule) UpdateRange(rn utils.V2) utils.V2 {
	rrng := self.GetRange()
	return utils.V2{
		X: utils.Max(rrng.X, rn.X),
		Y: utils.Min(rrng.Y, rn.Y),
	}
}

func (self *Rule) Invert() Rule {
	switch self.cmp {
	case "<":
		return Rule{
			self.attr,
			">",
			self.val - 1,
			"",
		}
	case ">":
		return Rule{
			self.attr,
			"<",
			self.val + 1,
			"",
		}
	default:
		panic("Bad")
	}
}

type Workflow struct {
	name  string
	rules []Rule
}

func (self *Workflow) Eval(p Part) string {
	for _, r := range self.rules {
		if r.attr == "" {
			return r.next
		}

		v := p[r.attr]

		switch r.cmp {
		case ">":
			if v > r.val {
				return r.next
			}
		case "<":
			if v < r.val {
				return r.next
			}
		}
	}
	return "ERR"
}

func parse(fname string) (map[string]Workflow, []Part) {
	lines := utils.ReadAllLines(fname)
	reWorkflowLine := regexp.MustCompile("([a-z]+)\\{(.*)\\}")
	reWorkflow := regexp.MustCompile("([a-z])([><])([0-9]+):([a-zA-z]+)")
	rePart := regexp.MustCompile("([a-z])=([0-9]+)")

	flows := make(map[string]Workflow)
	var parts []Part
	wflw := true
	for _, ln := range lines {
		if ln == "" {
			wflw = false
			continue
		}

		if wflw {
			m := reWorkflowLine.FindStringSubmatch(ln)
			flow := Workflow{
				name:  m[1],
				rules: []Rule{},
			}

			for _, part := range strings.Split(m[2], ",") {
				wflwParts := reWorkflow.FindStringSubmatch(part)

				if len(wflwParts) == 0 {
					// not a real rule, just a next
					flow.rules = append(flow.rules, Rule{
						attr: "",
						cmp:  "",
						val:  0,
						next: part,
					})
				} else {
					flow.rules = append(flow.rules, Rule{
						attr: wflwParts[1],
						cmp:  wflwParts[2],
						val:  utils.StrToInt(wflwParts[3]),
						next: wflwParts[4],
					})
				}
			}

			flows[flow.name] = flow
		} else {
			// part
			p := make(map[string]int)
			for _, m := range rePart.FindAllStringSubmatch(ln, -1) {
				p[m[1]] = utils.StrToInt(m[2])
			}

			parts = append(parts, p)
		}
	}
	return flows, parts
}

func p1(fname string) int {
	flows, parts := parse(fname)
	tot := 0

	for _, p := range parts {
		currFlow := flows["in"]
		done := false
		for !done {
			next := currFlow.Eval(p)
			switch next {
			case "A":
				tot += p.Total()
				done = true
			case "R":
				done = true
			case "ERR":
				panic("Fuck")
			default:
				currFlow = flows[next]
			}
		}
	}
	return tot
}

type State struct {
	curr        string
	constraints map[string]utils.V2
}

func p2(fname string) int {
	flows, _ := parse(fname)

	tot := 0
	paths := []State{{"in", make(map[string]utils.V2)}}
	paths[0].constraints["x"] = utils.V2{X: 1, Y: MAX_VAL + 1}
	paths[0].constraints["m"] = utils.V2{X: 1, Y: MAX_VAL + 1}
	paths[0].constraints["a"] = utils.V2{X: 1, Y: MAX_VAL + 1}
	paths[0].constraints["s"] = utils.V2{X: 1, Y: MAX_VAL + 1}

	for len(paths) > 0 {
		p := paths[0]
		paths = paths[1:]

		if p.curr == "A" {
			// accepted path, tally combinations and add
			comb := 1
			for _, rng := range p.constraints {
				comb *= rng.Y - rng.X
			}
			tot += comb
			continue
		} else if p.curr == "R" {
			// rejected path, drop
			continue
		}

		// expand path
		f := flows[p.curr]

		for _, r := range f.rules {
			if r.cmp != "" {
				// add a new path for taking this branch
				nc := utils.CopyMap(p.constraints)
				nc[r.attr] = r.UpdateRange(nc[r.attr])
				paths = append(paths, State{
					r.next,
					nc,
				})

				// add the opposite rule to constrain not taking this branch
				tmpr := r.Invert()
				p.constraints[r.attr] = tmpr.UpdateRange(p.constraints[r.attr])
			} else {
				// reached a rule with no comparison, advance to next state
				paths = append(paths, State{
					r.next,
					p.constraints,
				})
			}
		}
	}
	return tot
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/19/input.txt"
	fmt.Println("p1:", p1(fname))
	fmt.Println("p2:", p2(fname))
}
