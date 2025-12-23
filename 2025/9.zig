const std = @import("std");
const zutils = @import("zutils");

const V2i = zutils.vec.V2i;
const V2u = zutils.vec.V2u;
const Range = zutils.Range(isize);

fn parse(gpa: std.mem.Allocator, inp: []const u8) ![]V2i {
    var vecs = std.array_list.Managed(V2i).init(gpa);
    var iter = std.mem.splitScalar(u8, inp, '\n');

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

fn solveP1(vecs: []V2i) usize {
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

fn solveP2(vecs: []V2i) usize {
    var area: usize = 0;
    for (vecs, 0..) |v1, i| {
        for (vecs[i + 1 ..]) |v2| {
            if (!zutils.vec.quadInPoly(isize, vecs, v1, v2)) continue;

            const d = v1.sub(v2);
            const ar = (@abs(d.x) + 1) * (@abs(d.y) + 1);
            area = @max(ar, area);
        }
    }

    return area;
}

fn solve(gpa: std.mem.Allocator, inp: []const u8) ![2]usize {
    const vecs = try parse(gpa, inp);
    defer gpa.free(vecs);

    const v1 = solveP1(vecs);
    const v2 = solveP2(vecs);

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
    const inp = try zutils.fs.readFile(std.heap.page_allocator, //
        "~/sync/dev/aoc_inputs/2025/9.txt");
    defer std.heap.page_allocator.free(inp);

    const res = try solve(std.heap.page_allocator, inp);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
