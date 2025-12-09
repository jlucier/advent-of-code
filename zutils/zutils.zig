const std = @import("std");

pub const fs = @import("fs.zig");
pub const fmt = @import("fmt.zig");
pub const vec = @import("vec.zig");
pub const grid = @import("grid.zig");
pub const graph = @import("graph.zig");
pub const str = @import("str.zig");

pub const Grid = grid.Grid;
pub const V2 = vec.V2;
pub const V2u = vec.V2u;
pub const V2i = vec.V2i;
pub const StringList = str.StringList;

pub fn Range(comptime T: type) type {
    return struct {
        begin: T,
        end: T,

        const Self = @This();

        pub fn contains(self: *const Self, other: *const Self) bool {
            return self.begin <= other.begin and self.end >= other.end;
        }

        pub fn containsScalar(self: *const Self, v: T) bool {
            return self.begin <= v and self.end >= v;
        }

        pub fn overlaps(self: *const Self, other: *const Self) bool {
            return self.contains(other) or (self.begin >= other.begin and self.begin <= other.end) //
            or (self.end >= other.begin and self.end <= other.end);
        }
    };
}

/// Add up the values of a slice
pub fn sum(comptime T: type, slice: []const T) T {
    var s: T = 0;
    for (slice) |el| s += el;
    return s;
}

pub fn mul(comptime T: type, slice: []const T) T {
    var s: T = 1;
    for (slice) |el| s *= el;
    return s;
}

pub fn factorial(comptime T: type, n: T) T {
    var v: T = n;
    for (1..n) |i| {
        const vi: T = @intCast(i);
        v *= n - vi;
    }
    return v;
}

// Combinations of n choose k
pub fn combinations(comptime T: type, n: T, k: T) T {
    if (n < k) return 0;
    var num: T = n;
    for (1..k) |i| {
        const v: T = @intCast(i);
        num *= n - v;
    }
    return num / factorial(T, k);
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

test "combinations" {
    try std.testing.expectEqual(3, combinations(u8, 3, 2));
    try std.testing.expectEqual(2_598_960, combinations(usize, 52, 5));
}

test "countNonzero" {
    const a = [_]i8{ 0, 1, -3, 0 };
    try std.testing.expectEqual(2, countNonzero(i8, &a));
}

test {
    std.testing.refAllDecls(@This());
}
