const std = @import("std");
const zutils = @import("zutils");

fn parts(gpa: std.mem.Allocator, input: []const u8) !usize {
    const lines = try zutils.str.splitScalar(gpa, input, '\n');
    defer gpa.free(lines);
    const g = try zutils.Grid(u8).init2DSlice(gpa, lines);
    defer g.deinit();

    var p1: usize = 0;
    var giter = g.iterator();

    while (giter.next()) |loc| {
        var occupied: u8 = 0;
        var nbiter = g.neighbors(loc, .all);
        while (nbiter.next()) |nb| {
            occupied += @intFromBool(g.atV(nb) == '@');
        }
        p1 += @intFromBool(occupied < 4);
    }

    return p1;
}

test "example" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;

    const res = try parts(std.testing.allocator, input);
    try std.testing.expectEqual(13, res);
}

pub fn main() !void {}
