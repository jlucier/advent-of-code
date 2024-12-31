const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);
const V2Set = std.AutoArrayHashMap(V2, void);
const ReachMap = std.AutoArrayHashMap(V2, SearchVals);
const Grid = zutils.Grid(u8);

const SearchVals = struct {
    vset: V2Set,
    npaths: usize = 0,
};

const State = struct {
    allocator: std.mem.Allocator,
    grid: Grid,
    starts: []V2,
    visited: ReachMap,

    fn initParse(allocator: std.mem.Allocator, lines: []const []const u8) !State {
        const parser = zutils.makeIntParser(u8, u8, 10, 0);
        const grid = try Grid.init2DSliceWithParser(u8, allocator, lines, parser.parse);
        var starts = std.ArrayList(V2).init(allocator);
        defer starts.deinit();

        var iter = grid.iterator();
        while (iter.next()) |loc| {
            const v = grid.at(loc.y, loc.x);
            if (v == 0) {
                try starts.append(loc.asType(isize));
            }
        }

        return .{
            .allocator = allocator,
            .grid = grid,
            .starts = try starts.toOwnedSlice(),
            .visited = ReachMap.init(allocator),
        };
    }

    fn deinit(self: *State) void {
        self.grid.deinit();
        self.allocator.free(self.starts);
        for (self.visited.values()) |*v| {
            v.vset.deinit();
        }
        self.visited.deinit();
    }

    fn print(self: *const State, pos: V2) void {
        std.debug.print("\n", .{});

        var i: usize = 0;
        while (i < self.grid.nrows) : (i += 1) {
            var j: usize = 0;
            while (j < self.grid.ncols) : (j += 1) {
                const v = self.grid.at(i, j);
                const loc = V2{ .x = @intCast(j), .y = @intCast(i) };
                if (pos.equal(loc)) {
                    std.debug.print("{s}{d}{s}", .{ zutils.ANSI_RED, v, zutils.ANSI_RESET });
                } else if (self.visited.getPtr(loc) != null) {
                    std.debug.print("{s}{d}{s}", .{ zutils.ANSI_GREEN, v, zutils.ANSI_RESET });
                } else {
                    std.debug.print("{d}", .{v});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    fn search(self: *State, pos: V2) !void {
        if (self.visited.getPtr(pos) != null) {
            return;
        }

        const v: i8 = @intCast(self.grid.at(@intCast(pos.y), @intCast(pos.x)));
        try self.visited.put(pos, .{
            .vset = V2Set.init(self.allocator),
        });

        if (v == 9) {
            const tmp = self.visited.getPtr(pos).?;
            try tmp.vset.put(pos, {});
            tmp.npaths += 1;
            return;
        }

        const next = [4]V2{
            // left
            pos.add(.{ .x = -1 }),
            // right
            pos.add(.{ .x = 1 }),
            // up
            pos.add(.{ .y = -1 }),
            // down
            pos.add(.{ .y = 1 }),
        };

        for (next) |n| {
            if (!n.inGridBounds(@intCast(self.grid.ncols), @intCast(self.grid.nrows))) {
                continue;
            }

            const nv: i8 = @intCast(self.grid.at(@intCast(n.y), @intCast(n.x)));
            if (nv - v != 1) {
                continue;
            }

            try self.search(n);
            const nreach = self.visited.getPtr(n).?;
            var myreach = self.visited.getPtr(pos).?;
            for (nreach.vset.keys()) |p| {
                try myreach.vset.put(p, {});
            }
            myreach.npaths += nreach.npaths;
        }
    }

    fn parts(self: *State) ![2]usize {
        var p1: usize = 0;
        var p2: usize = 0;
        for (self.starts) |st| {
            try self.search(st);
            const res = self.visited.getPtr(st).?;
            p1 += res.vset.count();
            p2 += res.npaths;
        }
        return .{ p1, p2 };
    }
};

test "example" {
    const lines = [_][]const u8{
        "89010123",
        "78121874",
        "87430965",
        "96549874",
        "45678903",
        "32019012",
        "01329801",
        "10456732",
    };

    var st = try State.initParse(std.testing.allocator, &lines);
    defer st.deinit();
    const ans = try st.parts();

    try std.testing.expectEqual(36, ans[0]);
    try std.testing.expectEqual(81, ans[1]);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/10.txt");
    var st = try State.initParse(std.heap.page_allocator, lines.items());
    defer st.deinit();

    const ans = try st.parts();
    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
