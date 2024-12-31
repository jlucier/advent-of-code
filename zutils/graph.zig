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

            fn reset(self: *Vertex) void {
                self.d = std.math.maxInt(usize);
                self.pred.clearRetainingCapacity();
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

        /// Resets the state so another call to findPaths can run correctly
        pub fn reset(self: *Self) void {
            for (self.verts.values()) |*v| {
                v.reset();
            }
            // make sure to set the start cost to 0
            self.verts.getPtr(self.start).?.d = 0;
        }

        pub fn removeVertex(self: *Self, v: VData) bool {
            var removed = false;
            self.verts.unlockPointers();
            if (self.verts.fetchSwapRemove(v)) |entry| {
                entry.value.deinit();
                removed = true;
            }
            self.verts.lockPointers();
            return removed;
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

            var visited = try self.allocator.alloc(bool, self.verts.capacity());
            defer self.allocator.free(visited);

            while (queue.removeOrNull()) |u| {
                visited[self.verts.getIndex(u.v).?] = true;
                if (print) |p| {
                    try p(self.allocator, self, u);
                }

                const edges = try getAdjacent(self.allocator, u.v, self.context);
                defer self.allocator.free(edges);
                for (edges) |n| {
                    const dv_i = self.verts.getIndex(n.v).?;
                    if (visited[dv_i]) {
                        continue;
                    }

                    const dv = &self.verts.values()[dv_i];
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
            seen: ?std.AutoHashMap(VData, void),

            fn init(dj: *const Self, start: VData, unique: bool) !PathIterator {
                var q = try std.ArrayList(*const Vertex).initCapacity(dj.allocator, 1);
                q.appendAssumeCapacity(dj.verts.getPtr(start).?);
                return .{
                    .dj = dj,
                    .queue = q,
                    .seen = if (!unique) null else std.AutoHashMap(VData, void).init(dj.allocator),
                };
            }

            pub fn deinit(self: *PathIterator) void {
                self.queue.deinit();
                if (self.seen) |*s| s.deinit();
            }

            pub fn next(self: *PathIterator) !?VData {
                while (self.queue.popOrNull()) |dv| {
                    if (self.seen) |*s| {
                        // if already retured, skip, otherwise add as we will return
                        if ((try s.getOrPut(dv.v)).found_existing) {
                            continue;
                        }
                    }

                    for (dv.pred.items) |p| {
                        try self.queue.append(self.dj.verts.getPtr(p).?);
                    }

                    return dv.v;
                }
                return null;
            }
        };

        /// Return an iterator over VData's which are located along the path. Optionally
        /// only the unique ones
        pub fn pathIterator(self: *const Self, v: VData, unique: bool) !PathIterator {
            return try PathIterator.init(self, v, unique);
        }
    };
}
