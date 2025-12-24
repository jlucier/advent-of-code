const std = @import("std");
const zutils = @import("zutils");

const Machine = struct {
    lights: []u8 = undefined,
    targetLights: []u8 = undefined,
    wiring: [][]usize = undefined,
    joltage: []usize = undefined,

    const Self = @This();

    pub fn init(gpa: std.mem.Allocator, ln: []const u8) !Self {
        var m = Machine{};

        var iter = std.mem.splitScalar(u8, ln, ' ');
        var wiring = std.array_list.Managed([]usize).init(gpa);

        while (iter.next()) |part| {
            const sp = part[1 .. part.len - 1];
            switch (part[0]) {
                '[' => {
                    m.targetLights = try gpa.alloc(u8, sp.len);
                    m.lights = try gpa.alloc(u8, sp.len);
                    std.mem.copyForwards(u8, m.targetLights, sp);
                    for (m.lights) |*l| l.* = '.';
                },
                '{' => {
                    m.joltage = try zutils.str.parseInts(usize, gpa, sp, ',');
                },
                '(' => {
                    const wl = try zutils.str.parseInts(usize, gpa, sp, ',');
                    try wiring.append(wl);
                },
                else => unreachable,
            }
        }

        m.wiring = try wiring.toOwnedSlice();
        return m;
    }

    pub fn print(self: *const Self) void {
        std.debug.print("<Machine\n\tlights: [{s}]\n\ttarget: [{s}]\n\twiring: ", .{
            self.lights,
            self.targetLights,
        });

        for (self.wiring) |w| {
            std.debug.print("{any} ", .{w});
        }
        std.debug.print("\n\tjoltage: {any}\n", .{self.joltage});
    }
};

fn parse(gpa: std.mem.Allocator, input: []const u8) ![]Machine {
    var machines = try gpa.alloc(Machine, std.mem.count(u8, input, &[1]u8{'\n'}) + 1);
    var iter = std.mem.splitScalar(u8, input, '\n');
    var i: usize = 0;
    while (iter.next()) |ln| : (i += 1) {
        machines[i] = try Machine.init(gpa, ln);
    }
    return machines;
}

fn solve(gpa: std.mem.Allocator, input: []const u8) ![2]usize {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const alloc = arena.allocator();

    const machines = try parse(alloc, input);
    std.debug.print("hey: {d}\n", .{machines.len});
    for (machines) |*m| {
        m.print();
    }
    return .{ 0, 0 };
}

test "example" {
    const input =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;

    const res = try solve(std.testing.allocator, input);

    try std.testing.expectEqual(0, res[0]);
    try std.testing.expectEqual(0, res[1]);
}
