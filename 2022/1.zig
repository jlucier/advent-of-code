const std = @import("std");
const zutils = @import("zutils.zig");

pub fn main() void {
    const allocator = std.heap.page_allocator;
    const res1 = zutils.expandHomeDir(allocator, "~") catch {
        std.debug.print("Bad alloc\n", .{});
        return;
    };
    defer allocator.free(res1);
    std.debug.print("{s}\n", .{res1});
}
