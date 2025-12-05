const std = @import("std");

const ArenaAllocator = std.heap.ArenaAllocator;

pub const StringList = struct {
    owned: bool = false,
    arena: *std.heap.ArenaAllocator,
    list: std.array_list.Managed([]u8),

    pub fn initWithArena(arena: *ArenaAllocator) StringList {
        return .{
            .owned = false,
            .arena = arena,
            .list = std.array_list.Managed([]u8).init(arena.allocator()),
        };
    }

    pub fn init(allocator: std.mem.Allocator) !StringList {
        const arena = try allocator.create(ArenaAllocator);
        arena.* = ArenaAllocator.init(allocator);
        var ret = StringList.initWithArena(arena);
        ret.owned = true;
        return ret;
    }

    pub fn deinit(self: *const StringList) void {
        if (self.owned) {
            self.arena.deinit();
            self.arena.child_allocator.destroy(self.arena);
        }
    }

    pub fn size(self: *const StringList) usize {
        return self.items().len;
    }

    pub fn items(self: *const StringList) []const []u8 {
        return self.list.items;
    }

    pub fn append(self: *StringList, elem: []u8) !void {
        try self.list.append(elem);
    }
};

pub fn splitScalar(gpa: std.mem.Allocator, buf: []const u8, delimiter: u8) ![][]const u8 {
    var array = std.array_list.Managed([]const u8).init(gpa);
    var iter = std.mem.splitScalar(u8, buf, delimiter);

    while (iter.next()) |part| {
        try array.append(part);
    }
    return array.toOwnedSlice();
}

// test "string list internal arena" {
//     var sl = StringList.init(std.testing.allocator);
//     const alloc = sl.arena.allocator();
//     var i: usize = 0;
//     while (i < 10) : (i += 1) {
//         try sl.append(try alloc.alloc(u8, 10));
//     }
//
//     try std.testing.expectEqual(10, sl.size());
// }

test "splitScalar" {
    const gpa = std.testing.allocator;
    const out1 = try splitScalar(gpa, "hello world", ' ');
    defer gpa.free(out1);

    try std.testing.expectEqualSlices(u8, "hello", out1[0]);
    try std.testing.expectEqualSlices(u8, "world", out1[1]);
}
