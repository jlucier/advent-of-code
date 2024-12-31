const std = @import("std");
const zutils = @import("zutils");

const Grid = zutils.Grid(u8);

const DijkCtx = struct {
    grid: *const Grid,
};

const DijkSolver = zutils.graph.Dijkstras(zutils.V2u, DijkCtx);
const Edge = DijkSolver.Edge;

fn getNeighbors(
    allocator: std.mem.Allocator,
    dv: zutils.V2u,
    ctx: DijkCtx,
) ![]Edge {
    var edges = try std.ArrayList(Edge).initCapacity(allocator, 4);
    const grid = ctx.grid;
    var iter = dv.iterNeighborsInGridBounds(grid.ncols, grid.nrows);

    while (iter.next()) |n| {
        if (grid.atV(n) == '#') {
            continue;
        }
        edges.appendAssumeCapacity(.{
            .v = n,
            .cost = 1,
        });
    }

    return edges.toOwnedSlice();
}

fn makeVerts(allocator: std.mem.Allocator, grid: *const Grid) ![]zutils.V2u {
    var verts = std.ArrayList(zutils.V2u).init(allocator);

    var iter = grid.iterator();
    while (iter.next()) |v| {
        if (grid.atV(v) != '#') {
            try verts.append(v);
        }
    }
    return verts.toOwnedSlice();
}

fn parseV2(ln: []const u8) !zutils.V2u {
    const c_idx = std.mem.indexOfScalar(u8, ln, ',').?;
    return .{
        .x = try std.fmt.parseUnsigned(usize, ln[0..c_idx], 10),
        .y = try std.fmt.parseUnsigned(usize, ln[c_idx + 1 ..], 10),
    };
}

fn readFallingBytes(grid: *Grid, lines: []const []const u8) !void {
    for (lines) |ln| {
        grid.atPtrV(try parseV2(ln)).* = '#';
    }
}

const Ans = struct {
    p1: usize,
    p2: []const u8,
};

fn parts(
    allocator: std.mem.Allocator,
    grid_size: usize,
    lines: []const []const u8,
    run_n: usize,
) !Ans {
    var grid = try Grid.init(allocator, grid_size, grid_size);
    defer grid.deinit();

    // initialize grid and run first n bytes
    grid.fill('.');
    try readFallingBytes(&grid, lines[0..run_n]);

    // set up the solver
    const start = zutils.V2u{};
    const end = zutils.V2u{ .x = grid.ncols - 1, .y = grid.nrows - 1 };
    const initial_verts = try makeVerts(allocator, &grid);
    defer allocator.free(initial_verts);
    var dj = try DijkSolver.init(allocator, start, initial_verts, .{ .grid = &grid });
    defer dj.deinit();

    // solve p1
    try dj.findPaths(getNeighbors);
    const p1 = dj.verts.getPtr(end).?.d;

    // solve p2
    var i = run_n;
    var p2: []const u8 = undefined;
    while (i < lines.len) : (i += 1) {
        // affect grid with next byte
        try readFallingBytes(&grid, lines[i .. i + 1]);

        // remove the vertex that just got murked
        std.debug.assert(dj.removeVertex(try parseV2(lines[i])));
        dj.reset();

        // re-solve, finished when path can't be found
        try dj.findPaths(getNeighbors);
        const cost = dj.verts.getPtr(end).?.d;
        if (cost == std.math.maxInt(usize)) {
            p2 = lines[i];
            break;
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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    const lines = try zutils.readLines(allocator, "~/sync/dev/aoc_inputs/2024/18.txt");

    const ans = try parts(allocator, 71, lines.strings.items, 1024);

    std.debug.print("p1: {d}\n", .{ans.p1});
    std.debug.print("p2: {s}\n", .{ans.p2});
}
