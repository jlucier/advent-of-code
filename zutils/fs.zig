const std = @import("std");
const zutils = @import("zutils.zig");

/// Expand the ~ in a pathname to the users home dir. Caller owns the returned path string
pub fn expandHomeDir(allocator: std.mem.Allocator, pathname: []const u8) ![]u8 {
    if (pathname[0] == '~' and (pathname.len == 1 or pathname[1] == '/')) {
        const home = std.posix.getenv("HOME") orelse "";
        const tmp = [_][]const u8{ home, pathname[1..] };
        return std.mem.concat(allocator, u8, &tmp);
    }

    return allocator.dupe(u8, pathname);
}

/// Open a file using a path that may need expanding. File is callers to manage
pub fn openFile(allocator: std.mem.Allocator, pathname: []const u8, flags: std.fs.File.OpenFlags) !std.fs.File {
    const path = try expandHomeDir(allocator, pathname);
    defer allocator.free(path);
    return std.fs.openFileAbsolute(path, flags);
}

fn readLinesInner(
    allocator: std.mem.Allocator,
    list: *zutils.StringList,
    pathname: []const u8,
) !void {
    const file = try openFile(allocator, pathname, .{ .mode = .read_only });
    defer file.close();
    const reader = file.reader();

    while (true) {
        const ln = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1_000_000);

        if (ln) |l| {
            try list.append(l);
        } else {
            break;
        }
    }
}

/// Read lines of a file. ArrayList and strings inside are owned by caller
pub fn readLines(allocator: std.mem.Allocator, pathname: []const u8) !zutils.StringList {
    var ll = zutils.StringList.init(allocator);
    try readLinesInner(allocator, &ll, pathname);
    return ll;
}

// pub fn readLinesArena(arena: *std.heap.ArenaAllocator, pathname: []const u8) !zutils.StringList {
//     var ll = zutils.StringList.initWithArena(arena);
//     try readLinesInner(arena.allocator(), &ll, pathname);
//     return ll;
// }

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
    const f = try std.fs.cwd().realpathAlloc(std.testing.allocator, "zutils/test.txt");
    defer std.testing.allocator.free(f);

    const ll = try readLines(std.testing.allocator, f);
    defer ll.deinit();

    try std.testing.expect(std.mem.eql(u8, ll.items()[0], "1000"));
    try std.testing.expect(std.mem.eql(u8, ll.items()[1], "2000"));
    try std.testing.expect(std.mem.eql(u8, ll.items()[2], "3000"));
    try std.testing.expect(std.mem.eql(u8, ll.items()[3], ""));
    try std.testing.expect(std.mem.eql(u8, ll.items()[4], "4000"));
}
