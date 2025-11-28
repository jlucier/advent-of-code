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

const DijkSolver = zutils.graph.Dijkstras(DV, struct {
    grid: *const Grid,

    const Edge = struct {
        v: DV,
        cost: usize,
    };

    pub fn getAdjacent(ctx: @This(), allocator: std.mem.Allocator, dv: DV) ![]Edge {
        const grid = ctx.grid;
        var edges = try std.array_list.Managed(Edge).initCapacity(allocator, 4);
        var niter = dv.pos.iterNeighborsInGridBounds(grid.ncols, grid.nrows);
        while (niter.next()) |n| {
            const next_dir = n.sub(dv.pos);
            // skip if turning around
            if (next_dir.add(dv.dir).equal(V2i{}) or
                // skip if wall
                grid.atV(n.asType(usize)) == '#')
            {
                continue;
            }
            var move_cost: usize = 1;
            if (!next_dir.equal(dv.dir)) {
                move_cost += 1000;
            }

            edges.appendAssumeCapacity(.{
                .v = .{ .pos = n, .dir = next_dir },
                .cost = move_cost,
            });
        }
        return try edges.toOwnedSlice();
    }
});

fn printCurr(
    allocator: std.mem.Allocator,
    dj: *const DijkSolver,
    v: *const DijkSolver.Vertex,
) !void {
    const grid = dj.context.grid;

    var hl = std.array_list.Managed(zutils.V2u).init(allocator);
    defer hl.deinit();
    try hl.append(v.v.pos.asType(usize));

    var queue = std.array_list.Managed(*const DijkSolver.Vertex).init(allocator);
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

fn makeVerts(allocator: std.mem.Allocator, grid: *const Grid) ![]DV {
    var verts = std.array_list.Managed(DV).init(allocator);

    var iter = grid.iterator();
    while (iter.next()) |v| {
        if (grid.atV(v) != '#') {
            const iv = v.asType(isize);
            var niter = iv.iterNeighborsInGridBounds(grid.ncols, grid.nrows);
            while (niter.next()) |n| {
                try verts.append(.{ .pos = iv, .dir = n.asType(isize).sub(iv) });
            }
        }
    }
    return verts.toOwnedSlice();
}

fn parts(arena: *std.heap.ArenaAllocator, lines: Lines) ![2]usize {
    const allocator = arena.allocator();
    const grid = try Grid.init2DSlice(allocator, lines);

    const res = findStartEnd(&grid);
    const start = res[0];
    const end = res[1];

    const initial_verts = try makeVerts(allocator, &grid);

    var dj = try DijkSolver.initWithArena(
        arena,
        .{ .pos = start, .dir = .{ .x = 1 } },
        initial_verts,
        .{ .grid = &grid },
    );
    try dj.findPaths();

    var best: ?*const DijkSolver.Vertex = null;
    for (dj.verts.values()) |*dv| {
        if (dv.v.pos.equal(end)) {
            if (best == null or best.?.d > dv.d) {
                best = dv;
            }
        }
    }

    var best_cells = std.AutoHashMap(V2i, void).init(allocator);
    var iter = try dj.pathIterator(best.?.v, false);

    while (try iter.next()) |v| {
        try best_cells.put(v.pos, {});
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

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ans = try parts(&arena, &inp);
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

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ans = try parts(&arena, &inp);
    try std.testing.expectEqual(11048, ans[0]);
    try std.testing.expectEqual(64, ans[1]);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const lines = try zutils.fs.readLines(arena.allocator(), "~/sync/dev/aoc_inputs/2024/16.txt");

    const ans = try parts(&arena, lines.items());
    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
