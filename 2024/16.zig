const std = @import("std");
const zutils = @import("zutils");

const V2i = zutils.V2i;
const Grid = zutils.Grid(u8);
const Lines = []const []const u8;

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

const DV = struct {
    pos: V2i,
    dir: V2i,
};

const Edge = struct {
    v: DV,
    cost: usize,
};

const DijkCtx = struct {
    grid: *const Grid,
};

const DijkSolver = zutils.graph.Dijkstras(DV, Edge, DijkCtx, getNeighbors);

fn printCurr(
    allocator: std.mem.Allocator,
    dj: *const DijkSolver,
    v: *const DijkSolver.Vertex,
) !void {
    const grid = dj.context.grid;

    var hl = std.ArrayList(zutils.V2u).init(allocator);
    defer hl.deinit();
    try hl.append(v.v.pos.asType(usize));

    var queue = std.ArrayList(*const DijkSolver.Vertex).init(allocator);
    defer queue.deinit();
    try queue.append(v);

    while (queue.popOrNull()) |dv| {
        for (dv.pred.items) |it| {
            try hl.append(it.pos.asType(usize));
            try queue.append(dj.verts.getPtr(it).?);
        }
    }

    std.debug.print("eval: {} {} {any}\n", .{ v.d, v.v, v.pred.items });
    grid.printHl(hl.items);
    std.debug.print("\n", .{});
}

fn getNeighbors(allocator: std.mem.Allocator, dv: DV, ctx: DijkCtx) ![]Edge {
    const grid = ctx.grid;
    var edges = std.ArrayList(Edge).init(allocator);
    for (dv.pos.neighbors()) |n| {
        const next_dir = n.sub(dv.pos);
        // skip if OB
        if (!n.inGridBounds(@intCast(grid.ncols), @intCast(grid.nrows)) or
            // skip if turning around
            next_dir.add(dv.dir).equal(V2i{}) or
            // skip if wall
            grid.atV(n.asType(usize)) == '#')
        {
            continue;
        }
        var move_cost: usize = 1;
        if (!next_dir.equal(dv.dir)) {
            move_cost += 1000;
        }

        try edges.append(.{
            .v = .{ .pos = n, .dir = next_dir },
            .cost = move_cost,
        });
    }
    return try edges.toOwnedSlice();
}

fn makeVerts(allocator: std.mem.Allocator, grid: *const Grid) ![]DV {
    var verts = std.ArrayList(DV).init(allocator);

    var iter = grid.iterator();
    while (iter.next()) |v| {
        if (grid.atV(v) != '#') {
            const iv = v.asType(isize);
            for (iv.neighbors()) |n| {
                if (n.inGridBounds(@intCast(grid.ncols), @intCast(grid.nrows))) {
                    const d = n.asType(isize).sub(iv);
                    try verts.append(.{ .pos = iv, .dir = d });
                }
            }
        }
    }
    return verts.toOwnedSlice();
}

fn parts(allocator: std.mem.Allocator, lines: Lines) ![2]usize {
    const grid = try Grid.init2DSlice(allocator, lines);
    defer grid.deinit();

    const res = findStartEnd(&grid);
    const start = res[0];
    const end = res[1];

    const initial_verts = try makeVerts(allocator, &grid);
    defer allocator.free(initial_verts);

    var dj = try DijkSolver.init(
        allocator,
        .{ .pos = start, .dir = .{ .x = 1 } },
        initial_verts,
        .{ .grid = &grid },
    );
    defer dj.deinit();
    try dj.findPaths(null);

    var best: ?*DijkSolver.Vertex = null;
    for (dj.verts.values()) |*dv| {
        if (dv.v.pos.equal(end)) {
            if (best == null or best.?.d > dv.d) {
                best = dv;
            }
        }
    }

    var best_cells = std.AutoHashMap(V2i, void).init(allocator);
    defer best_cells.deinit();
    var queue = std.ArrayList(*const DijkSolver.Vertex).init(allocator);
    defer queue.deinit();
    try queue.append(best.?);

    while (queue.popOrNull()) |v| {
        try best_cells.put(v.v.pos, {});
        for (v.pred.items) |p| {
            try queue.append(dj.verts.getPtr(p).?);
        }
    }

    return .{ best.?.d, best_cells.count() };
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
