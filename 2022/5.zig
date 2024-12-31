const std = @import("std");
const zutils = @import("zutils");

const CHAR_PER_STACK = 4;

const Instruction = struct {
    n: usize = 0,
    from: usize = 0,
    to: usize = 0,
};

const MultiStack = struct {
    const Stack = std.ArrayList(u8);
    stacks: std.ArrayList(Stack),

    pub fn initCapacity(allocator: std.mem.Allocator, n: usize) !MultiStack {
        var mstack = MultiStack{
            .stacks = try std.ArrayList(Stack).initCapacity(allocator, n),
        };

        var i: usize = 0;
        while (i < n) : (i += 1) {
            mstack.stacks.appendAssumeCapacity(Stack.init(allocator));
        }

        return mstack;
    }

    pub fn deinit(self: *const MultiStack) void {
        for (self.stacks.items) |st| {
            st.deinit();
        }
        self.stacks.deinit();
    }

    pub fn print(self: *const MultiStack) void {
        for (self.stacks.items) |st| {
            std.debug.print("{s}\n", .{st.items});
        }
    }

    fn move(self: *MultiStack, inst: *const Instruction) !void {
        var i: usize = 0;
        while (i < inst.n) : (i += 1) {
            const el = self.stacks.items[inst.from].pop();
            try self.stacks.items[inst.to].append(el);
        }
    }

    fn moveMulti(self: *MultiStack, inst: *const Instruction) !void {
        var from = &self.stacks.items[inst.from];
        var to = &self.stacks.items[inst.to];

        // grab slice being moved
        const to_move = from.items[from.items.len - inst.n ..];
        // add to dest
        try to.appendSlice(to_move);

        // remove from source
        const rep = [0]u8{};
        try from.replaceRange(from.items.len - inst.n, inst.n, &rep);
    }

    pub fn runInstructions(self: *MultiStack, lines: []const []const u8, version: u8) !void {
        for (lines) |ln| {
            const inst = try parseInstruction(ln);
            switch (version) {
                0 => try self.move(&inst),
                else => try self.moveMulti(&inst),
            }
        }
    }

    pub fn printTops(self: *MultiStack) void {
        for (self.stacks.items) |st| {
            std.debug.print("{c}", .{st.getLast()});
        }
        std.debug.print("\n", .{});
    }
};

fn findEmptyLine(lines: []const []const u8) usize {
    var i: usize = 0;
    while (i < lines.len) : (i += 1) {
        if (lines[i].len == 0) {
            break;
        }
    }
    return i;
}

fn parseInstruction(str: []const u8) !Instruction {
    var iter = std.mem.splitScalar(u8, str, ' ');
    var stage: u8 = 0;
    var inst = Instruction{};

    while (iter.next()) |p| {
        const v = std.fmt.parseUnsigned(usize, p, 10) catch {
            continue;
        };

        // have int
        switch (stage) {
            0 => {
                inst.n = v;
            },
            1 => {
                inst.from = v - 1;
            },
            2 => {
                inst.to = v - 1;
            },
            else => unreachable,
        }
        stage += 1;
    }
    return inst;
}

fn parseStacks(allocator: std.mem.Allocator, lines: []const []const u8) !MultiStack {
    var i = findEmptyLine(lines);

    // exclusive
    const end_stacks = i - 1;
    const num_stacks = (lines[0].len - 3) / 4 + 1;
    const mstack = try MultiStack.initCapacity(allocator, num_stacks);

    i = 0;
    while (i < end_stacks) : (i += 1) {
        const ln = lines[i];
        var j: usize = 0;

        while (j < ln.len) : (j += CHAR_PER_STACK) {
            if (ln[j] != '[') {
                // there is no crate here
                continue;
            }

            const c = ln[j + 1];
            const stack_n = j / CHAR_PER_STACK;

            try mstack.stacks.items[stack_n].append(c);
        }
    }
    for (mstack.stacks.items) |st| {
        std.mem.reverse(u8, st.items);
    }
    return mstack;
}

fn doIt(allocator: std.mem.Allocator, lines: []const []const u8, version: u8) !void {
    var mstack = try parseStacks(allocator, lines);
    defer mstack.deinit();

    const inst_start = findEmptyLine(lines) + 1;
    // mstack.print();
    // std.debug.print("\n", .{});
    try mstack.runInstructions(lines[inst_start..], version);
    // std.debug.print("after\n", .{});
    // mstack.print();
    // std.debug.print("\n", .{});

    mstack.printTops();
}

test "test both parts" {
    const inp = [_][]const u8{
        "    [D]    ",
        "[N] [C]    ",
        "[Z] [M] [P]",
        " 1   2   3 ",
        "",
        "move 1 from 2 to 1",
        "move 3 from 1 to 3",
        "move 2 from 2 to 1",
        "move 1 from 1 to 2",
    };
    try doIt(std.testing.allocator, &inp, 0);
    try doIt(std.testing.allocator, &inp, 1);
}

pub fn main() void {
    const lines = zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/5.txt") catch {
        std.debug.print("Could not read input\n", .{});
        return;
    };

    doIt(std.heap.page_allocator, lines.items(), 0) catch {
        std.debug.print("Failed to do it\n", .{});
        return;
    };

    doIt(std.heap.page_allocator, lines.items(), 1) catch {
        std.debug.print("Failed to do it\n", .{});
        return;
    };
}
