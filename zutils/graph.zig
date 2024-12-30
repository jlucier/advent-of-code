const std = @import("std");

/// Create a dijkstras solver given a type for the node and function
pub fn Dijkstras(comptime VData: type, comptime Context: type) type {
    return struct {
        const PredList = std.ArrayList(VData);

        pub const Vertex = struct {
            v: VData,
            d: usize = std.math.maxInt(usize),
            pred: PredList,

            fn deinit(self: *const Vertex) void {
                self.pred.deinit();
            }

            fn compare(_: void, a: *const Vertex, b: *const Vertex) std.math.Order {
                return if (a.d < b.d) .lt else if (a.d == b.d) .eq else .gt;
            }
        };

        pub const Edge = struct {
            cost: usize,
            v: VData,
        };

        const AdjFn = fn (
            allcator: std.mem.Allocator,
            v: VData,
            ctx: Context,
        ) std.mem.Allocator.Error![]Edge;

        const Self = @This();

        allocator: std.mem.Allocator,
        start: VData,
        verts: std.AutoArrayHashMap(VData, Vertex),
        context: Context,

        pub fn init(
            allocator: std.mem.Allocator,
            start: VData,
            initial_verts: []VData,
            context: Context,
        ) !Self {
            var dv = std.AutoArrayHashMap(VData, Vertex).init(allocator);
            try dv.ensureTotalCapacity(initial_verts.len);

            for (initial_verts) |vd| {
                dv.putAssumeCapacity(vd, .{ .v = vd, .pred = PredList.init(allocator) });
            }

            dv.putAssumeCapacity(start, .{
                .v = start,
                .d = 0,
                .pred = PredList.init(allocator),
            });

            dv.lockPointers();
            return .{
                .allocator = allocator,
                .start = start,
                .verts = dv,
                .context = context,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.verts.values()) |*dv| {
                dv.deinit();
            }
            self.verts.unlockPointers();
            self.verts.deinit();
        }

        pub fn findPaths(self: *Self, getAdjacent: AdjFn) !void {
            return self.findPathsPrint(getAdjacent, null);
        }

        pub fn findPathsPrint(
            self: *Self,
            getAdjacent: AdjFn,
            print: ?fn (
                allocator: std.mem.Allocator,
                dj: *const Self,
                v: *const Vertex,
            ) std.mem.Allocator.Error!void,
        ) !void {
            var queue = std.PriorityQueue(
                *Vertex,
                void,
                Vertex.compare,
            ).init(self.allocator, {});
            defer queue.deinit();
            try queue.add(self.verts.getPtr(self.start).?);

            var visited = std.AutoArrayHashMap(VData, void).init(self.allocator);
            defer visited.deinit();
            try visited.ensureTotalCapacity(self.verts.capacity());

            while (queue.removeOrNull()) |u| {
                visited.putAssumeCapacity(u.v, {});
                if (print) |p| {
                    try p(self.allocator, self, u);
                }

                const edges = try getAdjacent(self.allocator, u.v, self.context);
                defer self.allocator.free(edges);
                for (edges) |n| {
                    if (visited.get(n.v) != null) {
                        continue;
                    }

                    const dv = self.verts.getPtr(n.v).?;
                    const next_cost = u.d + n.cost;
                    if (next_cost < dv.d) {
                        // cost was beaten, relax and replace with single predecessor
                        dv.d = next_cost;
                        dv.pred.clearRetainingCapacity();
                        try dv.pred.append(u.v);
                        try queue.add(dv);
                    } else if (next_cost == dv.d) {
                        // cost was tied, add predecessor and do not enqueue since we have
                        // already hit it
                        try dv.pred.append(u.v);
                    }
                }
            }
        }

        const PathIterator = struct {
            dj: *const Self,
            queue: std.ArrayList(*const Vertex),

            pub fn deinit(self: *const PathIterator) void {
                self.queue.deinit();
            }

            pub fn next(self: *PathIterator) !?VData {
                const ret = self.queue.popOrNull();
                if (ret) |dv| {
                    for (dv.pred.items) |p| {
                        try self.queue.append(self.dj.verts.getPtr(p).?);
                    }
                }

                return if (ret) |dv| dv.v else null;
            }
        };

        pub fn pathIterator(self: *const Self, v: VData) !PathIterator {
            var q = try std.ArrayList(*const Vertex).initCapacity(self.allocator, 1);
            q.appendAssumeCapacity(self.verts.getPtr(v).?);
            return .{
                .dj = self,
                .queue = q,
            };
        }
    };
}
