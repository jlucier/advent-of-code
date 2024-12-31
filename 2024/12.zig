const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);
const Lines = []const []const u8;

const Region = struct {
    crop: u8,
    area: usize = 0,
    perimeter: usize = 0,
    border: std.AutoArrayHashMap(V2, void),

    fn deinit(self: *Region) void {
        self.border.deinit();
    }

    fn p1Price(self: *const Region) usize {
        return self.area * self.perimeter;
    }

    fn addBorder(self: *Region, v: V2) !void {
        _ = try self.border.getOrPut(v);
        self.perimeter += 1;
    }
};

fn printRegion(lines: Lines, region: *const Region) void {
    for (lines, 0..) |ln, j| {
        for (ln, 0..) |c, i| {
            if (region.border.get(.{ .x = @intCast(i), .y = @intCast(j) }) != null) {
                zutils.printRed(ln[i .. i + 1]);
            } else {
                std.debug.print("{c}", .{c});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn parseRegions(allocator: std.mem.Allocator, lines: Lines) !std.ArrayList(Region) {
    var regions = std.ArrayList(Region).init(allocator);
    var seen = std.AutoHashMap(V2, void).init(allocator);
    defer seen.deinit();
    try seen.ensureTotalCapacity(@intCast(lines.len * lines[0].len));

    for (lines, 0..) |ln, i| {
        for (ln, 0..) |c, j| {
            const pos = V2{ .x = @intCast(j), .y = @intCast(i) };
            const res = seen.getOrPutAssumeCapacity(pos);
            if (!res.found_existing) {
                try regions.append(.{
                    .crop = c,
                    .border = std.AutoArrayHashMap(V2, void).init(allocator),
                });
                try expandRegion(allocator, &seen, &regions.items[regions.items.len - 1], pos, lines);
            }
        }
    }
    return regions;
}

fn expandRegion(
    allocator: std.mem.Allocator,
    seen: *std.AutoHashMap(V2, void),
    region: *Region,
    start: V2,
    lines: Lines,
) !void {
    var queue = try std.ArrayList(V2).initCapacity(allocator, 1);
    defer queue.deinit();
    queue.appendAssumeCapacity(start);

    while (queue.popOrNull()) |pos| {
        if (lines[@intCast(pos.y)][@intCast(pos.x)] == region.crop) {
            region.area += 1;
        }

        for (pos.neighbors()) |n| {
            if (!inBounds(lines, n)) {
                try region.addBorder(pos);
                continue;
            }

            if (lines[@intCast(n.y)][@intCast(n.x)] == region.crop) {
                if (!seen.getOrPutAssumeCapacity(n).found_existing) {
                    try queue.append(n);
                }
            } else {
                try region.addBorder(pos);
            }
        }
    }
}

fn inBounds(lines: Lines, v: V2) bool {
    return v.inGridBounds(@intCast(lines[0].len), @intCast(lines.len));
}

fn getCrop(lines: Lines, v: V2) ?u8 {
    if (inBounds(lines, v))
        return lines[@intCast(v.y)][@intCast(v.x)];
    return null;
}

/// Find a neighbors of the border of the region
fn getOutline(
    allocator: std.mem.Allocator,
    region: *const Region,
    lines: Lines,
) !std.AutoArrayHashMap(V2, void) {
    var ret = std.AutoArrayHashMap(V2, void).init(allocator);
    for (region.border.keys()) |v| {
        for (v.neighbors()) |n| {
            // includes nulls
            if (getCrop(lines, n) != region.crop) {
                try ret.put(n, {});
            }
        }
    }
    return ret;
}

fn borderPathExists(lines: Lines, region: *const Region, start: V2, end: V2) bool {
    var v = start;
    const dir = end.sub(start).unit(f32).asType(isize);
    // std.debug.print("    hmm: {} {} {}\n", .{ start, dir, end });
    while (!v.equal(end)) {
        if (getCrop(lines, v) != region.crop or region.border.get(v) == null) {
            return false;
        }
        v.addMut(dir);
    }
    return true;
}

fn findDiffNeighbor(lines: Lines, v: V2, crop: u8) ?V2 {
    for (v.neighbors()) |n| {
        if (getCrop(lines, n) != crop) {
            return n;
        }
    }
    return null;
}

fn findRegionSides(allocator: std.mem.Allocator, region: *const Region, lines: Lines) !usize {
    var sides: usize = 0;

    const start_wall = region.border.keys()[0];
    const start = findDiffNeighbor(lines, start_wall, region.crop).?;
    std.debug.print("start_wall: {} start: {}\n", .{ start_wall, start });

    var curr = start;
    var wall_dir = start_wall.sub(start);
    var move_dir = wall_dir.rotateCounterClockwise();
    std.debug.print("move: {} wall: {}\n", .{ move_dir, wall_dir });

    const grid = try zutils.Grid(u8).init2DSlice(allocator, lines);
    defer grid.deinit();
    var hl = [2]zutils.V2(usize){ start.asType(usize), curr.asType(usize) };

    var internal = false;
    while (true) {
        std.debug.print("hmm: {}\n", .{curr});
        if (curr.x >= 0 and curr.y >= 0) {
            hl[1] = curr.asType(usize);
            grid.printHl(&hl);
        } else {
            const tmp = [_]zutils.V2(usize){start.asType(usize)};
            grid.printHl(&tmp);
        }
        var next = curr.add(move_dir);
        if (next.equal(start)) {
            return sides;
        }

        var count = true;
        if (getCrop(lines, next) == region.crop) {
            std.debug.print("internal\n", .{});
            // internal
            sides += 1;
            wall_dir = wall_dir.rotateCounterClockwise();
            move_dir = move_dir.rotateCounterClockwise();
            internal = true;
            count = false;
        } else if (getCrop(lines, next.add(wall_dir)) != region.crop) {
            // ran past
            if (internal) {
                // already hit internal, diag
                next.addMut(wall_dir);
                if (next.equal(start)) {
                    return sides;
                }
            } else {
                std.debug.print("past\n", .{});
                sides += 1;
                wall_dir = wall_dir.rotateClockwise();
                move_dir = move_dir.rotateClockwise();
                count = false;
            }
        }

        if (count) {
            curr = next;
            internal = false;
        }
    }

    return sides;

    // OLD

    // 1. pick cell
    // 2. for each dir that is edge
    //   a. for other borders in the same col if looking horiz, row if vert
    //   b. if a path exists between original and that point, same side
    //   c. cache this direction for everything same side

    // cache indices corresponde to each neighbor sequentially
    // var cache = std.AutoHashMap(V2, [4]bool).init(allocator);
    // defer cache.deinit();
    //
    // const grid = try zutils.Grid(u8).init2DSlice(allocator, lines);
    // defer grid.deinit();
    // const list = try allocator.alloc(zutils.V2(usize), region.border.count());
    // defer allocator.free(list);
    // for (region.border.keys(), 0..) |v, i| {
    //     list[i] = v.asType(usize);
    // }
    //
    // grid.printHl(list);
    //
    // for (region.border.keys()) |start| {
    //     std.debug.print("start: {}\n", .{start});
    //     for (start.neighbors(), 0..) |n, dir_idx| {
    //         if (getCrop(lines, n) == region.crop) {
    //             // looking in
    //             continue;
    //         }
    //         // this is a direction out of the region
    //         const start_cache = try cache.getOrPutValue(start, .{ false, false, false, false });
    //         if (start_cache.value_ptr[dir_idx]) {
    //             std.debug.print("  cached {}\n", .{n.sub(start)});
    //             continue;
    //         }
    //
    //         const dir = n.sub(start);
    //         std.debug.print("  dir: {}\n", .{dir});
    //
    //         start_cache.value_ptr[dir_idx] = true;
    //         sides += 1;
    //
    //         for (region.border.keys()) |other| {
    //             if (other.equal(start)) {
    //                 continue;
    //             }
    //
    //             const check = if (dir.x != 0) other.x == start.x else other.y == start.y;
    //             if (check and borderPathExists(lines, region, start, other)) {
    //                 std.debug.print("  same side as: {}\n", .{other});
    //                 const o_cache = try cache.getOrPutValue(other, .{ false, false, false, false });
    //                 o_cache.value_ptr[dir_idx] = true;
    //             }
    //         }
    //     }
    // }
    //
    // return sides;
}

fn p1Total(regions: *const std.ArrayList(Region)) usize {
    var tot: usize = 0;
    for (regions.items) |r| {
        tot += r.p1Price();
    }
    return tot;
}

fn p2Total(
    allocator: std.mem.Allocator,
    lines: Lines,
    regions: *const std.ArrayList(Region),
) !usize {
    var tot: usize = 0;
    for (regions.items[2..]) |*r| {
        const sides = try findRegionSides(allocator, r, lines);
        std.debug.print("{c}: {d}\n", .{ r.crop, sides });
        tot += sides * r.area;
        break;
    }
    return tot;
}

fn problem(allocator: std.mem.Allocator, lines: Lines) ![2]usize {
    const regions = try parseRegions(allocator, lines);
    defer {
        for (regions.items) |*r| {
            r.deinit();
        }
        regions.deinit();
    }

    return .{
        p1Total(&regions),
        try p2Total(allocator, lines, &regions),
    };
}

test "example" {
    const lines = [_][]const u8{
        "RRRRIICCFF",
        "RRRRIICCCF",
        "VVRRRCCFFF",
        "VVRCCCJFFF",
        "VVVVCJJCFE",
        "VVIVCCJJEE",
        "VVIIICJJEE",
        "MIIIIIJJEE",
        "MIIISIJEEE",
        "MMMISSJEEE",
    };

    const ans = try problem(std.testing.allocator, &lines);
    try std.testing.expectEqual(1930, ans[0]);
    try std.testing.expectEqual(1206, ans[1]);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/12.txt");
    defer lines.deinit();

    const ans = try problem(std.heap.page_allocator, lines.items());
    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
