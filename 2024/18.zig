const std = @import("std");
const zutils = @import("zutils");

const Grid = zutils.Grid(u8);
const V2u = zutils.V2(u8);

const DijkCtx = struct {
    grid: *const Grid,
};

const DijkSolver = zutils.graph.Dijkstras(V2u, DijkCtx);
const Edge = DijkSolver.Edge;

fn getNeighbors(
    allocator: std.mem.Allocator,
    dv: V2u,
    ctx: DijkCtx,
) ![]Edge {
    var edges = try std.ArrayList(Edge).initCapacity(allocator, 4);
    const grid = ctx.grid;
    var iter = dv.iterNeighborsInGridBounds(grid.ncols, grid.nrows);

    while (iter.next()) |n| {
        if (grid.atV(n.asType(usize)) == '#') {
            continue;
        }
        edges.appendAssumeCapacity(.{
            .v = n,
            .cost = 1,
        });
    }

    return edges.toOwnedSlice();
}

fn makeVerts(allocator: std.mem.Allocator, grid: *const Grid) ![]V2u {
    var verts = std.ArrayList(V2u).init(allocator);

    var iter = grid.iterator();
    while (iter.next()) |v| {
        if (grid.atV(v) != '#') {
            try verts.append(v.asType(u8));
        }
    }
    return verts.toOwnedSlice();
}

fn parseV2(ln: []const u8) !V2u {
    const c_idx = std.mem.indexOfScalar(u8, ln, ',').?;
    return .{
        .x = try std.fmt.parseUnsigned(u8, ln[0..c_idx], 10),
        .y = try std.fmt.parseUnsigned(u8, ln[c_idx + 1 ..], 10),
    };
}

fn readFallingBytes(grid: *Grid, lines: []const []const u8) !void {
    for (lines) |ln| {
        grid.atPtrV((try parseV2(ln)).asType(usize)).* = '#';
    }
}

fn onPath(dj: *const DijkSolver, end: V2u, bad: V2u) !bool {
    var iter = try dj.pathIterator(end, true);
    defer iter.deinit();
    while (try iter.next()) |v| {
        if (v.equal(bad)) {
            return true;
        }
    }
    return false;
}

fn onPathOld(allocator: std.mem.Allocator, dj: *const DijkSolver, end: V2u, bad: V2u) !bool {
    var queue = std.ArrayList(V2u).init(allocator);
    defer queue.deinit();
    var seen = std.AutoHashMap(V2u, void).init(allocator);
    defer seen.deinit();
    try queue.append(end);

    while (queue.popOrNull()) |v| {
        if (v.equal(bad)) {
            return true;
        }

        try seen.put(v, {});

        const dv = dj.verts.getPtr(v).?;
        for (dv.pred.items) |prev| {
            const res = try seen.getOrPut(prev);
            if (!res.found_existing) {
                try queue.append(prev);
            }
        }
    }
    return false;
}

const Ans = struct {
    p1: usize,
    p2: []const u8,
};

fn parts(
    child: std.mem.Allocator,
    grid_size: usize,
    lines: []const []const u8,
    run_n: usize,
) !Ans {
    var arena = std.heap.ArenaAllocator.init(child);
    defer arena.deinit();
    const allocator = arena.allocator();

    var grid = try Grid.init(allocator, grid_size, grid_size);

    // initialize grid and run first n bytes
    grid.fill('.');
    try readFallingBytes(&grid, lines[0..run_n]);

    // set up the solver
    const start = V2u{};
    const end = V2u{ .x = @intCast(grid.ncols - 1), .y = @intCast(grid.nrows - 1) };
    const initial_verts = try makeVerts(allocator, &grid);

    var dj = try DijkSolver.initWithArena(&arena, start, initial_verts, .{ .grid = &grid });

    // solve p1
    try dj.findPaths(getNeighbors);
    const p1 = dj.verts.getPtr(end).?.d;

    // solve p2
    var i = run_n;
    var p2: []const u8 = undefined;
    while (i < lines.len) : (i += 1) {
        // affect grid with next byte
        try readFallingBytes(&grid, lines[i .. i + 1]);

        const loc = try parseV2(lines[i]);
        // const op = try onPathOld(allocator, &dj, end, loc);
        const op = try onPath(&dj, end, loc);

        if (op) {
            // remove the vertex that just got murked
            std.debug.assert(dj.removeVertex(loc));
            dj.reset();

            // re-solve, finished when path can't be found
            try dj.findPaths(getNeighbors);
            const cost = dj.verts.getPtr(end).?.d;
            if (cost == std.math.maxInt(usize)) {
                p2 = lines[i];
                break;
            }
        }
    }

    return .{
        .p1 = p1,
        .p2 = p2,
    };
}

test "ex" {
    const inp = [_][]const u8{
        "5,4",
        "4,2",
        "4,5",
        "3,0",
        "2,1",
        "6,3",
        "2,4",
        "1,5",
        "0,6",
        "3,3",
        "2,6",
        "5,1",
        "1,2",
        "5,5",
        "2,5",
        "6,5",
        "1,4",
        "0,4",
        "6,4",
        "1,1",
        "6,1",
        "1,0",
        "0,5",
        "1,6",
        "2,0",
    };

    const ans = try parts(std.testing.allocator, 7, &inp, 12);

    try std.testing.expectEqual(22, ans.p1);
    try std.testing.expectEqualStrings("6,1", ans.p2);
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/18.txt");
    defer lines.deinit();

    const ans = try parts(std.heap.page_allocator, 71, lines.strings.items, 1024);

    std.debug.print("p1: {d}\n", .{ans.p1});
    std.debug.print("p2: {s}\n", .{ans.p2});
}
