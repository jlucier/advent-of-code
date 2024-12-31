const std = @import("std");
const zutils = @import("zutils");

pub fn main() void {
    const allocator = std.heap.page_allocator;
    const ll = zutils.fs.readLines(allocator, "~/sync/dev/aoc_inputs/2022/1.txt") catch {
        std.debug.print("Failed to read", .{});
        return;
    };
    defer ll.deinit();

    var curr: u32 = 0;
    var totals = std.ArrayList(u32).init(allocator);

    for (ll.items()) |ln| {
        if (ln.len == 0) {
            totals.append(curr) catch {
                std.debug.print("Failed to grow array\n", .{});
                return;
            };
            curr = 0;
        } else {
            curr += std.fmt.parseInt(u32, ln, 10) catch {
                std.debug.print("Failed to parse int: {s}", .{ln});
                return;
            };
        }
    }

    std.mem.sort(u32, totals.items, {}, std.sort.desc(u32));

    std.debug.print("p1: {d}\n", .{totals.items[0]});
    std.debug.print("p2: {d}\n", .{zutils.sum(u32, totals.items[0..3])});
}
