const std = @import("std");

const DayFour = struct {
    part_one: u32 = 0,
    part_two: u32 = 0,

    grid_width: usize = 0,
    grid_height: usize = 0,

    grid_stride: usize = 0,

    grid: []const u8 = undefined,

    fn areCoordsValud(self: *DayFour, x: usize, y: usize) bool {
        return (x < self.grid_width) and (y < self.grid_height);
    }

    fn countNeighbors(self: *DayFour, x: usize, y: usize) u8 {
        var result: u8 = 0;

        if (!areCoordsValud(self, x, y)) return 0;

        const min_x = @as(usize, @intCast(@max(0, @as(i32, @intCast(x)) - 1)));
        const max_x = @as(usize, @intCast(@min(self.grid_width, @as(i32, @intCast(x)) + 1)));
        const min_y = @as(usize, @intCast(@max(0, @as(i32, @intCast(y)) - 1)));
        const max_y = @as(usize, @intCast(@min(self.grid_height, @as(i32, @intCast(y)) + 1)));

        std.log.debug("min x {} max x {} min y {} max y {}", .{ min_x, max_x, min_y, max_y });

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

    pub fn dayFour() DayFour {
        var self: DayFour = .{};

        const input_path = "./inputs/day_four.txt";
        self.grid = @embedFile(input_path);

        const stride_ = std.mem.indexOfScalar(u8, self.grid, '\n');

        if (stride_ == null) {
            std.log.err("Couldn't parse file stride", .{});
            return .{};
        }

        self.grid_stride = stride_.? + 1;
        self.grid_width = stride_.?;
        self.grid_height = (self.grid.len / self.grid_stride) - 1;

        self.part_one = 0;

        for (0..self.grid_height) |y| {
            for (0..self.grid_width) |x| {
                const neighbors = self.countNeighbors(x, y);

                std.log.debug("x {} y {} n {}", .{ x, y, neighbors });

                if (neighbors < 4) {
                    self.part_one += 1;
                }
            }
        }

        return self;
    }
};

pub fn main() void {
    const day: DayFour = DayFour.dayFour();

    std.log.info("Day 4 part 1: {d}", .{day.part_one});
    std.log.info("Day 4 part 2: {d}", .{day.part_two});
}
