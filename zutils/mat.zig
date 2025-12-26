const std = @import("std");

pub const Mat2i = Mat2(isize);
pub const Mat2f = Mat2(f64);

pub fn Mat2(comptime T: type) type {
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
            var res = try Self.init(gpa, M, N);
            for (&res.data) |*x| x.* = 0;
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
            return self.data[r * self.N + c];
        }

        pub fn atPtr(self: *Self, r: usize, c: usize) *T {
            return &self.data[r * self.N + c];
        }

        pub fn row(self: *Self, i: usize) []T {
            std.debug.assert(i < self.M);
            const st = i * self.N;
            return self.data[st .. st + self.N];
        }

        fn swapRow(self: *Self, a: usize, b: usize) void {
            std.debug.assert(a >= 0 and a < self.M and b >= 0 and b < self.M);
            for (0..self.N) |c| {
                const tmp = self.at(a, c);
                self.atPtr(a, c).* = self.at(b, c);
                self.atPtr(b, c).* = tmp;
            }
        }

        /// Find a pivot in an assumed upper triangular (or close) matrix starting from
        /// position startPos
        fn findPivot(self: *const Self, startRow: usize) ?[2]usize {
            var pCol: usize = 0;
            while (pCol < self.N) : (pCol += 1) {
                for (startRow..self.M) |ri| {
                    if (self.at(ri, pCol) != 0) {
                        return .{ ri, pCol };
                    }
                }
            }
            return null;
        }

        pub fn U(self: *const Self) !Self {
            var new = try Self.init(self.gpa, self.M, self.N);
            std.mem.copyForwards(T, new.data, self.data);

            var finishedRows: usize = 0;
            while (new.findPivot(finishedRows)) |ret| {
                var pRow = ret[0];
                const pCol = ret[1];

                // ensure pivot is in correct row
                if (pRow != pCol) {
                    new.swapRow(pRow, finishedRows);
                    pRow = finishedRows;
                }

                // reduce down
                const pivot = new.at(pRow, pCol);
                std.debug.assert(pivot != 0);
                for (pRow + 1..self.M) |ri| {
                    const factor = switch (@typeInfo(T)) {
                        .int => @divTrunc(new.at(ri, pCol), pivot),
                        else => new.at(ri, pCol) / pivot,
                    };

                    for (0..self.N) |ci| {
                        new.atPtr(ri, ci).* = new.at(ri, ci) - new.at(pRow, ci) * factor;
                    }
                }

                finishedRows += 1;
            }
            return new;
        }

        pub fn rref(self: *const Self) !Self {
            var new = try self.U();
            var finishedRows: usize = 0;
            while (new.findPivot(finishedRows)) |ret| {
                var pRow = ret[0];
                const pCol = ret[1];

                // normalize pivot
                const pivot = new.at(pRow, pCol);
                for (new.row(pRow)) |*x| {
                    x.* = switch (@typeInfo(T)) {
                        .int => @divTrunc(x.*, pivot),
                        else => x.* / pivot,
                    };
                }

                // reduce up
                while (pRow > 0) : (pRow -= 1) {
                    const ri = pRow - 1;
                    // pivot is now 1, factor is just the value at that location
                    const factor = new.at(ri, pCol);
                    for (0..self.N) |ci| {
                        new.atPtr(ri, ci).* = new.at(ri, ci) - new.at(pRow, ci) * factor;
                    }
                }

                finishedRows += 1;
            }
            return new;
        }

        /// Solve for the simplest solution to the system if one exists
        pub fn solve(self: *const Self) !?[]T {
            const R = try self.rref();
            defer R.deinit();
            // check for no solutions
            outer: for (0..self.M) |r| {
                for (0..self.N - 1) |c| {
                    if (R.at(r, c) != 0) continue :outer;
                }
                // row is all zero, check for contradiction
                if (R.at(r, self.N - 1) != 0) return null;
            }

            var soln = try self.gpa.alloc(T, self.N - 1);
            for (soln) |*x| x.* = 0;

            var pRow: usize = 0;
            while (R.findPivot(pRow)) |ret| {
                pRow = ret[0];
                const pCol = ret[1];

                soln[pCol] = R.at(pRow, self.N - 1);
                pRow += 1;
            }

            return soln;
        }

        pub fn print(self: *const Self) void {
            std.debug.print("<Mat2({s}) {d}x{d}\n", .{ @typeName(T), self.M, self.N });

            for (0..self.M) |r| {
                std.debug.print("  {any}\n", .{self.data[r * self.N .. (r + 1) * self.N]});
            }
            std.debug.print(">\n", .{});
        }

        pub fn eql(self: *const Self, other: *const Self) bool {
            return std.mem.eql(T, self.data, other.data);
        }

        pub fn approxEql(self: *const Self, other: *const Self, atol: T, rtol: T) bool {
            for (self.data, 0..) |sx, i| {
                const ox = other.data[i];

                if (@abs(ox - sx) > atol + rtol * @abs(ox))
                    return false;
            }
            return true;
        }
    };
}

test "Mat.rref" {
    const M = try Mat2i.fromSlice(std.testing.allocator, 3, &[_]isize{
        1, 3, 3, 2, //
        2, 6, 9, 7, //
        -1, -3, 3, 4, //
    });
    defer M.deinit();
    const R = try M.rref();
    defer R.deinit();
    const exp = try Mat2i.fromSlice(std.testing.allocator, 3, &[_]isize{
        1, 3, 0, -1, //
        0, 0, 1, 1, //
        0, 0, 0, 0, //
    });
    defer exp.deinit();
    try std.testing.expect(R.eql(&exp));

    //     const M2 = Mat2i.init(std.testing.allocator, 3, 3){
    //         .data = .{
    //             2, 1, 1, //
    //             4, -6, 0, //
    //             -2, 7, 2, //
    //         },
    //     };
    //     try std.testing.expect(M2.rref().eql(&Mat2i.init(std.testing.allocator, 3, 3){
    //         .data = .{
    //             1, 0, 0, //
    //             0, 1, 0, //
    //             0, 0, 1, //
    //         },
    //     }));
    //
    //     // same as first with extra col
    //     const M3 = Mat2i.init(std.testing.allocator, 3, 5){
    //         .data = .{
    //             1, 3, 3, 2, 1, //
    //             2, 6, 9, 7, 5, //
    //             -1, -3, 3, 4, 5, //
    //         },
    //     };
    //     try std.testing.expect(M3.rref().eql(&Mat2i.init(std.testing.allocator, 3, 5){
    //         .data = .{
    //             1, 3, 0, -1, -2, //
    //             0, 0, 1, 1, 1, //
    //             0, 0, 0, 0, 0, //
    //         },
    //     }));
}

test "Mat.solve" {
    const M = try Mat2i.fromSlice(
        std.testing.allocator,
        3,
        &[_]isize{
            1, 3, 3, 2, 1, //
            2, 6, 9, 7, 5, //
            -1, -3, 3, 4, 5, //
        },
    );
    defer M.deinit();
    const res = (try M.solve()).?;
    defer std.testing.allocator.free(res);
    try std.testing.expectEqualSlices(isize, &.{ -2, 0, 1, 0 }, res);

    // const M2 = Mat2i.init(std.testing.allocator, 3, 5){
    //     .data = .{
    //         1, 2, 3, 5, 0, //
    //         2, 4, 8, 12, 6, //
    //         3, 6, 7, 13, -6, //
    //     },
    // };
    // try std.testing.expectEqualSlices(isize, &.{ -9, 0, 3, 0 }, &M2.solve().?);
}

// test "eye" {
//     try std.testing.expect(Mat2i.eye(std.testing.allocator, 2, 2).eql(&Mat2i.init(std.testing.allocator, 2, 2){
//         .data = .{
//             1, 0, //
//             0, 1, //
//         },
//     }));
//     try std.testing.expect(Mat2i.eye(std.testing.allocator, 3, 4).eql(&Mat2i.init(std.testing.allocator, 3, 4){
//         .data = .{
//             1, 0, 0, 0, //
//             0, 1, 0, 0, //
//             0, 0, 1, 0, //
//         },
//     }));
// }
