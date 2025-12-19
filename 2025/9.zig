const std = @import("std");
const zutils = @import("zutils");

const V2i = zutils.vec.V2i;
const V2u = zutils.vec.V2u;
const Grid = zutils.grid.Grid(u8);
const Range = zutils.Range(isize);

fn parse(gpa: std.mem.Allocator, input: []const u8) ![]V2i {
    var vecs = std.array_list.Managed(V2i).init(gpa);
    var iter = std.mem.splitScalar(u8, input, '\n');

    while (iter.next()) |ln| {
        if (ln.len == 0) continue;
        const comma = std.mem.indexOfScalar(u8, ln, ',').?;
        try vecs.append(.{
            .x = try std.fmt.parseInt(isize, ln[0..comma], 10),
            .y = try std.fmt.parseInt(isize, ln[comma + 1 ..], 10),
        });
    }
    return vecs.toOwnedSlice();
}

// fn fillGreen(gpa: std.mem.Allocator, vecs: []V2i) !Grid {
//     var extents = V2u{};
//     for (vecs) |v| {
//         extents.x = @max(extents.x, v.x);
//         extents.y = @max(extents.y, v.y);
//     }
//
//     // add 2 instead of 1 so that there is border around the shape to ensure we can
//     // flood fill everywhere around it
//     var grid = try Grid.init(gpa, extents.y + 2, extents.x + 2);
//     std.debug.print("Finished init: {any}\n", .{extents});
//     grid.fill('.');
//     std.debug.print("Finished initial fill\n", .{});
//
//     // connect edges
//     for (vecs, 0..) |v, i| {
//         const other = vecs[if (i > 0) i - 1 else vecs.len - 1];
//         // add existing
//         grid.atPtrV(v.asType(usize)).* = '#';
//         grid.atPtrV(other.asType(usize)).* = '#';
//
//         std.debug.assert(other.x == v.x or other.y == v.y);
//
//         const moveOnX = v.y == other.y;
//         const st = if (moveOnX) @min(v.x, other.x) + 1 else @min(v.y, other.y) + 1;
//         const end = if (moveOnX) @max(v.x, other.x) else @max(v.y, other.y);
//         var c = st;
//         while (c != end) : (c += 1) {
//             const row: usize = @intCast(if (moveOnX) v.y else c);
//             const col: usize = @intCast(if (moveOnX) c else v.x);
//             grid.atPtr(row, col).* = 'X';
//         }
//     }
//     std.debug.print("Finished edges\n", .{});
//
//     // fill cells that do not lie on edges or within the shape with 'o'
//     var cells = try std.array_list.Managed(V2u).initCapacity(gpa, 1);
//     defer cells.deinit();
//     cells.appendAssumeCapacity(.{ .x = 0, .y = 0 });
//
//     while (cells.pop()) |c| {
//         var iter = grid.neighbors(c, .cardinal);
//         while (iter.next()) |n| {
//             const v = grid.atPtrV(n);
//             if (v.* == '.') {
//                 v.* = 'o';
//                 try cells.append(n);
//             }
//         }
//     }
//     std.debug.print("Finished fill\n", .{});
//
//     return grid;
// }

fn p1(vecs: []V2i) usize {
    var area: usize = 0;
    for (vecs, 0..) |v1, i| {
        for (vecs[i + 1 ..]) |v2| {
            const d = v1.sub(v2);
            const a = (@abs(d.x) + 1) * (@abs(d.y) + 1);
            area = @max(a, area);
        }
    }
    return area;
}

fn pointInPoly(poly: []V2i, point: V2i) bool {
    for (poly, 0..) |v, i| {
        const other = poly[if (i > 0) i - 1 else poly.len - 1];
        const xr = Range{ .begin = @min(v.x, other.x), .end = @max(v.x, other.x) };
        const yr = Range{ .begin = @min(v.y, other.y), .end = @max(v.y, other.y) };

        // on edge
        if (point.x == v.x and v.x == other.x and yr.containsScalar(point.y)) {
            return true;
        } else if (point.y == v.y and v.y == other.y and xr.containsScalar(point.x)) {
            return true;
        }

        if (yr.begin <= point.y and point.y < yr.end) {
            const x_int = x1 + (py - y1) * (x2 - x1) / (y2 - y1);
        }

        // y needs to be between the edge endpoints
        // p.x >= edge x
    }
}

fn p2(vecs: []V2i, grid: *const Grid) usize {
    var area: usize = 0;
    for (vecs, 0..) |v1, i| {
        inner: for (vecs[i + 1 ..]) |v2| {
            const sx: usize = @intCast(@min(v1.x, v2.x));
            const ex: usize = @intCast(@max(v1.x, v2.x) + 1);
            const sy: usize = @intCast(@min(v1.y, v2.y));
            const ey: usize = @intCast(@max(v1.y, v2.y) + 1);

            for (sy..ey) |r| {
                for (sx..ex) |c| {
                    if (grid.at(r, c) == 'o') continue :inner;
                }
            }
            const d = v1.sub(v2);
            const ar = (@abs(d.x) + 1) * (@abs(d.y) + 1);
            area = @max(ar, area);
        }
    }
    return area;
}

fn solve(gpa: std.mem.Allocator, input: []const u8) ![2]usize {
    const vecs = try parse(gpa, input);
    defer gpa.free(vecs);

    const v1 = p1(vecs);
    const v2 = p2(vecs);

    return .{ v1, v2 };
}

test "example" {
    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;

    const res = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(50, res[0]);
    try std.testing.expectEqual(24, res[1]);
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, //
        "~/sync/dev/aoc_inputs/2025/9.txt");
    const res = try solve(std.heap.page_allocator, input);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
