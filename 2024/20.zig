const std = @import("std");
const zutils = @import("zutils");

const V2u = zutils.V2u;

const Dijkstras = zutils.graph.GridDijkstras(V2u, u8, '#', zutils.graph.ManhattanCostCtx(V2u));

const Grid = Dijkstras.Grid;

const State = struct {
    arena: std.heap.ArenaAllocator,
    grid: Grid,
    dj: Dijkstras,
    start: V2u,
    end: V2u,
};

fn getCheatCandidates(allocator: std.mem.Allocator, grid: *const Grid) ![]V2u {
    var cells = std.AutoArrayHashMap(V2u, void).init(allocator);
    defer cells.deinit();

    var iter = grid.iterator();
    while (iter.next()) |v| {
        if (grid.atV(v) != '#') {
            continue;
        }
        const iv = v.asType(isize);
        var neighbors = v.iterNeighborsInGridBounds(grid.ncols, grid.nrows);
        while (neighbors.next()) |n| {
            if (grid.atV(n) == '#') {
                continue;
            }

            // check if neighbor opposite this one is open
            const dir = iv.sub(n.asType(isize));
            const opp = iv.add(dir);
            if (opp.inGridBounds(@intCast(grid.ncols), @intCast(grid.nrows))) {
                if (grid.atV(opp.asType(usize)) != '#') {
                    try cells.put(v, {});
                }
            }
        }
    }
    const ret = try allocator.alloc(V2u, cells.count());
    std.mem.copyForwards(V2u, ret, cells.keys());
    return ret;
}

fn parts(
    arena: *std.heap.ArenaAllocator,
    lines: []const []const u8,
) !std.AutoArrayHashMap(usize, usize) {
    const allocator = arena.allocator();
    const start = zutils.indexOf2DScalar(u8, lines, 'S').?;
    const end = zutils.indexOf2DScalar(u8, lines, 'E').?;

    var grid = try Grid.init2DSlice(allocator, lines);
    var dj = try Dijkstras.initSolverWithArena(arena, start, &grid, .{});

    try dj.findPaths();

    const og_cost = dj.verts.getPtr(end).?.d;

    const cheats = try getCheatCandidates(allocator, &grid);
    var successful = std.AutoArrayHashMap(usize, usize).init(allocator);
    for (cheats) |c| {
        // unblock cheat
        grid.atPtrV(c).* = '.';
        try dj.addVertex(c);

        // search
        dj.reset();
        try dj.findPaths();

        // check for improvement
        const new_cost = dj.verts.getPtr(end).?.d;
        if (new_cost < og_cost) {
            const imp = og_cost - new_cost;
            const res = try successful.getOrPutValue(imp, 0);
            res.value_ptr.* += 1;
        }

        // unwind
        grid.atPtrV(c).* = '#';
        _ = dj.removeVertex(c);
    }
    return successful;
}

test "example" {
    const inp = [_][]const u8{
        "###############",
        "#...#...#.....#",
        "#.#.#.#.#.###.#",
        "#S#...#.#.#...#",
        "#######.#.#.###",
        "#######.#.#...#",
        "#######.#.###.#",
        "###..E#...#...#",
        "###.#######.###",
        "#...###...#...#",
        "#.#####.#.###.#",
        "#.#...#.#.#...#",
        "#.#.#.#.#.#.###",
        "#...#...#...###",
        "###############",
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var successful = try parts(&arena, &inp);

    try std.testing.expectEqual(14, successful.get(2));
    try std.testing.expectEqual(14, successful.get(4));
    try std.testing.expectEqual(2, successful.get(6));
    try std.testing.expectEqual(4, successful.get(8));
    try std.testing.expectEqual(2, successful.get(10));
    try std.testing.expectEqual(3, successful.get(12));
    try std.testing.expectEqual(1, successful.get(20));
    try std.testing.expectEqual(1, successful.get(36));
    try std.testing.expectEqual(1, successful.get(38));
    try std.testing.expectEqual(1, successful.get(40));
    try std.testing.expectEqual(1, successful.get(64));
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const lines = try zutils.fs.readLinesArena(&arena, "~/sync/dev/aoc_inputs/2024/20.txt");

    const res = try parts(&arena, lines.items());
    var iter = res.iterator();

    var over_100: usize = 0;
    while (iter.next()) |ent| {
        if (ent.key_ptr.* >= 100) {
            over_100 += 1;
        }
    }

    std.debug.print("p1: {d}\n", .{over_100});
}
