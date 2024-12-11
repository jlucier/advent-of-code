const std = @import("std");
const zutils = @import("zutils");

const StoneList = std.ArrayList(Stone);

const Stone = struct {
    order: usize,
    zero: bool,
};

fn parseStones(allocator: std.mem.Allocator, line: []const u8) !StoneList {
    var list = try StoneList.initCapacity(allocator, std.mem.count(u8, line, " ") + 1);
    var iter = std.mem.splitScalar(u8, line, ' ');
    while (iter.next()) |s| {
        const v = try std.fmt.parseUnsigned(usize, s, 10);
        list.appendAssumeCapacity(.{
            .order = if (v == 0) 0 else std.math.log10_int(v),
            .zero = v == 0,
        });
    }
    return list;
}

fn blinkNTimes(list: *StoneList, n: usize) !void {
    var b: usize = 0;
    while (b < n) : (b += 1) {
        var i: usize = 0;
        const og_len = list.items.len;
        while (i < og_len) : (i += 1) {
            // TODO need to figure out how to work with the order and determine if a number's
            // lower half is zero or not. Maybe just if it's a clean multiple of 10**order/2+1?
            const v = &list.items[i];
            const log = if (v.* != 0) std.math.log10_int(v.*) else 0;

            if (v.* == 0) {
                v.* = 1;
            } else if (log % 2 == 0) {
                // even log = odd num digits
                v.* *= 2024;
            } else {
                const base = std.math.pow(usize, 10, log / 2 + 1);
                const left = v.* / base;
                const right = v.* % base;

                v.* = left;
                try list.append(right);
            }
        }
    }
}

test "simple" {
    const inp = "125 17";

    var list = try parseStones(std.testing.allocator, inp);
    defer list.deinit();

    try blinkNTimes(&list, 6);
    try std.testing.expectEqual(22, list.items.len);

    try blinkNTimes(&list, 19);
    try std.testing.expectEqual(55312, list.items.len);
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/11.txt");
    defer lines.deinit();

    var list = try parseStones(std.heap.page_allocator, lines.strings.items[0]);
    defer list.deinit();

    try blinkNTimes(&list, 25);
    std.debug.print("p1: {d}\n", .{list.items.len});

    try blinkNTimes(&list, 50);
    std.debug.print("p2: {d}\n", .{list.items.len});
}
