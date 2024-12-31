const std = @import("std");
const zutils = @import("zutils");

const V2 = zutils.V2(isize);
const Grid = zutils.Grid(u8);

const State = struct {
    allocator: std.mem.Allocator,
    grid: Grid,
    moves: []V2,
    bot: V2,
    nextMove: usize = 0,

    fn createDouble(self: *const State) !State {
        var grid = try Grid.init(self.allocator, self.grid.nrows, self.grid.ncols * 2);
        var iter = self.grid.iterator();
        while (iter.next()) |loc| {
            const idx = grid.dataIdx(loc.y, loc.x * 2);
            const range = grid.data[idx .. idx + 2];

            switch (self.grid.atV(loc.asType(usize))) {
                'O' => {
                    range[0] = '[';
                    range[1] = ']';
                },
                '@' => {
                    range[0] = '@';
                    range[1] = '.';
                },
                else => |v| {
                    range[0] = v;
                    range[1] = v;
                },
            }
        }
        return .{
            .allocator = self.allocator,
            .grid = grid,
            .moves = try self.allocator.dupe(V2, self.moves),
            .bot = .{ .x = self.bot.x * 2, .y = self.bot.y },
        };
    }

    fn deinit(self: *State) void {
        self.grid.deinit();
        self.allocator.free(self.moves);
    }

    fn moveBot1(self: *State, move: V2) void {
        const start = self.bot.add(move);
        var loc = start;

        while (true) {
            switch (self.grid.atV(loc.asType(usize))) {
                '#' => {
                    // hit wall, can't execute move
                    return;
                },
                '.' => {
                    // hit space, we good
                    break;
                },
                'O' => {
                    loc.addMut(move);
                },
                else => unreachable,
            }
        }

        const final_p = self.grid.atPtrV(loc.asType(usize));
        const start_p = self.grid.atPtrV(start.asType(usize));
        const bot_p = self.grid.atPtrV(self.bot.asType(usize));
        final_p.* = 'O';
        start_p.* = '@';
        bot_p.* = '.';
        self.bot.addMut(move);
    }

    fn moveBot2(self: *State, move: V2) !void {
        const start = self.bot.add(move);

        var to_move = std.AutoArrayHashMap(V2, void).init(self.allocator);
        defer to_move.deinit();
        try to_move.put(self.bot, {});
        var look_ahead = try std.ArrayList(V2).initCapacity(self.allocator, 1);
        defer look_ahead.deinit();
        look_ahead.appendAssumeCapacity(start);

        while (look_ahead.items.len > 0) {
            const loc = look_ahead.orderedRemove(0);
            switch (self.grid.atV(loc.asType(usize))) {
                '#' => {
                    // hit wall, can't execute move
                    return;
                },
                '.' => {
                    // hit space, we good
                    continue;
                },
                else => |v| {
                    const o = switch (v) {
                        // add right half as well
                        '[' => loc.add(.{ .x = 1 }),
                        // add left half as well
                        ']' => loc.add(.{ .x = -1 }),
                        else => unreachable,
                    };
                    try to_move.put(loc, {});
                    try look_ahead.append(loc.add(move));

                    // if moving vert
                    if (move.y != 0) {
                        try to_move.put(o, {});
                        try look_ahead.append(o.add(move));
                    }
                },
            }
        }

        // do last ones first
        std.mem.reverse(V2, to_move.keys());
        for (to_move.keys()) |v| {
            const dest = self.grid.atPtrV(v.add(move).asType(usize));
            const src = self.grid.atPtrV(v.asType(usize));
            const tmp = dest.*;
            dest.* = src.*;
            src.* = tmp;
        }

        self.bot.addMut(move);
    }

    fn runMoves1(self: *State, n: usize) void {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            moveBot1(self, self.moves[self.nextMove + i]);
        }
        self.nextMove += n;
    }

    fn runMoves2(self: *State, n: usize) !void {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            try moveBot2(self, self.moves[self.nextMove + i]);
        }
        self.nextMove += n;
    }

    fn gpsSum(self: *const State) usize {
        var sum: usize = 0;
        var iter = self.grid.iterator();
        while (iter.next()) |loc| {
            const v = self.grid.atV(loc.asType(usize));

            if (v == 'O' or v == '[') {
                sum += loc.x + 100 * loc.y;
            }
        }
        return sum;
    }

    fn checkBroken(self: *const State) bool {
        var iter = self.grid.iterator();
        while (iter.next()) |v| {
            switch (self.grid.atV(v)) {
                '[' => if (self.grid.atV(v.add(.{ .x = 1 })) != ']') return true,
                else => continue,
            }
        }
        return false;
    }
};

fn findEmptyLine(lines: []const []const u8) ?usize {
    for (lines, 0..) |ln, i| {
        if (std.mem.eql(u8, ln, "")) {
            return i;
        }
    }
    return null;
}

fn parseInput(allocator: std.mem.Allocator, lines: []const []const u8) !State {
    const empty_ln = findEmptyLine(lines).?;

    const move_lines = lines[empty_ln + 1 ..];
    var nmoves: usize = 0;
    for (move_lines) |ln| {
        nmoves += ln.len;
    }

    const moves = try allocator.alloc(V2, nmoves);
    var i: usize = 0;
    for (move_lines) |ln| {
        for (ln) |m| {
            moves[i] = switch (m) {
                '>' => .{ .x = 1 },
                '<' => .{ .x = -1 },
                '^' => .{ .y = -1 },
                'v' => .{ .y = 1 },
                else => unreachable,
            };
            i += 1;
        }
    }

    // parse grid without converting @ to ., then find robot
    var grid = try Grid.init2DSlice(
        allocator,
        lines[0..empty_ln],
    );
    var bot = V2{};
    var iter = grid.iterator();
    while (iter.next()) |v| {
        const c = grid.atPtr(v.y, v.x);
        if (c.* == '@') {
            bot = v.asType(isize);
            break;
        }
    }
    return .{
        .allocator = allocator,
        .grid = grid,
        .moves = moves,
        .bot = bot,
    };
}

test "big" {
    const inp = [_][]const u8{
        "##########",
        "#..O..O.O#",
        "#......O.#",
        "#.OO..O.O#",
        "#..O@..O.#",
        "#O#..O...#",
        "#O..O..O.#",
        "#.OO.O.OO#",
        "#....O...#",
        "##########",
        "",
        "<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^",
        "vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v",
        "><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<",
        "<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^",
        "^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><",
        "^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^",
        ">^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^",
        "<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>",
        "^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>",
        "v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^",
    };

    var state = try parseInput(std.testing.allocator, &inp);
    defer state.deinit();
    var state2 = try state.createDouble();
    defer state2.deinit();

    state.runMoves1(state.moves.len);
    try std.testing.expectEqual(10092, state.gpsSum());

    try state2.runMoves2(state2.moves.len);
    try std.testing.expectEqual(9021, state2.gpsSum());
}

test "small" {
    const inp = [_][]const u8{
        "#######",
        "#...#.#",
        "#.....#",
        "#..OO@#",
        "#..O..#",
        "#.....#",
        "#######",
        "",
        "<vv<<^^<<^^",
    };
    var state = try parseInput(std.testing.allocator, &inp);
    defer state.deinit();
    var state2 = try state.createDouble();
    defer state2.deinit();

    try state2.runMoves2(state.moves.len);
}

test "rando" {
    const inp = [_][]const u8{
        "#######",
        "#.....#",
        "#.....#",
        "#.@O..#",
        "#..#O.#",
        "#...O.#",
        "#..O..#",
        "#.....#",
        "#######",
        "",
        ">><vvv>v>^^^",
    };
    var state = try parseInput(std.testing.allocator, &inp);
    defer state.deinit();
    var state2 = try state.createDouble();
    defer state2.deinit();

    try state2.runMoves2(state.moves.len);
    try std.testing.expectEqual(1430, state2.gpsSum());
}

pub fn main() !void {
    const lines = try zutils.fs.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2024/15.txt");
    var state = try parseInput(std.heap.page_allocator, lines.items());
    var state2 = try state.createDouble();
    defer state2.deinit();

    state.runMoves1(state.moves.len);

    std.debug.print("p1: {d}\n", .{state.gpsSum()});

    try state2.runMoves2(state2.moves.len);
    std.debug.print("p2: {d}\n", .{state2.gpsSum()});
}
