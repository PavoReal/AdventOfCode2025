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

fn lineContainsOp(line: []const u8) bool {
    return std.mem.containsAtLeastScalar2(u8, line, '+', 1) or std.mem.containsAtLeastScalar2(u8, line, '*', 1);
}

pub fn calcWorksheetWidth(input: []const u8) usize {
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var width: usize = 0;

    const first_line = line_iter.next().?;

    var digit_iter = std.mem.tokenizeScalar(u8, first_line, ' ');
    while (digit_iter.next()) |d| {
        if (d.len == 0) {
            continue;
        }

        width += 1;
    }

    return width;
}

pub fn calcWorksheetHeight(input: []const u8) usize {
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var height: usize = 0;

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (lineContainsOp(line)) {
            break;
        }

        height += 1;
    }

    return height;
}

fn createWorksheet(comptime input: []const u8) type {
    const width = comptime calcWorksheetWidth(input);
    const height = comptime calcWorksheetHeight(input);

    return struct { data: [width * height]i64 = undefined, width: usize = width, height: usize = height };
}

fn calculatePartTwo(input: []const u8) !i64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    defer arena.deinit();
    const allocator = arena.allocator();

    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var max_len: usize = 0;

    while (it.next()) |line| {
        try lines.append(allocator, line);
        if (line.len > max_len) max_len = line.len;
    }

    var grand_total: i64 = 0;
    var current_op: u8 = ' ';
    var current_nums: std.ArrayList(i64) = .empty;
    defer current_nums.deinit(allocator);

    var inside_block = false;

    var x: usize = max_len;
    while (x > 0) {
        x -= 1;

        var col_chars: std.ArrayList(u8) = .empty;
        defer col_chars.deinit(allocator);

        var is_separator = true;

        for (lines.items) |line| {
            const char = if (x < line.len) line[x] else ' ';
            try col_chars.append(allocator, char);
            if (char != ' ') is_separator = false;
        }

        if (is_separator) {
            if (inside_block) {
                if (current_nums.items.len > 0) {
                    var blk_res = current_nums.items[0];
                    for (current_nums.items[1..]) |num| {
                        if (current_op == '+') blk_res += num;
                        if (current_op == '*') blk_res *= num;
                    }
                    grand_total += blk_res;
                }
                current_nums.clearRetainingCapacity();
                current_op = ' ';
                inside_block = false;
            }
        } else {
            inside_block = true;

            const bot_char = col_chars.items[col_chars.items.len - 1];
            if (bot_char == '+' or bot_char == '*') {
                current_op = bot_char;
            }

            var digit_val: i64 = 0;
            var mult: i64 = 1;
            var has_digits = false;

            var y: usize = col_chars.items.len - 1;
            while (y > 0) {
                y -= 1;
                const ch = col_chars.items[y];
                if (std.ascii.isDigit(ch)) {
                    digit_val += (ch - '0') * mult;
                    mult *= 10;
                    has_digits = true;
                }
            }

            if (has_digits) {
                try current_nums.append(allocator, digit_val);
            }
        }
    }

    if (inside_block and current_nums.items.len > 0) {
        var blk_res = current_nums.items[0];
        for (current_nums.items[1..]) |num| {
            if (current_op == '+') blk_res += num;
            if (current_op == '*') blk_res *= num;
        }
        grand_total += blk_res;
    }

    return grand_total;
}
fn runDay() !DayResults {
    @setEvalBranchQuota(1000000);

    var result: DayResults = .{};
    result.part_one = 0;
    result.part_two = 0;

    const input = @embedFile("./inputs/day_six.txt");

    var worksheet = comptime createWorksheet(input){};
    @memset(&worksheet.data, 0);

    var line_iter = comptime std.mem.tokenizeScalar(u8, input, '\n');

    var x: usize = 0;
    var y: usize = 0;

    // Parse digit grid
    while (line_iter.peek()) |line| {
        if (lineContainsOp(line)) break;

        _ = line_iter.next();
        x = 0;

        var digits_iter = std.mem.tokenizeScalar(u8, line, ' ');

        while (digits_iter.next()) |digits| {
            if (digits.len == 0) {
                continue;
            }

            const val = try std.fmt.parseInt(i64, digits, 10);
            const i = (y * worksheet.width) + x;

            worksheet.data[i] = val;
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
            var reverse_total: i64 = 0;

            if (std.mem.allEqual(u8, op, '*')) {
                op_func = opMult;
                total = 1;
                reverse_total = 1;
            }

            for (0..worksheet.height) |h| {
                // Part 1
                const index = (h * worksheet.width) + x;
                const ws = worksheet.data[index];

                total = op_func(total, ws);
            }

            result.part_one += total;
            x += 1;
        }
    }

    result.part_two = try calculatePartTwo(input);
    return result;
}

pub fn main() !void {
    const day = try runDay();

    std.log.info("Day 6 part 1: {d}", .{day.part_one});
    std.log.info("Day 6 part 2: {d}", .{day.part_two});
}
