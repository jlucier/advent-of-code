package main

import (
  "fmt"
  "strings"

  "aoc/utils"
)

type AdjList map[string]*utils.StrSet
type Path struct {
  nodes []string
  counts map[string]int
}

func NewPath() *Path {
  p := &Path{}
  p.counts = make(map[string]int)
  return p
}

func (s *Path) Copy() *Path {
  p := NewPath()
  for _, n := range s.nodes {
    p.AddNode(n)
  }
  return p
}

func (s *Path) AddNode(node string) *Path {
  s.nodes = append(s.nodes, node)
  _, ok := s.counts[node]
  if !ok {
    s.counts[node] = 0
  }
  s.counts[node] += 1
  return s
}

func (s *Path) Last() string {
  if len(s.nodes) == 0 {
    panic("No Nodes?")
  }
  return s.nodes[len(s.nodes)-1]
}

func (s *Path) Size() int {
  return len(s.nodes)
}

func (s *Path) Count(node string) int {
  c, ok := s.counts[node]
  if !ok {
    return 0
  }
  return c
}


func isUpper(s string) bool {
  return s == strings.ToUpper(s)
}

func addNode(adj AdjList, k, v string) {
    s, ok := adj[k]
    if !ok {
      adj[k] = utils.NewStrSet().Add(v)
    } else {
      s.Add(v)
    }
}

func parseInput(filename string) AdjList {
  lines := utils.ReadLines(filename)

  adj := AdjList{}

  for _, l := range lines {
    tokens := strings.Split(l, "-")
    start := tokens[0]
    end := tokens[1]

    addNode(adj, start, end)
    addNode(adj, end, start)
  }
  return adj
}

func part1Check(path *Path, node string) bool {
  return node != "start" && (isUpper(node) || path.Count(node) == 0)
}

func part2Check(path *Path, node string) bool {
  if node == "start" {
    return false
  }

  if isUpper(node) || path.Count(node) == 0 {
    return true
  }

  for n, c := range path.counts {
    if isUpper(n) {
      continue
    } else if c > 1{
      return false
    }
  }
  return true
}

func findPaths(adj AdjList, part int) []*Path {
  var complete []*Path
  queue := []*Path{NewPath().AddNode("start")}

  for len(queue) > 0 {
    p := queue[0]
    queue = queue[1:]

    if p.Last() == "end" {
      complete = append(complete, p)
      continue
    }

    opts, _ := adj[p.Last()]
    for _, n := range opts.Values() {
      good := true
      switch part {
        case 1:
          good = part1Check(p, n)
        case 2:
          good = part2Check(p, n)
      }
      if !good {
        continue
      }

      queue = append(queue, p.Copy().AddNode(n))
    }
  }
  return complete
}

func main() {
  adj := parseInput("inp.txt")

  paths := findPaths(adj, 2)
  fmt.Println("Paths", len(paths))
  // for _, p := range paths {
  //   fmt.Println(p.nodes)
  // }
}
