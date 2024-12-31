const std = @import("std");
const zutils = @import("zutils");

const Range = struct {
    begin: u32,
    end: u32,

    pub fn contains(self: *const Range, other: *const Range) bool {
        return self.begin <= other.begin and self.end >= other.end;
    }

    pub fn overlaps(self: *const Range, other: *const Range) bool {
        return self.contains(other) or (self.begin >= other.begin and self.begin <= other.end) //
        or (self.end >= other.begin and self.end <= other.end);
    }
};

fn parseRange(str: []const u8) !Range {
    var iter = std.mem.splitScalar(u8, str, '-');
    return .{
        .begin = try std.fmt.parseInt(u32, iter.next().?, 10),
        .end = try std.fmt.parseInt(u32, iter.next().?, 10),
    };
}

const BadLine = error{BadLine};

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![2]Range {
    var sl = zutils.StringList.init(allocator);
    defer sl.deinit();
    var iter = std.mem.splitScalar(u8, line, ',');
    while (iter.next()) |p| {
        try sl.append(try allocator.dupe(u8, p));
    }

    if (sl.size() != 2) {
        return error.BadLine;
    }

    const p1 = sl.items()[0];
    const p2 = sl.items()[1];
    return .{
        try parseRange(p1),
        try parseRange(p2),
    };
}

test "parsing" {
    const r = try parseRange("1-10");

    try std.testing.expectEqual(1, r.begin);
    try std.testing.expectEqual(10, r.end);

    const ln = try parseLine(std.testing.allocator, "31-34,32-33");

    try std.testing.expect(ln[0].contains(&ln[1]));
    try std.testing.expect(!ln[1].contains(&ln[0]));
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
        const rngs = try parseLine(std.testing.allocator, ln);
        try std.testing.expect(rngs[0].overlaps(&rngs[1]));
    }

    for (no_overlap) |ln| {
        const rngs = try parseLine(std.testing.allocator, ln);
        try std.testing.expect(!rngs[0].overlaps(&rngs[1]));
    }
}

pub fn main() void {
    const ll = zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/4.txt") catch {
        std.debug.print("Could not read file\n", .{});
        return;
    };
    defer ll.deinit();

    var contained: u32 = 0;
    var overlaps: u32 = 0;

    for (ll.items()) |ln| {
        const ln_ranges = parseLine(std.heap.page_allocator, ln) catch {
            std.debug.print("Failed to parse line: {s}\n", .{ln});
            return;
        };

        if (ln_ranges[0].contains(&ln_ranges[1]) or ln_ranges[1].contains(&ln_ranges[0])) {
            contained += 1;
        }

        if (ln_ranges[0].overlaps(&ln_ranges[1])) {
            overlaps += 1;
        }
    }

    std.debug.print("p1: {d}\n", .{contained});
    std.debug.print("p2: {d}\n", .{overlaps});
}
