const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);

const Path = struct {
    loc: V2,
    dist: usize = 0,
    est: isize = 0,
};

fn comparePaths(_: void, a: Path, b: Path) std.math.Order {
    return if (a.est < b.est) .lt else if (a.est == b.est) .eq else .gt;
}

fn findShortestPath(allocator: std.mem.Allocator, lines: []const []const u8) !usize {
    const start: V2 = zutils.indexOf2DScalar(u8, lines, 'S').?.asType(isize);
    const end: V2 = zutils.indexOf2DScalar(u8, lines, 'E').?.asType(isize);
    const nrows: isize = @intCast(lines.len);
    const ncols: isize = @intCast(lines[0].len);

    var queue = std.PriorityQueue(Path, void, comparePaths).init(allocator, {});
    defer queue.deinit();
    try queue.add(.{ .loc = start, .est = end.sub(start).manhattanMag() });
    var visited = std.AutoArrayHashMap(V2, usize).init(allocator);
    defer visited.deinit();

    while (queue.removeOrNull()) |p| {
        if (p.loc.equal(end)) {
            std.debug.print("\n", .{});
            for (lines, 0..) |ln, j| {
                for (ln, 0..) |c, i| {
                    const tmp = V2{ .x = @intCast(i), .y = @intCast(j) };
                    if (visited.getKey(tmp) != null) {
                        std.debug.print("{s}{c}{s}", .{ zutils.ANSI_RED, c, zutils.ANSI_RESET });
                    } else {
                        std.debug.print("{c}", .{c});
                    }
                }
                std.debug.print("\n", .{});
            }
            return p.dist;
        }
        try visited.put(p.loc, p.dist);

        const c = lines[@intCast(p.loc.y)][@intCast(p.loc.x)];
        const curr_elv: i8 = if (c == 'S') @intCast('a') else @intCast(c);

        const next = [4]V2{
            // left
            p.loc.add(.{ .x = -1 }),
            // right
            p.loc.add(.{ .x = 1 }),
            // up
            p.loc.add(.{ .y = -1 }),
            // down
            p.loc.add(.{ .y = 1 }),
        };
        for (next) |n| {
            if (!n.inGridBounds(ncols, nrows)) {
                continue;
            }

            const next_cost = p.dist + 1;
            const best_cost = visited.get(n) orelse std.math.maxInt(usize);
            if (next_cost >= best_cost) {
                continue;
            }

            const oc = lines[@intCast(n.y)][@intCast(n.x)];
            const other_elev: i8 = if (oc == 'E') @intCast('z') else @intCast(oc);
            const delta = other_elev - curr_elv;

            if (delta <= 1) {
                const nc_i: isize = @intCast(next_cost);
                try queue.add(.{
                    .loc = n,
                    .dist = next_cost,
                    .est = end.sub(n).manhattanMag() + nc_i,
                });
            }
        }
    }
    return 0;
}

test "one" {
    const lines = [_][]const u8{
        "Sabqponm",
        "abcryxxl",
        "accszExk",
        "acctuvwj",
        "abdefghi",
    };
    const d = try findShortestPath(std.testing.allocator, &lines);

    try std.testing.expectEqual(31, d);
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/12.txt");
    const d = try findShortestPath(std.heap.page_allocator, lines.strings.items);

    std.debug.print("p1: {d}\n", .{d});
}
