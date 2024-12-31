const std = @import("std");
const zutils = @import("zutils");

const LineNums = struct {
    left: usize,
    right: usize,

    pub fn parse(line: []const u8) !LineNums {
        var iter = std.mem.splitSequence(u8, line, "   ");
        return .{
            .left = try std.fmt.parseUnsigned(usize, iter.next().?, 10),
            .right = try std.fmt.parseUnsigned(usize, iter.next().?, 10),
        };
    }
};

/// Both lists are owned by caller
fn parseLists(allocator: std.mem.Allocator, lines: []const []const u8) ![2][]usize {
    const left = try allocator.alloc(usize, lines.len);
    const right = try allocator.alloc(usize, lines.len);

    for (lines, 0..) |ln, i| {
        const nums = try LineNums.parse(ln);
        left[i] = nums.left;
        right[i] = nums.right;
    }

    return .{ left, right };
}

fn p1(left: []usize, right: []usize) usize {
    std.mem.sort(usize, left, {}, comptime std.sort.asc(usize));
    std.mem.sort(usize, right, {}, comptime std.sort.asc(usize));

    var sumDiff: usize = 0;
    var i: usize = 0;
    while (i < left.len) : (i += 1) {
        const l = left[i];
        const r = right[i];
        sumDiff += if (r > l) r - l else l - r;
    }
    return sumDiff;
}

fn p2(allocator: std.mem.Allocator, left: []const usize, right: []const usize) !usize {
    var in_right = std.AutoHashMap(usize, usize).init(allocator);
    defer in_right.deinit();

    for (right) |r| {
        try in_right.put(r, 1 + (in_right.get(r) orelse 0));
    }

    var score: usize = 0;
    for (left) |l| {
        score += l * (in_right.get(l) orelse 0);
    }
    return score;
}

fn doParts(allocator: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    const lists = try parseLists(allocator, lines);
    const left = lists[0];
    const right = lists[1];
    defer allocator.free(left);
    defer allocator.free(right);

    return .{ p1(left, right), try p2(allocator, left, right) };
}

test "tests" {
    const lines = [_][]const u8{
        "3   4",
        "4   3",
        "2   5",
        "1   3",
        "3   9",
        "3   3",
    };

    const res = try doParts(std.testing.allocator, &lines);

    // p1
    try std.testing.expectEqual(11, res[0]);

    // p2
    try std.testing.expectEqual(31, res[1]);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/1.txt");
    const res = try doParts(std.heap.page_allocator, lines.items());

    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
