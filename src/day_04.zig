const std = @import("std");

const DayResults = struct { a: u64 = 0, b: u64 = 0 };

pub fn dayFour() DayResults {
    // const input_path = "./inputs/day_three.txt";
    // const input: []const u8 = @embedFile(input_path);

    return .{ .a = 0, .b = 0 };
}

pub fn main() void {
    const result = dayFour();

    std.log.info("Day 4 part 1: {d}", .{result.a});
    std.log.info("Day 4 part 2: {d}", .{result.b});
}
