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

func (self *Map) countSAs(path []Cell) byte {
	start := path[0]
	startNeighbors := utils.NewSet(self.ConnectedNeighbors(&start))

	if startNeighbors.Contains(start.Up()) {
		if startNeighbors.Contains(start.Down()) {
			return '|'
		} else if startNeighbors.Contains(start.Right()) {
			return 'L'
		} else if startNeighbors.Contains(start.Left()) {
			return 'J'
		}
	} else if startNeighbors.Contains(start.Down()) {
		if startNeighbors.Contains(start.Right()) {
			return 'F'
		} else if startNeighbors.Contains(start.Left()) {
			return '7'
		}
	}
	return '-'
}

func (self *Map) NumContained(path []Cell) int {
	sCounts := self.countSAs(path)
	start := path[0]
	self.grid[start.row][start.col] = sCounts

	pathCells := utils.NewSet(path)
	tot := 0
	insideCells := utils.EmptySet[Cell]()
	upCorners := "LJ"
	downCorners := "F7"

	for i := 0; i < len(self.grid); i++ {
		inside := false
		seenCorners := 0
		for j := 0; j < len(self.grid[0]); j++ {
			b := self.grid[i][j]

			if pathCells.Contains(Cell{i, j}) {
				// hitting path
				if b == '|' {
					inside = !inside
					seenCorners = 0
				} else if strings.ContainsRune(upCorners, rune(b)) {
					seenCorners++
					if seenCorners == 0 {
						inside = !inside
					} else if seenCorners > 1 {
						seenCorners = 0
					}
				} else if strings.ContainsRune(downCorners, rune(b)) {
					seenCorners--
					if seenCorners == 0 {
						inside = !inside
					} else if seenCorners < -1 {
						seenCorners = 0
					}
				}
			} else if inside {
				insideCells.Add(Cell{i, j})
				tot++
			}
		}
	}

	self.Print(path, insideCells.Values())
	return tot
}

func main() {
	m := parseMap("~/sync/dev/aoc_inputs/2023/10/input.txt")
	p := m.Walk()
	fmt.Println("p1:", len(p)/2)
	fmt.Println("p2:", m.NumContained(p))
}
