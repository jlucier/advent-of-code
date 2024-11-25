const std = @import("std");

/// Expand the ~ in a pathname to the users home dir. Caller owns the returned path string
pub fn expandHomeDir(allocator: std.mem.Allocator, pathname: []const u8) ![]u8 {
    if (pathname[0] == '~' and (pathname.len == 1 or pathname[1] == '/')) {
        const home = std.posix.getenv("HOME") orelse "";
        const tmp = [_][]const u8{ home, pathname[1..] };
        return std.mem.concat(allocator, u8, &tmp);
    }

    return allocator.dupe(u8, pathname);
}

/// Read lines of a file. ArrayList and strings inside are owned by caller
pub fn readFile(allocator: std.mem.Allocator, pathname: []const u8) !std.ArrayList([]u8) {
    const path = try expandHomeDir(allocator, pathname);
    defer allocator.free(path);

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();
    const reader = file.reader();

    var lines = std.ArrayList([]u8).init(allocator);
    while (true) {
        const ln = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1_000_000);

        if (ln != null) {
            try lines.append(ln.?);
        } else {
            break;
        }
    }

    return lines;
}

// TESTS

test "expand home" {
    const res1 = try expandHomeDir(std.testing.allocator, "~");
    defer std.testing.allocator.free(res1);

    const res2 = try expandHomeDir(std.testing.allocator, "~/something/other");
    defer std.testing.allocator.free(res2);

    const res3 = try expandHomeDir(std.testing.allocator, "/something/other");
    defer std.testing.allocator.free(res3);

    try std.testing.expect(std.mem.eql(u8, res1, "/home/jordan"));
    try std.testing.expect(std.mem.eql(u8, res2, "/home/jordan/something/other"));
    try std.testing.expect(std.mem.eql(u8, res3, "/something/other"));
}

test "read lines" {
    const f = try std.fs.cwd().realpathAlloc(std.testing.allocator, "test.txt");
    defer std.testing.allocator.free(f);

    const lines = try readFile(std.testing.allocator, f);
    defer {
        for (lines.items) |ln| {
            std.testing.allocator.free(ln);
        }
        lines.deinit();
    }

    try std.testing.expect(std.mem.eql(u8, lines.items[0], "1000"));
    try std.testing.expect(std.mem.eql(u8, lines.items[1], "2000"));
    try std.testing.expect(std.mem.eql(u8, lines.items[2], "3000"));
    try std.testing.expect(std.mem.eql(u8, lines.items[3], ""));
    try std.testing.expect(std.mem.eql(u8, lines.items[4], "4000"));
}
