const std = @import("std");
const zutils = @import("zutils");

const Ops = struct {
    // max size observed in input
    nums: [4]usize = undefined,
    size: usize = 0,
};

const Equation = struct {
    p1ops: Ops = .{},
    p2ops: Ops = .{},
    operator: u8 = '_',
    colStart: usize = 0,

    const Self = @This();

    pub fn solve(self: *const Self) [2]usize {
        return switch (self.operator) {
            '*' => .{
                zutils.mul(usize, self.p1ops.nums[0..self.p1ops.size]),
                zutils.mul(usize, self.p2ops.nums[0..self.p2ops.size]),
            },
            else => .{
                zutils.sum(usize, self.p1ops.nums[0..self.p1ops.size]),
                zutils.sum(usize, self.p2ops.nums[0..self.p2ops.size]),
            },
        };
    }
};

fn parseOperandLine(gpa: std.mem.Allocator, ln: []const u8) ![]Equation {
    const total = std.mem.count(u8, ln, "*") + std.mem.count(u8, ln, "+");
    var eqns = try gpa.alloc(Equation, total);

    var iter = std.mem.tokenizeScalar(u8, ln, ' ');
    var i: usize = 0;
    while (iter.next()) |op| {
        eqns[i].colStart = iter.index - op.len;
        eqns[i].operator = op[0];
        eqns[i].p1ops.size = 0;
        eqns[i].p2ops.size = 0;
        i += 1;
    }
    return eqns;
}

fn parseEquations(arena: *std.heap.ArenaAllocator, inp: []const []const u8) ![]Equation {
    const gpa = arena.allocator();
    const eqns = try parseOperandLine(gpa, inp[inp.len - 1]);

    for (eqns, 0..) |*eq, eqi| {
        const end = if (eqi + 1 < eqns.len) eqns[eqi + 1].colStart - 1 else inp[0].len;

        for (inp, 0..) |ln, lni| {
            if (lni == inp.len - 1) break;

            const num = std.mem.trim(u8, ln[eq.colStart..end], " ");

            eq.p1ops.nums[lni] = try std.fmt.parseInt(usize, num, 10);
            eq.p1ops.size += 1;
        }

        for (eq.colStart..end) |j| {
            var scratch: usize = 0;
            var iter = std.mem.reverseIterator(inp[0 .. inp.len - 1]);
            var i: usize = 0;
            while (iter.next()) |ln| {
                if (ln[j] == ' ') continue;
                const digit = try std.fmt.parseInt(usize, ln[j .. j + 1], 10);
                scratch += digit * std.math.pow(usize, 10, i);
                i += 1;
            }
            eq.p2ops.nums[eq.p2ops.size] = scratch;
            eq.p2ops.size += 1;
        }
    }
    return eqns;
}

fn parts(eqns: []const Equation) [2]usize {
    var p1: usize = 0;
    var p2: usize = 0;
    for (eqns) |eq| {
        const res = eq.solve();
        p1 += res[0];
        p2 += res[1];
    }
    return .{ p1, p2 };
}

test "example" {
    const input = [_][]const u8{
        "123 328  51 64 ",
        " 45 64  387 23 ",
        "  6 98  215 314",
        "*   +   *   +  ",
    };

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const eqns = try parseEquations(&arena, &input);
    const res = parts(eqns);
    try std.testing.expectEqual(4277556, res[0]);
    try std.testing.expectEqual(3263827, res[1]);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try zutils.fs.readLines(arena.allocator(), //
        "~/sync/dev/aoc_inputs/2025/6.txt");
    const eqns = try parseEquations(&arena, input.list.items);

    const res = parts(eqns);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
