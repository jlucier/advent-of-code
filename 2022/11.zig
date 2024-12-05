const std = @import("std");
const zutils = @import("zutils");

const OpType = enum {
    mul,
    add,
};

const MonkeyList = std.ArrayList(Monkey);

const Monkey = struct {
    op_type: OpType = .mul,
    operand: ?usize = null,
    divisor: usize = 0,
    true_out: usize = 0,
    false_out: usize = 0,
    n_inspections: usize = 0,
    items: std.ArrayList(usize),

    pub fn deinit(self: *Monkey) void {
        self.items.deinit();
    }

    pub fn initFromLines(allocator: std.mem.Allocator, lines: []const []const u8) !Monkey {
        var monkey = Monkey{
            .items = std.ArrayList(usize).init(allocator),
        };

        // items
        const starting_items = lines[1];
        const items_start = std.mem.indexOfScalar(u8, starting_items, ':').? + 2;
        var items = std.mem.splitSequence(u8, starting_items[items_start..], ", ");
        while (items.next()) |it| {
            try monkey.items.append(try std.fmt.parseInt(usize, it, 10));
        }

        // operation
        const operation = lines[2];
        const op_start = std.mem.lastIndexOfScalar(u8, operation, ' ').? - 1;
        monkey.op_type = switch (operation[op_start]) {
            '*' => .mul,
            '+' => .add,
            else => unreachable,
        };
        const operand_str = operation[op_start + 2 ..];
        if (!std.mem.eql(u8, operand_str, "old")) {
            monkey.operand = try std.fmt.parseInt(usize, operand_str, 10);
        }

        // test
        const test_ln = lines[3];
        const n_start = std.mem.indexOfScalar(u8, test_ln, 'y').? + 2;
        monkey.divisor = try std.fmt.parseInt(usize, test_ln[n_start..], 10);

        const true_ln = lines[4];
        const true_st = std.mem.lastIndexOfScalar(u8, true_ln, ' ').? + 1;
        const false_ln = lines[5];
        const false_st = std.mem.lastIndexOfScalar(u8, false_ln, ' ').? + 1;

        monkey.true_out = try std.fmt.parseInt(usize, true_ln[true_st..], 10);
        monkey.false_out = try std.fmt.parseInt(usize, false_ln[false_st..], 10);

        return monkey;
    }

    pub fn doTurn(self: *Monkey, monkeys: *const MonkeyList, part: u8) !void {
        var lcm: usize = 1;
        for (monkeys.items) |m| {
            lcm *= m.divisor;
        }

        for (self.items.items) |it| {
            var held_it = it;
            self.n_inspections += 1;
            // increase op
            const op = self.operand orelse held_it;
            switch (self.op_type) {
                .mul => {
                    held_it *= op;
                },
                .add => {
                    held_it += op;
                },
            }

            switch (part) {
                // decrease from boredom
                1 => {
                    held_it /= 3;
                },
                2 => {
                    held_it %= lcm;
                },
                else => unreachable,
            }

            // test
            const recipient_idx = if (held_it % self.divisor == 0) self.true_out else self.false_out;
            // throw
            try monkeys.items[recipient_idx].items.append(held_it);
        }
        self.items.clearRetainingCapacity();
    }

    pub fn printItems(self: *const Monkey) void {
        for (self.items.items, 0..) |it, i| {
            std.debug.print("{d}{s}", .{ it, if (i + 1 >= self.items.items.len) "" else "," });
        }
        std.debug.print("\n", .{});
    }
};

fn parseMonkeys(allocator: std.mem.Allocator, lines: []const []const u8) !MonkeyList {
    var i: usize = 0;
    var monkeys = try MonkeyList.initCapacity(allocator, lines.len / 7 + 1);

    while (i + 5 < lines.len) : (i += 7) {
        monkeys.appendAssumeCapacity(try Monkey.initFromLines(allocator, lines[i .. i + 6]));
    }
    return monkeys;
}

fn printMonkeys(monkeys: *const MonkeyList) void {
    for (monkeys.items, 0..) |mkey, m| {
        std.debug.print("Monkey {d}: ", .{m});
        mkey.printItems();
    }
    std.debug.print("\n", .{});
}

fn compareMonkeyInspections(_: void, a: Monkey, b: Monkey) bool {
    return a.n_inspections > b.n_inspections;
}

fn monkeyBusiness(allocator: std.mem.Allocator, lines: []const []const u8, part: u8) !usize {
    var monkeys = try parseMonkeys(allocator, lines);
    defer {
        for (monkeys.items) |*mkey| {
            mkey.deinit();
        }
        monkeys.deinit();
    }

    var i: usize = 0;
    const rounds: usize = if (part == 1) 20 else 10000;
    while (i < rounds) : (i += 1) {
        for (monkeys.items) |*mkey| {
            try mkey.doTurn(&monkeys, part);
        }
    }

    std.mem.sort(Monkey, monkeys.items, {}, compareMonkeyInspections);
    return monkeys.items[0].n_inspections * monkeys.items[1].n_inspections;
}

test "parts" {
    const inp = [_][]const u8{
        "Monkey 0:",
        "  Starting items: 79, 98",
        "  Operation: new = old * 19",
        "  Test: divisible by 23",
        "    If true: throw to monkey 2",
        "    If false: throw to monkey 3",
        "",
        "Monkey 1:",
        "  Starting items: 54, 65, 75, 74",
        "  Operation: new = old + 6",
        "  Test: divisible by 19",
        "    If true: throw to monkey 2",
        "    If false: throw to monkey 0",
        "",
        "Monkey 2:",
        "  Starting items: 79, 60, 97",
        "  Operation: new = old * old",
        "  Test: divisible by 13",
        "    If true: throw to monkey 1",
        "    If false: throw to monkey 3",
        "",
        "Monkey 3:",
        "  Starting items: 74",
        "  Operation: new = old + 3",
        "  Test: divisible by 17",
        "    If true: throw to monkey 0",
        "    If false: throw to monkey 1",
    };

    const mbusiness1 = try monkeyBusiness(std.testing.allocator, &inp, 1);
    try std.testing.expectEqual(10605, mbusiness1);

    const mbusiness2 = try monkeyBusiness(std.testing.allocator, &inp, 2);
    try std.testing.expectEqual(2713310158, mbusiness2);
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/11.txt");
    defer lines.deinit();
    const p1 = try monkeyBusiness(std.heap.page_allocator, lines.strings.items, 1);
    const p2 = try monkeyBusiness(std.heap.page_allocator, lines.strings.items, 2);
    std.debug.print("p1: {d}\n", .{p1});
    std.debug.print("p2: {d}\n", .{p2});
}
