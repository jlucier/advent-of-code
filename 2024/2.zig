const std = @import("std");
const zutils = @import("zutils");

fn parseReport(allocator: std.mem.Allocator, line: []const u8) ![]isize {
    const size = std.mem.count(u8, line, " ") + 1;
    const report = try allocator.alloc(isize, size);

    var nums = std.mem.splitScalar(u8, line, ' ');
    var i: usize = 0;
    while (nums.next()) |n| : (i += 1) {
        report[i] = try std.fmt.parseInt(isize, n, 10);
    }
    return report;
}

fn isSafe(report: []const isize, ignore_idx: ?usize) bool {
    var i: usize = 0;
    var sign: i8 = 0;
    while (i < report.len - 1) : (i += 1) {
        var a = report[i];
        var b = report[i + 1];
        if (ignore_idx) |idx| {
            if (i == idx) {
                if (i == 0) {
                    continue;
                } else {
                    a = report[i - 1];
                }
            } else if (i + 1 == idx) {
                if (i + 2 < report.len) {
                    b = report[i + 2];
                } else {
                    continue;
                }
            }
        }
        const dx = a - b;
        const dsign: i8 = if (dx < 0) -1 else 1;

        // consistent increase or decrease
        if (sign == 0) {
            sign = dsign;
        } else if (sign != dsign) {
            return false;
        }

        // delta mag

        const abs = zutils.abs(isize, dx);
        if (!(abs >= 1 and abs <= 3)) {
            return false;
        }
    }
    return true;
}

fn parts(allocator: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    var safe: usize = 0;
    var safe_ignore: usize = 0;

    for (lines) |ln| {
        const rep = try parseReport(allocator, ln);
        defer allocator.free(rep);

        const rs = isSafe(rep, null);
        safe += if (rs) 1 else 0;

        if (!rs) {
            // try with removals
            var i: usize = 0;
            while (i < rep.len) : (i += 1) {
                const is = isSafe(rep, i);
                safe_ignore += if (is) 1 else 0;
                if (is) {
                    break;
                }
            }
        }
    }
    return .{ safe, safe_ignore };
}

test "example" {
    const inp = [_][]const u8{
        "7 6 4 2 1",
        "1 2 7 8 9",
        "9 7 6 2 1",
        "1 3 2 4 5",
        "8 6 4 4 1",
        "1 3 6 7 9",
    };

    const answers = try parts(std.testing.allocator, &inp);
    try std.testing.expectEqual(2, answers[0]);
    try std.testing.expectEqual(4, zutils.sum(usize, &answers));
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/2.txt");
    defer lines.deinit();
    const answers = try parts(std.heap.page_allocator, lines.strings.items);
    std.debug.print("p1: {d}\n", .{answers[0]});
    std.debug.print("p2: {d}\n", .{zutils.sum(usize, &answers)});
}
