const std = @import("std");
const zutils = @import("zutils");

const RuleSet = std.AutoArrayHashMap(usize, std.AutoArrayHashMap(usize, void));
fn destroyRuleSet(rs: *RuleSet) void {
    for (rs.values()) |*v| {
        v.deinit();
    }
    rs.deinit();
}

fn parseRules(allocator: std.mem.Allocator, lines: []const []const u8) !RuleSet {
    var rs = RuleSet.init(allocator);
    for (lines) |ln| {
        const mid = std.mem.indexOfScalar(u8, ln, '|').?;

        const a = try std.fmt.parseUnsigned(usize, ln[0..mid], 10);
        const b = try std.fmt.parseUnsigned(usize, ln[mid + 1 ..], 10);

        if (rs.getPtr(a)) |set| {
            try set.put(b, {});
        } else {
            var set = std.AutoArrayHashMap(usize, void).init(allocator);
            try set.put(b, {});
            try rs.put(a, set);
        }
    }
    return rs;
}

fn parseUpdate(allocator: std.mem.Allocator, line: []const u8) ![]usize {
    var upd = try allocator.alloc(usize, std.mem.count(u8, line, ",") + 1);
    var iter = std.mem.splitScalar(u8, line, ',');
    var i: usize = 0;
    while (iter.next()) |part| {
        upd[i] = try std.fmt.parseUnsigned(usize, part, 10);
        i += 1;
    }
    return upd;
}

fn findEmpty(lines: []const []const u8) ?usize {
    for (lines, 0..) |ln, i| {
        if (std.mem.eql(u8, ln, "")) {
            return i;
        }
    }
    return null;
}

fn checkUpdate(allocator: std.mem.Allocator, update: []const usize, rs: *RuleSet) !bool {
    var seen = std.AutoArrayHashMap(usize, void).init(allocator);
    defer seen.deinit();

    var pass = true;
    for (update) |v| {
        if (rs.getPtr(v)) |nums| {
            // nums must come after v
            for (nums.keys()) |o| {
                if (seen.getKey(o) != null) {
                    pass = false;
                    // return false;
                }
            }
        }
        try seen.put(v, {});
    }
    return pass;
}

const UpdSortCtx = struct {
    num_rules: *const std.AutoArrayHashMap(usize, usize),
};

fn updElemLessThan(ctx: UpdSortCtx, a: usize, b: usize) bool {
    // ones with most rules first
    return ctx.num_rules.get(a).? > ctx.num_rules.get(b).?;
}

fn fixUpdate(allocator: std.mem.Allocator, upd: []usize, rs: *const RuleSet) !void {
    var num_rules = std.AutoArrayHashMap(usize, usize).init(allocator);
    defer num_rules.deinit();

    // for each item in the update, count number of rules applying to that number
    for (upd) |v| {
        var nr: usize = 0;
        if (rs.getPtr(v)) |nums| {
            for (nums.keys()) |n| {
                if (std.mem.indexOfScalar(usize, upd, n) != null) {
                    nr += 1;
                }
            }
        }
        try num_rules.put(v, nr);
    }

    // in order of most restricted number to least, place them
    std.mem.sort(usize, upd, UpdSortCtx{ .num_rules = &num_rules }, updElemLessThan);
}

fn parts(allocator: std.mem.Allocator, lines: []const []const u8) ![2]usize {
    const empty = findEmpty(lines).?;

    var rs = try parseRules(allocator, lines[0..empty]);
    defer destroyRuleSet(&rs);

    var p1: usize = 0;
    var p2: usize = 0;
    for (lines[empty + 1 ..]) |ln| {
        const upd = try parseUpdate(allocator, ln);
        defer allocator.free(upd);

        const res = try checkUpdate(allocator, upd, &rs);
        if (!res) {
            try fixUpdate(allocator, upd, &rs);
        }
        // add middle
        var idx = upd.len / 2;
        if (upd.len % 2 == 0) idx -= 1;

        if (res) {
            p1 += upd[idx];
        } else {
            p2 += upd[idx];
        }
    }

    return .{ p1, p2 };
}

test "parts" {
    const lines = [_][]const u8{
        "47|53",
        "97|13",
        "97|61",
        "97|47",
        "75|29",
        "61|13",
        "75|53",
        "29|13",
        "97|29",
        "53|29",
        "61|53",
        "97|53",
        "61|29",
        "47|13",
        "75|47",
        "97|75",
        "47|61",
        "75|61",
        "47|29",
        "75|13",
        "53|13",
        "",
        "75,47,61,53,29",
        "97,61,53,29,13",
        "75,29,13",
        "75,97,47,61,53",
        "61,13,29",
        "97,13,75,29,47",
    };

    const ans = try parts(std.testing.allocator, &lines);
    try std.testing.expectEqual(143, ans[0]);
    try std.testing.expectEqual(123, ans[1]);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/5.txt");
    defer lines.deinit();

    const ans = try parts(std.heap.page_allocator, lines.items());
    std.debug.print("p1: {d}\n", .{ans[0]});
    std.debug.print("p2: {d}\n", .{ans[1]});
}
