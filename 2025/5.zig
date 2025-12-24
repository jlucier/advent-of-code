const std = @import("std");
const zutils = @import("zutils");

const Range = zutils.Range(usize);

fn compareRange(_: void, a: Range, b: Range) bool {
    return a.begin < b.begin;
}

const DB = struct {
    gpa: std.mem.Allocator,
    ranges: []Range,
    ids: []usize,

    const Self = @This();

    pub fn init(gpa: std.mem.Allocator, inp: []const u8) !Self {
        var iter = std.mem.splitScalar(u8, inp, '\n');
        var ranges = std.array_list.Managed(Range).init(gpa);
        var ids = std.array_list.Managed(usize).init(gpa);

        var parseIds = false;
        while (iter.next()) |ln| {
            if (ln.len == 0) {
                parseIds = true;
                continue;
            }

            if (parseIds) {
                try ids.append(try std.fmt.parseInt(usize, ln, 10));
            } else {
                const dash = std.mem.indexOfScalar(u8, ln, '-').?;
                try ranges.append(.{
                    .begin = try std.fmt.parseInt(usize, ln[0..dash], 10),
                    .end = try std.fmt.parseInt(usize, ln[dash + 1 ..], 10),
                });
            }
        }

        std.mem.sort(Range, ranges.items, {}, compareRange);

        var ret = DB{
            .gpa = gpa,
            .ranges = try ranges.toOwnedSlice(),
            .ids = try ids.toOwnedSlice(),
        };
        try ret.makeNonOverlapping();
        return ret;
    }

    pub fn deinit(self: *const Self) void {
        self.gpa.free(self.ranges);
        self.gpa.free(self.ids);
    }

    pub fn countFresh(self: *const Self) usize {
        var fresh: usize = 0;
        for (self.ids) |id| {
            for (self.ranges) |rng| {
                if (rng.begin > id) break;

                if (rng.containsScalar(id)) {
                    fresh += 1;
                    break;
                }
            }
        }
        return fresh;
    }

    pub fn possibleFresh(self: *const Self) usize {
        var possible: usize = 0;
        for (self.ranges) |rng| {
            possible += rng.end - rng.begin + 1;
        }
        return possible;
    }

    fn makeNonOverlapping(self: *Self) !void {
        var newRanges = std.array_list.Managed(Range).init(self.gpa);
        try newRanges.append(self.ranges[0]);
        for (self.ranges[1..]) |*b| {
            var a = &newRanges.items[newRanges.items.len - 1];
            if (b.contains(a.*)) {
                // b subsumes a, overwrite
                a.* = b.*;
                continue;
            } else if (a.contains(b.*)) {
                // do nothing, a full encapsulates b
                continue;
            } else if (a.overlaps(b.*)) {
                // augment a to remove overlap with b
                a.end = @max(a.begin, b.begin - 1);
            }
            try newRanges.append(b.*);
        }
        self.gpa.free(self.ranges);
        self.ranges = try newRanges.toOwnedSlice();
    }

    pub fn printRanges(self: *const DB) void {
        for (self.ranges) |rng| {
            std.debug.print("{any}\n", .{rng});
        }
    }
};

test "example" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;
    var db = try DB.init(std.testing.allocator, input);
    defer db.deinit();

    try std.testing.expectEqual(3, db.countFresh());
    try std.testing.expectEqual(14, db.possibleFresh());
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2025/5.txt");
    const db = try DB.init(std.heap.page_allocator, input);
    defer db.deinit();

    std.debug.print("p1: {d}\np2: {d}\n", .{ db.countFresh(), db.possibleFresh() });
}
