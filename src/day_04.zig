const std = @import("std");

const Point = struct { x: usize = 0, y: usize = 0 };

const DayFour = struct {
    part_one: u32 = 0,
    part_two: u32 = 0,

    grid_width: usize = 0,
    grid_height: usize = 0,
    grid_stride: usize = 0,

    grid: []u8 = undefined,

    pub fn countNeighbors(self: *DayFour, point: Point) u8 {
        var result: u8 = 0;

        if ((point.x >= self.grid_width) or (point.y >= self.grid_height)) return 0;

        const min_x = @as(usize, @intCast(@max(0, @as(i32, @intCast(point.x)) - 1)));
        const max_x = @as(usize, @intCast(@min(self.grid_width, @as(i32, @intCast(point.x)) + 2)));
        const min_y = @as(usize, @intCast(@max(0, @as(i32, @intCast(point.y)) - 1)));
        const max_y = @as(usize, @intCast(@min(self.grid_height, @as(i32, @intCast(point.y)) + 2)));

        for (min_y..max_y) |yy| {
            for (min_x..max_x) |xx| {
                if (yy == point.y and xx == point.x) continue;

                const index = (yy * self.grid_stride) + xx;

                const c = self.grid[index];

                if (c == '@') {
                    result += 1;
                    continue;
                }
            }
        }

        return result;
    }

    pub fn calcIndex(self: *DayFour, point: Point) usize {
        return (point.y * self.grid_stride) + point.x;
    }

    pub fn clearPoint(self: *DayFour, point: Point) void {
        if ((point.x >= self.grid_width) or (point.y >= self.grid_height)) return;

        self.grid[self.calcIndex(point)] = '.';
    }
};

pub fn main() void {
    var day: DayFour = .{};

    const input = @embedFile("./inputs/day_four.txt");
    var buffer: [input.len]u8 = undefined;
    std.mem.copyForwards(u8, &buffer, input);

    day.grid = &buffer;

    const width = std.mem.indexOfScalar(u8, day.grid, '\n');

    if (width == null) {
        std.log.err("Couldn't parse file stride", .{});
        return;
    }

    day.grid_width = width.?;
    day.grid_stride = day.grid_width + 1;
    day.grid_height = std.mem.countScalar(u8, day.grid, '\n');

    var points_to_remove: [input.len]Point = undefined;
    @memset(&points_to_remove, .{});

    var first_loop = true;

    while (true) {
        var index_top: usize = 0;

        for (0..day.grid_height) |y| {
            for (0..day.grid_width) |x| {
                const p: Point = .{ .x = x, .y = y };

                if (day.grid[day.calcIndex(p)] != '@') {
                    continue;
                }

                const neighbors = day.countNeighbors(p);

                if (neighbors < 4) {
                    if (first_loop) {
                        day.part_one += 1;
                    }
                    day.part_two += 1;

                    points_to_remove[index_top] = p;
                    index_top += 1;
                }
            }
        }

        first_loop = false;

        if (index_top == 0) {
            break;
        }

        for (0..index_top) |i| {
            day.clearPoint(points_to_remove[i]);
        }
    }

    std.log.info("Day 4 part 1: {d}", .{day.part_one});
    std.log.info("Day 4 part 2: {d}", .{day.part_two});
}
