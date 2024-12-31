const std = @import("std");
const vec = @import("vec.zig");
const fmt = @import("fmt.zig");

pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
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

        pub fn init(allocator: std.mem.Allocator, rows: usize, cols: usize) !Self {
            return .{
                .allocator = allocator,
                .nrows = rows,
                .ncols = cols,
                .data = try allocator.alloc(T, rows * cols),
            };
        }

        pub fn init2DSlice(allocator: std.mem.Allocator, sl: []const []const T) !Self {
            var g = try Self.init(allocator, sl.len, sl[0].len);
            for (sl, 0..) |row, i| {
                for (row, 0..) |v, j| {
                    g.atPtr(i, j).* = v;
                }
            }
            return g;
        }

        pub fn init2DSliceWithParser(
            comptime OT: type,
            allocator: std.mem.Allocator,
            sl: []const []const OT,
            comptime parser: fn (v: OT) T,
        ) !Self {
            var g = try Self.init(allocator, sl.len, sl[0].len);
            for (sl, 0..) |row, i| {
                for (row, 0..) |v, j| {
                    g.atPtr(i, j).* = parser(v);
                }
            }
            return g;
        }

        pub fn deinit(self: *const Self) void {
            self.allocator.free(self.data);
        }

        pub fn clone(self: *const Self) !Self {
            return .{
                .allocator = self.allocator,
                .data = try self.allocator.dupe(T, self.data),
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
            const swap = try self.allocator.alloc(T, self.ncols);
            defer self.allocator.free(swap);

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
