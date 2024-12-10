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

    fn firstBlock(self: *const Layout, free: bool, hint: usize) ?usize {
        for (self.disk.items[hint..], 0..) |it, i| {
            if ((free and it.id == null) or (!free and it.id != null)) {
                return i + hint;
            }
        }
        return null;
    }

    fn lastBlock(self: *const Layout, free: bool, hint: usize) ?usize {
        var i: usize = hint;
        while (i >= 0) : (i -= 1) {
            const it = self.disk.items[i];
            if ((free and it.id == null) or (!free and it.id != null)) {
                return i;
            }
        }
        return null;
    }

    pub fn compactP1(self: *Layout) !void {
        var free_i = self.firstBlock(true, 0).?;
        var occ_i = self.lastBlock(false, self.disk.items.len - 1).?;
        while (occ_i > free_i) {
            // pop this guy off the list
            var occ_seg = &self.disk.items[occ_i];
            const free_seg = &self.disk.items[free_i];
            const amount_moved = zutils.min(usize, occ_seg.nblocks, free_seg.nblocks);

            if (free_seg.nblocks == amount_moved) {
                // the portion of occ moved subsumes free space
                free_seg.id = occ_seg.id;
                free_seg.nblocks = amount_moved;
            } else {
                // there is leftover free space, insert partial occ prior
                free_seg.nblocks -= amount_moved;
                occ_i += 1;
                try self.disk.insert(free_i, .{ .id = occ_seg.id, .nblocks = amount_moved });
            }

            // WARN: POINTERS INVALIDATED
            occ_seg = &self.disk.items[occ_i];
            occ_seg.nblocks -= amount_moved;
            if (occ_seg.nblocks == 0) {
                occ_seg.id = null;
            }

            free_i = self.firstBlock(true, free_i).?;
            occ_i = self.lastBlock(false, occ_i).?;
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
            }

            break;
        }
    }

    pub fn compactP2(self: *Layout, allocator: std.mem.Allocator) !void {
        const seen = try allocator.alloc(bool, self.disk.items.len / 2 + self.disk.items.len % 2);
        defer allocator.free(seen);

        var i: isize = @intCast(self.disk.items.len - 1);
        while (true) {
            // last block not seen
            var blkidx: ?usize = null;
            while (i >= 0) : (i -= 1) {
                const blk = self.disk.items[@intCast(i)];
                if (blk.id == null) {
                    continue;
                }
                if (!seen[blk.id.?]) {
                    blkidx = @intCast(i);
                    seen[blk.id.?] = true;
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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const lines = try zutils.readLines(allocator, "~/sync/dev/aoc_inputs/2024/9.txt");
    const ln = lines.strings.items[0];

    var layout1 = try Layout.init(allocator, ln);
    try layout1.compactP1();

    std.debug.print("p1: {d}\n", .{layout1.checksum()});

    var layout2 = try Layout.init(allocator, ln);
    try layout2.compactP2(std.heap.page_allocator);

    std.debug.print("p2: {d}\n", .{layout2.checksum()});
}
