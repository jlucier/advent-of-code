const std = @import("std");
const zutils = @import("zutils");

const NodeList = std.array_list.Managed([]const u8);
const Graph = std.array_hash_map.StringArrayHashMap(NodeList);
const SearchCache = std.array_hash_map.StringArrayHashMap(usize);

fn deinitGraph(g: *Graph) void {
    var iter = g.iterator();
    while (iter.next()) |e| {
        e.value_ptr.deinit();
    }

    g.deinit();
}

fn parse(gpa: std.mem.Allocator, input: []const u8) !Graph {
    var iter = std.mem.splitScalar(u8, input, '\n');
    var graph = Graph.init(gpa);

    while (iter.next()) |ln| {
        if (ln.len == 0) continue;

        var lnIt = std.mem.splitScalar(u8, ln, ' ');
        var first = true;
        var nl: ?*NodeList = null;
        while (lnIt.next()) |part| {
            if (first) {
                const key = part[0 .. part.len - 1];
                try graph.put(key, NodeList.init(gpa));
                nl = graph.getPtr(key).?;
                first = false;
            } else {
                try nl.?.append(part);
            }
        }
    }
    return graph;
}

fn explore(
    g: *const Graph,
    cache: *SearchCache,
    curr: []const u8,
    end: []const u8,
) usize {
    if (std.mem.eql(u8, curr, end))
        return 1;

    // not last, DFS into neighbors
    var total: usize = 0;
    const neighbors = g.getPtr(curr);
    if (neighbors == null) return 0;

    for (neighbors.?.items) |next| {
        if (cache.get(next)) |nv| {
            total += nv;
        } else {
            // miss, recurse
            total += explore(g, cache, next, end);
        }
    }

    // update cache for this node
    cache.putAssumeCapacity(curr, total);
    return total;
}

fn paths(
    gpa: std.mem.Allocator,
    g: *const Graph,
    start: []const u8,
    end: []const u8,
) !usize {
    var allNodes = SearchCache.init(gpa);
    defer allNodes.deinit();
    try allNodes.ensureTotalCapacity(g.count());

    return explore(g, &allNodes, start, end);
}

fn p2(gpa: std.mem.Allocator, g: *const Graph, start: []const u8, end: []const u8) !usize {
    return try paths(gpa, g, start, "dac") //
    * try paths(gpa, g, "dac", "fft") //
    * try paths(gpa, g, "fft", end) //
    + try paths(gpa, g, start, "fft") //
        * try paths(gpa, g, "fft", "dac") //
        * try paths(gpa, g, "dac", end);
}

fn solve(gpa: std.mem.Allocator, input: []const u8) ![2]usize {
    var g = try parse(gpa, input);
    defer deinitGraph(&g);

    return .{
        try paths(gpa, &g, "you", "out"),
        try p2(gpa, &g, "svr", "out"),
    };
}

test "example.p1" {
    const input =
        \\aaa: you hhh
        \\you: bbb ccc
        \\bbb: ddd eee
        \\ccc: ddd eee fff
        \\ddd: ggg
        \\eee: out
        \\fff: out
        \\ggg: out
        \\hhh: ccc fff iii
        \\iii: out
    ;

    var g = try parse(std.testing.allocator, input);
    defer deinitGraph(&g);
    try std.testing.expectEqual(5, try paths(std.testing.allocator, &g, "you", "out"));
}

test "example.p2" {
    const input =
        \\svr: aaa bbb
        \\aaa: fft
        \\fft: ccc
        \\bbb: tty
        \\tty: ccc
        \\ccc: ddd eee
        \\ddd: hub
        \\hub: fff
        \\eee: dac
        \\dac: fff
        \\fff: ggg hhh
        \\ggg: out
        \\hhh: out
    ;
    var g = try parse(std.testing.allocator, input);
    defer deinitGraph(&g);
    try std.testing.expectEqual(2, try p2(std.testing.allocator, &g, "svr", "out"));
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2025/11.txt");
    const res = try solve(std.heap.page_allocator, input);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
