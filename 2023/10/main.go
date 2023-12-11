package main

import (
	"fmt"
	"strings"

	"aoc/utils"
)

const (
	NORTH_CONN = "S|LJ"
	SOUTH_CONN = "S|7F"
	WEST_CONN  = "S-J7"
	EAST_CONN  = "S-LF"
	CORNERS    = "LJ7F"
)

type Cell struct {
	row int
	col int
}

func (self *Cell) Add(other *Cell) Cell {
	return Cell{self.row + other.row, self.col + other.col}
}

func (self *Cell) Rotate(angle int) Cell {
	switch angle {
	case 90:
		return Cell{-self.col, self.row}
	case -90:
		return Cell{self.col, -self.row}
	case 0:
		return *self
	}
	panic("Unhandled rotation")
}

func (self *Cell) Diff(other *Cell) Cell {
	return Cell{self.row - other.row, self.col - other.col}
}

func (self *Cell) Up() Cell {
	return Cell{self.row - 1, self.col}
}

func (self *Cell) Down() Cell {
	return Cell{self.row + 1, self.col}
}

func (self *Cell) Left() Cell {
	return Cell{self.row, self.col - 1}
}

func (self *Cell) Right() Cell {
	return Cell{self.row, self.col + 1}
}

type Map struct {
	grid  [][]byte
	start Cell
}

func parseMap(fname string) Map {
	lines := utils.ReadLines(fname)
	m := Map{make([][]byte, len(lines)), Cell{0, 0}}

	for i, ln := range lines {
		m.grid[i] = make([]byte, len(ln))
		for j, c := range ln {
			m.grid[i][j] = byte(c)

			if c == 'S' {
				m.start = Cell{i, j}
			}
		}
	}
	return m
}

func (self *Map) Print(path []Cell, hl []Cell) {
	pSet := utils.NewSet(path)
	hlSet := utils.NewSet(hl)

	var bld strings.Builder

	for i, ln := range self.grid {
		for j, b := range ln {
			s := string(b)
			c := Cell{i, j}

			if hlSet.Contains(c) {
				s = utils.Blue(s)
			} else if b == 'S' {
				s = utils.Green(s)
			} else if pSet.Contains(c) {
				s = utils.Red(s)
			}
			bld.WriteString(s)
		}
		bld.WriteByte('\n')
	}

	fmt.Println(bld.String())
}

func (self *Map) Get(c *Cell) byte {
	return self.grid[c.row][c.col]
}

// Get outgoing connections from cell
func (self *Map) Neighbors(c *Cell) []Cell {
	var nbors []Cell
	height := len(self.grid)
	width := len(self.grid[0])
	char := rune(self.Get(c))

	north := c.Up()
	south := c.Down()
	west := c.Left()
	east := c.Right()

	if north.row >= 0 && strings.ContainsRune(NORTH_CONN, char) {
		nbors = append(nbors, north)
	}

	if south.row < height && strings.ContainsRune(SOUTH_CONN, char) {
		nbors = append(nbors, south)
	}

	if west.col >= 0 && strings.ContainsRune(WEST_CONN, char) {
		nbors = append(nbors, west)
	}

	if east.col < width && strings.ContainsRune(EAST_CONN, char) {
		nbors = append(nbors, east)
	}
	return nbors
}

// Return whether two cells connect
func (self *Map) CellsConnect(a *Cell, b *Cell) bool {
	// Check for mutual connection
	aconnb := false
	for _, an := range self.Neighbors(a) {
		if an == *b {
			aconnb = true
		}
	}

	if !aconnb {
		return false
	}

	bconna := false
	for _, bn := range self.Neighbors(b) {
		if bn == *a {
			bconna = true
		}
	}

	return bconna
}

// Neighbors that mutually connect
func (self *Map) ConnectedNeighbors(c *Cell) []Cell {
	var nbors []Cell
	for _, nb := range self.Neighbors(c) {
		if self.CellsConnect(c, &nb) {
			nbors = append(nbors, nb)
		}
	}
	return nbors
}

func (self *Map) Walk() []Cell {
	seen := utils.EmptySet[Cell]()
	path := []Cell{self.start}

	for {
		lastCell := path[len(path)-1]
		seen.Add(lastCell)

		nbors := self.ConnectedNeighbors(&lastCell)

		for _, nb := range nbors {
			if !seen.Contains(nb) {
				path = append(path, nb)
				break
			} else if len(path) > 2 && nb == self.start {
				return path
			}
		}
	}
}

func (self *Map) findSomethingExterior(path []Cell) Cell {
	pathCells := utils.NewSet(path)

	for i := 0; i < len(self.grid); i++ {
		le := Cell{i, 0}
		re := Cell{i, len(self.grid[0]) - 1}

		if !pathCells.Contains(le) {
			return le
		} else if !pathCells.Contains(re) {
			return re
		}
	}

	for i := 0; i < len(self.grid[0]); i++ {
		te := Cell{0, i}
		be := Cell{len(self.grid) - 1, i}

		if !pathCells.Contains(te) {
			return te
		} else if !pathCells.Contains(be) {
			return be
		}
	}
	return Cell{}
}

func (self *Map) findAllAdjacent(cell Cell, seen *utils.Set[Cell]) {
	opts := []Cell{
		cell.Up(),
		cell.Down(),
		cell.Left(),
		cell.Right(),
	}

	for _, o := range opts {
		if !seen.Contains(o) &&
			utils.Between(o.row, 0, len(self.grid)) && utils.Between(o.col, 0, len(self.grid[0])) {
			seen.Add(o)
			self.findAllAdjacent(o, seen)
		}
	}
}

func (self *Map) WalkNextTo(path []Cell) {
	pathCells := utils.NewSet(path)

	ext := self.findSomethingExterior(path)
	grp := utils.NewSet(path)
	grp.Add(ext)
	self.findAllAdjacent(ext, &grp)
	grp.RemoveAll(path)

	var extC Cell
	var pathC Cell

	for _, opt := range grp.Values() {
		pathNb := pathCells.Intersection([]Cell{opt.Up(), opt.Down(), opt.Left(), opt.Right()})
		// fmt.Println(opt, pathNb)
		if pathNb.Size() > 0 {
			extC = opt
			pathC = pathNb.Values()[0]
			break
		}
	}

	pathI := 0
	for i, c := range path {
		if c == pathC {
			pathI = i
			break
		}
	}

	extOrPath := pathCells.Copy()
	for i := 0; i < len(path); i++ {
		if !pathCells.Contains(extC) {
			// find any unkown
			self.findAllAdjacent(extC, &extOrPath)
		}

		// move extC accordingly
		ri := (pathI + i) % len(path)
		// fmt.Println(pathI, i, len(path), ri)
		// if ri+1 >= pathI {
		// 	break
		// }

		curr := path[ri]
		next := path[(ri+1)%len(path)]
		nextMove := next.Diff(&curr)
		// TODO we have issues with repeated tight bends making our
		// offset dude crazy

		delta := extC.Diff(&curr)

		fmt.Println("path", curr, "ext", extC, "d", delta)
		self.Print([]Cell{curr, extC}, []Cell{})

		if strings.ContainsRune(CORNERS, rune(self.Get(&curr))) {
			// corner
			tmpD := delta.Rotate(getTurn(&delta, self.Get(&curr)))
			nextExt := next.Add(&tmpD)
			// fmt.Println("After", nextExt)

			missed := curr.Add(&tmpD)
			// need to check neighbors?
			if !pathCells.Contains(missed) {
				fmt.Println("checking missed", missed)
				self.Print([]Cell{missed}, []Cell{})
				self.findAllAdjacent(missed, &extOrPath)
			}
			extC = nextExt
		} else {
			extC = extC.Add(&nextMove)
		}

		// fmt.Println(nextMove, delta)
		// self.Print([]Cell{curr, extC}, []Cell{})
		//
		// if strings.ContainsRune(CORNERS, rune(self.Get(&curr))) &&
		// 	((nextMove.row != 0 && delta.row != 0) || (nextMove.col != 0 && delta.col != 0)) {
		// 	adj := utils.NewSet([]Cell{
		// 		curr.Up(),
		// 		curr.Down(),
		// 		curr.Left(),
		// 		curr.Right(),
		// 	})
		// 	adj.Remove(extC)
		// 	adj.Remove(next)
		// 	prev := path[(ri-1+len(path))%len(path)]
		// 	adj.Remove(prev)
		// 	fmt.Println(extC, adj.Values()[0])
		//
		// 	if adj.Size() != 1 {
		// 		fmt.Println(curr, adj.Values())
		// 		panic("FUCK")
		// 	}
		// 	// move ext dude to the only remaining neighbor before we add the delta
		// 	extC = adj.Values()[0]
		// 	// also find here since we'll skip it
		// 	self.findAllAdjacent(extC, &extOrPath)
		// }
		//
		// extC = extC.Add(&nextMove)
	}

	self.Print([]Cell{}, extOrPath.Values())

	fmt.Println("p2:", len(self.grid)*len(self.grid[0])-extOrPath.Size())
}

func getTurn(d *Cell, letter byte) int {
	switch letter {
	case 'L':
		if d.row != 0 {
			return -90
		}
		return 90
	case 'J':
		if d.row != 0 {
			return 90
		}
		return -90
	case 'F':
		if d.row != 0 {
			return 90
		}
		return -90
	case '7':
		if d.row != 0 {
			return -90
		}
		return 90
	}
	return 0
}

func main() {
	m := parseMap("~/sync/dev/aoc_inputs/2023/10/ex.txt")
	p := m.Walk()
	fmt.Println("p1:", len(p)/2)
	m.WalkNextTo(p)
}
