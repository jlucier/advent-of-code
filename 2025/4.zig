const std = @import("std");
const zutils = @import("zutils");

fn findRolls(gpa: std.mem.Allocator, g: *const zutils.Grid(u8)) ![]zutils.vec.V2u {
    var giter = g.iterator();
    var remove = std.array_list.Managed(zutils.vec.V2u).init(gpa);

    while (giter.next()) |loc| {
        if (g.atV(loc) != '@') continue;

        var occupied: u8 = 0;
        var nbiter = g.neighbors(loc, .all);
        while (nbiter.next()) |nb| {
            occupied += @intFromBool(g.atV(nb) == '@');
        }
        if (occupied < 4) {
            try remove.append(loc);
        }
    }

    return remove.toOwnedSlice();
}

fn parts(gpa: std.mem.Allocator, input: []const u8) ![2]usize {
    const lines = try zutils.str.splitScalar(gpa, input, '\n');
    defer gpa.free(lines);
    var g = try zutils.Grid(u8).init2DSlice(gpa, lines);
    defer g.deinit();

    const p1 = try findRolls(gpa, &g);
    defer gpa.free(p1);
    var p2: usize = 0;

    while (true) {
        const remove = try findRolls(gpa, &g);
        defer gpa.free(remove);

        if (remove.len == 0) break;

        p2 += remove.len;

        for (remove) |loc| {
            g.atPtrV(loc).* = '.';
        }
    }

    return .{ p1.len, p2 };
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
    try std.testing.expectEqual(13, res[0]);
    try std.testing.expectEqual(43, res[1]);
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2025/4.txt");
    const res = try parts(std.heap.page_allocator, input);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
