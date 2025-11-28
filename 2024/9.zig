const std = @import("std");
const zutils = @import("zutils");

const Segment = struct {
    id: usize,
    nblocks: usize,
    nfree: usize = 0,
};

const Layout = struct {
    disk: std.array_list.Managed(Segment),

    pub fn init(allocator: std.mem.Allocator, str: []const u8) !Layout {
        var layout = Layout{
            .disk = try std.array_list.Managed(Segment).initCapacity(allocator, str.len / 2 + str.len % 2),
        };

        for (str, 0..) |_, i| {
            const v = try std.fmt.parseUnsigned(usize, str[i .. i + 1], 10);
            const i_adj = i / 2;
            if (i % 2 == 0) {
                layout.disk.appendAssumeCapacity(.{
                    .id = i_adj,
                    .nblocks = v,
                });
            } else {
                layout.disk.items[i_adj].nfree = v;
            }
        }
        return layout;
    }

    pub fn deinit(self: *const Layout) void {
        self.disk.deinit();
    }

    fn firstBlock(self: *const Layout, free: bool, hint: usize) ?usize {
        for (self.disk.items[hint..], 0..) |it, i| {
            if ((free and it.nfree > 0) or (!free and it.nblocks > 0)) {
                return i + hint;
            }
        }
        return null;
    }

    fn lastBlock(self: *const Layout, free: bool, hint: usize) ?usize {
        var i: usize = hint;
        while (i >= 0) : (i -= 1) {
            const it = self.disk.items[i];
            if ((free and it.nfree > 0) or (!free and it.nblocks > 0)) {
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
            const amount_moved = zutils.min(usize, occ_seg.nblocks, free_seg.nfree);

            occ_seg.nblocks -= amount_moved;
            free_seg.nfree -= amount_moved;

            const moved = Segment{
                .id = occ_seg.id,
                .nblocks = amount_moved,
                .nfree = free_seg.nfree,
            };
            free_seg.nfree = 0;

            // WARN: POINTERS INVALIDATED
            occ_i += 1;
            try self.disk.insert(free_i + 1, moved);

            occ_seg = &self.disk.items[occ_i];
            if (occ_seg.nblocks == 0) {
                _ = self.disk.swapRemove(occ_i);
                occ_i -= 1;
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
            if (fseg.nfree < seg.nblocks) {
                continue;
            }

            const nfree = fseg.nfree - seg.nblocks;
            const nblocks = seg.nblocks;
            fseg.nfree = 0;
            seg.nfree += seg.nblocks;
            seg.nblocks = 0;
            try self.disk.insert(fidx + 1, .{
                .id = seg.id,
                .nblocks = nblocks,
                .nfree = nfree,
            });

            break;
        }
    }

    pub fn compactP2(self: *Layout, allocator: std.mem.Allocator) !void {
        const seen = try allocator.alloc(bool, self.disk.items.len);
        defer allocator.free(seen);

        var i: isize = @intCast(self.disk.items.len - 1);
        while (true) {
            // last block not seen
            var blkidx: ?usize = null;
            while (i >= 0) : (i -= 1) {
                const blk = self.disk.items[@intCast(i)];
                if (blk.nblocks == 0) {
                    continue;
                }
                if (!seen[blk.id]) {
                    blkidx = @intCast(i);
                    seen[blk.id] = true;
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
                sum += disk_i * it.id;
                disk_i += 1;
            }
            disk_i += it.nfree;
        }
        return sum;
    }

    pub fn printDisk(self: *const Layout) void {
        for (self.disk.items) |it| {
            var i: usize = 0;
            const c: u8 = @intCast(it.id + 48);
            while (i < it.nblocks) : (i += 1) {
                std.debug.print("{c}", .{c});
            }
            i = 0;
            while (i < it.nfree) : (i += 1) {
                std.debug.print(".", .{});
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
    const lines = try zutils.fs.readLines(allocator, "~/sync/dev/aoc_inputs/2024/9.txt");
    const ln = lines.items()[0];

    var layout1 = try Layout.init(allocator, ln);
    try layout1.compactP1();

    std.debug.print("p1: {d}\n", .{layout1.checksum()});

    var layout2 = try Layout.init(allocator, ln);
    try layout2.compactP2(std.heap.page_allocator);

    std.debug.print("p2: {d}\n", .{layout2.checksum()});
}
