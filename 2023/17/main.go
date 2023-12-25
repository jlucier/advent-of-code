package main

import (
	"container/heap"
	"fmt"
	"strings"

	"aoc/utils"
)

type PriorityQueue []Path

func (pq PriorityQueue) Len() int { return len(pq) }

func (pq PriorityQueue) Less(i, j int) bool {
	return pq[i].costEst() < pq[j].costEst()
}

func (pq PriorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
}

func (pq *PriorityQueue) Push(x any) {
	item := x.(Path)
	*pq = append(*pq, item)
}

func (pq *PriorityQueue) Pop() any {
	old := *pq
	n := len(old)
	item := old[n-1]
	// old[n-1] = nil // avoid memory leak
	*pq = old[0 : n-1]
	return item
}

type Path struct {
	pos        utils.V2
	dir        utils.V2
	nSinceTurn int
	loss       int
	h          int
	w          int
}

type PathState struct {
	pos        utils.V2
	dir        utils.V2
	nSinceTurn int
}

func (self *Path) costEst() int {
	return self.loss + (self.w - self.pos.X) + (self.h - self.pos.Y)
}

func (self *Path) Print(mp [][]int) {
	lines := make([][]string, len(mp))
	for y, ln := range mp {
		sln := utils.IntsToStrs(ln)
		if self.pos.Y == y {
			sln[self.pos.X] = utils.Red(sln[self.pos.X])
		}
		lines[y] = sln
	}

	// for _, loc := range self.path {
	// 	lines[loc.Y][loc.X] = utils.Green(string(lines[loc.Y][loc.X]))
	// }

	for _, ln := range lines {
		fmt.Println(strings.Join(ln, ""))
	}
}

func (self *Path) getNextOpts(mp [][]int) []Path {
	h := len(mp)
	w := len(mp[0])

	r := utils.V2{X: self.dir.Y, Y: -self.dir.X}
	l := utils.V2{X: -self.dir.Y, Y: self.dir.X}
	nextPositions := []utils.V2{
		self.pos.Add(&self.dir),
		self.pos.Add(&r),
		self.pos.Add(&l),
	}
	nextPositions = utils.Filter(nextPositions, func(v utils.V2, i int) bool {
		return v.X >= 0 && v.X < w && v.Y >= 0 && v.Y < h
	})

	// create paths

	var paths []Path
	for _, pos := range nextPositions {
		np := Path{
			pos,
			pos.Sub(&self.pos),
			self.nSinceTurn + 1,
			self.loss + mp[pos.Y][pos.X],
			len(mp) - 1,
			len(mp[0]) - 1,
		}

		// check straights
		if self.dir != np.dir {
			// we've turned on this move
			np.nSinceTurn = 1
		} else if np.nSinceTurn > 3 {
			// can't use this path since it doesn't turn
			continue
		}
		// good to add
		paths = append(paths, np)
	}
	return paths
}

func parseMap(fname string) [][]int {
	lines := utils.ReadLines(fname)
	mp := make([][]int, len(lines))

	for i, ln := range lines {
		mp[i] = utils.StrsToInts(strings.Split(ln, ""))
	}
	return mp
}

func printMap(mp [][]int, hl []utils.V2) {
	lines := make([][]string, len(mp))
	for y, ln := range mp {
		sln := utils.IntsToStrs(ln)
		lines[y] = sln
	}
	for _, v := range hl {
		lines[v.Y][v.X] = utils.Red(lines[v.Y][v.X])
	}
	for _, ln := range lines {
		fmt.Println(strings.Join(ln, ""))
	}
}

func findBestPath(mp [][]int) int {
	paths := PriorityQueue{{
		utils.V2{X: 0, Y: 0},
		utils.V2{X: 1, Y: 0},
		1,
		0,
		len(mp) - 1,
		len(mp[0]) - 1,
	}, {
		utils.V2{X: 0, Y: 0},
		utils.V2{X: 0, Y: 1},
		1,
		0,
		len(mp) - 1,
		len(mp[0]) - 1,
	}}
	heap.Init(&paths)

	bests := make(map[PathState]int)
	npaths := 0

	for paths.Len() > 0 {
		p := heap.Pop(&paths).(Path)
		st := PathState{p.pos, p.dir, p.nSinceTurn}

		if bests[st] != 0 && bests[st] < p.costEst() {
			continue
		}
		bests[st] = p.costEst()

		if p.pos.X == len(mp[0])-1 && p.pos.Y == len(mp)-1 {
			fmt.Println("done", npaths)
			return p.loss
		}

		if npaths%1000000 == 0 {
			fmt.Println("processed", npaths, len(paths), p.pos)
			opts := utils.EmptySet[utils.V2]()
			for _, op := range paths {
				opts.Add(op.pos)
			}
			printMap(mp, opts.Values())
		}
		for _, np := range p.getNextOpts(mp) {
			npSt := PathState{np.pos, np.dir, np.nSinceTurn}
			if bests[npSt] == 0 || bests[npSt] > np.costEst() {
				heap.Push(&paths, np)
			}
		}
		npaths++
	}

	return 0
}

func p1(mp [][]int) {
	fmt.Println("p1:", findBestPath(mp))
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/17/input.txt"
	mp := parseMap(fname)
	p1(mp)
}
