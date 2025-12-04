const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    // It's also possible to define more custom flags to toggle optional features
    // of this build script using `b.option()`. All defined flags (including
    // target and optimize options) will be listed when running `zig build --help`
    // in this directory.

    const days = [_]struct {
        name: []const u8,
        source: []const u8,
    }{
        .{ .name = "day_01", .source = "src/day_01.zig" },
        .{ .name = "day_02", .source = "src/day_02.zig" },
        .{ .name = "day_03", .source = "src/day_03.zig" },
        .{ .name = "day_04", .source = "src/day_04.zig" },
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
