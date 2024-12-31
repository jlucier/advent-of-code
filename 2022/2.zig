const std = @import("std");
const zutils = @import("zutils");

fn getOppVal(play: u8) i8 {
    return switch (play) {
        'A' => 0,
        'B' => 1,
        'C' => 2,
        else => unreachable,
    };
}

fn score(game: *const [2]u8) u32 {
    const opp_play: i8 = getOppVal(game.ptr[0]);
    const my_play: i8 = switch (game.ptr[1]) {
        'X' => 0,
        'Y' => 1,
        'Z' => 2,
        else => unreachable,
    };

    const delta: i8 = opp_play - my_play;
    const result: u32 = switch (delta) {
        0 => 3,
        1 => 0,
        2 => 6,
        -1 => 6,
        -2 => 0,
        else => unreachable,
    };

    const uplay: u32 = @intCast(my_play);
    return uplay + 1 + result;
}

test "score" {
    try std.testing.expectEqual(score("AY"), 8);
    try std.testing.expectEqual(score("BX"), 1);
    try std.testing.expectEqual(score("CZ"), 6);
}

fn remap(game: *[2]u8) void {
    const opp_val = getOppVal(game.ptr[0]);
    // handle outcome
    var play: i8 = switch (game.ptr[1]) {
        'X' => @rem((opp_val - 1), 3),
        'Y' => opp_val,
        'Z' => @rem((opp_val + 1), 3),
        else => unreachable,
    };
    if (play < 0) {
        play += 3;
    }

    game.ptr[1] = switch (play) {
        0 => 'X',
        1 => 'Y',
        2 => 'Z',
        else => unreachable,
    };
}

test "p2" {
    var inputs = try std.testing.allocator.alloc(u8, 6);
    defer std.testing.allocator.free(inputs);
    std.mem.copyForwards(u8, inputs, "AYBXCZ");

    var i: u8 = 0;
    while (i < 6) : (i += 2) {
        const p: *[2]u8 = @ptrCast(inputs[i .. i + 2].ptr);
        remap(p);
    }

    try std.testing.expectEqual(score(inputs[0..2]), 4);
    try std.testing.expectEqual(score(inputs[2..4]), 1);
    try std.testing.expectEqual(score(inputs[4..6]), 7);
}

pub fn main() void {
    const allocator = std.heap.page_allocator;
    const ll = zutils.fs.readLines(allocator, "~/sync/dev/aoc_inputs/2022/2.txt") catch {
        std.debug.print("failed to read\n", .{});
        return;
    };
    defer ll.deinit();

    var p1: u32 = 0;
    var p2: u32 = 0;

    for (ll.items()) |ln| {
        if (ln.len != 3) {
            std.debug.print("Unexpected length of line: {d} {s}\n", .{ ln.len, ln });
            return;
        }

        var parts = [_]u8{ ln.ptr[0], ln.ptr[2] };
        // part 1
        p1 += score(&parts);

        // part 2
        remap(&parts);
        p2 += score(&parts);
    }

    std.debug.print("p1: {d}\n", .{p1});
    std.debug.print("p2: {d}\n", .{p2});
}
