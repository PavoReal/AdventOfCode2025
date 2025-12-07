const std = @import("std");

const DayResults = struct {
    part_one: i64 = 0,
    part_two: i64 = 0,
};

fn opAdd(a: i64, b: i64) i64 {
    return a + b;
}

fn opMult(a: i64, b: i64) i64 {
    return a * b;
}

fn runDay() !DayResults {
    @setEvalBranchQuota(1000000);

    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const alloc = allocator.allocator();

    var result: DayResults = .{};
    result.part_one = 0;
    result.part_two = 0;

    const input = @embedFile("./inputs/day_six.txt");
    const first_endl = comptime std.mem.findScalar(u8, input, '\n').?;

    var worksheet: []i64 = try alloc.alloc(i64, first_endl * first_endl);
    @memset(worksheet, 0);
    var line_iter = comptime std.mem.tokenizeScalar(u8, input, '\n');

    var x: usize = 0;
    var y: usize = 0;

    // Parse digit grid
    while (line_iter.peek()) |line| {
        const contains_add = std.mem.containsAtLeastScalar2(u8, line, '+', 1);
        const contains_mult = std.mem.containsAtLeastScalar2(u8, line, '*', 1);

        if (contains_add or contains_mult) {
            break;
        }

        _ = line_iter.next();
        x = 0;

        var digits_iter = std.mem.tokenizeScalar(u8, line, ' ');

        while (digits_iter.next()) |digits| {
            if (digits.len == 0) {
                continue;
            }

            const val = try std.fmt.parseInt(i64, digits, 10);
            const i = (y * first_endl) + x;

            worksheet[i] = val;
            x += 1;
        }

        y += 1;
    }

    x = 0;

    // Parse operations
    while (line_iter.next()) |line| {
        var op_iter = std.mem.tokenizeScalar(u8, line, ' ');

        while (op_iter.next()) |op| {
            var op_func: *const (fn (i64, i64) i64) = opAdd;
            var total: i64 = 0;

            if (std.mem.allEqual(u8, op, '*')) {
                op_func = opMult;
                total = 1;
            }

            for (0..y) |h| {
                const index = (h * first_endl) + x;
                const ws = worksheet[index];

                total = op_func(total, ws);
            }

            x += 1;

            result.part_one += total;
        }
    }

    return result;
}

pub fn main() !void {
    const day = try runDay();

    std.log.info("Day 6 part 1: {d}", .{day.part_one});
    std.log.info("Day 6 part 2: {d}", .{day.part_two});
}
