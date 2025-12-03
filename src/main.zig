const std = @import("std");
const advent_of_code_2025 = @import("advent_of_code_2025");

pub fn main() !void {
    std.log.info("~~~~~~~~~~Day 1 Start~~~~~~~~~", .{});

    var timer = try std.time.Timer.start();
    advent_of_code_2025.dayOne();
    var elapsed_ns = timer.read();

    std.log.info("Day 1 completed in {d} ns", .{elapsed_ns});
    std.log.info("~~~~~~~~~~Day 1 Done~~~~~~~~~~", .{});

    std.log.info("~~~~~~~~~~Day 2 Start~~~~~~~~~", .{});

    timer = try std.time.Timer.start();
    advent_of_code_2025.dayTwo();
    elapsed_ns = timer.read();

    std.log.info("Day 2 completed in {d} ns", .{elapsed_ns});
    std.log.info("~~~~~~~~~~Day 2 Done~~~~~~~~~~", .{});
}
