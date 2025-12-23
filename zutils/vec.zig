const std = @import("std");
const zutils = @import("zutils.zig");

pub const V2i = V2(isize);
pub const V2u = V2(usize);

fn toSigned(comptime T: type) type {
    const tinfo = @typeInfo(T);
    return switch (tinfo) {
        .int => {
            if (tinfo.int.signedness == .signed) {
                return T;
            }
            var signed = tinfo;
            signed.int.signedness = .signed;
            return @Type(signed);
        },
        .float => T,
        else => @compileError("V2 type needs to be numeric"),
    };
}

pub fn Vec(comptime T: type, comptime n: usize) type {
    return struct {
        data: [n]T,

        const Self = @This();
        pub const ValueT = T;

        pub fn x(self: *const Self) T {
            std.debug.assert(self.data.len > 0);
            return self.data[0];
        }

        pub fn y(self: *const Self) T {
            std.debug.assert(self.data.len > 1);
            return self.data[1];
        }

        pub fn z(self: *const Self) T {
            std.debug.assert(self.data.len > 2);
            return self.data[1];
        }

        pub fn add(self: *const Self, other: Self) Self {
            var new = Self{ .data = self.data };
            new.addMut(other);
            return new;
        }

        pub fn addMut(self: *Self, other: Self) void {
            for (&self.data, 0..) |*d, i| {
                d.* += other.data[i];
            }
        }

        pub fn sub(self: *const Self, other: Self) Self {
            var new = Self{ .data = self.data };
            new.subMut(other);
            return new;
        }

        pub fn subMut(self: *Self, other: Self) void {
            for (&self.data, 0..) |*d, i| {
                d.* -= other.data[i];
            }
        }

        pub fn dot(self: *const Self, other: Self) T {
            var ret: T = 0;
            for (self.data, 0..) |d, i| {
                ret += d * other.data[i];
            }
            return ret;
        }

        pub fn mul(self: *const Self, v: T) Self {
            var newData: [n]T = undefined;
            for (self.data, 0..) |d, i| {
                newData[i] = d * v;
            }
            return .{ .data = newData };
        }

        pub fn mag(self: *const Self, comptime FT: type) FT {
            var tmp: T = 0;
            for (self.data) |d| {
                tmp += d * d;
            }
            const f: FT = switch (@typeInfo(T)) {
                .int => @floatFromInt(tmp),
                .float => tmp,
                else => @compileError("V2 type needs to be numeric"),
            };
            return std.math.sqrt(f);
        }

        pub fn equal(self: *const Self, other: Self) bool {
            return std.mem.eql(T, &self.data, &other.data);
        }
    };
}

pub fn V2(comptime T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,

        pub const ValueT = T;
        const SignedT = toSigned(T);
        const Self = @This();

        pub fn clone(self: *const Self) Self {
            return .{ .x = self.x, .y = self.y };
        }

        pub fn xComp(self: *const Self) Self {
            return .{ .x = self.x };
        }
        pub fn yComp(self: *const Self) Self {
            return .{ .y = self.y };
        }

        pub fn add(self: *const Self, other: Self) Self {
            var new = Self{ .x = self.x, .y = self.y };
            new.addMut(other);
            return new;
        }

        pub fn addMut(self: *Self, other: Self) void {
            self.x += other.x;
            self.y += other.y;
        }

        pub fn sub(self: *const Self, other: Self) Self {
            var new = Self{ .x = self.x, .y = self.y };
            new.subMut(other);
            return new;
        }

        pub fn subMut(self: *Self, other: Self) void {
            self.x -= other.x;
            self.y -= other.y;
        }

        pub fn dot(self: *const Self, other: Self) T {
            return self.x * other.x + self.y * other.y;
        }

        pub fn mul(self: *const Self, v: T) Self {
            return .{
                .x = self.x * v,
                .y = self.y * v,
            };
        }

        pub fn mag(self: *const Self, comptime FT: type) FT {
            const tmp = self.x * self.x + self.y * self.y;
            const f: FT = switch (@typeInfo(T)) {
                .int => @floatFromInt(tmp),
                .float => tmp,
                else => @compileError("V2 type needs to be numeric"),
            };
            return std.math.sqrt(f);
        }

        ///Return the distance this vector represents in "Manhattan Distance"
        pub fn manhattanMag(self: *const Self) T {
            const res = @abs(self.x) + @abs(self.y);
            return switch (@typeInfo(T)) {
                .int => @intCast(res),
                .float => @floatCast(res),
                else => @compileError("V2 type needs to be numeric"),
            };
        }

        pub fn unit(self: *const Self, comptime FT: type) V2(FT) {
            const tinfo = @typeInfo(T);
            const x: FT = switch (tinfo) {
                .int => @floatFromInt(self.x),
                .float => self.x,
                else => @compileError("V2 type needs to be numeric"),
            };
            const y: FT = switch (tinfo) {
                .int => @floatFromInt(self.y),
                .float => self.y,
                else => @compileError("V2 type needs to be numeric"),
            };
            const m = self.mag(FT);
            return V2(FT){
                .x = x / m,
                .y = y / m,
            };
        }

        /// Rotate the vector 90 clockwise, without the trig
        pub fn rotateClockwise(self: *const Self) Self {
            return .{
                .x = self.y,
                .y = -self.x,
            };
        }

        pub fn rotateCounterClockwise(self: *const Self) Self {
            return .{
                .x = -self.y,
                .y = self.x,
            };
        }

        pub fn asSigned(self: *const Self) V2(SignedT) {
            return self.asType(SignedT);
        }

        pub fn asType(self: *const Self, comptime OT: type) V2(OT) {
            return V2(OT){
                .x = Self.myTypeToOther(OT, self.x),
                .y = Self.myTypeToOther(OT, self.y),
            };
        }

        pub fn equal(self: *const Self, other: Self) bool {
            return self.x == other.x and self.y == other.y;
        }

        /// Return whether the vector is inside the bounds of a grid ranging
        /// from 0,x and 0,y
        pub fn inGridBounds(self: *const Self, x: T, y: T) bool {
            return zutils.between(T, self.x, 0, x) and zutils.between(T, self.y, 0, y);
        }

        pub fn print(self: *const Self) void {
            std.debug.print("<V2 {d},{d}>\n", .{ self.x, self.y });
        }

        fn myTypeToOther(comptime O: type, v: T) O {
            const ot = @typeInfo(O);
            return switch (@typeInfo(T)) {
                .int => {
                    return switch (ot) {
                        .int => @intCast(v),
                        .float => @floatFromInt(v),
                        else => @compileError("V2 type needs to be numeric"),
                    };
                },
                .float => {
                    return switch (ot) {
                        .int => @intFromFloat(v),
                        .float => @floatCast(v),
                        else => @compileError("V2 type needs to be numeric"),
                    };
                },
                else => @compileError("V2 type needs to be numeric"),
            };
        }

        const NeighborIterator = struct {
            v: Self,
            i: usize = 0,
            nrows: usize,
            ncols: usize,

            pub fn next(self: *NeighborIterator) ?Self {
                while (self.i < 4) {
                    var next_v: ?Self = null;

                    // this logic is implmented in a way that should work and be safe regardless
                    // of whether the T is signed or unsigned
                    switch (self.i) {
                        0 => {
                            if (self.v.x >= 1) {
                                next_v = .{ .x = self.v.x - 1, .y = self.v.y };
                            }
                        },
                        1 => {
                            if (self.v.x + 1 < self.ncols) {
                                next_v = .{ .x = self.v.x + 1, .y = self.v.y };
                            }
                        },
                        2 => {
                            if (self.v.y >= 1) {
                                next_v = .{ .x = self.v.x, .y = self.v.y - 1 };
                            }
                        },
                        3 => {
                            if (self.v.y + 1 < self.nrows) {
                                next_v = .{ .x = self.v.x, .y = self.v.y + 1 };
                            }
                        },
                        else => unreachable,
                    }

                    self.i += 1;
                    if (next_v) |ret| {
                        return ret;
                    }
                }
                return null;
            }
        };

        /// Return all four cardinal direction neighbors of the vector, no checking
        /// for bounds / overflows
        pub fn neighbors(self: *const Self) [4]Self {
            return .{
                // left
                .{ .x = self.x - 1, .y = self.y },
                // right
                .{ .x = self.x + 1, .y = self.y },
                // up
                .{ .x = self.x, .y = self.y - 1 },
                // down
                .{ .x = self.x, .y = self.y + 1 },
            };
        }

        /// Returns an iterator over neighbors in grid bounds
        pub fn iterNeighborsInGridBounds(
            self: *const Self,
            ncols: usize,
            nrows: usize,
        ) NeighborIterator {
            return .{
                .v = self.*,
                .nrows = nrows,
                .ncols = ncols,
            };
        }
    };
}

fn EdgeIter(comptime T: type) type {
    return struct {
        poly: []const V2(T),
        i: usize = 0,

        pub fn reset(self: *@This()) void {
            self.i = 0;
        }

        pub fn next(self: *@This()) ?[2]*const V2(T) {
            if (self.i >= self.poly.len) {
                return null;
            }
            const i = self.i;
            self.i += 1;
            return .{
                &self.poly[i],
                &self.poly[if (i > 0) i - 1 else self.poly.len - 1],
            };
        }
    };
}

fn pointOnEdge(comptime T: type, e: [2]*const V2(T), point: V2(T)) bool {
    const lx = @min(e[0].x, e[1].x);
    const hx = @max(e[0].x, e[1].x);
    const ly = @min(e[0].y, e[1].y);
    const hy = @max(e[0].y, e[1].y);

    return point.x >= lx and point.x <= hx and point.y >= ly and point.y <= hy;
}

pub fn pointInPoly(comptime T: type, poly: []const V2(T), point: V2(T)) bool {
    var iter = EdgeIter(T){ .poly = poly };

    // check if point lies on actual edge
    while (iter.next()) |e| {
        if (pointOnEdge(T, e, point)) {
            return true;
        }
    }

    var cross: usize = 0;
    const upper: usize = @intCast(point.x + 1);
    var x: usize = 0;
    while (x < upper) {
        iter.reset();

        while (iter.next()) |e| {
            if (e[1].y <= point.y) continue;

            if (pointOnEdge(T, e, .{ .x = @intCast(x), .y = point.y })) {
                cross += 1;
                continue;
            }
        }

        // find next x
        var nextX: usize = std.math.maxInt(usize);
        iter.reset();
        while (iter.next()) |e| {
            const lx = @min(e[0].x, e[1].x);
            if (lx <= x) continue;

            nextX = @intCast(@min(lx, nextX));
        }
        x = nextX;
    }
    return cross % 2 == 1;
}

pub fn quadInPoly(comptime T: type, poly: []const V2(T), p1: V2(T), p2: V2(T)) bool {
    return pointInPoly(T, poly, p1) and pointInPoly(T, poly, p2) //
    and pointInPoly(T, poly, .{ .x = p1.x, .y = p2.y }) //
    and pointInPoly(T, poly, .{ .x = p2.x, .y = p1.y });
}

test "V2" {
    const v = V2(i8){ .x = 1, .y = 1 };
    const a = v.add(.{ .x = 2, .y = 3 });
    const s = v.sub(.{ .x = 2, .y = 3 });
    const d = a.dot(.{ .x = 1, .y = 2 });

    try std.testing.expectApproxEqAbs(std.math.sqrt2, v.mag(f32), 0.001);
    try std.testing.expect(a.equal(.{ .x = 3, .y = 4 }));
    try std.testing.expect(s.equal(.{ .x = -1, .y = -2 }));
    try std.testing.expect(v.unit(f32).equal(.{ .x = std.math.sqrt1_2, .y = std.math.sqrt1_2 }));
    try std.testing.expectEqual(11, d);
}

test "Vec" {
    const V3 = Vec(f32, 3);
    const a = V3{ .data = .{ 0, 1, 0 } };
    const b = V3{ .data = .{ 0, 0, 1 } };

    try std.testing.expect(a.equal(a));
    try std.testing.expect(!a.equal(b));
    try std.testing.expect(a.add(b).equal(.{ .data = .{ 0, 1, 1 } }));
    try std.testing.expect(a.sub(b).equal(.{ .data = .{ 0, 1, -1 } }));
    try std.testing.expectEqual(0, a.dot(b));
    try std.testing.expectApproxEqAbs(std.math.sqrt2, a.add(b).mag(f32), 0.001);
}

test "V2 astype" {
    const v = V2(usize){ .x = 1, .y = 0 };

    try std.testing.expect(v.equal(v.asType(isize).asType(usize)));
}

const testPoly = [_]V2u{
    .{ .x = 7, .y = 1 },
    .{ .x = 11, .y = 1 },
    .{ .x = 11, .y = 7 },
    .{ .x = 9, .y = 7 },
    .{ .x = 9, .y = 5 },
    .{ .x = 2, .y = 5 },
    .{ .x = 2, .y = 3 },
    .{ .x = 7, .y = 3 },
};

test "pointInPoly" {
    // endpoints
    try std.testing.expect(pointInPoly(usize, &testPoly, .{ .x = 9, .y = 5 }));
    try std.testing.expect(pointInPoly(usize, &testPoly, .{ .x = 2, .y = 3 }));
    // other
    try std.testing.expect(pointInPoly(usize, &testPoly, .{ .x = 2, .y = 5 }));
    try std.testing.expect(pointInPoly(usize, &testPoly, .{ .x = 9, .y = 3 }));
}

test "quadInPoly" {
    try std.testing.expect(quadInPoly(
        usize,
        &testPoly,
        .{ .x = 9, .y = 5 },
        .{ .x = 2, .y = 3 },
    ));
}
