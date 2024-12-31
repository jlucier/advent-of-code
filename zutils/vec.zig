const std = @import("std");
const zutils = @import("zutils.zig");

pub const V2i = V2(isize);
pub const V2u = V2(usize);

pub fn V2(comptime T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,

        pub const ValueT = T;
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
                .Int => @floatFromInt(tmp),
                .Float => tmp,
                else => @compileError("V2 type needs to be numeric"),
            };
            return std.math.sqrt(f);
        }

        ///Return the distance this vector represents in "Manhattan Distance"
        pub fn manhattanMag(self: *const Self) T {
            const res = @abs(self.x) + @abs(self.y);
            return switch (@typeInfo(T)) {
                .Int => @intCast(res),
                .Float => @floatCast(res),
                else => @compileError("V2 type needs to be numeric"),
            };
        }

        pub fn unit(self: *const Self, comptime FT: type) V2(FT) {
            const tinfo = @typeInfo(T);
            const x: FT = switch (tinfo) {
                .Int => @floatFromInt(self.x),
                .Float => self.x,
                else => @compileError("V2 type needs to be numeric"),
            };
            const y: FT = switch (tinfo) {
                .Int => @floatFromInt(self.y),
                .Float => self.y,
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
                .Int => {
                    return switch (ot) {
                        .Int => @intCast(v),
                        .Float => @floatFromInt(v),
                        else => @compileError("V2 type needs to be numeric"),
                    };
                },
                .Float => {
                    return switch (ot) {
                        .Int => @intFromFloat(v),
                        .Float => @floatCast(v),
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

test "V2 astype" {
    const v = V2(usize){ .x = 1, .y = 0 };

    try std.testing.expect(v.equal(v.asType(isize).asType(usize)));
}
