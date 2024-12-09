const std = @import("std");
const zutils = @import("zutils");

const Segment = struct {
    id: ?usize,
    nblocks: usize,
};

const Layout = struct {
    disk: std.ArrayList(Segment),

    pub fn init(allocator: std.mem.Allocator, str: []const u8) !Layout {
        var layout = Layout{
            .disk = try std.ArrayList(Segment).initCapacity(allocator, str.len),
        };

        for (str, 0..) |_, i| {
            const v = try std.fmt.parseUnsigned(usize, str[i .. i + 1], 10);
            const i_adj = i / 2 + i % 2;
            layout.disk.appendAssumeCapacity(.{
                .id = if (i % 2 == 0) @intCast(i_adj) else null,
                .nblocks = v,
            });
        }
        return layout;
    }

    pub fn deinit(self: *const Layout) void {
        self.disk.deinit();
    }

    fn firstBlock(self: *const Layout, free: bool) ?usize {
        for (self.disk.items, 0..) |it, i| {
            if ((free and it.id == null) or (!free and it.id != null)) {
                return i;
            }
        }
        return null;
    }

    fn lastBlock(self: *const Layout, free: bool) ?usize {
        var i: usize = self.disk.items.len - 1;
        while (i >= 0) : (i -= 1) {
            const it = self.disk.items[i];
            if ((free and it.id == null) or (!free and it.id != null)) {
                return i;
            }
        }
        return null;
    }

    pub fn compactP1(self: *Layout) !void {
        while (true) {
            const free_i = self.firstBlock(true).?;
            const occ_i = self.lastBlock(false).?;

            if (occ_i < free_i) {
                return;
            }

            // pop this guy off the list
            var occ_seg = self.disk.orderedRemove(occ_i);
            const free_seg = &self.disk.items[free_i];
            const amount_moved = zutils.min(usize, occ_seg.nblocks, free_seg.nblocks);

            free_seg.nblocks -= amount_moved;
            occ_seg.nblocks -= amount_moved;

            if (free_seg.nblocks == 0) {
                // the portion of occ moved subsumes free space
                free_seg.id = occ_seg.id;
                free_seg.nblocks = amount_moved;
            }
            // WARN: POINTERS INVALIDATED
            else {
                // there is leftover free space, insert partial occ prior
                try self.disk.insert(free_i, .{ .id = occ_seg.id, .nblocks = amount_moved });
            }

            if (occ_seg.nblocks > 0) {
                // add it back, didn't finish
                self.disk.appendAssumeCapacity(occ_seg);
            }
        }
    }

    fn compactOneSeg(self: *Layout, idx: usize) !void {
        const seg = &self.disk.items[idx];
        var fidx: usize = 0;
        while (fidx < idx) : (fidx += 1) {
            const fseg = &self.disk.items[fidx];
            if (fseg.id != null or fseg.nblocks < seg.nblocks) {
                continue;
            }

            if (fseg.nblocks == seg.nblocks) {
                // replace
                fseg.id = seg.id;
                seg.id = null;
            } else {
                fseg.nblocks -= seg.nblocks;
                const sid = seg.id;
                seg.id = null;
                // WARN: Invalidate pointers
                try self.disk.insert(fidx, .{ .id = sid, .nblocks = seg.nblocks });
                // free og
            }

            break;
        }
    }

    pub fn compactP2(self: *Layout, allocator: std.mem.Allocator) !void {
        var seen = std.AutoHashMap(usize, void).init(allocator);
        defer seen.deinit();

        while (true) {
            // last block not seen
            var i: isize = @intCast(self.disk.items.len - 1);
            var blkidx: ?usize = null;
            while (i >= 0) : (i -= 1) {
                const blk = self.disk.items[@intCast(i)];
                if (blk.id == null) {
                    continue;
                }
                const res = try seen.getOrPut(blk.id.?);
                if (!res.found_existing) {
                    blkidx = @intCast(i);
                    break;
                }
            }
            if (blkidx) |idx| {
                try self.compactOneSeg(idx);
            } else {
                break;
            }
        }
    }

    pub fn checksum(self: *const Layout) usize {
        var disk_i: usize = 0;
        var sum: usize = 0;
        for (self.disk.items) |it| {
            var j: usize = 0;
            while (j < it.nblocks) : (j += 1) {
                if (it.id) |id| {
                    sum += disk_i * id;
                }
                disk_i += 1;
            }
        }
        return sum;
    }

    pub fn printDisk(self: *const Layout) void {
        for (self.disk.items) |it| {
            var i: usize = 0;
            const id: u8 = if (it.id != null) @intCast(it.id.? + 48) else '.';
            while (i < it.nblocks) : (i += 1) {
                std.debug.print("{c}", .{id});
            }
        }
        std.debug.print("\n", .{});
    }
};

const EXAMPLE = "2333133121414131402";

test "p1" {
    var layout = try Layout.init(std.testing.allocator, EXAMPLE);
    defer layout.deinit();

    try layout.compactP1();
    try std.testing.expectEqual(1928, layout.checksum());
}

test "p2" {
    var layout = try Layout.init(std.testing.allocator, EXAMPLE);
    defer layout.deinit();

    try layout.compactP2(std.testing.allocator);

    try std.testing.expectEqual(2858, layout.checksum());
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/9.txt");
    defer lines.deinit();
    const ln = lines.strings.items[0];

    var layout1 = try Layout.init(std.heap.page_allocator, ln);
    try layout1.compactP1();

    std.debug.print("p1: {d}\n", .{layout1.checksum()});

    var layout2 = try Layout.init(std.heap.page_allocator, ln);
    try layout2.compactP2(std.heap.page_allocator);

    std.debug.print("p2: {d}\n", .{layout2.checksum()});
}
