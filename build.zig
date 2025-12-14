const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

    const days = [_]struct {
        name: []const u8,
        source: []const u8,
        deps: []const u8,
    }{
        .{ .name = "day_01", .source = "src/day_01.zig", .deps = "" },
        .{ .name = "day_02", .source = "src/day_02.zig", .deps = "" },
        .{ .name = "day_03", .source = "src/day_03.zig", .deps = "" },
        .{ .name = "day_04", .source = "src/day_04.zig", .deps = "" },
        .{ .name = "day_05", .source = "src/day_05.zig", .deps = "" },
        .{ .name = "day_06", .source = "src/day_06.zig", .deps = "" },
        .{ .name = "day_07", .source = "src/day_07.zig", .deps = "" },
        .{ .name = "day_08", .source = "src/day_08.zig", .deps = "" },
        .{ .name = "day_09", .source = "src/day_09.zig", .deps = "" },
        .{ .name = "day_10", .source = "src/day_10.zig", .deps = "z3" },
    };

    const run_all_step = b.step("run", "Run all day executables");
    const test_step = b.step("test", "Run tests");

    for (days) |day| {
        const exe = b.addExecutable(.{
            .name = day.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(day.source),
                .target = target,
                .optimize = optimize,
            }),
        });

        if (day.deps.len > 0) {
            exe.root_module.linkSystemLibrary(day.deps, .{});
        }

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step(b.fmt("run-{s}", .{day.name}), b.fmt("Run {s}", .{day.name}));
        run_step.dependOn(&run_cmd.step);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        run_all_step.dependOn(&run_cmd.step);

        const tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(day.source),
                .target = target,
                .optimize = optimize,
            }),
        });
        const run_tests = b.addRunArtifact(tests);
        test_step.dependOn(&run_tests.step);
    }
}
