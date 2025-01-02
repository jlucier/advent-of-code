const std = @import("std");
const zutils = @import("zutils");

const V2u = zutils.V2(u8);

const Dijkstras = zutils.graph.GridDijkstras(V2u, u8, '#', struct {
    pub fn cost(_: @This(), _: V2u, _: V2u) usize {
        return 1;
    }
});

const DijkSolver = Dijkstras.DijkSolver;
const Grid = Dijkstras.Grid;

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

const Ans = struct {
    p1: usize,
    p2: []const u8,
};

fn parts(
    arena: *std.heap.ArenaAllocator,
    grid_size: usize,
    lines: []const []const u8,
    run_n: usize,
) !Ans {
    const allocator = arena.allocator();

    var grid = try Grid.init(allocator, grid_size, grid_size);

    // initialize grid and run first n bytes
    grid.fill('.');
    try readFallingBytes(&grid, lines[0..run_n]);

    // set up the solver
    const start = V2u{};
    const end = V2u{ .x = @intCast(grid.ncols - 1), .y = @intCast(grid.nrows - 1) };

    var dj = try Dijkstras.initSolverWithArena(arena, start, &grid, .{});

    // solve p1
    try dj.findPaths();
    const p1 = dj.verts.getPtr(end).?.d;

    // solve p2
    var i = run_n;
    var p2: []const u8 = undefined;
    while (i < lines.len) : (i += 1) {
        // affect grid with next byte
        try readFallingBytes(&grid, lines[i .. i + 1]);

        const loc = try parseV2(lines[i]);
        const op = try onPath(&dj, end, loc);

        if (op) {
            // remove the vertex that just got murked
            std.debug.assert(dj.removeVertex(loc));
            dj.reset();

            // re-solve, finished when path can't be found
            try dj.findPaths();
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

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ans = try parts(&arena, 7, &inp, 12);

    try std.testing.expectEqual(22, ans.p1);
    try std.testing.expectEqualStrings("6,1", ans.p2);
}

pub fn main() !void {
    // Why go through all the effort to make the dijstras implementation able to create its own
    // arena just to avoid using that and plubming in our own? Turns out that loading all the
    // input data and initial stuff into the same arena seems to "prime" it with enough space
    // so that none of the further operations cause it to grow. Fun.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const lines = try zutils.fs.readLinesArena(&arena, "~/sync/dev/aoc_inputs/2024/18.txt");

    const ans = try parts(&arena, 71, lines.items(), 1024);

    std.debug.print("p1: {d}\n", .{ans.p1});
    std.debug.print("p2: {s}\n", .{ans.p2});
}
