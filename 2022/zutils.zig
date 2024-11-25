const std = @import("std");

// FS

/// Expand the ~ in a pathname to the users home dir. Caller owns the returned path string
pub fn expandHomeDir(allocator: std.mem.Allocator, pathname: []const u8) ![]u8 {
    if (pathname[0] == '~' and (pathname.len == 1 or pathname[1] == '/')) {
        const home = std.posix.getenv("HOME") orelse "";
        const tmp = [_][]const u8{ home, pathname[1..] };
        return std.mem.concat(allocator, u8, &tmp);
    }

    return allocator.dupe(u8, pathname);
}

pub const LineList = struct {
    lines: std.ArrayList([]u8),
    allocator: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) LineList {
        return LineList{ .lines = std.ArrayList([]u8).init(alloc), .allocator = alloc };
    }

    pub fn deinit(self: *const LineList) void {
        for (self.lines.items) |ln| {
            self.allocator.free(ln);
        }
        self.lines.deinit();
    }
};

/// Read lines of a file. ArrayList and strings inside are owned by caller
pub fn readLines(allocator: std.mem.Allocator, pathname: []const u8) !LineList {
    const path = try expandHomeDir(allocator, pathname);
    defer allocator.free(path);

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();
    const reader = file.reader();

    var ll = LineList.init(allocator);
    while (true) {
        const ln = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1_000_000);

        if (ln) |l| {
            try ll.lines.append(l);
        } else {
            break;
        }
    }

    return ll;
}

// Slices

pub fn sum(comptime T: type, slice: []const T) T {
    var s: T = 0;
    for (slice) |el| s += el;
    return s;
}

// TESTS

test "expand home" {
    const home = std.posix.getenv("HOME") orelse "";
    const p1 = "/something/other";

    const parts = [_][]const u8{ home, p1 };
    const a2 = try std.fs.path.join(std.testing.allocator, &parts);
    defer std.testing.allocator.free(a2);

    const res1 = try expandHomeDir(std.testing.allocator, "~");
    defer std.testing.allocator.free(res1);

    const res2 = try expandHomeDir(std.testing.allocator, "~/something/other");
    defer std.testing.allocator.free(res2);

    const res3 = try expandHomeDir(std.testing.allocator, "/something/other");
    defer std.testing.allocator.free(res3);

    try std.testing.expect(std.mem.eql(u8, res1, home));
    try std.testing.expect(std.mem.eql(u8, res2, a2));
    try std.testing.expect(std.mem.eql(u8, res3, p1));
}

test "read lines" {
    const f = try std.fs.cwd().realpathAlloc(std.testing.allocator, "test.txt");
    defer std.testing.allocator.free(f);

    const ll = try readLines(std.testing.allocator, f);
    defer ll.deinit();

    try std.testing.expect(std.mem.eql(u8, ll.lines.items[0], "1000"));
    try std.testing.expect(std.mem.eql(u8, ll.lines.items[1], "2000"));
    try std.testing.expect(std.mem.eql(u8, ll.lines.items[2], "3000"));
    try std.testing.expect(std.mem.eql(u8, ll.lines.items[3], ""));
    try std.testing.expect(std.mem.eql(u8, ll.lines.items[4], "4000"));
}

test "sum" {
    const a = [_]u8{ 1, 2, 3, 4 };
    try std.testing.expectEqual(sum(u8, &a), 10);

    const b = [_]i32{ -1, 2, 3, -4 };
    try std.testing.expectEqual(sum(i32, &b), 0);
}