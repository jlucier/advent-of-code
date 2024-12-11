const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);
const V2Set = std.AutoArrayHashMap(V2, void);
const ReachMap = std.AutoArrayHashMap(V2, V2Set);
const Grid = zutils.Grid(u8);

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
        for (self.visited.values()) |*vset| {
            vset.deinit();
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

        // self.print(pos);
        const v: i8 = @intCast(self.grid.at(@intCast(pos.y), @intCast(pos.x)));
        try self.visited.put(pos, V2Set.init(self.allocator));

        if (v == 9) {
            try self.visited.getPtr(pos).?.put(pos, {});
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
            for (nreach.keys()) |p| {
                try myreach.put(p, {});
            }
        }
    }

    fn p1(self: *State) !usize {
        var tot: usize = 0;
        for (self.starts) |st| {
            try self.search(st);
            tot += self.visited.getPtr(st).?.count();
        }
        return tot;
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

    try std.testing.expectEqual(36, try st.p1());
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/10.txt");
    var st = try State.initParse(std.heap.page_allocator, lines.strings.items);
    defer st.deinit();

    std.debug.print("p1: {d}\n", .{try st.p1()});
}
