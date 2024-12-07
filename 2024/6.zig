const std = @import("std");
const zutils = @import("zutils");

const Grid = zutils.Grid(u8);
const V2 = zutils.V2(isize);

const Guard = struct {
    const UniquePos = std.AutoArrayHashMap(V2, void);
    pos: V2,
    dir: V2,
    uniq: UniquePos,

    pub fn init(allocator: std.mem.Allocator) Guard {
        return .{
            .pos = .{},
            .dir = .{ .x = 0, .y = 1 },
            .uniq = UniquePos.init(allocator),
        };
    }

    pub fn deinit(self: *Guard) void {
        self.uniq.deinit();
    }

    pub fn moveOnce(self: *Guard, grid: *const Grid) !?V2 {
        while (true) {
            const next = self.pos.add(self.dir);
            if (!grid.inBounds(next.y, next.x)) {
                return null;
            } else if (grid.at(@intCast(next.y), @intCast(next.x)) == 0) {
                // open, move
                self.pos = next;
                try self.uniq.put(next, {});
                return self.pos;
            } else {
                // turn and retry
                self.dir = self.dir.rotateClockwise();
            }
        }
    }

    pub fn moveUntilLeave(self: *Guard, grid: *const Grid) !void {
        while (try self.moveOnce(grid) != null) {}
    }

    pub fn moveUntilLoop(self: *Guard, allocator: std.mem.Allocator, grid: *const Grid) !bool {
        var cache = std.AutoArrayHashMap([2]V2, void).init(allocator);
        defer cache.deinit();
        while (try self.moveOnce(grid)) |next| {
            const res = try cache.getOrPut(.{ next, self.dir });
            if (res.found_existing) {
                // loop detected
                return true;
            }
        }
        // ran to completion without loops
        return false;
    }

    pub fn printState(self: *const Guard, grid: *const Grid) void {
        var i: usize = 0;
        while (i < grid.nrows * grid.ncols) : (i += 1) {
            const v = grid.data[i];
            const c: u8 = if (v == 0) '.' else '#';
            var visited = false;
            if (self.uniq.getKey(V2{
                .x = @intCast(i % grid.ncols),
                .y = @intCast(i / grid.ncols),
            }) != null) {
                visited = true;
            }
            const col = if (visited) zutils.ANSI_RED else "";
            const rs = if (visited) zutils.ANSI_RESET else "";
            std.debug.print("{s}{c}{s}", .{ col, c, rs });
            if ((i + 1) % grid.ncols == 0) {
                std.debug.print("\n", .{});
            }
        }
    }
};

const ParseReturnVal = struct {
    guard: Guard,
    grid: Grid,
};

fn parseGridCell(v: u8) u8 {
    return switch (v) {
        '.' => 0,
        '#' => 1,
        '^' => 0,
        else => unreachable,
    };
}

fn parse(allocator: std.mem.Allocator, lines: []const []const u8) !ParseReturnVal {
    var ret = ParseReturnVal{
        .grid = try Grid.init2DSliceWithParser(u8, allocator, lines, parseGridCell),
        .guard = Guard.init(allocator),
    };
    try ret.grid.transposeY();

    outer: for (lines, 0..) |ln, y| {
        for (ln, 0..) |c, x| {
            if (c == '^') {
                // need to transposeY for start y
                ret.guard.pos = V2{ .x = @intCast(x), .y = @intCast(ret.grid.nrows - y) };
                try ret.guard.uniq.put(ret.guard.pos, {});
                break :outer;
            }
        }
    }
    std.debug.assert(ret.guard.uniq.count() == 1);
    return ret;
}

fn solve(allocator: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    const state = try parse(allocator, lines);
    var grid = state.grid;
    var guard = state.guard;
    defer guard.deinit();
    defer grid.deinit();

    const start_pos = guard.pos;

    // solve p1
    try guard.moveUntilLeave(&grid);
    const p1 = guard.uniq.count();
    // guard.printState(&grid);

    // p2
    var loops: usize = 0;
    for (guard.uniq.keys()) |p| {
        if (p.equal(start_pos)) {
            continue;
        }
        // try place obstacle at p, resolve
        var tmp_guard = Guard.init(allocator);
        defer tmp_guard.deinit();

        tmp_guard.pos = start_pos;
        const loc = grid.atPtr(@intCast(p.y), @intCast(p.x));
        // set block
        loc.* = 1;
        // try running
        if (try tmp_guard.moveUntilLoop(allocator, &grid)) {
            loops += 1;
        }
        // set back
        loc.* = 0;
    }

    return .{ p1, loops };
}

test "p1" {
    const lines = [_][]const u8{
        "....#.....",
        ".........#",
        "..........",
        "..#.......",
        ".......#..",
        "..........",
        ".#..^.....",
        "........#.",
        "#.........",
        "......#...",
    };

    const ans = try solve(std.testing.allocator, &lines);
    try std.testing.expectEqual(41, ans[0]);
    try std.testing.expectEqual(6, ans[1]);
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/6.txt");
    defer lines.deinit();

    const ans = try solve(std.heap.page_allocator, lines.strings.items);
    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
