const std = @import("std");
const zutils = @import("zutils");

const V2i = zutils.V2i;
const Grid = zutils.Grid(u8);
const Lines = []const []const u8;

const Path = struct {
    loc: V2i,
    dir: V2i,
    dist: usize = 0,
    est: usize = 0,
    hist: std.ArrayList(V2i),
};

fn comparePaths(_: void, a: Path, b: Path) std.math.Order {
    return if (a.est < b.est) .lt else if (a.est == b.est) .eq else .gt;
}

fn findStartEnd(grid: *const Grid) [2]V2i {
    var start = V2i{};
    var end = V2i{};

    var iter = grid.iterator();
    while (iter.next()) |n| {
        switch (grid.atV(n)) {
            'S' => {
                start = n.asType(isize);
            },
            'E' => {
                end = n.asType(isize);
            },
            else => {},
        }
    }

    return .{ start, end };
}

/// Run A* to find paths. The reason this works for part two is because
/// the visited cache key is on location + direction, which accounts for
/// arriving at the same spot facing different ways and not killing that
/// path
fn parts(allocator: std.mem.Allocator, lines: Lines) ![2]usize {
    const grid = try Grid.init2DSlice(allocator, lines);
    defer grid.deinit();

    const res = findStartEnd(&grid);
    const start = res[0];
    const end = res[1];

    var queue = std.PriorityQueue(Path, void, comparePaths).init(allocator, {});
    defer queue.deinit();
    try queue.add(.{
        .loc = start,
        .dir = .{ .x = 1 },
        .est = @intCast(end.sub(start).manhattanMag()),
        .hist = std.ArrayList(V2i).init(allocator),
    });

    var visited = std.AutoHashMap(V2i, usize).init(allocator);
    defer visited.deinit();

    var overall_best_cost: usize = 0;
    var best_cells = std.AutoArrayHashMap(V2i, void).init(allocator);
    defer best_cells.deinit();

    while (queue.removeOrNull()) |p| {
        if (p.loc.equal(end)) {
            if (overall_best_cost == 0) {
                overall_best_cost = p.dist;
            }

            if (p.dist == overall_best_cost) {
                // add squares
                for (p.hist.items) |v| {
                    try best_cells.put(v, {});
                }
                try best_cells.put(p.loc, {});
            }
            p.hist.deinit();
            continue;
        }

        try visited.put(p.loc, p.dist);

        for (p.loc.neighbors()) |n| {
            if (p.hist.items.len > 0 and n.equal(p.hist.items[p.hist.items.len - 1])) {
                continue;
            }
            // can move
            if (!n.inGridBounds(@intCast(grid.ncols), @intCast(grid.nrows)) or
                grid.atV(n.asType(usize)) == '#')
            {
                continue;
            }
            const next_dir = n.sub(p.loc);

            // should move
            var move_cost: usize = 1;
            if (!next_dir.equal(p.dir)) {
                move_cost += 1000;
            }

            const next_cost = p.dist + move_cost;
            const best_cost = visited.get(n);

            // within one turn
            if (next_cost > if (best_cost) |bc| bc else std.math.maxInt(usize)) {
                continue;
            }

            const remaining_est: usize = @intCast(end.sub(n).manhattanMag());
            var next_hist = try p.hist.clone();
            try next_hist.append(p.loc);
            try queue.add(.{
                .loc = n,
                .dir = next_dir,
                .dist = next_cost,
                .est = remaining_est + next_cost,
                .hist = next_hist,
            });
        }

        p.hist.deinit();
    }
    return .{ overall_best_cost, best_cells.count() };
}

test "example1" {
    const inp = [_][]const u8{
        "###############",
        "#.......#....E#",
        "#.#.###.#.###.#",
        "#.....#.#...#.#",
        "#.###.#####.#.#",
        "#.#.#.......#.#",
        "#.#.#####.###.#",
        "#...........#.#",
        "###.#.#####.#.#",
        "#...#.....#.#.#",
        "#.#.#.###.#.#.#",
        "#.....#...#.#.#",
        "#.###.#.#.#.#.#",
        "#S..#.....#...#",
        "###############",
    };

    const ans = try parts(std.testing.allocator, &inp);
    try std.testing.expectEqual(7036, ans[0]);
    try std.testing.expectEqual(45, ans[1]);
}

test "example2" {
    const inp = [_][]const u8{
        "#################",
        "#...#...#...#..E#",
        "#.#.#.#.#.#.#.#.#",
        "#.#.#.#...#...#.#",
        "#.#.#.#.###.#.#.#",
        "#...#.#.#.....#.#",
        "#.#.#.#.#.#####.#",
        "#.#...#.#.#.....#",
        "#.#.#####.#.###.#",
        "#.#.#.......#...#",
        "#.#.###.#####.###",
        "#.#.#...#.....#.#",
        "#.#.#.#####.###.#",
        "#.#.#.........#.#",
        "#.#.#.#########.#",
        "#S#.............#",
        "#################",
    };

    const ans = try parts(std.testing.allocator, &inp);
    try std.testing.expectEqual(11048, ans[0]);
    try std.testing.expectEqual(64, ans[1]);
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/16.txt");

    const ans = try parts(std.heap.page_allocator, lines.strings.items);
    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
