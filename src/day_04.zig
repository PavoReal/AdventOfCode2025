const std = @import("std");

const DayFour = struct {
    part_one: u32 = 0,
    part_two: u32 = 0,

    grid_width: usize = 0,
    grid_height: usize = 0,
    grid_stride: usize = 0,

    grid: []const u8 = undefined,

    fn countNeighbors(self: *DayFour, x: usize, y: usize) u8 {
        var result: u8 = 0;

        if ((x >= self.grid_width) or (y >= self.grid_height)) return 0;

        const min_x = @as(usize, @intCast(@max(0, @as(i32, @intCast(x)) - 1)));
        const max_x = @as(usize, @intCast(@min(self.grid_width, @as(i32, @intCast(x)) + 2)));
        const min_y = @as(usize, @intCast(@max(0, @as(i32, @intCast(y)) - 1)));
        const max_y = @as(usize, @intCast(@min(self.grid_height, @as(i32, @intCast(y)) + 2)));

        for (min_y..max_y) |yy| {
            for (min_x..max_x) |xx| {
                if (yy == y and xx == x) continue;

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
};

pub fn main() void {
    var day: DayFour = .{};

    const input = @embedFile("./inputs/day_four.txt");
    day.grid = input;

    const width = std.mem.indexOfScalar(u8, day.grid, '\n');

    if (width == null) {
        std.log.err("Couldn't parse file stride", .{});
        return;
    }

    day.grid_width = width.?;
    day.grid_stride = day.grid_width + 1;
    day.grid_height = std.mem.countScalar(u8, day.grid, '\n');
    day.part_one = 0;

    for (0..day.grid_height) |y| {
        for (0..day.grid_width) |x| {
            const spot = day.grid[(y * day.grid_stride) + x];

            if (spot != '@') {
                continue;
            }

            const neighbors = day.countNeighbors(x, y);

            if (neighbors < 4) {
                day.part_one += 1;
            }
        }
    }

    std.log.info("Day 4 part 1: {d}", .{day.part_one});
    std.log.info("Day 4 part 2: {d}", .{day.part_two});
}
