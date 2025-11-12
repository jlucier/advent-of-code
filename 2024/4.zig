const std = @import("std");
const zutils = @import("zutils");

const Grid = zutils.Grid(u8);

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
    matches: std.array_list.Managed(usize),
    seq: []const u8,

    fn init(allocator: std.mem.Allocator, lines: []const []const u8, seq: []const u8) !SearchState {
        return .{
            .matches = std.array_list.Managed(usize).init(allocator),
            .g = try Grid.init2DSlice(allocator, lines),
            .seq = seq,
        };
    }

    fn deinit(self: *const SearchState) void {
        self.matches.deinit();
        self.g.deinit();
    }

    /// Range is inclusive, because that makes it much easier to go in reverse
    fn search(self: *SearchState, start: usize, end: usize, stride: isize) !void {
        var ss = MatchState{ .seq = self.seq };

        const e: isize = @intCast(end);
        var i: isize = @intCast(start);
        while (if (stride < 0) i >= e else i <= e) : (i += stride) {
            if (ss.check(self.g.data[@intCast(i)])) {
                // the index of interest is one stride back
                try self.matches.append(@intCast(i - stride));
            }
        }
    }

    fn searchForwardBackward(self: *SearchState, start: usize, end: usize, stride: isize) !void {
        try self.search(start, end, stride);
        try self.search(end, start, -stride);
    }

    fn searchVertHoriz(self: *SearchState) !void {
        // rows left-to-right and right-to-left
        var row: usize = 0;
        while (row < self.g.nrows) : (row += 1) {
            const s = row * self.g.ncols;
            const e = (row + 1) * self.g.ncols - 1;
            try self.searchForwardBackward(s, e, 1);
        }

        // cols up-down and down-up
        var col: usize = 0;
        while (col < self.g.ncols) : (col += 1) {
            const s = col;
            const e = col + (self.g.nrows - 1) * self.g.ncols;
            const stride: isize = @intCast(self.g.ncols);
            try self.searchForwardBackward(s, e, stride);
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
            try self.searchForwardBackward(s, e, stride);

            if (i == 0) {
                // skip the main diagonal for this section
                continue;
            }
            // starting in the first column, moving down right (or reverse)
            s = i * self.g.ncols;
            e = self.g.ncols * self.g.nrows - i - 1;
            try self.searchForwardBackward(s, e, stride);
        }

        // diagonal ur - dl and dl - ur
        i = 0;
        while (i < n) : (i += 1) {
            // advancing down left is ncols - 1
            const stride: isize = @intCast(self.g.ncols - 1);
            var s = i;
            var e = i * self.g.ncols;
            // starting in the first row, moving down left (or reverse)
            try self.searchForwardBackward(s, e, stride);

            if (i == 0) {
                // skip the main diagonal for this section
                continue;
            }
            // starting in the last column, moving down right (or reverse)
            s = (i + 1) * self.g.ncols - 1;
            e = self.g.ncols * (self.g.nrows - 1) + i;
            try self.searchForwardBackward(s, e, stride);
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

fn p2(allocator: std.mem.Allocator, lines: []const []const u8) !usize {
    var ss = try SearchState.init(allocator, lines, "MAS");
    defer ss.deinit();

    try ss.searchDiag();

    // Find all diagonal matches that share an A. Since only 2 matches
    // can ever share an A, we can sort and check adjacents. Also, two matches
    // cannot occupy the same diagonal, so they must form an X.
    std.mem.sort(usize, ss.matches.items, {}, std.sort.asc(usize));
    var i: usize = 0;
    var tot: usize = 0;
    while (i < ss.matches.items.len - 1) : (i += 1) {
        const a = ss.matches.items[i];
        const b = ss.matches.items[i + 1];

        if (a == b) {
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
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/4.txt");
    const a1 = try p1(std.heap.page_allocator, lines.items());
    const a2 = try p2(std.heap.page_allocator, lines.items());

    std.debug.print("p1: {d}\n", .{a1});
    std.debug.print("p2: {d}\n", .{a2});
}
