const std = @import("std");

const DayThreeResults = struct { a: u32 = 0, b: u32 = 0 };

pub fn dayOne() DayThreeResults {
    return .{};
}

pub fn main() !void {
    const result = comptime dayOne();

    std.log.info("Day 3 part 1: {d}", .{result.a});
    std.log.info("Day 3 part 2: {d}", .{result.b});
}
