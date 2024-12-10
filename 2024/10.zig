const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);
const CostCache = std.AutoArrayHashMap(V2, usize);
const Grid = zutils.Grid(u8);

const State = struct {
    allocator: std.mem.Allocator,
    grid: Grid,
    starts: []V2,

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
        };
    }

    fn deinit(self: *State) void {
        self.grid.deinit();
        self.allocator.free(self.starts);
    }
};

fn search(allocator: std.mem.Allocator, cache: CostCache, start: V2, grid: Grid) usize {
    var queue = try std.ArrayList(V2).initCapacity(allocator, 4);
    queue.appendAssumeCapacity(start);

    while (queue.popOrNull()) |loc| {
        const next = [4]V2{
            // left
            loc.add(.{ .x = -1 }),
            // right
            loc.add(.{ .x = 1 }),
            // up
            loc.add(.{ .y = -1 }),
            // down
            loc.add(.{ .y = 1 }),
        };
        for (next) |n| {
            if (!n.inGridBounds(grid.ncols, grid.nrows)) {
                continue;
            }
        }
    }
}

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
}

pub fn main() !void {}
