const std = @import("std");
const zutils = @import("zutils");

const Grid = zutils.Grid(u8);

const Dir = enum { H, V, D1, D2 };

const Match = struct {
    a_idx: usize,
    dir: Dir,
};

const MatchState = struct {
    seq: []const u8,
    next: u8 = 0,

    fn check(self: *MatchState, char: u8) bool {
        var m: bool = false;
        const next_char = self.seq[self.next];

        if (char == next_char) {
            if (self.next == self.seq.len - 1) {
                // fully matched
                self.next = 0;
                m = true;
            } else {
                // advance to next char
                self.next += 1;
            }
        } else {
            // miss, reset
            self.next = if (char == self.seq[0]) 1 else 0;
        }
        return m;
    }
};

const SearchState = struct {
    g: Grid,
    matches: std.ArrayList(Match),
    seq: []const u8,

    fn init(allocator: std.mem.Allocator, lines: []const []const u8, seq: []const u8) !SearchState {
        return .{
            .matches = std.ArrayList(Match).init(allocator),
            .g = try Grid.init2DSlice(allocator, lines),
            .seq = seq,
        };
    }

    fn deinit(self: *const SearchState) void {
        self.matches.deinit();
        self.g.deinit();
    }

    /// Range is inclusive, because that makes it much easier to go in reverse
    fn search(self: *SearchState, start: usize, end: usize, stride: isize, dir: Dir) !void {
        var ss = MatchState{ .seq = self.seq };

        const e: isize = @intCast(end);
        var i: isize = @intCast(start);
        while (if (stride < 0) i >= e else i <= e) : (i += stride) {
            if (ss.check(self.g.data[@intCast(i)])) {
                try self.matches.append(.{
                    // the index of interest is one stride back
                    .a_idx = @intCast(i - stride),
                    .dir = dir,
                });
            }
        }
    }

    fn searchForwardBackward(self: *SearchState, start: usize, end: usize, stride: isize, dir: Dir) !void {
        try self.search(start, end, stride, dir);
        try self.search(end, start, -stride, dir);
    }

    fn searchVertHoriz(self: *SearchState) !void {
        // rows left-to-right and right-to-left
        var row: usize = 0;
        while (row < self.g.nrows) : (row += 1) {
            const s = row * self.g.ncols;
            const e = (row + 1) * self.g.ncols - 1;
            try self.searchForwardBackward(s, e, 1, .H);
        }

        // cols up-down and down-up
        var col: usize = 0;
        while (col < self.g.ncols) : (col += 1) {
            const s = col;
            const e = col + (self.g.nrows - 1) * self.g.ncols;
            const stride: isize = @intCast(self.g.ncols);
            try self.searchForwardBackward(s, e, stride, .V);
        }
    }

    fn searchDiag(self: *SearchState) !void {
        // assume square
        const n = self.g.ncols;

        // diagonal ul - dr and dr - ul
        var i: usize = 0;
        while (i < n) : (i += 1) {
            // advancing down right is ncols + 1
            const stride: isize = @intCast(self.g.ncols + 1);
            var s = i;
            var e = (self.g.nrows - i) * self.g.ncols - 1;
            // starting in the first row, moving down right (or reverse)
            try self.searchForwardBackward(s, e, stride, .D1);

            if (i == 0) {
                // skip the main diagonal for this section
                continue;
            }
            // starting in the first column, moving down right (or reverse)
            s = i * self.g.ncols;
            e = self.g.ncols * self.g.nrows - i - 1;
            try self.searchForwardBackward(s, e, stride, .D1);
        }

        // diagonal ur - dl and dl - ur
        i = 0;
        while (i < n) : (i += 1) {
            // advancing down left is ncols - 1
            const stride: isize = @intCast(self.g.ncols - 1);
            var s = i;
            var e = i * self.g.ncols;
            // starting in the first row, moving down left (or reverse)
            try self.searchForwardBackward(s, e, stride, .D2);

            if (i == 0) {
                // skip the main diagonal for this section
                continue;
            }
            // starting in the last column, moving down right (or reverse)
            s = (i + 1) * self.g.ncols - 1;
            e = self.g.ncols * (self.g.nrows - 1) + i;
            try self.searchForwardBackward(s, e, stride, .D2);
        }
    }

    fn searchAllDirections(self: *SearchState) !void {
        try self.searchVertHoriz();
        try self.searchDiag();
    }
};

fn p1(allocator: std.mem.Allocator, lines: []const []const u8) !usize {
    var ss = try SearchState.init(allocator, lines, "XMAS");
    defer ss.deinit();

    try ss.searchAllDirections();
    return ss.matches.items.len;
}

fn compareMatch(_: void, a: Match, b: Match) bool {
    return a.a_idx < b.a_idx;
}

fn p2(allocator: std.mem.Allocator, lines: []const []const u8) !usize {
    var ss = try SearchState.init(allocator, lines, "MAS");
    defer ss.deinit();

    try ss.searchDiag();

    // Find all diagonal matches that share an A and are orthogonal.
    // Since there are a max of 2 possible matches that share a single A
    // we can just sort and check adjacent matches
    std.mem.sort(Match, ss.matches.items, {}, compareMatch);
    var i: usize = 0;
    var tot: usize = 0;
    while (i < ss.matches.items.len - 1) : (i += 1) {
        const a = &ss.matches.items[i];
        const b = &ss.matches.items[i + 1];

        if (a.a_idx == b.a_idx and a.dir != b.dir) {
            tot += 1;
        }
    }
    return tot;
}

const TEST_LINES = [_][]const u8{
    "MMMSXXMASM",
    "MSAMXMSMSA",
    "AMXSXMAAMM",
    "MSAMASMSMX",
    "XMASAMXAMM",
    "XXAMMXXAMA",
    "SMSMSASXSS",
    "SAXAMASAAA",
    "MAMMMXMMMM",
    "MXMXAXMASX",
};

test "p1" {
    try std.testing.expectEqual(18, try p1(std.testing.allocator, &TEST_LINES));
}

test "p2" {
    try std.testing.expectEqual(9, try p2(std.testing.allocator, &TEST_LINES));
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/4.txt");
    const a1 = try p1(std.heap.page_allocator, lines.strings.items);
    const a2 = try p2(std.heap.page_allocator, lines.strings.items);

    std.debug.print("p1: {d}\n", .{a1});
    std.debug.print("p2: {d}\n", .{a2});
}
