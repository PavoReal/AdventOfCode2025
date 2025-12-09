const std = @import("std");

const DayResults = struct { part_one: u64 = 0, part_two: u64 = 0 };

fn runDay() !DayResults {
    const input = @embedFile("./inputs/day_nine.txt");
    return .{};
}

pub fn main() !void {
    const results = try runDay();

    std.log.info("Day 9 part 1 {}", .{results.part_one});
    std.log.info("Day 9 part 2 {}", .{results.part_two});
}
