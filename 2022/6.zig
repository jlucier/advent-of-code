const std = @import("std");
const zutils = @import("zutils");

const ASCII_A = 97;

fn searchForNUnique(data: []const u8, n: u8) usize {
    var counts = [_]u8{0} ** 26;

    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        const v = data[i] - ASCII_A;
        // add current to set
        counts[v] += 1;

        if (zutils.sum(u8, &counts) == n and zutils.countNonzero(u8, &counts) == n) {
            return i + 1;
        }

        // not enough uniques yet, remove oldest and keep going
        if (i > n - 2) {
            counts[data[i - (n - 1)] - ASCII_A] -= 1;
        }
    }
    return 0;
}

test "stuff" {
    const test_inps = [_][]const u8{
        "mjqjpqmgbljsphdztnvjfqwrcgsmlb",
        "bvwbjplbgvbhsrlpgdmjqwftvncz",
        "nppdvjthqldpwncqszvftbrmjlhg",
        "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg",
        "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw",
    };

    try std.testing.expectEqual(7, searchForNUnique(test_inps[0], 4));
    try std.testing.expectEqual(19, searchForNUnique(test_inps[0], 14));

    try std.testing.expectEqual(5, searchForNUnique(test_inps[1], 4));
    try std.testing.expectEqual(23, searchForNUnique(test_inps[1], 14));

    try std.testing.expectEqual(6, searchForNUnique(test_inps[2], 4));
    try std.testing.expectEqual(23, searchForNUnique(test_inps[2], 14));

    try std.testing.expectEqual(10, searchForNUnique(test_inps[3], 4));
    try std.testing.expectEqual(29, searchForNUnique(test_inps[3], 14));

    try std.testing.expectEqual(11, searchForNUnique(test_inps[4], 4));
    try std.testing.expectEqual(26, searchForNUnique(test_inps[4], 14));
}

pub fn main() void {
    const file = zutils.fs.openFile(
        std.heap.page_allocator,
        "~/sync/dev/aoc_inputs/2022/6.txt",
        .{ .mode = .read_only },
    ) catch {
        std.debug.print("Failed to open file\n", .{});
        return;
    };
    defer file.close();

    const buf = file.readToEndAlloc(std.heap.page_allocator, 1_000_000) catch {
        std.debug.print("Failed to read file\n", .{});
        return;
    };
    defer std.heap.page_allocator.free(buf);

    std.debug.print("p1: {d}\n", .{searchForNUnique(buf, 4)});
    std.debug.print("p2: {d}\n", .{searchForNUnique(buf, 14)});
}
