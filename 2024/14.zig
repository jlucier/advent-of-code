const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);

const Robot = struct {
    pos: V2,
    vel: V2,
};

fn parseRobots(allocator: std.mem.Allocator, inp: []const []const u8) ![]Robot {
    const bots = try allocator.alloc(Robot, inp.len);
    for (inp, 0..) |ln, i| {
        const feq = std.mem.indexOfScalar(u8, ln, '=').?;
        const c1 = std.mem.indexOfScalar(u8, ln, ',').?;
        const sp = std.mem.indexOfScalar(u8, ln, ' ').?;
        const leq = std.mem.lastIndexOfScalar(u8, ln, '=').?;
        const c2 = std.mem.lastIndexOfScalar(u8, ln, ',').?;

        bots[i] = .{ .pos = V2{
            .x = try std.fmt.parseInt(isize, ln[feq + 1 .. c1], 10),
            .y = try std.fmt.parseInt(isize, ln[c1 + 1 .. sp], 10),
        }, .vel = V2{
            .x = try std.fmt.parseInt(isize, ln[leq + 1 .. c2], 10),
            .y = try std.fmt.parseInt(isize, ln[c2 + 1 ..], 10),
        } };
    }
    return bots;
}

fn moveRobot(bot: *Robot, gsize: V2, steps: isize) void {
    bot.pos.x += bot.vel.x * steps;
    bot.pos.x = @mod(bot.pos.x, gsize.x);

    bot.pos.y += bot.vel.y * steps;
    bot.pos.y = @mod(bot.pos.y, gsize.y);
}

fn print(gsize: V2, bots: []Robot) !void {
    var grid = try zutils.Grid(u8).init(std.heap.page_allocator, @intCast(gsize.y), @intCast(gsize.x));
    defer grid.deinit();
    grid.fill(0);

    for (bots) |b| {
        grid.atPtr(@intCast(b.pos.y), @intCast(b.pos.x)).* += 1;
    }
    grid.print();
}

fn runRobots(bots: []Robot, gsize: V2, steps: isize) void {
    for (bots) |*b| {
        moveRobot(b, gsize, steps);
    }
}

fn part1(bots: []Robot, gsize: V2) !usize {
    // part 1 answer
    var q = [4]usize{ 0, 0, 0, 0 };
    const hx = @divTrunc(gsize.x, 2);
    const hy = @divTrunc(gsize.y, 2);
    for (bots) |b| {
        if (b.pos.x == hx) {
            continue;
        }
        if (b.pos.y == hy) {
            continue;
        }

        var idx: usize = if (b.pos.x > hx) 1 else 0;
        idx += if (b.pos.y > hy) 2 else 0;
        q[idx] += 1;
    }

    return q[0] * q[1] * q[2] * q[3];
}

test "example" {
    const inp = [_][]const u8{
        "p=0,4 v=3,-3",
        "p=6,3 v=-1,-3",
        "p=10,3 v=-1,2",
        "p=2,0 v=2,-1",
        "p=0,0 v=1,3",
        "p=3,0 v=-2,-2",
        "p=7,6 v=-1,-3",
        "p=3,0 v=-1,-2",
        "p=9,3 v=2,3",
        "p=7,3 v=-1,2",
        "p=2,4 v=2,-3",
        "p=9,5 v=-3,-3",
    };
    const bots = try parseRobots(std.testing.allocator, &inp);
    defer std.testing.allocator.free(bots);

    const gsize = V2{ .x = 11, .y = 7 };
    runRobots(bots, gsize, 100);
    const a1 = try part1(bots, gsize);
    try std.testing.expectEqual(12, a1);
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/Downloads/14.txt");
    defer lines.deinit();
    const bots = try parseRobots(std.heap.page_allocator, lines.strings.items);
    defer std.heap.page_allocator.free(bots);

    const gsize = V2{ .x = 101, .y = 103 };
    const a1 = try part1(bots, gsize);
    std.debug.print("p1: {d}\n", .{a1});

    // const bots2 = try parseRobots(std.heap.page_allocator, lines.strings.items);
    // defer std.heap.page_allocator.free(bots2);
    // var i: usize = 210;
    // const d: isize = 101;
    // runRobots(bots2, gsize, @intCast(i));
    // while (i < 7000) : (i += d) {
    //     std.debug.print("step: {d}\n", .{i});
    //     try print(gsize, bots2);
    //     std.time.sleep(25e7);
    //     runRobots(bots2, gsize, d);
    // }
}
