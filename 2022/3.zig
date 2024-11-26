const std = @import("std");
const zutils = @import("zutils.zig");

/// Returns u8 [1,52]
fn charToPriority(ch: u8) u8 {
    if (ch >= 97) {
        return ch - 96;
    }

    return ch - 64 + 26;
}

/// Returns bitset friendly index for priority
fn charToPriorityIdx(ch: u8) u8 {
    return charToPriority(ch) - 1;
}

fn findSharedBetweenComps(sack: []const u8) !u8 {
    var s1 = std.StaticBitSet(52).initEmpty();

    for (sack[0 .. sack.len / 2]) |c| {
        s1.set(charToPriorityIdx(c));
    }
    for (sack[sack.len / 2 ..]) |c| {
        if (s1.isSet(charToPriorityIdx(c))) {
            return c;
        }
    }
    return 0;
}

fn p1Sacks(sacks: []const []const u8) !u32 {
    var tot: u32 = 0;
    for (sacks) |ln| {
        const sh = try findSharedBetweenComps(ln);
        const p: u32 = charToPriority(sh);
        tot += p;
    }

    return tot;
}

fn getBadge(allocator: std.mem.Allocator, group: []const []const u8) !u8 {
    const Bset = std.bit_set.StaticBitSet(52);
    const sets: []Bset = try allocator.alloc(Bset, group.len);
    defer allocator.free(sets);

    for (sets, 0..) |*bset, i| {
        bset.* = Bset.initEmpty();

        for (group[i]) |c| {
            bset.set(charToPriorityIdx(c));
        }
    }

    var final = sets[0];
    for (sets[1..]) |bset| {
        final.setIntersection(bset);
    }

    const priority: u8 = @intCast(final.findFirstSet() orelse 0);
    return priority + 1;
}

test "test input" {
    const lines = [_][]const u8{
        "vJrwpWtwJgWrhcsFMMfFFhFp",
        "jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL",
        "PmmdzqPrVvPwwTWBwg",
        "wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn",
        "ttgJtRGJQctTZtZT",
        "CrZsJsPPZsGzwwsLwLmpwMDw",
    };

    // p1
    try std.testing.expectEqual(charToPriority('a'), 1);
    try std.testing.expectEqual(charToPriority('z'), 26);
    try std.testing.expectEqual(charToPriority('A'), 27);
    try std.testing.expectEqual(charToPriority('Z'), 52);
    try std.testing.expectEqual(charToPriority(lines[0][0]), 22);

    const a1 = try findSharedBetweenComps(lines[0]);
    const a2 = try findSharedBetweenComps(lines[1]);
    const a3 = try findSharedBetweenComps(lines[2]);
    try std.testing.expectEqual(a1, 'p');
    try std.testing.expectEqual(a2, 'L');
    try std.testing.expectEqual(a3, 'P');

    const tot = try p1Sacks(&lines);
    try std.testing.expectEqual(tot, 157);

    // p2

    const b1 = try getBadge(std.testing.allocator, lines[0..3]);
    try std.testing.expectEqual(charToPriority('r'), b1);
}

pub fn main() void {
    const ll = zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/3.txt") catch {
        std.debug.print("Failed to read\n", .{});
        return;
    };
    defer ll.deinit();

    // p1
    const p1 = p1Sacks(ll.strings.items) catch {
        std.debug.print("Failed to process\n", .{});
        return;
    };
    std.debug.print("p1: {d}\n", .{p1});

    // p2

    var i: u32 = 0;
    var p2: u32 = 0;
    while (i < ll.size()) : (i += 3) {
        p2 += getBadge(std.heap.page_allocator, ll.strings.items[i .. i + 3]) catch {
            std.debug.print("Failed to get badge on input {d}", .{i});
            return;
        };
    }
    std.debug.print("p2: {d}\n", .{p2});
}
