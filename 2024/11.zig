const std = @import("std");
const zutils = @import("zutils");

const StoneList = std.array_list.Managed(usize);
const CacheKey = struct {
    value: usize,
    steps: usize,
};
const Cache = std.AutoHashMap(CacheKey, usize);

fn parseStones(allocator: std.mem.Allocator, line: []const u8) !StoneList {
    var list = try StoneList.initCapacity(allocator, std.mem.count(u8, line, " ") + 1);
    var iter = std.mem.splitScalar(u8, line, ' ');
    while (iter.next()) |s| {
        list.appendAssumeCapacity(try std.fmt.parseUnsigned(usize, s, 10));
    }
    return list;
}

fn stepForward(cache: *Cache, value: usize, steps: usize) !usize {
    if (cache.get(.{ .value = value, .steps = steps })) |res| {
        return res;
    } else if (steps == 0) {
        return 1;
    }

    const log = if (value != 0) std.math.log10_int(value) else 0;
    var tot: usize = 0;

    if (value == 0) {
        tot += try stepForward(cache, 1, steps - 1);
    } else if (log % 2 == 0) {
        tot += try stepForward(cache, value * 2024, steps - 1);
    } else {
        const base = std.math.pow(usize, 10, log / 2 + 1);
        tot += try stepForward(cache, value / base, steps - 1);
        tot += try stepForward(cache, value % base, steps - 1);
    }
    try cache.put(.{ .value = value, .steps = steps }, tot);
    return tot;
}

fn blinkNTimes(allocator: std.mem.Allocator, list: *StoneList, n: usize) !usize {
    var cache = Cache.init(allocator);
    defer cache.deinit();

    var tot: usize = 0;
    for (list.items) |stone| {
        tot += try stepForward(&cache, stone, n);
    }
    return tot;
}

test "simple" {
    const inp = "125 17";

    var list = try parseStones(std.testing.allocator, inp);
    defer list.deinit();

    const a1 = try blinkNTimes(std.testing.allocator, &list, 6);
    try std.testing.expectEqual(22, a1);

    const a2 = try blinkNTimes(std.testing.allocator, &list, 25);
    try std.testing.expectEqual(55312, a2);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/11.txt");
    defer lines.deinit();

    var list = try parseStones(std.heap.page_allocator, lines.items()[0]);
    defer list.deinit();

    const p1 = try blinkNTimes(std.heap.page_allocator, &list, 25);
    std.debug.print("p1: {d}\n", .{p1});

    const p2 = try blinkNTimes(std.heap.page_allocator, &list, 75);
    std.debug.print("p2: {d}\n", .{p2});
}
