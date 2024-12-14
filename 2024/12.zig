const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);

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

fn printRegion(lines: []const []const u8, region: *const Region) void {
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

fn printPoint(lines: []const []const u8, v: V2) void {
    for (lines, 0..) |ln, j| {
        for (ln, 0..) |c, i| {
            if (v.equal(.{ .x = @intCast(i), .y = @intCast(j) })) {
                zutils.printRed(ln[i .. i + 1]);
            } else {
                std.debug.print("{c}", .{c});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn parseRegions(allocator: std.mem.Allocator, lines: []const []const u8) !std.ArrayList(Region) {
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
    lines: []const []const u8,
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

fn inBounds(lines: []const []const u8, v: V2) bool {
    return v.inGridBounds(@intCast(lines[0].len), @intCast(lines.len));
}

fn getCrop(lines: []const []const u8, v: V2) ?u8 {
    if (inBounds(lines, v))
        return lines[@intCast(v.y)][@intCast(v.x)];
    return null;
}

fn colIndexOf(lines: []const []const u8, col: usize, scalar: u8) ?usize {
    var i: usize = 0;
    while (i < lines.len) : (i += 1) {
        if (lines[i][col] == scalar) {
            return i;
        }
    }
    return null;
}

fn lastColIndexOf(lines: []const []const u8, col: usize, scalar: u8) ?usize {
    var i: isize = @intCast(lines.len - 1);
    while (i >= 0) : (i -= 1) {
        if (lines[@intCast(i)][col] == scalar) {
            return @intCast(i);
        }
    }
    return null;
}

fn findRegionSides(allocator: std.mem.Allocator, region: *const Region, lines: []const []const u8) !usize {
    var to_process = try region.border.clone();
    defer to_process.deinit();

    var sides: usize = 0;
    var dir = V2{ .x = -1 };
    while (to_process.popOrNull()) |p| {
        const v = p.key;
        for (v.neighbors()) |n| {
            if (getCrop(lines, n) != region.crop) {}
        }

        printPoint(lines, p);
        sides += 1;
    }

    return sides;

    // for (region.border.keys()) |v| {
    // for each neighbor which is not a region member check the caches
    // use row cache when normal is vertical, col cache if horizontal

    // for (v.neighbors()) |n| {
    //     if (!n.inGridBounds(lines.len, lines[0].len) or
    //         lines[@intCast(n.y)][@intCast(n.x)] == region.crop)
    //     {
    //         continue;
    //     }
    // }
    // }

    //
    // var row_tot: usize = 0;
    // for (rows.keys()) |r| {
    //     var in: bool = false;
    //     for (lines[r]) |c| {
    //         if ((c == region.crop) != in) {
    //             row_tot += 1;
    //             in = !in;
    //         }
    //     }
    //     if (in) {
    //         row_tot += 1;
    //     }
    //     std.debug.print("after: {d}\n", .{row_tot});
    // }
    //
    // var col_tot: usize = 0;
    // for (cols.keys()) |j| {
    //     var in: bool = false;
    //     var i: usize = 0;
    //     while (i < lines.len) : (i += 1) {
    //         const c = lines[i][j];
    //         if ((c == region.crop) != in) {
    //             col_tot += 1;
    //             in = !in;
    //         }
    //     }
    //     if (in) {
    //         col_tot += 1;
    //     }
    // }
    // std.debug.print("hemmmm: {d}\n", .{col_tot + row_tot});
    // printPlot(lines, region);
    // return col_tot + row_tot;
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
    lines: []const []const u8,
    regions: *const std.ArrayList(Region),
) !usize {
    var tot: usize = 0;
    for (regions.items) |*r| {
        tot += (try findRegionSides(allocator, r, lines)) * r.area;
        // TODO
        break;
    }
    return tot;
}

fn problem(allocator: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    const regions = try parseRegions(allocator, lines);
    defer {
        for (regions.items) |*r| {
            r.deinit();
        }
        regions.deinit();
    }
    for (regions.items) |r| {
        printRegion(lines, &r);
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
    const lines = try zutils.readLines(std.heap.page_allocator, "~/Downloads/12.txt");
    defer lines.deinit();

    const ans = try problem(std.heap.page_allocator, lines.strings.items);
    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
