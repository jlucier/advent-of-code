const std = @import("std");
const zutils = @import("zutils");

const Cpu = struct {
    a: usize = 0,
    b: usize = 0,
    c: usize = 0,
    program: []usize,

    fn comboVal(self: *const Cpu, op: usize) usize {
        return switch (op) {
            4 => self.a,
            5 => self.b,
            6 => self.c,
            else => if (op <= 3) op else unreachable,
        };
    }

    fn runOp(self: *Cpu, ip: *usize, opcode: usize, operand: usize) ?usize {
        const combo = self.comboVal(operand);
        var inc_ip = true;
        var val: ?usize = null;
        switch (opcode) {
            // adv
            0 => {
                self.a >>= @intCast(combo);
            },
            // bxl
            1 => {
                self.b ^= operand;
            },
            // bst
            2 => {
                self.b = combo % 8;
            },
            // jnz
            3 => {
                if (self.a != 0) {
                    inc_ip = false;
                    ip.* = operand;
                }
            },
            // bxc
            4 => {
                self.b ^= self.c;
            },
            // out
            5 => {
                val = combo % 8;
            },
            // bdv
            6 => {
                self.b = self.a >> @intCast(combo);
            },
            // cdv
            7 => {
                self.c = self.a >> @intCast(combo);
            },
            else => unreachable,
        }

        if (inc_ip) {
            ip.* += 2;
        }
        return val;
    }

    fn run(self: *Cpu, allocator: std.mem.Allocator) !std.array_list.Managed(usize) {
        var out = std.array_list.Managed(usize).init(allocator);
        var ip: usize = 0;
        const og = self.*;
        while (ip < self.program.len - 1) {
            const val = self.runOp(&ip, self.program[ip], self.program[ip + 1]);
            if (val) |v| {
                try out.append(v);
            }
        }
        self.* = og;
        return out;
    }
};

fn parseLines(allocator: std.mem.Allocator, lines: []const []const u8) !Cpu {
    const prog_line = lines[lines.len - 1][9..];
    const program = try allocator.alloc(usize, std.mem.count(u8, prog_line, ",") + 1);
    var iter = std.mem.splitScalar(u8, prog_line, ',');
    var i: usize = 0;
    while (iter.next()) |s| : (i += 1) {
        program[i] = try std.fmt.parseUnsigned(usize, s, 10);
    }

    var cpu = Cpu{ .program = program };

    var reg_i: u8 = 0;
    for (lines) |ln| {
        if (ln.len == 0) {
            break;
        }
        const val = try std.fmt.parseUnsigned(usize, ln[12..], 10);
        switch (reg_i) {
            0 => cpu.a = val,
            1 => cpu.b = val,
            2 => cpu.c = val,
            else => unreachable,
        }
        reg_i += 1;
    }

    return cpu;
}

fn formatOutput(allocator: std.mem.Allocator, out: *const std.array_list.Managed(usize)) ![]const u8 {
    const nout = out.items.len;
    const buf = try allocator.alloc(u8, if (nout > 0) nout * 2 - 1 else 0);
    for (out.items, 0..) |n, i| {
        const idx = 2 * i;
        _ = try std.fmt.bufPrint(buf[idx..], "{d}", .{n});
        if (i + 1 < out.items.len) {
            _ = try std.fmt.bufPrint(buf[idx + 1 ..], "{c}", .{','});
        }
    }
    return buf;
}

const Ans = struct {
    p1: []const u8,
    p2: usize,
};

fn findValue(
    allocator: std.mem.Allocator,
    cpu: *Cpu,
    a: usize,
    start_v: usize,
    expected_len: usize,
) !?usize {
    var v = start_v;
    while (v < 8) : (v += 1) {
        cpu.a = a + v;
        cpu.b = 0;
        cpu.c = 0;

        const prog_out = try cpu.run(allocator);
        defer prog_out.deinit();

        if (prog_out.items.len != expected_len) {
            continue;
        }

        var iter = std.mem.reverseIterator(prog_out.items);
        var j: usize = 1;
        var all_good = true;

        while (iter.next()) |o| : (j += 1) {
            all_good = all_good and o == cpu.program[cpu.program.len - j];
        }

        if (all_good) {
            return v;
        }
    }
    return null;
}

fn parts(allocator: std.mem.Allocator, lines: []const []const u8) !Ans {
    var cpu = try parseLines(allocator, lines);
    defer allocator.free(cpu.program);
    const out = try cpu.run(allocator);
    defer out.deinit();
    const p1 = try formatOutput(allocator, &out);

    // p2

    var i: usize = 0;
    var a: usize = 0;
    var candidates = std.array_list.Managed(usize).init(allocator);
    defer candidates.deinit();
    try candidates.append(0);

    while (i < cpu.program.len) {
        const v = candidates.getLast();
        if (try findValue(allocator, &cpu, a, v, i + 1)) |good_v| {
            candidates.items[i] = good_v;
            try candidates.append(0);
            a += good_v;
            // only shift if we're continuing
            if (i + 1 < cpu.program.len) {
                a <<= 3;
            }
            i += 1;
        } else {
            // backtrack
            _ = candidates.pop();
            i -= 1;
            a >>= 3;
            a -= candidates.getLast();
            candidates.items[i] += 1;
        }
    }

    return .{
        .p1 = p1,
        .p2 = a,
    };
}

test "p1" {
    const inp = [_][]const u8{
        "Register A: 729",
        "Register B: 0",
        "Register C: 0",
        "",
        "Program: 0,1,5,4,3,0",
    };

    var cpu = try parseLines(std.testing.allocator, &inp);
    defer std.testing.allocator.free(cpu.program);

    const ol = try cpu.run(std.testing.allocator);
    defer ol.deinit();
    const out = try formatOutput(std.testing.allocator, &ol);
    defer std.testing.allocator.free(out);

    try std.testing.expectEqualStrings("4,6,3,5,6,3,5,2,1,0", out);
}

test "p2" {
    const inp = [_][]const u8{
        "Register A: 2024",
        "Register B: 0",
        "Register C: 0",
        "",
        "Program: 0,3,5,4,3,0",
    };

    const ans = try parts(std.testing.allocator, &inp);
    defer std.testing.allocator.free(ans.p1);

    try std.testing.expectEqual(117440, ans.p2);
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/17.txt");
    defer lines.deinit();

    const ans = try parts(std.heap.page_allocator, lines.items());
    defer std.heap.page_allocator.free(ans.p1);

    std.debug.print("p1: {s}\n", .{ans.p1});
    std.debug.print("p2: {d}\n", .{ans.p2});
}
