const std = @import("std");

const YEAR_DIRS = [_][]const u8{ "2022", "2024" };

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // set up zutils
    const zutils = b.addModule("zutils", .{
        .root_source_file = b.path("zutils/zutils.zig"),
        .target = target,
    });
    const zutils_test = b.addTest(.{ .root_source_file = b.path("zutils/zutils.zig") });
    const run_ztest = b.addRunArtifact(zutils_test);
    const ztest_step = b.step("test_zutils", "Run zutils tests");
    ztest_step.dependOn(&run_ztest.step);

    // iterate through day files and add targets
    const cwd = std.fs.cwd();
    for (YEAR_DIRS) |y| {
        const year = try cwd.openDir(y, .{ .iterate = true });
        var iter = year.iterate();
        while (try iter.next()) |ent| {
            switch (ent.kind) {
                .file => {
                    if (!std.mem.endsWith(u8, ent.name, ".zig")) {
                        continue;
                    }
                    const zigfile = b.fmt("{s}/{s}", .{ y, ent.name });
                    // remove .zig
                    const exename = b.fmt("{s}_{s}", .{ y, ent.name[0 .. ent.name.len - 4] });

                    // add day exe
                    const day_exe = b.addExecutable(.{
                        .name = exename,
                        .root_source_file = b.path(zigfile),
                        .target = target,
                        .optimize = optimize,
                    });
                    day_exe.root_module.addImport("zutils", zutils);
                    b.installArtifact(day_exe);

                    // add day run
                    const run_day = b.addRunArtifact(day_exe);
                    const run_step = b.step(b.fmt("run_{s}", .{exename}), b.fmt("Run {s}", .{exename}));
                    run_step.dependOn(&run_day.step);

                    // add day test
                    const day_test = b.addTest(.{ .root_source_file = b.path(zigfile) });
                    day_test.root_module.addImport("zutils", zutils);

                    const run_test = b.addRunArtifact(day_test);
                    const test_step = b.step(b.fmt("test_{s}", .{exename}), b.fmt("Run tests for {s}", .{exename}));
                    test_step.dependOn(&run_test.step);
                },
                else => {
                    continue;
                },
            }
        }
    }
}
