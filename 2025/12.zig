const std = @import("std");
const zutils = @import("zutils");

const N_SHAPES = 6;
const ShapeSlice = [N_SHAPES]usize;

fn parseShapes(input: []const u8) !ShapeSlice {
    var shapes: ShapeSlice = undefined;
    var iter = std.mem.splitSequence(u8, input, "\n\n");
    var i: usize = 0;
    while (iter.next()) |block| : (i += 1) {
        if (block[1] != ':') continue;

        var lniter = std.mem.splitScalar(
            u8,
            block[std.mem.indexOfScalar(u8, block, '\n').? + 1 ..],
            '\n',
        );

        var tot: usize = 0;
        while (lniter.next()) |ln| {
            for (ln) |c| {
                tot += @intFromBool(c == '#');
            }
        }

        shapes[i] = tot;
    }
    return shapes;
}

const Grid = struct {
    m: usize,
    n: usize,
    nshapes: ShapeSlice = undefined,
};

fn parseGrid(ln: []const u8) !Grid {
    const xi = std.mem.indexOfScalar(u8, ln, 'x').?;
    const colon = std.mem.indexOf(u8, ln, ": ").?;
    var ret = Grid{
        .m = try std.fmt.parseInt(usize, ln[0..xi], 10),
        .n = try std.fmt.parseInt(usize, ln[xi + 1 .. colon], 10),
    };

    var iter = std.mem.splitScalar(u8, ln[colon + 2 ..], ' ');
    var i: usize = 0;
    while (iter.next()) |v| : (i += 1) {
        ret.nshapes[i] = try std.fmt.parseInt(usize, v, 10);
    }
    return ret;
}

fn testGrid(_: ShapeSlice, g: *const Grid) bool {
    const required = zutils.sum(usize, &g.nshapes);
    const a = g.m / 3 * g.n / 3;
    return a >= required;
}

fn solve(input: []const u8) !usize {
    const shapes = try parseShapes(input);

    var firstGrid = std.mem.indexOfScalar(u8, input, 'x').?;
    firstGrid = std.mem.lastIndexOfScalar(u8, input[0..firstGrid], '\n').? + 1;

    var works: usize = 0;
    var iter = std.mem.splitScalar(u8, input[firstGrid..], '\n');
    while (iter.next()) |gl| {
        if (gl.len == 0) continue;
        const res = try parseGrid(gl);
        works += @intFromBool(testGrid(shapes, &res));
    }

    return works;
}

test "example" {
    const input =
        \\0:
        \\###
        \\##.
        \\##.
        \\
        \\1:
        \\###
        \\##.
        \\.##
        \\
        \\2:
        \\.##
        \\###
        \\##.
        \\
        \\3:
        \\##.
        \\###
        \\##.
        \\
        \\4:
        \\###
        \\#..
        \\###
        \\
        \\5:
        \\###
        \\.#.
        \\###
        \\
        \\4x4: 0 0 0 0 2 0
        \\12x5: 1 0 1 0 2 2
        \\12x5: 1 0 1 0 3 2
    ;

    const res = try solve(input);
    try std.testing.expectEqual(2, res);
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2025/12.txt");
    defer std.heap.page_allocator.free(input);

    const res = try solve(input);
    std.debug.print("p1: {d}\n", .{res});
}
