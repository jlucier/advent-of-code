const std = @import("std");
const zutils = @import("zutils");

const Range = zutils.Range(u32);

fn parseRange(str: []const u8) !Range {
    var iter = std.mem.splitScalar(u8, str, '-');
    return .{
        .begin = try std.fmt.parseInt(u32, iter.next().?, 10),
        .end = try std.fmt.parseInt(u32, iter.next().?, 10),
    };
}

fn parseLine(line: []const u8) ![2]Range {
    var iter = std.mem.splitScalar(u8, line, ',');
    return .{
        try parseRange(iter.next().?),
        try parseRange(iter.next().?),
    };
}

test "parsing" {
    const r = try parseRange("1-10");

    try std.testing.expectEqual(1, r.begin);
    try std.testing.expectEqual(10, r.end);

    const ln = try parseLine("31-34,32-33");

    try std.testing.expect(ln[0].contains(ln[1]));
    try std.testing.expect(!ln[1].contains(ln[0]));
}

test "overlaps" {
    const overlap = [_][]const u8{
        "5-7,7-9",
        "2-8,3-7",
        "6-6,4-6",
        "2-6,4-8",
    };
    const no_overlap = [_][]const u8{
        "2-4,6-8",
        "2-3,4-5",
    };

    for (overlap) |ln| {
        const rngs = try parseLine(ln);
        try std.testing.expect(rngs[0].overlaps(rngs[1]));
    }

    for (no_overlap) |ln| {
        const rngs = try parseLine(ln);
        try std.testing.expect(!rngs[0].overlaps(rngs[1]));
    }
}

pub fn main() !void {
    const ll = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/4.txt");
    defer ll.deinit();

    var contained: u32 = 0;
    var overlaps: u32 = 0;

    for (ll.items()) |ln| {
        const ln_ranges = try parseLine(ln);

        if (ln_ranges[0].contains(ln_ranges[1]) or ln_ranges[1].contains(ln_ranges[0])) {
            contained += 1;
        }

        if (ln_ranges[0].overlaps(ln_ranges[1])) {
            overlaps += 1;
        }
    }

    std.debug.print("p1: {d}\n", .{contained});
    std.debug.print("p2: {d}\n", .{overlaps});
}
