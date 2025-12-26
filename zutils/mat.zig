const std = @import("std");

pub fn Mat2i(comptime M: usize, comptime N: usize) type {
    return Mat2(isize, M, N);
}

pub fn Mat2f(comptime M: usize, comptime N: usize) type {
    return Mat2(f64, M, N);
}

pub fn Mat2(comptime T: type, comptime M: usize, comptime N: usize) type {
    return struct {
        data: [M * N]T = undefined,

        const Self = @This();

        pub fn at(self: *const Self, r: usize, c: usize) T {
            return self.data[r * N + c];
        }

        pub fn atPtr(self: *Self, r: usize, c: usize) *T {
            return &self.data[r * N + c];
        }

        pub fn row(self: *Self, i: usize) []T {
            std.debug.assert(i < M);
            const st = i * N;
            return self.data[st .. st + N];
        }

        fn swapRow(self: *Self, a: usize, b: usize) void {
            std.debug.assert(a >= 0 and a < M and b >= 0 and b < M);
            for (0..N) |c| {
                const tmp = self.at(a, c);
                self.atPtr(a, c).* = self.at(b, c);
                self.atPtr(b, c).* = tmp;
            }
        }

        pub fn U(self: *const Self) Self {
            var new = Self{};
            std.mem.copyForwards(T, &new.data, &self.data);

            var pCol: usize = 0;
            var finishedRows: usize = 0;
            while (pCol < N) : (pCol += 1) {
                var pRow: usize = 0;
                var hasPivot = false;

                // determine which row is a candidate
                for (finishedRows..M) |ri| {
                    if (new.at(ri, pCol) != 0) {
                        pRow = ri;
                        hasPivot = true;
                        break;
                    }
                }

                if (!hasPivot) continue;

                // ensure pivot is in correct row
                if (pRow != pCol) {
                    new.swapRow(pRow, finishedRows);
                    pRow = finishedRows;
                }

                // reduce down
                const pivot = new.at(pRow, pCol);
                std.debug.assert(pivot != 0);
                for (pRow + 1..M) |ri| {
                    const factor = switch (@typeInfo(T)) {
                        .int => @divTrunc(new.at(ri, pCol), pivot),
                        else => new.at(ri, pCol) / pivot,
                    };

                    for (0..N) |ci| {
                        new.atPtr(ri, ci).* = new.at(ri, ci) - new.at(pRow, ci) * factor;
                    }
                }

                finishedRows += 1;
            }
            return new;
        }

        pub fn rref(self: *const Self) Self {
            var new = self.U();
            var pCol: usize = 0;
            var finishedRows: usize = 0;
            while (pCol < N) : (pCol += 1) {
                var pRow: usize = 0;
                var hasPivot = false;

                // determine which row is a candidate
                for (finishedRows..M) |ri| {
                    if (new.at(ri, pCol) != 0) {
                        pRow = ri;
                        hasPivot = true;
                        break;
                    }
                }

                if (!hasPivot) continue;

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
                    for (0..N) |ci| {
                        new.atPtr(ri, ci).* = new.at(ri, ci) - new.at(pRow, ci) * factor;
                    }
                }

                finishedRows += 1;
            }
            return new;
        }

        pub fn print(self: *const Self) void {
            std.debug.print("<Mat2({s}) {d}x{d}\n", .{ @typeName(T), M, N });

            for (0..M) |r| {
                std.debug.print("  {any}\n", .{self.data[r * N .. (r + 1) * N]});
            }
            std.debug.print(">\n", .{});
        }

        pub fn eql(self: *const Self, other: *const Self) bool {
            return std.mem.eql(T, &self.data, &other.data);
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

test "Mat.U" {
    const M = Mat2i(3, 4){
        .data = .{
            1, 3, 3, 2, //
            2, 6, 9, 7, //
            -1, -3, 3, 4, //
        },
    };

    const M2 = Mat2i(3, 4){
        .data = .{
            1, 2, 3, 5, //
            2, 4, 8, 12, //
            3, 6, 7, 13, //
        },
    };

    const M3 = Mat2i(3, 3){
        .data = .{
            2, 1, 1, //
            4, -6, 0, //
            -2, 7, 2, //
        },
    };

    try std.testing.expect(M.U().eql(&Mat2i(3, 4){
        .data = .{
            1, 3, 3, 2, //
            0, 0, 3, 3, //
            0, 0, 0, 0, //
        },
    }));
    try std.testing.expect(M2.U().eql(&Mat2i(3, 4){
        .data = .{
            1, 2, 3, 5, //
            0, 0, 2, 2, //
            0, 0, 0, 0, //
        },
    }));
    try std.testing.expect(M3.U().eql(&Mat2i(3, 3){
        .data = .{
            2, 1, 1, //
            0, -8, -2, //
            0, 0, 1, //
        },
    }));
}

test "Mat.rref" {
    const M = Mat2i(3, 4){
        .data = .{
            1, 3, 3, 2, //
            2, 6, 9, 7, //
            -1, -3, 3, 4, //
        },
    };
    try std.testing.expect(M.rref().eql(&Mat2i(3, 4){
        .data = .{
            1, 3, 0, -1, //
            0, 0, 1, 1, //
            0, 0, 0, 0, //
        },
    }));
}
