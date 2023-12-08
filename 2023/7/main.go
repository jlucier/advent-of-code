package main

import (
	"fmt"
	"sort"
	"strings"

	"aoc/utils"
)

type hand struct {
	cards map[string]int
	bid   int
	hstr  string
}

const (
	HC int = iota
	PAIR
	TWO_PAIR
	THREE_OF_KIND
	FULL_HOUSE
	FOUR_OF_KIND
	FIVE_OF_KIND
)

func (self *hand) getType(jokerWild bool) int {
	mask := make([]int, 5)
	for _, count := range self.cards {
		mask[count-1]++
	}

	jokes := self.cards["J"]

	if jokerWild && jokes > 0 && jokes < 5 {
		// promote 1 of the best type up by num jokers
		mask[jokes-1]--
		for i := len(mask) - 1; i >= 0; i-- {
			if mask[i] > 0 {
				mask[i]--
				mask[utils.Min(4, i+jokes)]++
				break
			}
		}
	}

	if mask[4] > 0 {
		return FIVE_OF_KIND
	} else if mask[3] > 0 {
		return FOUR_OF_KIND
	} else if mask[2] > 0 && mask[1] > 0 {
		return FULL_HOUSE
	} else if mask[2] > 0 {
		return THREE_OF_KIND
	} else if mask[1] > 1 {
		return TWO_PAIR
	} else if mask[1] > 0 {
		return PAIR
	}
	return HC
}

func parseHands(fname string) []hand {
	lines := utils.ReadLines(fname)
	var hands []hand
	for i, ln := range lines {
		parts := strings.Split(ln, " ")
		hands = append(hands, hand{make(map[string]int), utils.StrToInt(parts[1]), parts[0]})
		for _, c := range parts[0] {
			hands[i].cards[string(c)]++
		}
	}
	return hands
}

func cardValue(c string, jokerWild bool) int {
	switch c[0] {
	case 'A':
		return 14
	case 'K':
		return 13
	case 'Q':
		return 12
	case 'J':
		if jokerWild {
			return -1
		}
		return 11
	case 'T':
		return 10
	default:
		return utils.StrToInt(c)
	}
}

func compareHands(a *hand, b *hand, jokerWild bool) int {
	aType := a.getType(jokerWild)
	bType := b.getType(jokerWild)

	if aType > bType {
		return -1
	}
	if bType > aType {
		return 1
	}

	for i := 0; i < 5; i++ {
		afv := cardValue(string(a.hstr[i]), jokerWild)
		bfv := cardValue(string(b.hstr[i]), jokerWild)

		if afv > bfv {
			return -1
		} else if bfv > afv {
			return 1
		}
	}
	return 0
}

func doPart(fname string, jokerWild bool) int {
	hands := parseHands(fname)
	// sort backwards for rank
	sort.Slice(hands, func(i, j int) bool {
		return compareHands(&hands[i], &hands[j], jokerWild) >= 0
	})
	winnings := 0
	for r, h := range hands {
		winnings += h.bid * (r + 1)
	}
	return winnings
}

func main() {
	fname := "~/sync/dev/aoc_inputs/2023/7/input.txt"
	fmt.Println("p1:", doPart(fname, false))
	fmt.Println("p2:", doPart(fname, true))
}
