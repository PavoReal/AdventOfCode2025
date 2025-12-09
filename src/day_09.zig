const std = @import("std");

const DayResults = struct { part_one: f64 = 0, part_two: u64 = 0 };
const Point = struct {
    x: u64 = 0,
    y: u64 = 0,

    pub fn init(line: []const u8) !Point {
        var iter = std.mem.tokenizeScalar(u8, line, ',');

        const x_digits = iter.next().?;
        const x = try std.fmt.parseInt(u64, x_digits, 10);

        const y_digits = iter.next().?;
        const y = try std.fmt.parseInt(u64, y_digits, 10);

        return .{ .x = x, .y = y };
    }
};

fn runDay(alloc: std.mem.Allocator) !DayResults {
    @setEvalBranchQuota(1000000);

    const input = @embedFile("./inputs/day_nine.txt");
    const input_num_lines = comptime std.mem.countScalar(u8, input, '\n');
    var line_iter = comptime std.mem.tokenizeScalar(u8, input, '\n');

    var points = try std.ArrayList(Point).initCapacity(alloc, input_num_lines);
    defer points.deinit(alloc);

    while (line_iter.next()) |line| {
        try points.append(alloc, try Point.init(line));
    }

    var max_area: f64 = 0;

    for (points.items, 0..) |p1, i| {
        for (i + 1..points.items.len) |j| {
            const p2 = &points.items[j];

            const dx = @abs(@as(f64, @floatFromInt(p2.x)) - @as(f64, @floatFromInt(p1.x))) + 1;
            const dy = @abs(@as(f64, @floatFromInt(p2.y)) - @as(f64, @floatFromInt(p1.y))) + 1;

            const area: f64 = dx * dy;
            max_area = @max(area, max_area);
        }
    }

    return .{ .part_one = max_area };
}

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const alloc = allocator.allocator();
    const results = try runDay(alloc);

    std.log.info("Day 9 part 1 {}", .{results.part_one});
    std.log.info("Day 9 part 2 {}", .{results.part_two});
}
