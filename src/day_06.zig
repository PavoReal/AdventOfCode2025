const std = @import("std");

const DayResults = struct {
    part_one: u64 = 0,
    part_two: u64 = 0,
};

const Worksheet = struct {
    data: std.ArrayList(i32),
    row_length: usize,

    pub fn at(self: *const Worksheet, row: usize, col: usize) i32 {
        return self.data.items[row * self.row_length + col];
    }
};

fn runDay(alloc: std.mem.Allocator) DayResults {
    var result: DayResults = .{};
    result.part_one = 0;
    result.part_two = 0;

    const input = @embedFile("./inputs/day_six.txt");

    var worksheet = Worksheet{
        .data = std.ArrayList(i32).init(alloc),
        .row_length = std.mem.findScalar(u8, input, '\n').?,
    };

    return result;
}

pub fn main() void {
    var allocator = std.heap.DebugAllocator(.{}){};
    const alloc = allocator.allocator();

    const day = runDay(alloc);

    std.log.info("Day 6 part 1: {d}", .{day.part_one});
    std.log.info("Day 6 part 2: {d}", .{day.part_two});
}
