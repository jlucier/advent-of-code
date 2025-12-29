const std = @import("std");
const zutils = @import("zutils");

const NodeList = std.array_list.Managed([]const u8);
const Graph = std.array_hash_map.StringArrayHashMap(NodeList);

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

const Path = struct {
    node: []const u8,
    dac: bool = false,
    fft: bool = false,
};

fn paths(
    gpa: std.mem.Allocator,
    g: *const Graph,
    start: []const u8,
    requireNodes: bool,
) !usize {
    var queue = std.array_list.Managed(Path).init(gpa);
    defer queue.deinit();
    try queue.append(.{
        .node = start,
    });

    var out: usize = 0;
    while (queue.pop()) |curr| {
        if (std.mem.eql(u8, curr.node, "out")) {
            out += if (requireNodes)
                @intFromBool(curr.dac and curr.fft)
            else
                1;
            continue;
        }

        for (g.get(curr.node).?.items) |next| {
            if (!std.mem.eql(u8, next, start)) {
                try queue.append(.{
                    .node = next,
                    .dac = curr.dac or std.mem.eql(u8, next, "dac"),
                    .fft = curr.fft or std.mem.eql(u8, next, "fft"),
                });
            }
        }
    }
    return out;
}

fn solve(gpa: std.mem.Allocator, input: []const u8) ![2]usize {
    var g = try parse(gpa, input);
    defer deinitGraph(&g);

    return .{
        try paths(gpa, &g, "you", false),
        try paths(gpa, &g, "svr", true),
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
    try std.testing.expectEqual(5, try paths(std.testing.allocator, &g, "you", false));
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
    try std.testing.expectEqual(2, try paths(std.testing.allocator, &g, "svr", true));
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2025/11.txt");
    const res = try solve(std.heap.page_allocator, input);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
