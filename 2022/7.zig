const std = @import("std");
const zutils = @import("zutils.zig");

const TOTAL_DISK = 70000000;
const NEEDED_DISK = 30000000;

const INode = struct {
    const INodeMap = std.StringArrayHashMap(INode);
    const INodeType = enum {
        file,
        dir,
    };

    typ: INodeType = .file,
    parent: ?*INode = null,
    // NOTE: I think it's ok for the INode not to "own" the string memory because it'll be referenceable
    // for the duration of the program since the input is in memory.
    name: []const u8,
    // file attrs
    size: usize = 0,
    // dir attrs
    children: INodeMap,

    /// Deinit and free all children
    pub fn deinit(self: *INode) void {
        for (self.children.values()) |*child| {
            child.deinit();
        }
        self.children.deinit();
    }

    // /// Get the total size of the subtree beneath this node
    // pub fn getSubtreeSize(self: *const INode) usize {
    //     var sx = self.size;
    //
    //     for (self.children.values()) |child| {
    //         sx += child.getSubtreeSize();
    //     }
    //     return sx;
    // }

    pub fn tree(self: *const INode, allocator: std.mem.Allocator, indent: u8) !void {
        const indent_str = try allocator.alloc(u8, indent);
        defer allocator.free(indent_str);
        for (indent_str) |*c| {
            c.* = ' ';
        }
        std.debug.print("{s}{s}", .{ indent_str, self.name });
        switch (self.typ) {
            .file => {
                std.debug.print(" ({d})\n", .{self.size});
            },
            .dir => {
                std.debug.print(" (tot: {d})\n", .{self.size});
                for (self.children.values()) |*child| {
                    try child.tree(allocator, indent + 1);
                }
            },
        }
    }

    /// calculate the sizes of all directories in the hierarchy
    pub fn computeSizes(self: *INode) void {
        for (self.children.values()) |*child| {
            child.computeSizes();
        }

        if (self.parent) |p| p.size += self.size;
    }

    /// sum sizes of directories less than threshold
    pub fn part1(self: *const INode, threshold: usize) usize {
        var tot: usize = if (self.typ == .dir and self.size <= threshold) self.size else 0;

        for (self.children.values()) |*child| {
            tot += switch (child.typ) {
                .file => 0,
                .dir => child.part1(threshold),
            };
        }
        return tot;
    }

    /// Find the size of the smallest directory we can delete to free up the desired
    /// amount of space
    pub fn part2(self: *const INode, desired: usize) usize {
        switch (self.typ) {
            .file => {
                return std.math.maxInt(usize);
            },
            .dir => {
                var v = if (self.size >= desired) self.size else std.math.maxInt(usize);

                for (self.children.values()) |*child| {
                    v = zutils.min(usize, v, child.part2(desired));
                }
                return v;
            },
        }
    }
};

/// Parses output line into two pieces
/// Command like "$ cd somedir" => ["cd", "somedir"]
/// ls output like "1234 file.txt" => ["1234", "file.txt"]
fn parseOutputLine(line: []const u8) [2][]const u8 {
    var iter = std.mem.splitScalar(u8, line, ' ');
    var parts: [2][]const u8 = undefined;
    var p: u8 = 0;
    while (iter.next()) |part| {
        if (std.mem.eql(u8, part, "$")) {
            continue;
        }

        parts[p] = part;
        p += 1;
    }
    return parts;
}

/// Returns a parsed filesystem tree from the output, user manages memory
fn makeFS(allocator: std.mem.Allocator, lines: []const []const u8) !INode {
    var root = INode{
        .typ = .dir,
        .name = "/",
        .children = INode.INodeMap.init(allocator),
    };

    var curr_node = &root;
    for (lines) |ln| {
        const parts = parseOutputLine(ln);

        if (ln[0] == '$') {
            // command
            if (std.mem.eql(u8, parts[0], "cd")) {
                if (std.mem.eql(u8, parts[1], "/")) {
                    continue;
                } else if (std.mem.eql(u8, parts[1], "..")) {
                    curr_node = curr_node.parent.?;
                } else {
                    // NOTE: I think it's safe to reference by address since we'll have built up
                    // the hashmap before we start to use it and this pointer should not invalidate
                    curr_node = curr_node.children.getPtr(parts[1]).?;
                }
            }
        } else {
            // ls output
            const typ: INode.INodeType = if (std.mem.eql(u8, parts[0], "dir")) .dir else .file;
            try curr_node.children.put(parts[1], .{
                .parent = curr_node,
                .name = parts[1],
                .children = INode.INodeMap.init(allocator),
                .typ = typ,
            });
            var new_node = curr_node.children.getPtr(parts[1]).?;

            if (typ == .file) {
                new_node.size = try std.fmt.parseInt(usize, parts[0], 10);
            }
        }
    }

    root.computeSizes();
    return root;
}

test "p1" {
    const lines = [_][]const u8{
        "$ cd /",
        "$ ls",
        "dir a",
        "14848514 b.txt",
        "8504156 c.dat",
        "dir d",
        "$ cd a",
        "$ ls",
        "dir e",
        "29116 f",
        "2557 g",
        "62596 h.lst",
        "$ cd e",
        "$ ls",
        "584 i",
        "$ cd ..",
        "$ cd ..",
        "$ cd d",
        "$ ls",
        "4060174 j",
        "8033020 d.log",
        "5626152 d.ext",
        "7214296 k",
    };
    var fs = try makeFS(std.testing.allocator, &lines);
    defer fs.deinit();

    // part 1
    const v = fs.part1(100000);
    try std.testing.expectEqual(95437, v);

    // part 2
    const curr_free = TOTAL_DISK - fs.size;
    const additional_needed = NEEDED_DISK - curr_free;
    try std.testing.expectEqual(21618835, curr_free);
    try std.testing.expectEqual(8381165, additional_needed);

    try std.testing.expectEqual(24933642, fs.part2(additional_needed));
}

pub fn main() void {
    const lines = zutils.readLines(std.heap.page_allocator, "~/sync/dev/aoc_inputs/2022/7.txt") catch {
        std.debug.print("Failed to read input\n", .{});
        return;
    };

    var fs = makeFS(std.heap.page_allocator, lines.strings.items) catch {
        std.debug.print("Failed to parse\n", .{});
        return;
    };
    defer fs.deinit();

    // fs.tree(std.heap.page_allocator, 0) catch {
    //     std.debug.print("Failed to print\n", .{});
    //     return;
    // };

    std.debug.print("p1: {d}\n", .{fs.part1(100000)});
    const curr_free = TOTAL_DISK - fs.size;
    const additional_needed = NEEDED_DISK - curr_free;
    std.debug.print("p2: {d}\n", .{fs.part2(additional_needed)});
}
