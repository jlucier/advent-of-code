const std = @import("std");
const vec = @import("vec.zig");
const fmt = @import("fmt.zig");

pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();

        gpa: std.mem.Allocator,
        nrows: usize,
        ncols: usize,
        data: []T,

        const Iterator = struct {
            curr: vec.V2u,
            ncols: usize,
            nrows: usize,

            pub fn next(self: *@This()) ?vec.V2u {
                const ret = self.curr;
                self.curr.x += 1;
                if (self.curr.x >= self.ncols) {
                    self.curr.x = 0;
                    self.curr.y += 1;
                }
                if (ret.y >= self.nrows) {
                    return null;
                }
                return ret;
            }
        };

        pub const NeighborType = enum {
            cardinal,
            diagonal,
            all,
        };

        const NeighborIterator = struct {
            positions: [8]vec.V2u = undefined,
            curr: usize = 0,
            total: usize = 0,

            pub fn next(self: *@This()) ?vec.V2u {
                if (self.curr >= self.total) return null;
                const res = self.positions[self.curr];
                self.curr += 1;
                return res;
            }
        };

        pub fn init(gpa: std.mem.Allocator, rows: usize, cols: usize) !Self {
            return .{
                .gpa = gpa,
                .nrows = rows,
                .ncols = cols,
                .data = try gpa.alloc(T, rows * cols),
            };
        }

        pub fn init2DSlice(gpa: std.mem.Allocator, sl: []const []const T) !Self {
            var g = try Self.init(gpa, sl.len, sl[0].len);
            for (sl, 0..) |row, i| {
                for (row, 0..) |v, j| {
                    g.atPtr(i, j).* = v;
                }
            }
            return g;
        }

        pub fn init2DSliceWithParser(
            comptime OT: type,
            gpa: std.mem.Allocator,
            sl: []const []const OT,
            comptime parser: fn (v: OT) T,
        ) !Self {
            var g = try Self.init(gpa, sl.len, sl[0].len);
            for (sl, 0..) |row, i| {
                for (row, 0..) |v, j| {
                    g.atPtr(i, j).* = parser(v);
                }
            }
            return g;
        }

        pub fn initFromVectors(
            comptime VT: type,
            gpa: std.mem.Allocator,
            vecs: []const vec.V2(VT),
            present: T,
            empty: T,
        ) !Self {
            var sx: usize = 0;
            var sy: usize = 0;
            for (vecs) |v| {
                sx = @max(sx, v.x);
                sy = @max(sy, v.y);
            }

            var g = try Self.init(gpa, sy + 1, sx + 1);
            g.fill(empty);
            for (vecs) |v| {
                g.atPtrV(v.asType(usize)).* = present;
            }
            return g;
        }

        pub fn deinit(self: *const Self) void {
            self.gpa.free(self.data);
        }

        pub fn clone(self: *const Self) !Self {
            return .{
                .gpa = self.gpa,
                .data = try self.gpa.dupe(T, self.data),
                .nrows = self.nrows,
                .ncols = self.ncols,
            };
        }

        pub fn fill(self: *Self, v: T) void {
            for (self.data) |*it| {
                it.* = v;
            }
        }

        /// Swap the Y Axis
        pub fn transposeY(self: *Self) !void {
            const swap = try self.gpa.alloc(T, self.ncols);
            defer self.gpa.free(swap);

            var i: usize = 0;
            while (i < self.nrows / 2) : (i += 1) {
                const row_i = self.data[i * self.ncols .. (i + 1) * self.ncols];
                const row_ni = self.data[(self.nrows - i - 1) * self.ncols .. (self.nrows - i) * self.ncols];
                // copy row i to swap
                std.mem.copyForwards(T, swap, row_i);
                // copy row (nrows - i) to row i
                std.mem.copyForwards(T, row_i, row_ni);
                // swap to ni
                std.mem.copyForwards(T, row_ni, swap);
            }
        }

        pub fn dataIdx(self: *const Self, row: usize, col: usize) usize {
            return row * self.ncols + col;
        }

        pub fn dataIdxV(self: *const Self, v: vec.V2u) usize {
            return self.dataIdx(v.y, v.x);
        }

        pub fn at(self: *const Self, row: usize, col: usize) T {
            return self.data[self.dataIdx(row, col)];
        }

        pub fn atPtr(self: *Self, row: usize, col: usize) *T {
            return &self.data[self.dataIdx(row, col)];
        }

        pub fn atV(self: *const Self, v: vec.V2u) T {
            return self.at(v.y, v.x);
        }

        pub fn atPtrV(self: *Self, v: vec.V2u) *T {
            return self.atPtr(v.y, v.x);
        }

        pub fn inBounds(self: *const Self, x: anytype, y: anytype) bool {
            return x >= 0 and x < self.ncols and y >= 0 and y < self.nrows;
        }

        pub fn iterator(self: *const Self) Iterator {
            return Iterator{
                .curr = .{},
                .ncols = self.ncols,
                .nrows = self.nrows,
            };
        }

        pub fn neighbors(self: *const Self, loc: vec.V2u, typ: NeighborType) NeighborIterator {
            var nbors = NeighborIterator{};
            const iy: isize = @intCast(loc.y);
            const ix: isize = @intCast(loc.x);
            const steps = [3]isize{ -1, 0, 1 };

            for (steps) |sy| {
                const y = iy + sy;

                for (steps) |sx| {
                    const x = ix + sx;

                    if ((x == ix and y == iy) or !self.inBounds(x, y)) {
                        continue;
                    }

                    const thisType = if (x != ix and y != iy) NeighborType.diagonal //
                    else NeighborType.cardinal;
                    if (typ != .all and typ != thisType) {
                        continue;
                    }

                    nbors.positions[nbors.total] = .{ .x = @intCast(x), .y = @intCast(y) };
                    nbors.total += 1;
                }
            }
            return nbors;
        }

        pub fn print(self: *const Self) void {
            self.printHl(null);
        }

        pub fn printHl(self: *const Self, highlight: ?[]const vec.V2u) void {
            std.debug.print("<Grid({}) {d}x{d}\n", .{ T, self.nrows, self.ncols });
            var i: usize = 0;
            while (i < self.nrows) : (i += 1) {
                var j: usize = 0;
                if (T == u8 and (highlight == null or highlight.?.len == 0)) {
                    std.debug.print(
                        "  {s} ({d})\n",
                        .{ self.data[i * self.ncols .. (i + 1) * self.ncols], i },
                    );
                } else {
                    std.debug.print("  ", .{});
                    while (j < self.ncols) : (j += 1) {
                        var color: []const u8 = "";
                        var reset: []const u8 = "";
                        if (highlight) |hl| {
                            for (hl) |v| {
                                if (v.x == j and v.y == i) {
                                    color = fmt.ANSI_RED;
                                    reset = fmt.ANSI_RESET;
                                    break;
                                }
                            }
                        }

                        if (T == u8) {
                            std.debug.print(
                                "{s}{c}{s}",
                                .{ color, self.at(i, j), reset },
                            );
                        } else {
                            std.debug.print(
                                "{s}{}{s}{s}",
                                .{
                                    color,
                                    self.at(i, j),
                                    reset,
                                    if (j + 1 >= self.ncols) "" else " ",
                                },
                            );
                        }
                    }
                    std.debug.print("  ({d})\n", .{i});
                }
            }
            std.debug.print(">\n", .{});
        }
    };
}

test "grid bounds" {
    const g = try Grid(u8).init(std.testing.allocator, 5, 5);
    defer g.deinit();

    try std.testing.expect(!g.inBounds(6, 5));
    try std.testing.expect(!g.inBounds(-1, 0));
    try std.testing.expect(!g.inBounds(0, 6));
    try std.testing.expect(!g.inBounds(0, -6));
}

test "grid reverse" {
    const sl = [_][]const u8{
        "#.",
        ".#",
        ".#",
    };
    var g = try Grid(u8).init2DSlice(std.testing.allocator, &sl);
    defer g.deinit();

    try std.testing.expectEqual('#', g.at(0, 0));
    try std.testing.expectEqual('.', g.at(0, 1));
    try std.testing.expectEqual('#', g.at(2, 1));

    try g.transposeY();

    try std.testing.expectEqual('.', g.at(0, 0));
    try std.testing.expectEqual('.', g.at(1, 0));
    try std.testing.expectEqual('#', g.at(1, 1));
    try std.testing.expectEqual('#', g.at(2, 0));
}

test "grid iterator" {
    const g = try Grid(u8).init(std.testing.allocator, 5, 5);
    defer g.deinit();

    var x: usize = 0;
    var y: usize = 0;
    const maxIter = g.ncols * g.nrows;
    var i: usize = 0;
    var iter = g.iterator();
    while (iter.next()) |v| {
        try std.testing.expect(v.equal(.{ .x = x, .y = y }));

        if (x + 1 == g.ncols) {
            y += 1;
        }
        x = (x + 1) % g.ncols;

        i += 1;
        try std.testing.expect(maxIter >= i);
    }
    try std.testing.expectEqual(maxIter, i);
}

const TestNeighborResult = struct {
    positions: [8]vec.V2u = undefined,
    n: usize = 0,
};

fn exhaustNeighbors(nbors: anytype) TestNeighborResult {
    var res = TestNeighborResult{};
    while (nbors.next()) |nb| {
        res.positions[res.n] = nb;
        res.n += 1;
    }
    return res;
}

test "grid neighbors" {
    const g = try Grid(u8).init(std.testing.allocator, 5, 5);
    defer g.deinit();

    // center point with all 8 neighbors
    var iter = g.neighbors(.{ .x = 2, .y = 2 }, .all);
    const nbors = exhaustNeighbors(&iter);
    try std.testing.expectEqual(8, nbors.n);

    var iter2 = g.neighbors(.{ .x = 0, .y = 0 }, .all);
    const nbors2 = exhaustNeighbors(&iter2);
    try std.testing.expectEqual(3, nbors2.n);

    var iter3 = g.neighbors(.{ .x = 0, .y = 0 }, .cardinal);
    const nbors3 = exhaustNeighbors(&iter3);
    try std.testing.expectEqual(2, nbors3.n);
    try std.testing.expect(nbors3.positions[0].equal(.{ .x = 1, .y = 0 }));
    try std.testing.expect(nbors3.positions[1].equal(.{ .x = 0, .y = 1 }));

    var iter4 = g.neighbors(.{ .x = 0, .y = 0 }, .diagonal);
    const nbors4 = exhaustNeighbors(&iter4);
    try std.testing.expectEqual(1, nbors4.n);
    try std.testing.expect(nbors4.positions[0].equal(.{ .x = 1, .y = 1 }));
}
