const std = @import("std");

pub const fs = @import("fs.zig");
pub const fmt = @import("fmt.zig");
pub const vec = @import("vec.zig");
pub const grid = @import("grid.zig");
pub const graph = @import("graph.zig");

pub const Grid = grid.Grid;
pub const V2 = vec.V2;
pub const V2u = vec.V2u;
pub const V2i = vec.V2i;

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

/// Add up the values of a slice
pub fn sum(comptime T: type, slice: []const T) T {
    var s: T = 0;
    for (slice) |el| s += el;
    return s;
}

pub fn countNonzero(comptime T: type, slice: []const T) usize {
    var s: usize = 0;
    for (slice) |el| s += if (el != 0) 1 else 0;
    return s;
}

pub fn indexOf2DScalar(comptime T: type, haystack: []const []const T, needle: T) ?vec.V2u {
    for (haystack, 0..) |row, y| {
        if (std.mem.indexOfScalar(T, row, needle)) |x| {
            return .{ .x = x, .y = y };
        }
    }
    return null;
}

// Math

pub fn min(comptime T: type, a: T, b: T) T {
    return if (a < b) a else b;
}

pub fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

pub fn abs(comptime T: type, a: T) T {
    return if (a >= 0) a else -a;
}

pub fn between(comptime T: type, v: T, low: T, high: T) bool {
    return v >= low and v < high;
}

// parsing

pub fn makeIntParser(comptime T: type, comptime O: type, base: usize, backup: O) type {
    return struct {
        pub fn parse(v: T) O {
            const tmp = [1]u8{v};
            return std.fmt.parseInt(O, &tmp, base) catch backup;
        }
    };
}

test "sum" {
    const a = [_]u8{ 1, 2, 3, 4 };
    try std.testing.expectEqual(10, sum(u8, &a));

    const b = [_]i32{ -1, 2, 3, -4 };
    try std.testing.expectEqual(0, sum(i32, &b));
}

test "countNonzero" {
    const a = [_]i8{ 0, 1, -3, 0 };
    try std.testing.expectEqual(2, countNonzero(i8, &a));
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

test {
    std.testing.refAllDecls(@This());
}
