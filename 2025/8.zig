const std = @import("std");
const zutils = @import("zutils");

const V3 = zutils.vec.Vec(isize, 3);
const Circuit = std.bit_set.DynamicBitSet;

fn circuitLarger(_: void, a: *const Circuit, b: *const Circuit) bool {
    return a.count() > b.count();
}

fn parseVec(ln: []const u8) !V3 {
    var iter = std.mem.splitScalar(u8, ln, ',');
    var data: [3]isize = undefined;
    var i: usize = 0;
    while (iter.next()) |part| : (i += 1) {
        data[i] = try std.fmt.parseInt(isize, part, 10);
    }
    return .{ .data = data };
}

fn parse(gpa: std.mem.Allocator, inp: []const u8) ![]V3 {
    var vecs = std.array_list.Managed(V3).init(gpa);
    var iter = std.mem.splitScalar(u8, inp, '\n');
    var i: usize = 0;
    while (iter.next()) |ln| : (i += 1) {
        if (ln.len > 0)
            try vecs.append(try parseVec(ln));
    }
    return vecs.toOwnedSlice();
}

const PairSortCtx = struct {
    vecs: []V3,
};

fn shorterPair(ctx: PairSortCtx, a: [2]usize, b: [2]usize) bool {
    return ctx.vecs[a[0]].sub(ctx.vecs[a[1]]).mag(f32) < //
        ctx.vecs[b[0]].sub(ctx.vecs[b[1]]).mag(f32);
}

fn shortestPairs(gpa: std.mem.Allocator, vecs: []V3) ![][2]usize {
    var pairs = try gpa.alloc([2]usize, zutils.combinations(usize, vecs.len, 2));

    var pi: usize = 0;
    for (0..vecs.len) |i| {
        for (i + 1..vecs.len) |j| {
            pairs[pi] = .{ i, j };
            pi += 1;
        }
    }
    std.mem.sort([2]usize, pairs, PairSortCtx{ .vecs = vecs }, shorterPair);
    return pairs;
}

fn solve(gpa: std.mem.Allocator, inp: []const u8, n: usize) ![2]isize {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const alloc = arena.allocator();

    var circuits = std.array_list.Managed(Circuit).init(alloc);

    const vecs = try parse(alloc, inp);

    // track which indices are connected to which circuit
    var box2Circuit = try alloc.alloc(usize, vecs.len);
    for (box2Circuit) |*v| v.* = vecs.len;

    const pairs = try shortestPairs(alloc, vecs);
    var p1: isize = 0;
    var p2: isize = 0;

    for (pairs, 0..) |pair, pi| {
        // const pair = minPair(vecs, box2Circuit);
        const i = pair[0];
        const j = pair[1];
        const iconn = box2Circuit[i] < vecs.len;
        const jconn = box2Circuit[j] < vecs.len;

        if (iconn and jconn) {
            // both already conected, nothing changes
            if (box2Circuit[i] == box2Circuit[j]) continue;

            // both connected, but not together, connect these circuits
            const oldCiruitIdx = box2Circuit[j];
            const old = circuits.items[oldCiruitIdx];
            circuits.items[box2Circuit[i]].setUnion(old);
            // update the circuit membership of each box in the old circuit
            var iter = old.iterator(.{});
            while (iter.next()) |oi| {
                box2Circuit[oi] = box2Circuit[i];
            }

            // delete the circuit
            // swap remove will replace the index with the element at the end,
            // so elem at the end has its index changed
            for (box2Circuit) |*b| {
                if (b.* == circuits.items.len - 1) {
                    b.* = oldCiruitIdx;
                }
            }
            _ = circuits.swapRemove(oldCiruitIdx);
        } else if (iconn) {
            // first vec is in circuit, add first
            circuits.items[box2Circuit[i]].set(j);
            box2Circuit[j] = box2Circuit[i];
        } else if (jconn) {
            // second vec is in circuit, add first
            circuits.items[box2Circuit[j]].set(i);
            box2Circuit[i] = box2Circuit[j];
        } else {
            // neither in circuit, add new
            var new = try circuits.addOne();
            new.* = try Circuit.initEmpty(alloc, vecs.len);
            new.set(i);
            new.set(j);
            box2Circuit[i] = circuits.items.len - 1;
            box2Circuit[j] = circuits.items.len - 1;
        }

        // std.debug.print("{any} - {any}\n", .{ vecs[pair[0]], vecs[pair[1]] });
        // const needle = [_]usize{vecs.len};
        // std.debug.print("\tcircuits: {d} solo: {d}\n", .{
        //     circuits.items.len,
        //     std.mem.count(usize, box2Circuit, &needle),
        // });
        // for (circuits.items) |*c| {
        //     std.debug.print("\tcircuit: {d}\n", .{c.count()});
        // }

        if (pi == n - 1) {
            // find largest
            var cptrs = try alloc.alloc(*const Circuit, circuits.items.len);
            for (circuits.items, 0..) |*c, ci| cptrs[ci] = c;
            std.mem.sort(*const Circuit, cptrs, {}, circuitLarger);

            p1 = 1;
            for (cptrs[0..3]) |c| {
                p1 *= @intCast(c.count());
            }
        }
        const needle = [_]usize{vecs.len};
        if (circuits.items.len == 1 and std.mem.count(usize, box2Circuit, &needle) == 0) {
            p2 = vecs[i].data[0] * vecs[j].data[0];
            break;
        }
    }

    return .{ p1, p2 };
}

test "example" {
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;

    const res = try solve(std.testing.allocator, input, 10);
    try std.testing.expectEqual(40, res[0]);
    try std.testing.expectEqual(25272, res[1]);
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, //
        "~/sync/dev/aoc_inputs/2025/8.txt");
    defer std.heap.page_allocator.free(input);

    const res = try solve(std.heap.page_allocator, input, 1000);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
