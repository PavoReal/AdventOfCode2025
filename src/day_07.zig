const std = @import("std");

const DayResults = struct {
    part_one: i64 = 0,
    part_two: i64 = 0,
};

fn runDay() DayResults {
    var result: DayResults = .{};

    const input = @embedFile("./inputs/day_seven.txt");
    var lines = comptime std.mem.tokenizeScalar(u8, input, '\n');
    const grid_stride = comptime std.mem.findScalar(u8, input, '\n').? + 1;

    var grid: [input.len]u8 = undefined;
    std.mem.copyForwards(u8, &grid, input);

    var start_index: usize = 0;
    var end_index: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        end_index = start_index + line.len;

        var search_index: usize = start_index;

        // Find all sources and create lasers below
        while (std.mem.indexOfScalarPos(u8, grid[0..end_index], search_index, 'S')) |offset| {
            const new_laser_index = offset + grid_stride;
            grid[new_laser_index] = '|';

            search_index = offset + 1;
        }

        // Find all splitters and split above laser
        search_index = start_index;
        while (std.mem.indexOfScalarPos(u8, grid[0..end_index], search_index, '^')) |offset| {

            // Verify laser is above splitter
            const above = grid[offset - grid_stride];
            if (above == '|') {
                const left_index = offset - 1;
                const right_index = offset + 1;

                if (grid[left_index] != '|') {
                    grid[left_index] = '|';
                }

                if (grid[right_index] != '|') {
                    grid[right_index] = '|';
                }

                result.part_one += 1;
            }

            search_index = offset + 1;
        }

        // Find and propagate lasers
        search_index = start_index;
        while (std.mem.indexOfScalarPos(u8, grid[0..end_index], search_index, '|')) |offset| {
            const below_index = offset + grid_stride;

            if (below_index >= grid.len) break;

            if (grid[below_index] == '.') {
                grid[below_index] = '|';
            }

            search_index = offset + 1;
        }

        start_index = end_index + 1;
    }

    return result;
}

pub fn main() !void {
    const day = runDay();

    std.log.info("Day 7 part 1 {}", .{day.part_one});
    std.log.info("Day 7 part 2 {}", .{day.part_two});
}
