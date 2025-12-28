const std = @import("std");

pub const MatrixXi = Matrix(isize);
pub const MatrixXf = Matrix(f64);

pub fn MatrixCi(comptime M: usize, comptime N: usize) type {
    return MatrixC(isize, M, N);
}

pub fn MatrixCf(comptime M: usize, comptime N: usize) type {
    return MatrixC(f64, M, N);
}

fn matApproxEql(comptime T: type, a: anytype, b: anytype, atol: T, rtol: T) bool {
    for (a.data, 0..) |sx, i| {
        const ox = b.data[i];

        if (@abs(ox - sx) > atol + rtol * @abs(ox))
            return false;
    }
    return true;
}

fn matPrint(comptime T: type, mat: anytype) void {
    std.debug.print("<Matrix({s}) {d}x{d}\n", .{ @typeName(T), mat.m(), mat.n() });

    for (0..mat.m()) |r| {
        std.debug.print("  {any}\n", .{mat.data[r * mat.n() .. (r + 1) * mat.n()]});
    }
    std.debug.print(">\n", .{});
}

fn swapRow(mat: anytype, a: usize, b: usize) void {
    std.debug.assert(a >= 0 and a < mat.m() and b >= 0 and b < mat.m());
    for (0..mat.n()) |c| {
        const tmp = mat.at(a, c);
        const bp = mat.atPtr(b, c);
        mat.atPtr(a, c).* = bp.*;
        bp.* = tmp;
    }
}

/// Find a pivot in an assumed upper triangular (or close) matrix starting from
/// position startPos
fn findPivot(mat: anytype, startRow: usize) ?[2]usize {
    var pCol: usize = 0;
    while (pCol < mat.n()) : (pCol += 1) {
        for (startRow..mat.m()) |ri| {
            if (mat.at(ri, pCol) != 0) {
                return .{ ri, pCol };
            }
        }
    }
    return null;
}

fn matRank(mat: anytype) usize {
    var pRow: usize = 0;
    while (findPivot(mat, pRow) != null) : (pRow += 1) {}
    return pRow;
}

fn matReduceU(comptime T: type, mat: anytype) void {
    var finishedRows: usize = 0;
    while (findPivot(mat, finishedRows)) |ret| {
        var pRow = ret[0];
        const pCol = ret[1];

        // ensure pivot is in correct row
        if (pRow != pCol) {
            swapRow(mat, pRow, finishedRows);
            pRow = finishedRows;
        }

        // reduce down
        const pivot = mat.at(pRow, pCol);
        std.debug.assert(pivot != 0);
        for (pRow + 1..mat.m()) |ri| {
            const tmp = mat.at(ri, pCol);
            const factor = switch (@typeInfo(T)) {
                .int => @divTrunc(tmp, pivot),
                else => tmp / pivot,
            };

            for (0..mat.n()) |ci| {
                mat.atPtr(ri, ci).* = mat.at(ri, ci) //
                    - mat.at(pRow, ci) * factor;
            }
        }

        finishedRows += 1;
    }
}

fn matReduceRref(comptime T: type, mat: anytype) void {
    var finishedRows: usize = 0;
    while (findPivot(mat, finishedRows)) |ret| {
        const pRow = ret[0];
        const pCol = ret[1];

        // normalize pivot
        const pivot = mat.at(pRow, pCol);
        for (mat.row(pRow)) |*x| {
            x.* = switch (@typeInfo(T)) {
                .int => @divTrunc(x.*, pivot),
                else => x.* / pivot,
            };
        }

        // reduce up
        var opRow = pRow;
        while (opRow > 0) : (opRow -= 1) {
            const ri = opRow - 1;
            // pivot is now 1, factor is just the value at that location
            const factor = mat.at(ri, pCol);
            for (0..mat.n()) |ci| {
                mat.atPtr(ri, ci).* = mat.at(ri, ci) //
                    - mat.at(pRow, ci) * factor;
            }
        }

        finishedRows += 1;
    }
}

fn SolutionIO(comptime T: type) type {
    return struct {
        xp: []T,
        Ns: *Matrix(T),
        colTypes: []ColType,
    };
}

/// Solve matrix assuming already in rref and of augmented form [R | d] from Rx = d
fn matSolve(comptime T: type, mat: anytype, sio: SolutionIO(T)) bool {
    // check for no solutions
    outer: for (0..mat.m()) |r| {
        for (0..mat.n() - 1) |c| {
            if (mat.at(r, c) != 0) continue :outer;
        }
        // row is all zero, check for contradiction
        if (mat.at(r, mat.n() - 1) != 0) return false;
    }

    for (sio.xp) |*x| x.* = 0;
    for (sio.colTypes) |*c| c.* = .free;

    var pRow: usize = 0;
    while (findPivot(mat, pRow)) |ret| : (pRow += 1) {
        pRow = ret[0];
        const pCol = ret[1];

        // update particular solution
        sio.xp[pCol] = mat.at(pRow, mat.n() - 1);
        sio.colTypes[pCol] = .pivot;
    }
    std.debug.print("{any} - {d}\n", .{ sio.colTypes, pRow });

    // initialize the rows for free variables
    var fi: usize = 0;
    for (sio.colTypes, 0..) |c, ci| {
        if (c == .free) {
            std.debug.print("{d},{d} vs {d}x{d}\n", .{ ci, fi, sio.Ns.M, sio.Ns.N });
            sio.Ns.atPtr(ci, fi).* = 1;
            fi += 1;
        }
    }

    // fill the remaining rows with the values from non-pivot columns of pivot rows
    pRow = 0;
    fi = 0;
    while (findPivot(mat, pRow)) |ret| : (pRow += 1) {
        pRow = ret[0];
        // determine the correct row for the Ns values
        for (sio.colTypes[fi..]) |c| {
            if (c == .pivot) break;
            fi += 1;
        }

        // for each pivot row, assemble a row of Ns out of the non-pivot column values
        var i: usize = 0;
        for (sio.colTypes, 0..) |c, ci| {
            if (c == .pivot) continue;
            sio.Ns.atPtr(fi, i).* = -mat.at(pRow, ci);
            i += 1;
        }
        // advance past the row in Ns we just handled
        fi += 1;
    }

    return true;
}

pub const ColType = enum {
    pivot,
    free,
};

pub fn MatrixC(comptime T: type, comptime M: usize, comptime N: usize) type {
    return struct {
        data: [M * N]T = undefined,

        const Self = @This();
        pub const SolutionT = struct {
            xp: [N - 1]T,
            Ns: Matrix(T),
            cols: [N - 1]ColType,

            pub fn deinit(self: *const @This()) void {
                self.Ns.deinit();
            }
        };

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

        pub fn m(_: *const Self) usize {
            return M;
        }

        pub fn n(_: *const Self) usize {
            return N;
        }

        pub fn at(self: *const Self, r: usize, c: usize) T {
            std.debug.assert(r < M and r >= 0);
            std.debug.assert(c < N and c >= 0);
            return self.data[r * N + c];
        }

        pub fn atPtr(self: *Self, r: usize, c: usize) *T {
            std.debug.assert(r < M and r >= 0);
            std.debug.assert(c < N and c >= 0);
            return &self.data[r * N + c];
        }

        pub fn row(self: *Self, r: usize) []T {
            std.debug.assert(r < M);
            const st = r * N;
            return self.data[st .. st + N];
        }

        pub fn rref(self: *const Self) Self {
            var new = Self{};
            std.mem.copyForwards(T, &new.data, &self.data);
            matReduceU(T, &new);
            matReduceRref(T, &new);
            return new;
        }

        pub fn det(self: *const Self) T {
            std.debug.assert(M == N);
            var new = Self{};
            std.mem.copyForwards(T, &new.data, &self.data);
            matReduceU(T, &new);
            var ret: T = 1;
            for (0..M) |i| {
                ret *= new.at(i, i);
            }
            return ret;
        }

        /// Solve for the simplest solution to the system if one exists
        pub fn solve(self: *const Self, gpa: std.mem.Allocator) !?SolutionT {
            const R = self.rref();
            const rank = matRank(R);
            // N-1 because we assume augmented matrix form
            const nFree = N - 1 - rank;
            var soln = SolutionT{
                .Ns = try Matrix(T).zeros(gpa, N - 1, nFree),
                .xp = undefined,
                .cols = undefined,
            };
            if (!matSolve(T, R, .{
                .Ns = &soln.Ns,
                .xp = &soln.xp,
                .colTypes = &soln.cols,
            })) {
                defer soln.deinit();
                return null;
            }
            return soln;
        }

        pub fn print(self: *const Self) void {
            matPrint(T, self);
        }

        pub fn eql(self: *const Self, other: *const Self) bool {
            return std.mem.eql(T, &self.data, &other.data);
        }

        pub fn approxEql(self: *const Self, other: *const Self, atol: T, rtol: T) bool {
            return matApproxEql(T, self, other, atol, rtol);
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
        pub const SolutionT = struct {
            xp: []T,
            Ns: Matrix(T),
            cols: []ColType,
            gpa: std.mem.Allocator,

            pub fn deinit(self: *const @This()) void {
                self.gpa.free(self.xp);
                self.gpa.free(self.cols);
                self.Ns.deinit();
            }
        };

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

        pub fn m(self: *const Self) usize {
            return self.M;
        }

        pub fn n(self: *const Self) usize {
            return self.N;
        }

        pub fn at(self: *const Self, r: usize, c: usize) T {
            std.debug.assert(r < self.M and r >= 0);
            std.debug.assert(c < self.N and c >= 0);
            return self.data[r * self.N + c];
        }

        pub fn atPtr(self: *Self, r: usize, c: usize) *T {
            std.debug.assert(r < self.M and r >= 0);
            std.debug.assert(c < self.N and c >= 0);
            return &self.data[r * self.N + c];
        }

        pub fn row(self: *Self, r: usize) []T {
            std.debug.assert(r < self.M);
            const st = r * self.N;
            return self.data[st .. st + self.N];
        }

        pub fn rref(self: *const Self) !Self {
            var new = try Self.init(self.gpa, self.M, self.N);
            std.mem.copyForwards(T, new.data, self.data);
            matReduceU(T, &new);
            matReduceRref(T, &new);
            return new;
        }

        pub fn det(self: *const Self) !T {
            std.debug.assert(self.M == self.N);
            var new = try Self.init(self.gpa, self.M, self.N);
            std.mem.copyForwards(T, new.data, self.data);
            matReduceU(T, &new);
            const ret: T = 1;
            for (0..self.M) |i| {
                ret *= new.at(i);
            }
            return ret;
        }

        /// Solve for the simplest solution to the system if one exists
        pub fn solve(self: *const Self) !?SolutionT {
            const R = try self.rref();
            defer R.deinit();
            const rank = matRank(R);
            // N-1 because we assume augmented matrix form
            const nFree = self.N - 1 - rank;
            var soln = SolutionT{
                .Ns = try Matrix(T).zeros(self.gpa, self.N - 1, nFree),
                .xp = try self.gpa.alloc(T, self.N - 1),
                .cols = try self.gpa.alloc(ColType, self.N - 1),
                .gpa = self.gpa,
            };
            if (!matSolve(T, R, .{
                .xp = soln.xp,
                .Ns = &soln.Ns,
                .colTypes = soln.cols,
            })) {
                soln.deinit();
                return null;
            }
            return soln;
        }

        pub fn print(self: *const Self) void {
            matPrint(T, self);
        }

        pub fn eql(self: *const Self, other: *const Self) bool {
            return std.mem.eql(T, self.data, other.data);
        }

        pub fn approxEql(self: *const Self, other: *const Self, atol: T, rtol: T) bool {
            return matApproxEql(T, self.data, other.data, atol, rtol);
        }
    };
}

test "Matrix.basic" {
    const M = try MatrixXi.fromSlice(std.testing.allocator, 3, &[_]isize{
        1, 3, 3, 2, //
        2, 6, 9, 7, //
        -1, -3, 3, 4, //
    });
    defer M.deinit();
    const R = try M.rref();
    defer R.deinit();
    const exp = try MatrixXi.fromSlice(std.testing.allocator, 3, &[_]isize{
        1, 3, 0, -1,
        0, 0, 1, 1,
        0, 0, 0, 0,
    });
    defer exp.deinit();
    try std.testing.expect(R.eql(&exp));

    const M2 = try MatrixXi.eye(std.testing.allocator, 2, 2);
    defer M2.deinit();
    const exp2 = try MatrixXi.fromSlice(std.testing.allocator, 2, &[_]isize{
        1, 0,
        0, 1,
    });
    defer exp2.deinit();

    try std.testing.expect(M2.eql(&exp2));
}

test "Matrix.solve" {
    const M = try MatrixXi.fromSlice(std.testing.allocator, 3, &[_]isize{
        1,  3,  3, 2, 1,
        2,  6,  9, 7, 5,
        -1, -3, 3, 4, 5,
    });
    defer M.deinit();
    const res = (try M.solve()).?;
    defer res.deinit();
    try std.testing.expectEqualSlices(isize, &.{
        -2,
        0,
        1,
        0,
    }, res.xp);
    try std.testing.expectEqualSlices(isize, &.{
        -3, 1,
        1,  0,
        0,  -1,
        0,  1,
    }, res.Ns.data);
}

test "Mat.rref" {
    const M = MatrixCi(3, 4){
        .data = .{
            1,  3,  3, 2,
            2,  6,  9, 7,
            -1, -3, 3, 4,
        },
    };
    try std.testing.expect(M.rref().eql(&MatrixCi(3, 4){
        .data = .{
            1, 3, 0, -1,
            0, 0, 1, 1,
            0, 0, 0, 0,
        },
    }));

    const M2 = MatrixCi(3, 3){
        .data = .{
            2,  1,  1,
            4,  -6, 0,
            -2, 7,  2,
        },
    };
    try std.testing.expect(M2.rref().eql(&MatrixCi(3, 3){
        .data = .{
            1, 0, 0,
            0, 1, 0,
            0, 0, 1,
        },
    }));

    const M3 = MatrixCi(5, 6){
        .data = .{
            1, 0, 1, 1, 0, 7,
            0, 0, 0, 1, 1, 5,
            1, 1, 0, 1, 1, 12,
            1, 1, 0, 0, 1, 7,
            1, 0, 1, 0, 1, 2,
        },
    };
    try std.testing.expect(M3.rref().eql(&MatrixCi(5, 6){
        .data = .{
            1, 0, 1,  0, 0, 2,
            0, 1, -1, 0, 0, 5,
            0, 0, 0,  1, 0, 5,
            0, 0, 0,  0, 1, 0,
            0, 0, 0,  0, 0, 0,
        },
    }));
}

test "Mat.solve" {
    const M = MatrixCi(3, 5){
        .data = .{
            1,  3,  3, 2, 1,
            2,  6,  9, 7, 5,
            -1, -3, 3, 4, 5,
        },
    };
    const res = (try M.solve(std.testing.allocator)).?;
    defer res.deinit();
    try std.testing.expectEqualSlices(isize, &.{
        -2,
        0,
        1,
        0,
    }, &res.xp);
    try std.testing.expectEqualSlices(isize, &.{
        -3, 1,
        1,  0,
        0,  -1,
        0,  1,
    }, res.Ns.data);

    const M2 = MatrixCi(3, 5){
        .data = .{
            1, 2, 3, 5,  0,
            2, 4, 8, 12, 6,
            3, 6, 7, 13, -6,
        },
    };
    const res2 = (try M2.solve(std.testing.allocator)).?;
    defer res2.deinit();
    try std.testing.expectEqualSlices(isize, &.{
        -9,
        0,
        3,
        0,
    }, &res2.xp);
    try std.testing.expectEqualSlices(isize, &.{
        -2, -2,
        1,  0,
        0,  -1,
        0,  1,
    }, res2.Ns.data);
}

test "eye" {
    try std.testing.expect(MatrixCi(3, 4).eye().eql(&MatrixCi(3, 4){
        .data = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
        },
    }));
}

test "Mat.solveNs" {
    const M = MatrixCi(5, 6){
        .data = .{
            1, 0, 1, 1, 0, 7,
            0, 0, 0, 1, 1, 5,
            1, 1, 0, 1, 1, 12,
            1, 1, 0, 0, 1, 7,
            1, 0, 1, 0, 1, 2,
        },
    };
    const res = (try M.solve(std.testing.allocator)).?;
    defer res.deinit();
    try std.testing.expectEqualSlices(isize, &.{
        -1,
        1,
        1,
        0,
        0,
    }, res.Ns.data);
}

test "Mat.det" {
    const M = MatrixCf(3, 3){
        .data = .{
            1,  2, 3,
            -4, 5, 6,
            7,  8, 9,
        },
    };

    try std.testing.expectApproxEqAbs(-48, M.det(), 1e-5);
}

test "Mat.rrefbug" {
    const M = MatrixCi(10, 13){ .data = .{
        0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 52,
        0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 67,
        0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 66,
        1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 109,
        0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 49,
        0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 65,
        1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 70,
        0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 66,
        0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 33,
        0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 72,
    } };
}
