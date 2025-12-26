const std = @import("std");

pub const MatrixXi = Matrix(isize);
pub const MatrixXf = Matrix(f64);

pub fn MatrixCi(comptime M: usize, comptime N: usize) type {
    return MatrixC(isize, M, N);
}

pub fn MatrixCf(comptime M: usize, comptime N: usize) type {
    return MatrixC(isize, M, N);
}

fn matAt(comptime T: type, data: []const T, N: usize, r: usize, c: usize) T {
    return data[r * N + c];
}

fn matAtPtr(comptime T: type, data: []T, N: usize, r: usize, c: usize) *T {
    return &data[r * N + c];
}

fn matRow(comptime T: type, data: []T, M: usize, N: usize, r: usize) []T {
    std.debug.assert(r < M);
    const st = r * N;
    return data[st .. st + N];
}

fn matApproxEql(comptime T: type, data: []const T, other: []const T, atol: T, rtol: T) bool {
    for (data, 0..) |sx, i| {
        const ox = other[i];

        if (@abs(ox - sx) > atol + rtol * @abs(ox))
            return false;
    }
    return true;
}

fn matPrint(comptime T: type, data: []const T, M: usize, N: usize) void {
    std.debug.print("<Matrix({s}) {d}x{d}\n", .{ @typeName(T), M, N });

    for (0..M) |r| {
        std.debug.print("  {any}\n", .{data[r * N .. (r + 1) * N]});
    }
    std.debug.print(">\n", .{});
}

fn swapRow(comptime T: type, data: []T, M: usize, N: usize, a: usize, b: usize) void {
    std.debug.assert(a >= 0 and a < M and b >= 0 and b < M);
    for (0..N) |c| {
        const tmp = matAt(T, data, N, a, c);
        const bp = matAtPtr(T, data, N, b, c);
        matAtPtr(T, data, N, a, c).* = bp.*;
        bp.* = tmp;
    }
}

/// Find a pivot in an assumed upper triangular (or close) matrix starting from
/// position startPos
fn findPivot(comptime T: type, data: []const T, M: usize, N: usize, startRow: usize) ?[2]usize {
    var pCol: usize = 0;
    while (pCol < N) : (pCol += 1) {
        for (startRow..M) |ri| {
            if (matAt(T, data, N, ri, pCol) != 0) {
                return .{ ri, pCol };
            }
        }
    }
    return null;
}

fn matReduceU(comptime T: type, data: []T, M: usize, N: usize) void {
    var finishedRows: usize = 0;
    while (findPivot(T, data, M, N, finishedRows)) |ret| {
        var pRow = ret[0];
        const pCol = ret[1];

        // ensure pivot is in correct row
        if (pRow != pCol) {
            swapRow(T, data, M, N, pRow, finishedRows);
            pRow = finishedRows;
        }

        // reduce down
        const pivot = matAt(T, data, N, pRow, pCol);
        std.debug.assert(pivot != 0);
        for (pRow + 1..M) |ri| {
            const tmp = matAt(T, data, N, ri, pCol);
            const factor = switch (@typeInfo(T)) {
                .int => @divTrunc(tmp, pivot),
                else => tmp / pivot,
            };

            for (0..N) |ci| {
                matAtPtr(T, data, N, ri, ci).* = matAt(T, data, N, ri, ci) //
                    - matAt(T, data, N, pRow, ci) * factor;
            }
        }

        finishedRows += 1;
    }
}

fn matReduceRref(comptime T: type, data: []T, M: usize, N: usize) void {
    var finishedRows: usize = 0;
    while (findPivot(T, data, M, N, finishedRows)) |ret| {
        var pRow = ret[0];
        const pCol = ret[1];

        // normalize pivot
        const pivot = matAt(T, data, N, pRow, pCol);
        for (matRow(T, data, M, N, pRow)) |*x| {
            x.* = switch (@typeInfo(T)) {
                .int => @divTrunc(x.*, pivot),
                else => x.* / pivot,
            };
        }

        // reduce up
        while (pRow > 0) : (pRow -= 1) {
            const ri = pRow - 1;
            // pivot is now 1, factor is just the value at that location
            const factor = matAt(T, data, N, ri, pCol);
            for (0..N) |ci| {
                matAtPtr(T, data, N, ri, ci).* = matAt(T, data, N, ri, ci) //
                    - matAt(T, data, N, pRow, ci) * factor;
            }
        }

        finishedRows += 1;
    }
}

/// Solve matrix assuming already in rref
fn matSolve(comptime T: type, data: []T, M: usize, N: usize, soln: []T) bool {
    // check for no solutions
    outer: for (0..M) |r| {
        for (0..N - 1) |c| {
            if (matAt(T, data, N, r, c) != 0) continue :outer;
        }
        // row is all zero, check for contradiction
        if (matAt(T, data, N, r, N - 1) != 0) return false;
    }

    for (soln) |*x| x.* = 0;

    var pRow: usize = 0;
    while (findPivot(T, data, M, N, pRow)) |ret| {
        pRow = ret[0];
        const pCol = ret[1];

        soln[pCol] = matAt(T, data, N, pRow, N - 1);
        pRow += 1;
    }

    return true;
}

pub fn MatrixC(comptime T: type, comptime M: usize, comptime N: usize) type {
    return struct {
        data: [M * N]T = undefined,

        const Self = @This();

        pub fn zeros() Self {
            var res = Self{};
            for (&res.data) |*x| x.* = 0;
            return res;
        }

        pub fn eye() Self {
            var res = Self.zeros();
            for (0..M) |i| {
                res.atPtr(i, i).* = 1;
            }
            return res;
        }

        pub fn at(self: *const Self, r: usize, c: usize) T {
            return matAt(T, &self.data, N, r, c);
        }

        pub fn atPtr(self: *Self, r: usize, c: usize) *T {
            return matAtPtr(T, &self.data, N, r, c);
        }

        pub fn row(self: *Self, r: usize) []T {
            return matRow(T, &self.data, M, N, r);
        }

        pub fn rref(self: *const Self) Self {
            var new = Self{};
            std.mem.copyForwards(T, &new.data, &self.data);
            matReduceU(T, &new.data, M, N);
            matReduceRref(T, &new.data, M, N);
            return new;
        }

        /// Solve for the simplest solution to the system if one exists
        pub fn solve(self: *const Self) ?[N - 1]T {
            var R = self.rref();
            var soln: [N - 1]T = undefined;
            if (!matSolve(T, &R.data, M, N, &soln)) {
                return null;
            }
            return soln;
        }

        pub fn print(self: *const Self) void {
            matPrint(T, self.data, M, N);
        }

        pub fn eql(self: *const Self, other: *const Self) bool {
            return std.mem.eql(T, &self.data, &other.data);
        }

        pub fn approxEql(self: *const Self, other: *const Self, atol: T, rtol: T) bool {
            return matApproxEql(T, &self.data, &other.data, atol, rtol);
        }
    };
}

pub fn Matrix(comptime T: type) type {
    return struct {
        data: []T = undefined,
        M: usize = 0,
        N: usize = 0,
        gpa: std.mem.Allocator,

        const Self = @This();

        pub fn init(gpa: std.mem.Allocator, M: usize, N: usize) !Self {
            return .{
                .data = try gpa.alloc(T, M * N),
                .M = M,
                .N = N,
                .gpa = gpa,
            };
        }

        pub fn deinit(self: *const Self) void {
            self.gpa.free(self.data);
        }

        pub fn fromSlice(gpa: std.mem.Allocator, M: usize, sl: []const T) !Self {
            std.debug.assert(sl.len % M == 0);
            const ret = try Self.init(gpa, M, @divTrunc(sl.len, M));
            for (sl, 0..) |v, i| ret.data[i] = v;
            return ret;
        }

        pub fn zeros(gpa: std.mem.Allocator, M: usize, N: usize) !Self {
            const res = try Self.init(gpa, M, N);
            for (res.data) |*x| x.* = 0;
            return res;
        }

        pub fn eye(gpa: std.mem.Allocator, M: usize, N: usize) !Self {
            var res = try Self.zeros(gpa, M, N);
            for (0..M) |i| {
                res.atPtr(i, i).* = 1;
            }
            return res;
        }

        pub fn at(self: *const Self, r: usize, c: usize) T {
            return matAt(T, self.data, self.N, r, c);
        }

        pub fn atPtr(self: *Self, r: usize, c: usize) *T {
            return matAtPtr(T, self.data, self.N, r, c);
        }

        pub fn row(self: *Self, r: usize) []T {
            return matRow(T, self.data, self.M, self.N, r);
        }

        pub fn rref(self: *const Self) !Self {
            const new = try Self.init(self.gpa, self.M, self.N);
            std.mem.copyForwards(T, new.data, self.data);
            matReduceU(T, new.data, self.M, self.N);
            matReduceRref(T, new.data, self.M, self.N);
            return new;
        }

        /// Solve for the simplest solution to the system if one exists
        pub fn solve(self: *const Self) !?[]T {
            const R = try self.rref();
            defer R.deinit();

            const soln = try self.gpa.alloc(T, self.N - 1);
            if (!matSolve(T, R.data, self.M, self.N, soln)) {
                self.gpa.free(soln);
                return null;
            }
            return soln;
        }

        pub fn print(self: *const Self) void {
            matPrint(T, self.data, self.M, self.N);
        }

        pub fn eql(self: *const Self, other: *const Self) bool {
            return std.mem.eql(T, self.data, other.data);
        }

        pub fn approxEql(self: *const Self, other: *const Self, atol: T, rtol: T) bool {
            return matApproxEql(T, self.data, other.data, atol, rtol);
        }
    };
}

test "MatrixX.test" {
    const M = try MatrixXi.fromSlice(std.testing.allocator, 3, &[_]isize{
        1, 3, 3, 2, //
        2, 6, 9, 7, //
        -1, -3, 3, 4, //
    });
    defer M.deinit();
    const R = try M.rref();
    defer R.deinit();
    const exp = try MatrixXi.fromSlice(std.testing.allocator, 3, &[_]isize{
        1, 3, 0, -1, //
        0, 0, 1, 1, //
        0, 0, 0, 0, //
    });
    defer exp.deinit();
    try std.testing.expect(R.eql(&exp));

    const M2 = try MatrixXi.eye(std.testing.allocator, 2, 2);
    defer M2.deinit();
    const exp2 = try MatrixXi.fromSlice(std.testing.allocator, 2, &[_]isize{
        1, 0, //
        0, 1, //
    });
    defer exp2.deinit();

    try std.testing.expect(M2.eql(&exp2));
}

test "Mat.rref" {
    const M = MatrixCi(3, 4){
        .data = .{
            1, 3, 3, 2, //
            2, 6, 9, 7, //
            -1, -3, 3, 4, //
        },
    };
    try std.testing.expect(M.rref().eql(&MatrixCi(3, 4){
        .data = .{
            1, 3, 0, -1, //
            0, 0, 1, 1, //
            0, 0, 0, 0, //
        },
    }));

    const M2 = MatrixCi(3, 3){
        .data = .{
            2, 1, 1, //
            4, -6, 0, //
            -2, 7, 2, //
        },
    };
    try std.testing.expect(M2.rref().eql(&MatrixCi(3, 3){
        .data = .{
            1, 0, 0, //
            0, 1, 0, //
            0, 0, 1, //
        },
    }));

    // same as first with extra col
    const M3 = MatrixCi(3, 5){
        .data = .{
            1, 3, 3, 2, 1, //
            2, 6, 9, 7, 5, //
            -1, -3, 3, 4, 5, //
        },
    };
    try std.testing.expect(M3.rref().eql(&MatrixCi(3, 5){
        .data = .{
            1, 3, 0, -1, -2, //
            0, 0, 1, 1, 1, //
            0, 0, 0, 0, 0, //
        },
    }));
}

test "Mat.solve" {
    const M = MatrixCi(3, 5){
        .data = .{
            1, 3, 3, 2, 1, //
            2, 6, 9, 7, 5, //
            -1, -3, 3, 4, 5, //
        },
    };
    try std.testing.expectEqualSlices(isize, &.{ -2, 0, 1, 0 }, &M.solve().?);

    const M2 = MatrixCi(3, 5){
        .data = .{
            1, 2, 3, 5, 0, //
            2, 4, 8, 12, 6, //
            3, 6, 7, 13, -6, //
        },
    };
    try std.testing.expectEqualSlices(isize, &.{ -9, 0, 3, 0 }, &M2.solve().?);
}

test "eye" {
    try std.testing.expect(MatrixCi(3, 4).eye().eql(&MatrixCi(3, 4){
        .data = .{
            1, 0, 0, 0, //
            0, 1, 0, 0, //
            0, 0, 1, 0, //
        },
    }));
}
