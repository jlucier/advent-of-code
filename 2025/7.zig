const std = @import("std");
const zutils = @import("zutils");

const Beam = struct {
    line: usize = 0,
    count: usize = 0,
};

fn solve(gpa: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    std.debug.assert(lines[0][lines[0].len / 2] == 'S');
    var beams = try gpa.alloc(Beam, lines[0].len);
    defer gpa.free(beams);

    for (beams) |*b| {
        b.line = 0;
        b.count = 0;
    }
    const s = lines[0].len / 2;
    beams[s].line = 1;
    beams[s].count = 1;

    var splits: usize = 0;
    for (lines[1..], 1..) |ln, lni| {
        for (beams, 0..) |*b, i| {
            if (ln[i] != '^') {
                if (b.line == lni) b.line += 1;
                continue;
            } else if (b.line != lni) {
                continue;
            }

            splits += 1;

            if (i > 0) {
                beams[i - 1].line = lni + 1;
                beams[i - 1].count += b.count;
            }
            if (i < ln.len - 1) {
                beams[i + 1].line = lni + 1;
                beams[i + 1].count += b.count;
            }

            b.line = 0;
            b.count = 0;
        }
    }

    var total: usize = 0;
    for (beams) |*b| total += b.count;
    return .{ splits, total };
}

test "example" {
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;
    const lines = try zutils.str.splitScalar(std.testing.allocator, input, '\n');
    defer std.testing.allocator.free(lines);

    const res = try solve(std.testing.allocator, lines);
    try std.testing.expectEqual(21, res[0]);
    try std.testing.expectEqual(40, res[1]);
}

pub fn main() !void {
    const sl = try zutils.fs.readLines(std.heap.page_allocator, //
        "~/sync/dev/aoc_inputs/2025/7.txt");
    defer sl.deinit();

    const res = try solve(std.heap.page_allocator, sl.list.items);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
