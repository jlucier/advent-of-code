const std = @import("std");
const zutils = @import("zutils");
const z3 = @cImport({
    @cInclude("z3.h");
});

const Machine = struct {
    target: []u8 = undefined,
    buttons: [][]usize = undefined,
    joltage: []usize = undefined,

    const Self = @This();

    pub fn init(gpa: std.mem.Allocator, ln: []const u8) !Self {
        var m = Machine{};

        var iter = std.mem.splitScalar(u8, ln, ' ');
        var buttons = std.array_list.Managed([]usize).init(gpa);

        while (iter.next()) |part| {
            const sp = part[1 .. part.len - 1];
            switch (part[0]) {
                '[' => {
                    m.target = try gpa.alloc(u8, sp.len);
                    std.mem.copyForwards(u8, m.target, sp);
                },
                '{' => {
                    m.joltage = try zutils.str.parseInts(usize, gpa, sp, ',');
                },
                '(' => {
                    const bl = try zutils.str.parseInts(usize, gpa, sp, ',');
                    try buttons.append(bl);
                },
                else => unreachable,
            }
        }

        m.buttons = try buttons.toOwnedSlice();
        return m;
    }

    pub fn print(self: *const Self) void {
        std.debug.print("<Machine\n\ttarget: [{s}]\n\twiring: ", .{self.target});

        for (self.buttons) |w| {
            std.debug.print("{any} ", .{w});
        }
        std.debug.print("\n\tjoltage: {any}\n", .{self.joltage});
    }
};

fn pressLights(gpa: std.mem.Allocator, state: []const u8, button: []const usize) ![]u8 {
    const newS = try gpa.alloc(u8, state.len);
    std.mem.copyForwards(u8, newS, state);
    for (button) |i| newS[i] = if (newS[i] == '#') '.' else '#';
    return newS;
}

fn solveLights(gpa: std.mem.Allocator, machine: *const Machine) !usize {
    const max_states = std.math.pow(usize, 2, machine.target.len);
    var states = std.StringArrayHashMap(usize).init(gpa);
    try states.ensureTotalCapacity(max_states);

    const starter = try gpa.alloc(u8, machine.target.len);
    defer gpa.free(starter);
    for (starter) |*c| c.* = '.';
    states.putAssumeCapacity(starter, 1);

    var i: usize = 0;
    while (states.count() > 0) : (i += 1) {
        if (states.get(machine.target) orelse 0 >= 1) return i;

        var next = std.StringArrayHashMap(usize).init(gpa);
        try next.ensureTotalCapacity(max_states);

        var iter = states.iterator();
        while (iter.next()) |s| {
            for (machine.buttons) |b| {
                const nS = try pressLights(gpa, s.key_ptr.*, b);
                const res = (try next.getOrPutValue(nS, 0));
                res.value_ptr.* += 1;
            }
        }
        states.deinit();
        states = next;
    }
    return 0;
}

fn solveJolts(gpa: std.mem.Allocator, machine: *const Machine) !usize {
    const cfg = z3.Z3_mk_config();
    defer z3.Z3_del_config(cfg);

    const ctx = z3.Z3_mk_context(cfg);
    defer z3.Z3_del_context(ctx);

    const opt = z3.Z3_mk_optimize(ctx);
    const int_sort = z3.Z3_mk_int_sort(ctx);
    const zero = z3.Z3_mk_int(ctx, 0, int_sort);

    // make variables
    var vars = try gpa.alloc(z3.Z3_ast, machine.buttons.len);
    defer gpa.free(vars);

    var equations = try gpa.alloc(std.array_list.Managed(z3.Z3_ast), machine.joltage.len);
    defer for (equations) |*eq| eq.deinit();
    for (0..equations.len) |i| {
        equations[i] = std.array_list.Managed(z3.Z3_ast).init(gpa);
    }

    for (machine.buttons, 0..) |b, bi| {
        const sym = z3.Z3_mk_string_symbol(ctx, &std.ascii.lowercase[bi]);
        vars[bi] = z3.Z3_mk_const(ctx, sym, int_sort);
        const ge = z3.Z3_mk_ge(ctx, vars[bi], zero);
        z3.Z3_optimize_assert(ctx, opt, ge);

        for (b) |ei| {
            try equations[ei].append(vars[bi]);
        }
    }

    // for each equation, create summations of variables
    for (equations, 0..) |*eq, ei| {
        const sum = z3.Z3_mk_add(ctx, @intCast(eq.items.len), &eq.items[0]);
        const b = z3.Z3_mk_int(ctx, @intCast(machine.joltage[ei]), int_sort);
        const zeq = z3.Z3_mk_eq(ctx, sum, b);
        z3.Z3_optimize_assert(ctx, opt, zeq);
    }

    // set up minimization
    const var_sum = z3.Z3_mk_add(ctx, @intCast(vars.len), &vars[0]);
    _ = z3.Z3_optimize_minimize(ctx, opt, var_sum);

    const result = z3.Z3_optimize_check(ctx, opt, 0, null);
    std.debug.assert(result == z3.Z3_L_TRUE);

    const model = z3.Z3_optimize_get_model(ctx, opt);
    z3.Z3_model_inc_ref(ctx, model);
    defer z3.Z3_model_dec_ref(ctx, model);

    var total: usize = 0;
    for (vars) |v| {
        var val: z3.Z3_ast = undefined;
        _ = z3.Z3_model_eval(ctx, model, v, true, &val);
        const num_str = z3.Z3_get_numeral_string(ctx, val);

        total += try std.fmt.parseInt(usize, std.mem.span(num_str), 10);
    }

    return total;
}

fn parse(gpa: std.mem.Allocator, input: []const u8) ![]Machine {
    var machines = std.array_list.Managed(Machine).init(gpa);
    var iter = std.mem.splitScalar(u8, input, '\n');
    var i: usize = 0;
    while (iter.next()) |ln| : (i += 1) {
        if (ln.len > 0)
            try machines.append(try Machine.init(gpa, ln));
    }
    return try machines.toOwnedSlice();
}

fn solve(gpa: std.mem.Allocator, input: []const u8) ![2]usize {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const alloc = arena.allocator();

    var p1: usize = 0;
    var p2: usize = 0;
    const machines = try parse(alloc, input);
    for (machines) |*m| {
        p1 += try solveLights(alloc, m);
        p2 += try solveJolts(alloc, m);
    }

    return .{ p1, p2 };
}

test "example" {
    const input =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;

    const res = try solve(std.testing.allocator, input);

    try std.testing.expectEqual(7, res[0]);
    try std.testing.expectEqual(33, res[1]);
}

pub fn main() !void {
    const input = try zutils.fs.readFile(std.heap.page_allocator, //
        "~/sync/dev/aoc_inputs/2025/10.txt");
    const res = try solve(std.heap.page_allocator, input);
    std.debug.print("p1: {d}\np2: {d}\n", .{ res[0], res[1] });
}
