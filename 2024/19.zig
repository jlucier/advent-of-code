const std = @import("std");
const zutils = @import("zutils");

const ProblemState = struct {
    options: [][]const u8,
    patterns: []const []const u8,
};

const Node = struct {
    pattern: []const u8,
    used: std.array_list.Managed([]const u8),

    fn deinit(self: *const Node) void {
        self.used.deinit();
    }
};

fn compareOpts(_: void, a: []const u8, b: []const u8) bool {
    return a.len > b.len;
}

fn parse(allocator: std.mem.Allocator, lines: []const []const u8) !ProblemState {
    var data = ProblemState{
        .options = try allocator.alloc([]const u8, std.mem.count(u8, lines[0], ",") + 1),
        .patterns = lines[2..],
    };

    var iter = std.mem.splitSequence(u8, lines[0], ", ");
    var i: usize = 0;
    while (iter.next()) |p| : (i += 1) {
        data.options[i] = p;
    }
    std.mem.sort([]const u8, data.options, {}, compareOpts);
    return data;
}

const StateSortCtx = struct {
    keys: [][]const u8,

    /// Sorts the keys in the states map from smallest to largest
    pub fn lessThan(ctx: StateSortCtx, a: usize, b: usize) bool {
        return ctx.keys[a].len < ctx.keys[b].len;
    }
};

/// Solve using the same Non-deterministic Finite Automaton approach from 2023/12
/// Eagle eye from liz noticing that this must be the same kind of problem. Still
/// a really cool method, need to actually remember it this time.
fn nfa(allocator: std.mem.Allocator, pstate: *const ProblemState, pattern: []const u8) !usize {
    var states = std.StringArrayHashMap(usize).init(allocator);
    defer states.deinit();
    try states.put(pattern, 1);

    var end_n: usize = 0;
    var iters: usize = 0;

    // NOTE: because we re-sort the list of states each iteration from smallest length to largest,
    // this will pop the largest states first since they are at the end
    while (states.pop()) |ent| : (iters += 1) {
        const remaining_ptrn = ent.key;
        const n = ent.value;

        // if we've found some at the end, add to total and continue onto further states
        if (remaining_ptrn.len == 0) {
            end_n += n;
            continue;
        }

        for (pstate.options) |opt| {
            if (std.mem.startsWith(u8, remaining_ptrn, opt)) {
                const res = try states.getOrPutValue(remaining_ptrn[opt.len..], 0);
                res.value_ptr.* += n;
            }
        }

        // resort so that we process largest first, this leads to more "collisions" of
        // states and thusly less iteration
        states.sort(StateSortCtx{ .keys = states.keys() });
    }

    return end_n;
}

fn parts(allocator: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    const pstate = try parse(allocator, lines);
    defer allocator.free(pstate.options);

    var p1: usize = 0;
    var p2: usize = 0;
    for (pstate.patterns) |p| {
        const n = try nfa(allocator, &pstate, p);
        p1 += if (n > 0) 1 else 0;
        p2 += n;
    }
    return .{ p1, p2 };
}

const EX_INP = [_][]const u8{
    "r, wr, b, g, bwu, rb, gb, br",
    "",
    "brwrr",
    "bggr",
    "gbbr",
    "rrbgbr",
    "ubwu",
    "bwurrg",
    "brgr",
    "bbrgwb",
};

test "simple" {
    const pstate = try parse(std.testing.allocator, &EX_INP);
    defer std.testing.allocator.free(pstate.options);

    try std.testing.expectEqual(2, try nfa(std.testing.allocator, &pstate, "brwrr"));
    try std.testing.expectEqual(1, try nfa(std.testing.allocator, &pstate, "bggr"));
    try std.testing.expectEqual(4, try nfa(std.testing.allocator, &pstate, "gbbr"));
}

test "full example" {
    const ans = try parts(std.testing.allocator, &EX_INP);

    try std.testing.expectEqual(6, ans[0]);
    try std.testing.expectEqual(16, ans[1]);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(
        std.heap.page_allocator,
        "~/sync/dev/aoc_inputs/2024/19.txt",
    );
    defer lines.deinit();

    const ans = try parts(std.heap.page_allocator, lines.items());

    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
