const std = @import("std");
const zutils = @import("zutils");

const State = struct {
    x: isize = 1,
    cycle: usize = 0,
    ss: isize = 0,
    crt_out: [6][40]u8 = undefined,
    crt_pos: zutils.V2(usize) = .{},

    pub fn updateSigStrength(self: *State) void {
        if (self.cycle >= 20 and (self.cycle - 20) % 40 == 0) {
            const cyc: isize = @intCast(self.cycle);
            const cs = cyc * self.x;
            self.ss += cs;
            // std.debug.print(
            //     "  cycle: {d} x: {d} ss: {d} tot: {d}\n",
            //     .{ self.cycle, self.x, cs, self.ss },
            // );
        }
    }

    pub fn drawCrtCell(self: *State) void {
        const cx: isize = @intCast(self.crt_pos.x);
        const diff: isize = zutils.abs(isize, self.x - cx);
        self.crt_out[self.crt_pos.y][self.crt_pos.x] = if (diff <= 1) '#' else '.';

        const next_crt_x = self.crt_pos.x + 1;
        if (next_crt_x >= 40) {
            self.crt_pos.y += 1;
        }
        self.crt_pos.x = next_crt_x % 40;
    }

    pub fn printCrt(self: *const State) void {
        for (self.crt_out) |line| {
            std.debug.print("{s}\n", .{line});
        }
    }
};

fn runInstuctions(lines: []const []const u8) !isize {
    var state = State{};

    for (lines) |ln| {
        const ncycle: usize = if (std.mem.eql(u8, ln, "noop")) 1 else 2;
        var i: usize = 0;
        while (i < ncycle) : (i += 1) {
            state.drawCrtCell();
            state.cycle += 1;
            state.updateSigStrength();
        }

        // update register
        if (ncycle == 2) {
            // lop off "addx "
            const dx: isize = try std.fmt.parseInt(isize, ln[5..], 10);
            state.x += dx;
        }
    }
    state.printCrt();
    return state.ss;
}

test "p1" {
    const p = try std.fs.cwd().realpathAlloc(
        std.testing.allocator,
        "2022/examples/10.txt",
    );
    defer std.testing.allocator.free(p);

    const lines = try zutils.readLines(std.testing.allocator, p);
    defer lines.deinit();

    try std.testing.expectEqual(13140, try runInstuctions(lines.strings.items));
}

pub fn main() !void {
    const lines = try zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/10.txt");
    defer lines.deinit();
    std.debug.print("p1: {}\n", .{try runInstuctions(lines.strings.items)});
}
