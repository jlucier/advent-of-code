const std = @import("std");

pub const fs = @import("fs.zig");
pub const fmt = @import("fmt.zig");
pub const vec = @import("vec.zig");
pub const mat = @import("mat.zig");
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

        pub fn fromUnsorted(a: T, b: T) Self {
            return .{
                .begin = @min(a, b),
                .end = @max(a, b),
            };
        }

        pub fn contains(self: *const Self, other: Self) bool {
            return self.begin <= other.begin and self.end >= other.end;
        }

        pub fn containsScalar(self: *const Self, v: T) bool {
            return self.begin <= v and self.end >= v;
        }

        pub fn overlaps(self: *const Self, other: Self) bool {
            return self.contains(other) //
            or between(T, self.begin, other.begin, other.end + 1) //
            or between(T, self.end, other.begin, other.end + 1);
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

fn transitiveOverlap(a: Range(u8), b: Range(u8)) !void {
    try std.testing.expect(a.overlaps(b));
    try std.testing.expect(b.overlaps(a));
}

test "Range" {
    const a = Range(u8){ .begin = 0, .end = 10 };
    const b = Range(u8){ .begin = 2, .end = 8 };
    const c = Range(u8){ .begin = 1, .end = 2 };
    const d = Range(u8){ .begin = 8, .end = 8 };

    try std.testing.expect(a.contains(b));
    try std.testing.expect(!b.contains(a));
    try transitiveOverlap(a, b);

    try std.testing.expect(a.overlaps(a));
    try std.testing.expect(c.overlaps(c));
    try std.testing.expect(d.overlaps(d));
    try transitiveOverlap(a, c);
    try transitiveOverlap(a, d);
    try transitiveOverlap(b, c);
    try transitiveOverlap(b, d);
}

test {
    std.testing.refAllDecls(@This());
}
