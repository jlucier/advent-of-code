const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2;

fn validateP1(id: []const u8) bool {
    return !std.mem.eql(u8, id[0 .. id.len / 2], id[id.len / 2 ..]);
}

fn validateP2(id: []const u8) bool {
    outer: for (1..id.len / 2 + 1) |sz| {
        if (id.len % sz != 0)
            continue;

        // check all substrs
        for (1..id.len / sz) |i| {
            if (!std.mem.eql(u8, id[0..sz], id[sz * i .. sz * (i + 1)]))
                continue :outer;
        }
        // all eql
        return false;
    }
    return true;
}

fn solveRange(start: []const u8, end: []const u8) ![2]usize {
    const st = try std.fmt.parseInt(usize, start, 10);
    const en = try std.fmt.parseInt(usize, end, 10);

    var buf: [128]u8 = undefined;

    var p1: usize = 0;
    var p2: usize = 0;
    for (st..en + 1) |i| {
        const s = try std.fmt.bufPrint(&buf, "{d}", .{i});
        if (!validateP1(s))
            p1 += i;
        if (!validateP2(s))
            p2 += i;
    }
    return .{ p1, p2 };
}

fn solve(input: []const u8) ![2]usize {
    const delims = [_]u8{ '\n', ',' };
    var iter = std.mem.splitAny(u8, input, &delims);

    var invalid = [2]usize{ 0, 0 };
    while (iter.next()) |range| {
        if (range.len == 0)
            continue;

        const dash = std.mem.indexOfScalar(u8, range, '-').?;

        const res = try solveRange(range[0..dash], range[dash + 1 ..]);
        invalid[0] += res[0];
        invalid[1] += res[1];
    }
    return invalid;
}

test "validate1" {
    try std.testing.expect(!validateP1("11"));
    try std.testing.expect(validateP1("10"));
    try std.testing.expect(!validateP1("222222"));
    try std.testing.expect(!validateP1("1188511885"));
    try std.testing.expect(validateP1("1001"));
}

test "validate2" {
    try std.testing.expect(!validateP2("101010"));
    try std.testing.expect(!validateP2("111"));
    try std.testing.expect(validateP2("101"));
}

test "basic" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
        \\1698522-1698528,446443-446449,38593856-38593862,565653-565659,
        \\824824821-824824827,2121212118-2121212124
    ;

    const res = try solve(input);
    try std.testing.expectEqual(1227775554, res[0]);
    try std.testing.expectEqual(4174379265, res[1]);
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, //
        "~/sync/dev/aoc_inputs/2025/2.txt");
    defer std.heap.page_allocator.free(input);

    const out = try solve(input);
    std.debug.print("p1: {d}\np2: {d}\n", .{ out[0], out[1] });
}
