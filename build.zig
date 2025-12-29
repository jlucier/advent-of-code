const std = @import("std");

const YEAR_DIRS = [_][]const u8{ "2022", "2024", "2025" };
const DEPEND_ON_Z3 = [_][]const u8{"2025_10"};

fn addZ3(b: *std.Build, comps: []*std.Build.Step.Compile) void {
    // Configure
    const z3_src = "vendor/z3";
    const z3_build = "zig-out/z3-build";
    const cmake_configure = b.addSystemCommand(&.{
        "cmake",
        "-S",
        z3_src,
        "-B",
        z3_build,
        "-DZ3_BUILD_LIBZ3_SHARED=ON",
        "-DZ3_BUILD_TESTS=OFF",
        "-DCMAKE_BUILD_TYPE=Release",
    });

    // Build
    const cmake_build = b.addSystemCommand(&.{
        "cmake",
        "--build",
        z3_build,
        "--config",
        "Release",
        "--parallel",
    });
    cmake_build.step.dependOn(&cmake_configure.step);

    for (comps) |c| {
        c.step.dependOn(&cmake_build.step);
        c.addIncludePath(b.path(b.pathJoin(&.{ z3_src, "/src/api" })));
        c.addIncludePath(b.path(b.pathJoin(&.{ z3_build, "/include" })));

        c.addLibraryPath(b.path(z3_build));
        c.linkSystemLibrary("z3");
        c.linkLibCpp();
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // set up zutils
    const zutils = b.addModule("zutils", .{
        .root_source_file = b.path("zutils/zutils.zig"),
        .target = target,
    });
    const zutils_test = b.addTest(.{ .root_module = zutils });
    const run_ztest = b.addRunArtifact(zutils_test);
    const ztest_step = b.step("test_zutils", "Run zutils tests");
    ztest_step.dependOn(&run_ztest.step);

    const all_test_step = b.step("test_all", "Run all tests");
    all_test_step.dependOn(&run_ztest.step);

    // iterate through day files and add targets
    const cwd = std.fs.cwd();
    var z3_dependants = std.array_list.Managed(*std.Build.Step.Compile).init(std.heap.page_allocator);
    defer z3_dependants.deinit();

    for (YEAR_DIRS) |y| {
        const year = try cwd.openDir(y, .{ .iterate = true });
        const run_year_step = b.step(b.fmt("run_{s}", .{y}), b.fmt("Run all in {s}", .{y}));

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

                    const day_mod = b.addModule(exename, .{
                        .root_source_file = b.path(zigfile),
                        .target = target,
                        .optimize = optimize,
                    });

                    // add day exe
                    const day_exe = b.addExecutable(.{
                        .name = exename,
                        .root_module = day_mod,
                    });
                    day_exe.root_module.addImport("zutils", zutils);
                    b.installArtifact(day_exe);

                    // add day run
                    const run_day = b.addRunArtifact(day_exe);
                    const run_step = b.step(b.fmt("run_{s}", .{exename}), b.fmt("Run {s}", .{exename}));
                    run_step.dependOn(&run_day.step);
                    run_year_step.dependOn(&run_day.step);

                    // add day test
                    const day_test = b.addTest(.{ .name = exename, .root_module = day_mod });
                    day_test.root_module.addImport("zutils", zutils);

                    const run_test = b.addRunArtifact(day_test);
                    const test_step = b.step(b.fmt("test_{s}", .{exename}), b.fmt("Run tests for {s}", .{exename}));
                    test_step.dependOn(&run_test.step);
                    all_test_step.dependOn(&run_test.step);

                    for (DEPEND_ON_Z3) |exe| {
                        if (std.mem.eql(u8, exe, exename)) {
                            try z3_dependants.append(day_exe);
                            try z3_dependants.append(day_test);
                            break;
                        }
                    }
                },
                else => {
                    continue;
                },
            }
        }
    }
    if (z3_dependants.items.len > 0) {
        addZ3(b, z3_dependants.items);
    }
}
