const std = @import("std");
const zutils = @import("zutils");

const Grid = zutils.Grid(u8);

/// Returns parsed trees, caller manages memork
fn parseInts(lines: []const []const u8, grid: *Grid) !void {
    for (lines, 0..) |line, i| {
        for (line, 0..) |_, j| {
            grid.atPtr(i, j).* = try std.fmt.parseInt(u8, line[j .. j + 1], 10);
        }
    }
}

/// Returns grid owned by caller
fn makeGrid(allocator: std.mem.Allocator, lines: []const []const u8) !Grid {
    var grid = try Grid.init(allocator, lines.len, lines[0].len);
    try parseInts(lines, &grid);
    return grid;
}

/// Counts visible trees across rows in direction, where direction is -1 or 1
fn countDirection(vis: *std.bit_set.DynamicBitSet, grid: *const Grid, dir: isize) !void {
    // check rows
    var i: usize = 0;
    while (i < grid.nrows) : (i += 1) {
        var j = if (dir > 0) 0 else grid.ncols - 1;
        const end = if (dir > 0) grid.ncols else 0;
        var rowMax: ?u8 = null;

        while (j != end) {
            const t = grid.at(i, j);
            if (rowMax == null or t > rowMax.?) {
                vis.set(i * grid.ncols + j);
                rowMax = t;
            }

            if (dir < 0) {
                j -= 1;
            } else {
                j += 1;
            }
        }
    }

    i = 0;
    while (i < grid.ncols) : (i += 1) {
        var j = if (dir > 0) 0 else grid.nrows - 1;
        const end = if (dir > 0) grid.nrows else 0;
        var colMax: ?u8 = null;

        while (j != end) {
            const t = grid.at(j, i);
            if (colMax == null or t > colMax.?) {
                vis.set(j * grid.ncols + i);
                colMax = t;
            }

            if (dir < 0) {
                j -= 1;
            } else {
                j += 1;
            }
        }
    }
}

fn visibleTrees(allocator: std.mem.Allocator, grid: *const Grid) !usize {
    var vis = try std.bit_set.DynamicBitSet.initEmpty(allocator, grid.nrows * grid.ncols);
    defer vis.deinit();

    try countDirection(&vis, grid, 1);
    try countDirection(&vis, grid, -1);
    return vis.count();
}

fn scenicScore(grid: *const Grid, row: usize, col: usize) usize {
    const base = grid.at(row, col);
    // make these isize since we'll be subtracting from them
    var r: isize = @intCast(row);
    var c: isize = @intCast(col);

    // left
    c -= 1;
    var left: usize = 0;
    while (c >= 0) : (c -= 1) {
        left += 1;
        if (grid.at(row, @intCast(c)) >= base) {
            break;
        }
    }

    // right
    c = @intCast(col);
    c += 1;
    var right: usize = 0;
    while (c < grid.ncols) : (c += 1) {
        right += 1;
        if (grid.at(row, @intCast(c)) >= base) {
            break;
        }
    }

    // up
    var up: usize = 0;
    r -= 1;
    while (r >= 0) : (r -= 1) {
        up += 1;
        if (grid.at(@intCast(r), col) >= base) {
            break;
        }
    }

    // down
    r = @intCast(row);
    r += 1;
    var down: usize = 0;
    while (r < grid.nrows) : (r += 1) {
        down += 1;
        if (grid.at(@intCast(r), col) >= base) {
            break;
        }
    }

    return left * right * up * down;
}

/// Find the best spot on the grid, having the best scenicScore
fn findBestSpot(grid: *const Grid) usize {
    var best: usize = 0;
    var i: usize = 0;
    while (i < grid.nrows) : (i += 1) {
        var j: usize = 0;
        while (j < grid.ncols) : (j += 1) {
            best = zutils.max(usize, best, scenicScore(grid, i, j));
        }
    }

    return best;
}

const TEST_LINES = [_][]const u8{
    "30373",
    "25512",
    "65332",
    "33549",
    "35390",
};

test "p1" {
    var grid = try makeGrid(std.testing.allocator, &TEST_LINES);
    defer grid.deinit();

    try std.testing.expectEqual(21, try visibleTrees(std.testing.allocator, &grid));
}

test "p2" {
    var grid = try makeGrid(std.testing.allocator, &TEST_LINES);
    defer grid.deinit();

    try std.testing.expectEqual(0, scenicScore(&grid, 0, 2));
    try std.testing.expectEqual(4, scenicScore(&grid, 1, 2));
    try std.testing.expectEqual(8, scenicScore(&grid, 3, 2));

    try std.testing.expectEqual(8, findBestSpot(&grid));
}

pub fn main() void {
    const ll = zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/8.txt") catch {
        std.debug.print("Could not read file\n", .{});
        return;
    };

    var grid = makeGrid(std.heap.page_allocator, ll.strings.items) catch {
        std.debug.print("Could not make grid\n", .{});
        return;
    };
    defer grid.deinit();

    const p1 = visibleTrees(std.heap.page_allocator, &grid) catch {
        std.debug.print("Could not find vis\n", .{});
        return;
    };
    const p2 = findBestSpot(&grid);

    std.debug.print("p1: {d}\n", .{p1});
    std.debug.print("p2: {d}\n", .{p2});
}
