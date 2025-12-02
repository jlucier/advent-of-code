const std = @import("std");
const zutils = @import("zutils");

fn parseLine(ln: []const u8) !usize {
    return try std.fmt.parseInt(usize, ln, 10);
}

fn parts(lines: []const []const u8) ![2]usize {
    const size = 100;
    var pos: isize = 50;
    var p1: usize = 0;
    var p2: usize = 0;
    var og = pos;

    for (lines) |ln| {
        const mag: isize = @intCast(try parseLine(ln[1..]));
        const move = switch (ln[0]) {
            'L' => -mag,
            'R' => mag,
            else => unreachable,
        };

        p2 += @intCast(@abs(@divTrunc(mag, size)));

        og = pos;
        // apply remainder only as move
        pos += @rem(move, size);

        p2 += @intFromBool(pos > size);

        // fix position
        pos = @rem(pos, size);
        if (pos < 0) {
            pos += size;
            // if we started at zero, the move negative doesn't cross
            // and we already accounted for moves larger than -99
            p2 += @intFromBool(og != 0);
        }

        if (pos == 0) {
            p1 += 1;
            // once more, if we started at zero, the move was a pure
            // multiple of size and we already would have counted this ending
            // at zero by mag / size being integral
            p2 += @intFromBool(og != 0);
        }
    }
    return .{ p1, p2 };
}

test "basic" {
    const input = [_][]const u8{
        "L68",
        "L30",
        "R48",
        "L5",
        "R60",
        "L55",
        "L1",
        "L99",
        "R14",
        "L82",
    };

    const res = try parts(&input);
    try std.testing.expectEqual(3, res[0]);
    try std.testing.expectEqual(6, res[1]);
}

test "simple" {
    const inp1 = [_][]const u8{
        "R50",
    };
    const res = try parts(&inp1);
    try std.testing.expectEqual(1, res[0]);
    try std.testing.expectEqual(1, res[1]);
}

test "annoying1" {
    const inp1 = [_][]const u8{
        "R1000",
    };
    const res = try parts(&inp1);
    try std.testing.expectEqual(0, res[0]);
    try std.testing.expectEqual(10, res[1]);
}

test "annoying2" {
    const inp = [_][]const u8{
        "L50",
        "R200",
    };
    const res = try parts(&inp);
    try std.testing.expectEqual(2, res[0]);
    try std.testing.expectEqual(3, res[1]);
}

test "annoying3" {
    const inp = [_][]const u8{
        "L49",
        "L101",
    };
    const res = try parts(&inp);
    try std.testing.expectEqual(1, res[0]);
    try std.testing.expectEqual(2, res[1]);
}

test "annoying4" {
    const inp = [_][]const u8{
        "L251",
    };
    const res = try parts(&inp);
    try std.testing.expectEqual(0, res[0]);
    try std.testing.expectEqual(3, res[1]);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, //
        "~/sync/dev/aoc_inputs/2025/1.txt");
    const res = try parts(lines.items());

    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
