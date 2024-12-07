const std = @import("std");
const zutils = @import("zutils");

fn parseLine(allocator: std.mem.Allocator, ln: []const u8) ![]usize {
    var sl = try allocator.alloc(usize, std.mem.count(u8, ln, " ") + 1);
    var iter = std.mem.splitScalar(u8, ln, ' ');
    var i: usize = 0;
    while (iter.next()) |part| : (i += 1) {
        if (part[part.len - 1] == ':') {
            sl[i] = try std.fmt.parseUnsigned(usize, part[0 .. part.len - 1], 10);
        } else {
            sl[i] = try std.fmt.parseUnsigned(usize, part, 10);
        }
    }
    return sl;
}

fn solveBackwards(allocator: std.mem.Allocator, eq: []const usize, nops: usize) !?usize {
    var stack = try std.ArrayList([2]usize).initCapacity(allocator, 1);
    defer stack.deinit();
    stack.appendAssumeCapacity(.{ eq[0], eq.len - 1 });

    while (stack.popOrNull()) |node| {
        const curr = node[0];
        const i = node[1];
        const operand = eq[i];
        // std.debug.print("eval: {any} operand: {d}\n", .{ node, operand });

        if (i == 1) {
            // we're at the end, don't go further
            if (curr == operand) {
                // solved
                // std.debug.print("solved\n", .{});
                return eq[0];
            }
            // not sovled, nothing to do
        } else {
            // explore branches, subject to rules

            // add
            if (curr > operand) {
                try stack.append(.{ curr - operand, i - 1 });
            }

            // mul (only if divisible)
            if (curr % operand == 0) {
                try stack.append(.{ curr / operand, i - 1 });
            }

            if (nops == 3) {
                // concat (only if ends with)
                if (curr > operand and (curr - operand) % 10 == 0) {
                    const factor = std.math.pow(usize, 10, std.math.log10_int(operand) + 1);
                    // std.debug.print("    adding: {d} {d}\n", .{ curr / factor, factor });
                    try stack.append(.{ curr / factor, i - 1 });
                }
            }
        }
    }
    return null;
}

fn checkSolvable(allocator: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    var p1: usize = 0;
    var p2: usize = 0;

    for (lines) |ln| {
        const eq = try parseLine(allocator, ln);
        defer allocator.free(eq);

        if (try solveBackwards(allocator, eq, 2)) |v| {
            p1 += v;
        } else if (try solveBackwards(allocator, eq, 3)) |v| {
            p2 += v;
        }
    }
    return .{ p1, p1 + p2 };
}

test "part" {
    const lines = [_][]const u8{
        "190: 10 19",
        "3267: 81 40 27",
        "83: 17 5",
        "156: 15 6",
        "7290: 6 8 6 15",
        "161011: 16 10 13",
        "192: 17 8 14",
        "21037: 9 7 18 13",
        "292: 11 6 16 20",
    };

    const res = try checkSolvable(std.testing.allocator, &lines);
    try std.testing.expectEqual(3749, res[0]);
    try std.testing.expectEqual(11387, res[1]);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lines = try zutils.readLines(allocator, "~/sync/dev/aoc_inputs/2024/7.txt");

    const res = try checkSolvable(allocator, lines.strings.items);
    std.debug.print("p1: {d}\n", .{res[0]});
    std.debug.print("p2: {d}\n", .{res[1]});
}

// NOTE: this code did work, it was my "small brain" solution. I liked parts of it
// and didn't want to just throw it away. Particularly, the initialization of all the
// permutations of operations was fun. I had never thought about that small problem before.
// This solution had basically nothing in the way of branch pruning, which was an obvious sign
// I was "doing it wrong", but it did actually finish running in a little less than 2 minutes
// on my laptop. Yay zig I guess. The new solution however, is very cool and runs both parts in
// 50ms. Slightly disappointed I didn't see it myself, but happy to have tried it out.
//
//
// const Operator = enum { ADD, MUL, CONCAT };
//
// const OpPerms = struct {
//     allocator: std.mem.Allocator,
//     perms: [][]Operator,
//
//     pub fn init(allocator: std.mem.Allocator, num_ops: usize, num_op_types: usize) !OpPerms {
//         const num_perms = std.math.pow(usize, num_op_types, num_ops);
//         const opms = OpPerms{
//             .allocator = allocator,
//             .perms = try allocator.alloc([]Operator, num_perms),
//         };
//
//         var i: usize = 0;
//         while (i < num_perms) : (i += 1) {
//             opms.perms[i] = try allocator.alloc(Operator, num_ops);
//         }
//
//         i = 0;
//         while (i < num_ops) : (i += 1) {
//             // for every slot, place each option for operator into that slot of every
//             // permutation, alternating every so often according to the slot index
//             var curr_op = Operator.ADD;
//             for (opms.perms, 0..) |p, j| {
//                 p[i] = curr_op;
//                 if ((j + 1) % std.math.pow(usize, num_op_types, i) == 0) {
//                     curr_op = switch (curr_op) {
//                         .ADD => .MUL,
//                         .MUL => if (num_op_types == 2) .ADD else .CONCAT,
//                         .CONCAT => .ADD,
//                     };
//                 }
//             }
//         }
//
//         return opms;
//     }
//
//     pub fn deinit(self: *const OpPerms) void {
//         for (self.perms) |p| {
//             self.allocator.free(p);
//         }
//         self.allocator.free(self.perms);
//     }
// };
//
// fn canSolve(allocator: std.mem.Allocator, eq: []const usize, nops: usize) !?usize {
//     const test_val = eq[0];
//     // len - 1 = num components, num components - 1 = num ops
//     const opms = try OpPerms.init(allocator, eq.len - 2, nops);
//     defer opms.deinit();
//
//     for (opms.perms) |ops| {
//         var curr: usize = eq[1];
//         for (eq[2..], 0..) |v, i| {
//             curr = switch (ops[i]) {
//                 .ADD => curr + v,
//                 .MUL => curr * v,
//                 .CONCAT => curr * std.math.pow(usize, 10, std.math.log10_int(v) + 1) + v,
//             };
//
//             if (curr > test_val) {
//                 // there is no op that reduces the number
//                 break;
//             }
//         }
//         if (curr == test_val) {
//             return test_val;
//         }
//     }
//     return null;
// }
