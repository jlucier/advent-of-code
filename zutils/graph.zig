const std = @import("std");
const grid = @import("grid.zig");
const vec = @import("vec.zig");

const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;

/// Create a dijkstras solver given a type for the node and function
/// Context at least has method:
/// fn getAdjacent(ctx: Context, allocator: Allocator, dv: VData) ![]{ v: VData, cost: usize }
pub fn Dijkstras(comptime VData: type, comptime Context: type) type {
    return struct {
        const PredList = std.ArrayList(VData);

        pub const Vertex = struct {
            v: VData,
            d: usize = std.math.maxInt(usize),
            pred: PredList,

            fn reset(self: *Vertex) void {
                self.d = std.math.maxInt(usize);
                self.pred.clearRetainingCapacity();
            }

            fn compare(_: void, a: *const Vertex, b: *const Vertex) std.math.Order {
                return if (a.d < b.d) .lt else if (a.d == b.d) .eq else .gt;
            }
        };

        const Self = @This();

        arena_owned: bool = false,
        arena: *ArenaAllocator,
        start: VData,
        verts: std.AutoArrayHashMap(VData, Vertex),
        context: Context,

        pub fn initWithArena(
            arena: *ArenaAllocator,
            start: VData,
            initial_verts: []VData,
            context: Context,
        ) !Self {
            const allocator = arena.allocator();
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
                .arena = arena,
                .start = start,
                .verts = dv,
                .context = context,
            };
        }

        pub fn init(
            allocator: Allocator,
            start: VData,
            initial_verts: []VData,
            context: Context,
        ) !Self {
            const arena = try allocator.create(ArenaAllocator);
            arena.* = ArenaAllocator.init(allocator);
            var ret = try Self.initWithArena(arena, start, initial_verts, context);
            ret.arena_owned = true;
            return ret;
        }

        pub fn deinit(self: *Self) void {
            self.verts.unlockPointers();
            if (self.arena_owned) {
                self.arena.deinit();
                self.arena.child_allocator.destroy(self.arena);
            }
        }

        /// Resets the state so another call to findPaths can run correctly
        pub fn reset(self: *Self) void {
            for (self.verts.values()) |*v| {
                v.reset();
            }
            // make sure to set the start cost to 0
            self.verts.getPtr(self.start).?.d = 0;
        }

        pub fn addVertex(self: *Self, v: VData) !void {
            self.verts.unlockPointers();
            try self.verts.put(v, .{
                .v = v,
                .pred = PredList.init(self.arena.allocator()),
            });
            self.verts.lockPointers();
        }

        pub fn removeVertex(self: *Self, v: VData) bool {
            self.verts.unlockPointers();
            const removed = self.verts.fetchSwapRemove(v) != null;
            self.verts.lockPointers();
            return removed;
        }

        pub fn findPaths(self: *Self) !void {
            return self.findPathsPrint(null);
        }

        pub fn findPathsPrint(
            self: *Self,
            print: ?fn (
                allocator: Allocator,
                dj: *const Self,
                v: *const Vertex,
            ) Allocator.Error!void,
        ) !void {
            const allocator = self.arena.allocator();
            var queue = std.PriorityQueue(
                *Vertex,
                void,
                Vertex.compare,
            ).init(allocator, {});
            try queue.add(self.verts.getPtr(self.start).?);

            var visited = try allocator.alloc(bool, self.verts.capacity());
            defer allocator.free(visited);

            while (queue.removeOrNull()) |u| {
                visited[self.verts.getIndex(u.v).?] = true;
                if (print) |p| {
                    try p(allocator, self, u);
                }

                const edges = try self.context.getAdjacent(allocator, u.v);
                defer allocator.free(edges);
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
                const allocator = dj.arena.allocator();
                var q = try std.ArrayList(*const Vertex).initCapacity(allocator, 1);
                q.appendAssumeCapacity(dj.verts.getPtr(start).?);
                return .{
                    .dj = dj,
                    .queue = q,
                    .seen = if (!unique) null else std.AutoHashMap(VData, void).init(allocator),
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

/// Commonly used manhattan distance cost for dijkstras
pub fn ManhattanCostCtx(comptime V2: type) type {
    return struct {
        pub fn cost(_: @This(), a: V2, b: V2) usize {
            return @intCast(a.asSigned().sub(b.asSigned()).manhattanMag());
        }
    };
}

/// Common util for solving grid based dijkstras with basic cost functions.
///
/// V2 is the vector type to use.
///
/// blocked_cell is the value in the grid representing a blocked cell, the grid
/// will be inferred to hold the type of the blocked_cell
///
/// Context can be anything, but must contain at least a function:
/// fn cost(ctx: @TypeOf(context), a: V2, b: V2) usize
/// which returns the cost of moving from a neighbor b
pub fn GridDijkstras(
    comptime V2: type,
    comptime Cell: type,
    comptime blocked_cell: Cell,
    comptime Context: type,
) type {
    return struct {
        pub const Grid = grid.Grid(Cell);
        pub const DijkCtx = struct {
            grid: *const Grid,
            sub_ctx: Context,

            const Edge = struct {
                v: V2,
                cost: usize,
            };

            pub fn getAdjacent(
                ctx: DijkCtx,
                allocator: Allocator,
                dv: V2,
            ) ![]Edge {
                var edges = try std.ArrayList(Edge).initCapacity(allocator, 4);
                const g = ctx.grid;
                var iter = dv.iterNeighborsInGridBounds(g.ncols, g.nrows);

                while (iter.next()) |n| {
                    if (g.atV(n.asType(usize)) == blocked_cell) {
                        continue;
                    }
                    edges.appendAssumeCapacity(.{
                        .v = n,
                        .cost = ctx.sub_ctx.cost(dv, n),
                    });
                }

                return edges.toOwnedSlice();
            }
        };

        pub const DijkSolver = Dijkstras(V2, DijkCtx);

        fn makeVerts(allocator: Allocator, g: *const Grid) ![]V2 {
            var verts = std.ArrayList(V2).init(allocator);

            var iter = g.iterator();
            while (iter.next()) |v| {
                if (g.atV(v) != blocked_cell) {
                    try verts.append(v.asType(V2.ValueT));
                }
            }
            return verts.toOwnedSlice();
        }

        pub fn initSolverWithArena(
            arena: *ArenaAllocator,
            start: V2,
            g: *const Grid,
            ctx: Context,
        ) !DijkSolver {
            const initial_verts = try makeVerts(arena.allocator(), g);
            return try DijkSolver.initWithArena(
                arena,
                start,
                initial_verts,
                .{ .grid = g, .sub_ctx = ctx },
            );
        }

        pub fn initSolver(
            allocator: Allocator,
            start: V2,
            g: *const Grid,
            ctx: Context,
        ) !DijkSolver {
            const initial_verts = try makeVerts(allocator, g);
            return try DijkSolver.init(
                allocator,
                start,
                initial_verts,
                .{ .grid = g, .sub_ctx = ctx },
            );
        }
    };
}
