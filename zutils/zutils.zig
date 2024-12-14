const std = @import("std");

pub const ANSI_RED = "\u{001b}[31m";
pub const ANSI_GREEN = "\u{001b}[32m";
pub const ANSI_RESET = "\u{001b}[m";

pub fn printRed(s: []const u8) void {
    return std.debug.print("{s}{s}{s}", .{ ANSI_RED, s, ANSI_RESET });
}

// FS

/// Expand the ~ in a pathname to the users home dir. Caller owns the returned path string
pub fn expandHomeDir(allocator: std.mem.Allocator, pathname: []const u8) ![]u8 {
    if (pathname[0] == '~' and (pathname.len == 1 or pathname[1] == '/')) {
        const home = std.posix.getenv("HOME") orelse "";
        const tmp = [_][]const u8{ home, pathname[1..] };
        return std.mem.concat(allocator, u8, &tmp);
    }

    return allocator.dupe(u8, pathname);
}

pub const StringList = struct {
    strings: std.ArrayList([]u8),

    pub fn init(alloc: std.mem.Allocator) StringList {
        return StringList{ .strings = std.ArrayList([]u8).init(alloc) };
    }

    pub fn deinit(self: *const StringList) void {
        for (self.strings.items) |s| {
            self.strings.allocator.free(s);
        }
        self.strings.deinit();
    }

    pub fn size(self: *const StringList) usize {
        return self.strings.items.len;
    }
};

/// Open a file using a path that may need expanding. File is callers to manage
pub fn openFile(allocator: std.mem.Allocator, pathname: []const u8, flags: std.fs.File.OpenFlags) !std.fs.File {
    const path = try expandHomeDir(allocator, pathname);
    defer allocator.free(path);
    return std.fs.openFileAbsolute(path, flags);
}

/// Read lines of a file. ArrayList and strings inside are owned by caller
pub fn readLines(allocator: std.mem.Allocator, pathname: []const u8) !StringList {
    const file = try openFile(allocator, pathname, .{ .mode = .read_only });
    defer file.close();
    const reader = file.reader();

    var ll = StringList.init(allocator);
    while (true) {
        const ln = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1_000_000);

        if (ln) |l| {
            try ll.strings.append(l);
        } else {
            break;
        }
    }

    return ll;
}

// Slices

/// Returns a StringList for the caller to own
pub fn splitIntoList(allocator: std.mem.Allocator, str: []const u8, delimiter: []const u8) !StringList {
    var parts = StringList.init(allocator);

    var iter = std.mem.splitSequence(u8, str, delimiter);

    while (iter.next()) |part| {
        try parts.strings.append(try allocator.dupe(u8, part));
    }

    return parts;
}

pub fn splitLines(allocator: std.mem.Allocator, str: []const u8) !StringList {
    return splitIntoList(allocator, str, "\n");
}

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

pub fn indexOf2DScalar(comptime T: type, haystack: []const []const T, needle: T) ?V2(usize) {
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

// Grid

pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        nrows: usize,
        ncols: usize,
        data: []T,

        const Iterator = struct {
            curr: V2(usize),
            ncols: usize,
            nrows: usize,

            pub fn next(self: *@This()) ?V2(usize) {
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

        pub fn at(self: *const Self, row: usize, col: usize) T {
            return self.data[row * self.ncols + col];
        }

        pub fn atPtr(self: *Self, row: usize, col: usize) *T {
            return &self.data[row * self.ncols + col];
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
            std.debug.print("<Grid({}) {d}x{d}\n", .{ T, self.nrows, self.ncols });
            var i: usize = 0;
            while (i < self.nrows) : (i += 1) {
                var j: usize = 0;
                std.debug.print("  ", .{});
                while (j < self.ncols) : (j += 1) {
                    std.debug.print("{}{s}", .{ self.at(i, j), if (j + 1 >= self.ncols) "" else " " });
                }
                std.debug.print("\n", .{});
            }
            std.debug.print(">\n", .{});
        }
    };
}

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

        pub fn neighbors(self: *const Self) [4]V2(T) {
            return .{
                // left
                self.add(.{ .x = -1 }),
                // right
                self.add(.{ .x = 1 }),
                // up
                self.add(.{ .y = -1 }),
                // down
                self.add(.{ .y = 1 }),
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
            return between(T, self.x, 0, x) and between(T, self.y, 0, y);
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
    };
}

// TESTS

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

    try std.testing.expect(std.mem.eql(u8, ll.strings.items[0], "1000"));
    try std.testing.expect(std.mem.eql(u8, ll.strings.items[1], "2000"));
    try std.testing.expect(std.mem.eql(u8, ll.strings.items[2], "3000"));
    try std.testing.expect(std.mem.eql(u8, ll.strings.items[3], ""));
    try std.testing.expect(std.mem.eql(u8, ll.strings.items[4], "4000"));
}

test "splitIntoList" {
    const list = try splitIntoList(std.testing.allocator, "testing-123", "-");
    defer list.deinit();

    try std.testing.expectEqual(2, list.size());
    try std.testing.expect(std.mem.eql(u8, list.strings.items[0], "testing"));
    try std.testing.expect(std.mem.eql(u8, list.strings.items[1], "123"));
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
