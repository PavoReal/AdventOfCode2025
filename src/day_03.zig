const std = @import("std");

fn extractDigitsFromLine(line: []const u8, num_digits: u8) u64 {
    if (line.len < num_digits) return 0;

    var result: u64 = 0;

    var search_start_index: usize = 0;
    var digits_needed = num_digits;

    while (digits_needed > 0) : (digits_needed -= 1) {
        const search_end_limit = line.len - digits_needed + 1;

        var max_digit: u8 = 0;
        var max_digit_index: usize = search_start_index;
        var found_first = false;

        for (search_start_index..search_end_limit) |i| {
            const digit = line[i] - '0';

            if (!found_first or digit > max_digit) {
                max_digit = digit;
                max_digit_index = i;

                if (max_digit == 9) break;
            }
            found_first = true;
        }

        result = (result * 10) + max_digit;

        search_start_index = max_digit_index + 1;
    }

    return result;
}

test "extractDigitsFromLine" {
    std.testing.log_level = .debug;
    try std.testing.expect(extractDigitsFromLine("987654321111111", 2) == 98);
    try std.testing.expect(extractDigitsFromLine("811111111111119", 2) == 89);
    try std.testing.expect(extractDigitsFromLine("234234234234278", 2) == 78);
    try std.testing.expect(extractDigitsFromLine("818181911112111", 2) == 92);
    try std.testing.expect(extractDigitsFromLine("987654321111111", 12) == 987654321111);
    try std.testing.expect(extractDigitsFromLine("811111111111119", 12) == 811111111119);
    try std.testing.expect(extractDigitsFromLine("234234234234278", 12) == 434234234278);
    try std.testing.expect(extractDigitsFromLine("818181911112111", 12) == 888911112111);
}

const DayThreeResults = struct { a: u64 = 0, b: u64 = 0 };

pub fn dayThree() DayThreeResults {
    const input_path = "./inputs/day_three.txt";
    const input: []const u8 = @embedFile(input_path);

    var iter = std.mem.splitScalar(u8, input, '\n');

    var part_one_count: u64 = 0;
    var part_two_count: u64 = 0;

    while (iter.next()) |line| {
        part_one_count += extractDigitsFromLine(line, 2);
        part_two_count += extractDigitsFromLine(line, 12);
    }

    return .{ .a = part_one_count, .b = part_two_count };
}

pub fn main() !void {
    const result = dayThree();

    std.log.info("Day 3 part 1: {d}", .{result.a});
    std.log.info("Day 3 part 2: {d}", .{result.b});
}
