const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);

fn printRope(rope: []const V2) void {
    // This function is ass. Does not work well
    var minX: isize = std.math.maxInt(isize);
    var maxX: isize = std.math.minInt(isize);
    var minY: isize = std.math.maxInt(isize);
    var maxY: isize = std.math.minInt(isize);

    for (rope) |v| {
        minX = zutils.min(isize, v.x, minX);
        maxX = zutils.max(isize, v.x, maxX);
        minY = zutils.min(isize, v.y, minY);
        maxY = zutils.max(isize, v.y, maxY);
    }
    // const minX: usize = 0;
    // const maxX: usize = 6;
    // const minY: usize = 0;
    // const maxY: usize = 6;

    // innefficient, but it'll do
    const dx: usize = zutils.max(usize, @intCast(maxX - minX), 10);
    const dy: usize = zutils.max(usize, @intCast(maxY - minY), 10);
    var j: usize = dy;
    std.debug.print("x=[{d},{d}] y=[{d},{d}]\n", .{ minX, maxX, minY, maxY });
    while (j > 0) : (j -= 1) {
        var i: usize = 0;
        while (i < dx) : (i += 1) {
            var match: bool = false;
            for (rope, 0..) |v, ri| {
                // if (v.x + minX == i and v.y + minY == j - 1) {
                if (v.x == i and v.y == j - 1) {
                    match = true;
                    std.debug.print("{d}", .{ri});
                    break;
                }
            }

            if (!match) {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    for (rope) |v| {
        std.debug.print("{}\n", .{v});
    }
    std.debug.print("\n", .{});
}

fn parseMove(move: []const u8) !V2 {
    const n: V2.ValueT = try std.fmt.parseInt(V2.ValueT, move[2..], 10);
    return switch (move[0]) {
        'R' => V2{
            .x = n,
            .y = 0,
        },
        'L' => V2{
            .x = -n,
            .y = 0,
        },
        'U' => V2{
            .x = 0,
            .y = n,
        },
        'D' => V2{
            .x = 0,
            .y = -n,
        },
        else => unreachable,
    };
}

/// Process a move, moving tail in reaction to head being moved, returns the reactionary move
fn reactTail(head: *const V2, tail: *V2) V2 {
    const dist = head.sub(tail.*);

    if (dist.mag() <= std.math.sqrt2) {
        return .{};
    }

    // need to move tail
    var tail_move = V2{};
    if (dist.x != 0 and dist.y != 0) {
        // must move diagonally
        tail_move = V2{
            .x = if (dist.x > 0) 1 else -1,
            .y = if (dist.y > 0) 1 else -1,
        };
    } else {
        // unit vector in the direction of the move should get us 1 away from head
        tail_move = dist.unit().asType(isize);
    }

    // move tail
    tail.addMut(tail_move);
    // sanity check that the move put tail adjacent to head
    std.debug.assert(tail.sub(head.*).mag() <= std.math.sqrt2);
    return tail_move;
}

fn trackTail(allocator: std.mem.Allocator, moves: []const []const u8, comptime n: comptime_int) !usize {
    var positions = std.array_hash_map.AutoArrayHashMap(V2, void).init(allocator);
    defer positions.deinit();
    var rope = [_]V2{.{}} ** n;

    // start processing
    var head = &rope[0];
    const tail = &rope[rope.len - 1];
    try positions.put(tail.*, {});

    for (moves) |m| {
        const mv = try parseMove(m);
        // break move into single steps
        const mvu = mv.unit().asType(isize);
        var i: usize = @intFromFloat(mv.mag());

        while (i > 0) : (i -= 1) {
            // start by moving the head according to the actual move
            head.addMut(mvu);

            // determine each segment's reactionary move
            var vi: usize = 0;
            while (vi < rope.len - 1) : (vi += 1) {
                _ = reactTail(&rope[vi], &rope[vi + 1]);
            }
            // track actual tail position
            try positions.put(tail.*, {});
        }
    }

    return positions.count();
}

test "p1" {
    const moves = [_][]const u8{
        "R 4",
        "U 4",
        "L 3",
        "D 1",
        "R 4",
        "D 1",
        "L 5",
        "R 2",
    };
    const npos = try trackTail(std.testing.allocator, &moves, 2);
    try std.testing.expectEqual(13, npos);
}

test "p2 simple" {
    const moves = [_][]const u8{
        "R 4",
        "U 4",
        "L 3",
        "D 1",
        "R 4",
        "D 1",
        "L 5",
        "R 2",
    };
    const npos = try trackTail(std.testing.allocator, &moves, 10);
    try std.testing.expectEqual(1, npos);
}

test "p2 harder" {
    const moves = [_][]const u8{
        "R 5",
        "U 8",
        "L 8",
        "D 3",
        "R 17",
        "D 10",
        "L 25",
        "U 20",
    };
    const npos = try trackTail(std.testing.allocator, &moves, 10);
    try std.testing.expectEqual(36, npos);
}

pub fn main() void {
    const moves = zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/9.txt") catch {
        std.debug.print("Failed to read file\n", .{});
        return;
    };
    defer moves.deinit();

    const p1 = trackTail(std.heap.page_allocator, moves.strings.items, 2) catch {
        std.debug.print("Failed to process moves\n", .{});
        return;
    };
    std.debug.print("p1: {d}\n", .{p1});

    const p2 = trackTail(std.heap.page_allocator, moves.strings.items, 10) catch {
        std.debug.print("Failed to process moves\n", .{});
        return;
    };
    std.debug.print("p2: {d}\n", .{p2});
}
