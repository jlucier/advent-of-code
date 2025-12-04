const std = @import("std");
const zutils = @import("zutils");

fn solveLine(ln: []const u8, nbat: u8) !usize {
    var maxes: [12]u8 = undefined;
    for (0..nbat) |i| {
        maxes[i] = 0;
    }

    var lastMax: usize = 0;
    for (0..nbat) |i| {
        const start = if (i > 0) lastMax + 1 else 0;
        const end = ln.len - (nbat - i);
        lastMax = std.sort.argMax(u8, ln[start .. end + 1], {}, std.sort.asc(u8)).? + start;
        maxes[i] = ln[lastMax];
    }
    return try std.fmt.parseInt(usize, maxes[0..nbat], 10);
}

fn parts(lines: []const u8) ![2]usize {
    var p1: usize = 0;
    var p2: usize = 0;
    var iter = std.mem.splitScalar(u8, lines, '\n');
    while (iter.next()) |ln| {
        if (ln.len == 0) continue;
        p1 += @intCast(try solveLine(ln, 2));
        p2 += @intCast(try solveLine(ln, 12));
    }
    return .{ p1, p2 };
}

test "example" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const res = try parts(input);
    try std.testing.expectEqual(357, res[0]);
    try std.testing.expectEqual(3121910778619, res[1]);
}

pub fn main() !void {
    const lines = try zutils.fs.readFile(std.heap.page_allocator, //
        "~/sync/dev/aoc_inputs/2025/3.txt");
    const res = try parts(lines);
    std.debug.print("p1: {}\np2: {}\n", .{ res[0], res[1] });
}
