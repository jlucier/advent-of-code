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
	return pq[i].loss < pq[j].loss
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
	path       []utils.V2
	nSinceTurn int
	loss       int
}

type PathState struct {
	pos        utils.V2
	nSinceTurn int
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

	for _, loc := range self.path {
		lines[loc.Y][loc.X] = utils.Green(string(lines[loc.Y][loc.X]))
	}

	for _, ln := range lines {
		fmt.Println(strings.Join(ln, ""))
	}
}

func (self *Path) getNextOpts(mp [][]int) []Path {
	// fmt.Println()
	// fmt.Println(*self)
	// self.Print(mp)

	h := len(mp)
	w := len(mp[0])

	nextPositions := []utils.V2{
		{X: self.pos.X - 1, Y: self.pos.Y},
		{X: self.pos.X, Y: self.pos.Y - 1},
		{X: self.pos.X + 1, Y: self.pos.Y},
		{X: self.pos.X, Y: self.pos.Y + 1},
	}
	seen := utils.NewSet[utils.V2](self.path)
	nextPositions = utils.Filter(nextPositions, func(v utils.V2, i int) bool {
		return v.X >= 0 && v.X < w && v.Y >= 0 && v.Y < h && !seen.Contains(v)
	})

	if len(self.path) > 0 {
		// lastPos is the one before the current
		lastPos := self.path[len(self.path)-1]
		nextPositions = utils.Filter(nextPositions, func(v utils.V2, i int) bool {
			return v != lastPos
		})
	}

	// create paths

	var paths []Path
	for _, pos := range nextPositions {
		np := Path{
			pos,
			make([]utils.V2, len(self.path)+1),
			self.nSinceTurn + 1,
			self.loss + mp[pos.Y][pos.X],
		}
		copy(np.path, self.path)
		np.path[len(np.path)-1] = self.pos

		// check straights
		if len(np.path) >= 2 {
			// np.path = np.path[len(np.path)-2:]
			tmp := pos.Sub(&np.path[len(np.path)-2])
			if tmp.X != 0 && tmp.Y != 0 {
				// we've turned on this move
				np.nSinceTurn = 1
			} else if np.nSinceTurn > 3 {
				// can't use this path since it doesn't turn
				continue
			}
		}

		// good to add
		paths = append(paths, np)
	}
	// fmt.Println("new paths")
	// for _, p := range paths {
	// 	fmt.Println(p)
	// }
	// fmt.Scanln()
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

func findBestPath(mp [][]int) int {
	paths := PriorityQueue{{
		utils.V2{X: 0, Y: 0},
		[]utils.V2{},
		1,
		0,
	}}
	heap.Init(&paths)

	bests := make(map[PathState]int)
	npaths := 0

	for len(paths) > 0 {
		p := heap.Pop(&paths).(Path)
		st := PathState{p.pos, p.nSinceTurn}
		// st := p.pos

		if bests[st] == 0 {
			bests[st] = p.loss
		} else {
			if bests[st] < p.loss {
				continue
			}
			bests[st] = utils.Min(bests[st], p.loss)
		}

		if p.pos.X == len(mp[0])-1 && p.pos.Y == len(mp)-1 {
			fmt.Println("done", p.loss)
			p.Print(mp)
			return p.loss
		}

		for _, np := range p.getNextOpts(mp) {
			npSt := PathState{np.pos, np.nSinceTurn}
			if bests[npSt] == 0 || bests[npSt] > np.loss {
				heap.Push(&paths, np)
			}
		}
		if npaths%100000 == 0 {
			fmt.Println("processed", npaths, len(paths))
			// fmt.Println(p.pos, p.loss)
			// // p.Print(mp)
			// fmt.Println()
			// fmt.Scanln()
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
