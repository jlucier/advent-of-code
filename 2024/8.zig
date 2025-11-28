const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);
const AntMap = std.AutoArrayHashMap(u8, std.array_list.Managed(V2));

fn deinitAntMap(map: *AntMap) void {
    for (map.values()) |v| {
        v.deinit();
    }
    map.deinit();
}

fn parseAntenna(allocator: std.mem.Allocator, lines: []const []const u8) !AntMap {
    var map = AntMap.init(allocator);

    for (lines, 0..) |ln, y| {
        for (ln, 0..) |c, x| {
            switch (c) {
                '.' => continue,
                else => {
                    const res = try map.getOrPut(c);
                    if (!res.found_existing) {
                        res.value_ptr.* = std.array_list.Managed(V2).init(allocator);
                    }
                    try res.value_ptr.append(.{ .x = @intCast(x), .y = @intCast(y) });
                },
            }
        }
    }

    return map;
}

fn totalAntinodes(
    allocator: std.mem.Allocator,
    map: *const AntMap,
    nrows: usize,
    ncols: usize,
    p2: bool,
) !usize {
    var uniq = std.AutoArrayHashMap(V2, void).init(allocator);
    defer uniq.deinit();

    for (map.values()) |*v| {
        // if more than 1 of this frequency, each node will be in line with at least
        // 2 others, contributing to the antinode count

        for (v.items) |a| {
            if (p2 and v.items.len > 1) {
                try uniq.put(a, {});
            }
            for (v.items) |b| {
                if (a.equal(b)) {
                    continue;
                }

                const node_dir = b.sub(a).mul(-1);
                var anti = a.add(node_dir);
                var i: usize = 0;
                while (true) : (i += 1) {
                    if (!p2 and i == 1) {
                        break;
                    }
                    if (anti.x >= 0 and anti.x < ncols and anti.y >= 0 and anti.y < nrows) {
                        try uniq.put(anti, {});
                        anti.addMut(node_dir);
                    } else {
                        break;
                    }
                }
            }
        }
    }
    return uniq.count();
}

fn parts(allocator: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    var map = try parseAntenna(allocator, lines);
    defer deinitAntMap(&map);
    const nrows = lines.len;
    const ncols = lines[0].len;

    return .{
        try totalAntinodes(allocator, &map, nrows, ncols, false),
        try totalAntinodes(allocator, &map, nrows, ncols, true),
    };
}

test "parts" {
    const lines = [_][]const u8{
        "............",
        "........0...",
        ".....0......",
        ".......0....",
        "....0.......",
        "......A.....",
        "............",
        "............",
        "........A...",
        ".........A..",
        "............",
        "............",
    };

    const ans = try parts(std.testing.allocator, &lines);
    try std.testing.expectEqual(14, ans[0]);
    try std.testing.expectEqual(34, ans[1]);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/8.txt");
    const ans = try parts(std.heap.page_allocator, lines.items());

    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
