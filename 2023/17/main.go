package main

import (
	"container/heap"
	"fmt"
	"math"
	"strings"

	"aoc/utils"
)

type PriorityQueue []*Path

func (pq PriorityQueue) Len() int {
	return len(pq)
}

func (pq PriorityQueue) Less(i, j int) bool {
	return pq[i].loss < pq[j].loss
}

func (pq PriorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
	pq[i].index = i
	pq[j].index = j
}

func (pq *PriorityQueue) Push(x any) {
	n := len(*pq)
	item := x.(*Path)
	*pq = append(*pq, item)
	item.index = n

}

func (pq *PriorityQueue) Pop() any {
	old := *pq
	n := len(old)
	item := old[n-1]
	old[n-1] = nil  // avoid memory leak
	item.index = -1 // for safety
	*pq = old[0 : n-1]
	return item
}

type Path struct {
	pos   utils.V2
	dir   utils.V2
	loss  int
	index int
}

type PathState struct {
	Pos utils.V2
	Dir utils.V2
}

func (self *Path) getPState() PathState {
	return PathState{self.pos, self.dir}
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

func initialize(mp [][]int) ([]Path, PriorityQueue, map[PathState]*Path) {
	var allPaths []Path
	var pq PriorityQueue
	pathMap := make(map[PathState]*Path)
	heap.Init(&pq)
	n := 0

	for i, row := range mp {
		for j := range row {
			for _, d := range []utils.V2{
				{X: 1, Y: 0},
				{X: 0, Y: 1},
				{X: -1, Y: 0},
				{X: 0, Y: -1},
			} {
				p := utils.V2{X: j, Y: i}
				st := PathState{p, d}

				v := math.MaxInt
				if i == 0 && j == 0 {
					v = 0
				}

				allPaths = append(allPaths, Path{p, d, v, n})
				heap.Push(&pq, &allPaths[n])
				pathMap[st] = &allPaths[n]
				n++
			}
		}
	}
	return allPaths, pq, pathMap
}

func findBestPath(mp [][]int, ultra bool) int {
	_, pq, pathMap := initialize(mp)

	h := len(mp)
	w := len(mp[0])
	rng := utils.Range(1, 4)
	if ultra {
		rng = utils.Range(4, 11)
	}

	for pq.Len() > 0 {
		p := heap.Pop(&pq).(*Path)
		st := p.getPState()

		if p.pos.X == len(mp[0])-1 && p.pos.Y == len(mp)-1 {
			return pathMap[st].loss
		}

		r := utils.V2{X: p.dir.Y, Y: -p.dir.X}
		l := utils.V2{X: -p.dir.Y, Y: p.dir.X}

		for _, dir := range []utils.V2{r, l} {
			for _, i := range rng {
				d := dir.Mul(i)
				np := p.pos.Add(&d)
				npst := PathState{np, dir}

				// check bounds
				if !(utils.Between(np.X, 0, w) && utils.Between(np.Y, 0, h)) {
					continue
				}

				// new loss
				l := pathMap[st].loss
				tmp := p.pos
				for d := 0; d < i; d++ {
					tmp = tmp.Add(&dir)
					l += mp[tmp.Y][tmp.X]
				}

				pathMap[npst].loss = utils.Min(pathMap[npst].loss, l)
				heap.Fix(&pq, pathMap[npst].index)
			}
		}
	}
	return 0
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/17/input.txt"
	mp := parseMap(fname)
	fmt.Println("p1:", findBestPath(mp, false))
	fmt.Println("p2:", findBestPath(mp, true))
}
