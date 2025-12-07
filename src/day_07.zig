const std = @import("std");

const DayResults = struct {
    part_one: u64 = 0,
    part_two: u64 = 0,
};

fn runDay() DayResults {
    var result: DayResults = .{};

    const input = @embedFile("./inputs/day_seven.txt");
    var lines = comptime std.mem.tokenizeScalar(u8, input, '\n');
    const grid_stride = comptime std.mem.findScalar(u8, input, '\n').? + 1;

    var grid_pt1: [input.len]u8 = undefined;
    std.mem.copyForwards(u8, &grid_pt1, input);

    var timeline_counts: [input.len]u64 = undefined;
    @memset(&timeline_counts, 0);

    if (std.mem.indexOfScalar(u8, input, 'S')) |idx| {
        timeline_counts[idx] = 1;
    }

    var start_index: usize = 0;
    var end_index: usize = 0;

    // Part 1
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        end_index = start_index + line.len;

        var search_index: usize = start_index;

        // Find all sources and create lasers below
        while (std.mem.indexOfScalarPos(u8, grid_pt1[0..end_index], search_index, 'S')) |offset| {
            const new_laser_index = offset + grid_stride;
            grid_pt1[new_laser_index] = '|';

            search_index = offset + 1;
        }

        // Find all splitters and split above laser
        search_index = start_index;
        while (std.mem.indexOfScalarPos(u8, grid_pt1[0..end_index], search_index, '^')) |offset| {

            // Verify laser is above splitter
            const above = grid_pt1[offset - grid_stride];
            if (above == '|') {
                const left_index = offset - 1;
                const right_index = offset + 1;

                if (grid_pt1[left_index] != '|') {
                    grid_pt1[left_index] = '|';
                }

                if (grid_pt1[right_index] != '|') {
                    grid_pt1[right_index] = '|';
                }

                result.part_one += 1;
            }

            search_index = offset + 1;
        }

        // Find and propagate lasers
        search_index = start_index;
        while (std.mem.indexOfScalarPos(u8, grid_pt1[0..end_index], search_index, '|')) |offset| {
            const below_index = offset + grid_stride;

            if (below_index >= grid_pt1.len) break;

            if (grid_pt1[below_index] == '.') {
                grid_pt1[below_index] = '|';
            }

            search_index = offset + 1;
        }

        // Part 2

        search_index = start_index;
        while (std.mem.indexOfScalarPos(u8, input[0..end_index], search_index, '^')) |idx| {
            if (timeline_counts[idx] > 0) {
                const count = timeline_counts[idx];

                timeline_counts[idx - 1] += count;
                timeline_counts[idx + 1] += count;

                timeline_counts[idx] = 0;
            }
            search_index = idx + 1;
        }

        for (start_index..end_index) |idx| {
            if (timeline_counts[idx] > 0) {
                const next_row_idx = idx + grid_stride;

                if (next_row_idx >= input.len) {
                    // Off the board -> Finished timeline
                    result.part_two += timeline_counts[idx];
                } else {
                    // Move down
                    timeline_counts[next_row_idx] += timeline_counts[idx];
                }
            }
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
