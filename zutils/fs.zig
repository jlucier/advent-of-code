const std = @import("std");
const zutils = @import("zutils.zig");

/// Expand the ~ in a pathname to the users home dir. Caller owns the returned path string
pub fn expandHomeDir(gpa: std.mem.Allocator, pathname: []const u8) ![]u8 {
    if (pathname[0] == '~' and (pathname.len == 1 or pathname[1] == '/')) {
        const home = std.posix.getenv("HOME") orelse "";
        const tmp = [_][]const u8{ home, pathname[1..] };
        return std.mem.concat(gpa, u8, &tmp);
    }

    return gpa.dupe(u8, pathname);
}

/// Open a file using a path that may need expanding. File is callers to manage
pub fn openFile(gpa: std.mem.Allocator, pathname: []const u8, flags: std.fs.File.OpenFlags) !std.fs.File {
    const path = try expandHomeDir(gpa, pathname);
    defer gpa.free(path);
    return std.fs.openFileAbsolute(path, flags);
}

fn readLinesInner(
    gpa: std.mem.Allocator,
    list: *zutils.StringList,
    pathname: []const u8,
) !void {
    const f = try openFile(gpa, pathname, .{ .mode = .read_only });
    defer f.close();
    var buf: [4096]u8 = undefined;
    var freader = f.reader(&buf);
    var reader = &freader.interface;

    while (reader.takeDelimiterInclusive('\n')) |ln| {
        const cp = try list.arena.allocator().dupe(u8, ln[0 .. ln.len - 1]);
        try list.append(cp);
    } else |err| switch (err) {
        error.EndOfStream => return,
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }
}

/// Read lines of a file. array_list.Managed and strings inside are owned by caller
pub fn readLines(gpa: std.mem.Allocator, pathname: []const u8) !zutils.StringList {
    var ll = try zutils.StringList.init(gpa);
    try readLinesInner(ll.arena.allocator(), &ll, pathname);
    return ll;
}

pub fn readLinesArena(arena: *std.heap.ArenaAllocator, pathname: []const u8) !zutils.StringList {
    var ll = zutils.StringList.initWithArena(arena);
    try readLinesInner(arena.allocator(), &ll, pathname);
    return ll;
}

pub fn readFile(alloc: std.mem.Allocator, pathname: []const u8) ![]u8 {
    const file = try openFile(alloc, pathname, .{ .mode = .read_only });
    defer file.close();

    var buf: [4096]u8 = undefined;
    var freader = file.reader(&buf);
    var reader = &freader.interface;
    return reader.allocRemaining(alloc, .unlimited);
}

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

test "read file" {
    const f = try std.fs.cwd().realpathAlloc(std.testing.allocator, "zutils/test.txt");
    defer std.testing.allocator.free(f);

    const contents = try readFile(std.testing.allocator, f);
    defer std.testing.allocator.free(contents);
}
