const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);

const Game = struct {
    a: V2,
    b: V2,
    prize: V2,

    fn minPresses(self: *const Game, scale: isize) ?V2 {
        // cramer's rule for solving
        const det = self.a.x * self.b.y - self.b.x * self.a.y;
        if (det == 0) return null;

        const p = self.prize.add(.{ .x = scale, .y = scale });

        const a_num = p.x * self.b.y - self.b.x * p.y;
        const b_num = p.y * self.a.x - self.a.y * p.x;
        const abs_det: isize = @intCast(@abs(det));
        if (@rem(a_num, abs_det) != 0 or @rem(b_num, abs_det) != 0) {
            return null;
        }
        return .{
            .x = @divExact(a_num, det),
            .y = @divExact(b_num, det),
        };
    }
};

fn parseV2(line: []const u8) !V2 {
    const xidx = std.mem.indexOfScalar(u8, line, 'X').?;
    const yidx = std.mem.indexOfScalar(u8, line, 'Y').?;
    const comma = std.mem.indexOfScalar(u8, line, ',').?;

    return .{
        .x = try std.fmt.parseUnsigned(isize, line[xidx + 2 .. comma], 10),
        .y = try std.fmt.parseUnsigned(isize, line[yidx + 2 ..], 10),
    };
}

fn parseInput(allocator: std.mem.Allocator, lines: []const []const u8) ![]Game {
    const games = try allocator.alloc(Game, lines.len / 4 + 1);
    var i: usize = 0;
    while (i < lines.len) : (i += 4) {
        games[i / 4] = .{
            .a = try parseV2(lines[i]),
            .b = try parseV2(lines[i + 1]),
            .prize = try parseV2(lines[i + 2]),
        };
    }
    return games;
}

fn solve(games: []Game, scale: isize) usize {
    var tok: usize = 0;
    for (games) |g| {
        if (g.minPresses(scale)) |v| {
            tok += @intCast(v.x * 3 + v.y);
        }
    }
    return tok;
}

test "example" {
    const lines = [_][]const u8{
        "Button A: X+94, Y+34",
        "Button B: X+22, Y+67",
        "Prize: X=8400, Y=5400",
        "",
        "Button A: X+26, Y+66",
        "Button B: X+67, Y+21",
        "Prize: X=12748, Y=12176",
        "",
        "Button A: X+17, Y+86",
        "Button B: X+84, Y+37",
        "Prize: X=7870, Y=6450",
        "",
        "Button A: X+69, Y+23",
        "Button B: X+27, Y+71",
        "Prize: X=18641, Y=10279",
    };

    const games = try parseInput(std.testing.allocator, &lines);
    defer std.testing.allocator.free(games);

    try std.testing.expectEqual(480, solve(games, 0));
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/13.txt");
    defer lines.deinit();

    const games = try parseInput(std.heap.page_allocator, lines.items());
    defer std.heap.page_allocator.free(games);

    std.debug.print("p1: {d}\n", .{solve(games, 0)});
    std.debug.print("p2: {d}\n", .{solve(games, 10000000000000)});
}
