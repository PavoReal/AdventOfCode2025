const std = @import("std");

fn isAddressValidPartOne(address: []const u8) !bool {
    if ((address.len % 2) != 0) {
        return true;
    }

    const middle = address.len / 2;
    const lhs = address[0..middle];
    const rhs = address[middle..];

    const is_valid = ~std.mem.eql(u8, lhs, rhs);

    return is_valid;
}

fn isAddressValidPartTwo(address: []const u8) !bool {
    for (1..(address.len / 2) + 1) |len| {
        if (address.len % len != 0) continue;

        const pattern = address[0..len];
        var is_repeating = true;
        var i = len;

        while (i < address.len) : (i += len) {
            const chunk = address[i .. i + len];

            if (!std.mem.eql(u8, pattern, chunk)) {
                is_repeating = false;
                break;
            }
        }

        if (is_repeating) {
            return false;
        }
    }

    return true;
}

test "Test isAddressValidPartOne" {
    try std.testing.expect(try isAddressValidPartOne("9"));
    try std.testing.expect(try isAddressValidPartOne("10"));
    try std.testing.expect(!try isAddressValidPartOne("11"));
    try std.testing.expect(!try isAddressValidPartOne("1188511885"));
}

const RangeParseError = error{NO_SEP};

const Range = struct {
    start: u64,
    end: u64,

    pub fn new(str: []const u8) !Range {
        const sep_index = std.mem.indexOfScalar(u8, str, '-');

        if (sep_index == null) {
            return RangeParseError.NO_SEP;
        }

        var result: Range = .{ .start = 10, .end = 10 };

        const sep_index_value = sep_index.?;

        const start = str[0..sep_index_value];
        const end = str[sep_index_value + 1 ..];

        result.start = try std.fmt.parseInt(u64, start, 10);
        result.end = try std.fmt.parseInt(u64, std.mem.trimEnd(u8, end, "\n\r"), 10);

        return result;
    }
};

const DayTwoResults = struct { part_one_sum: u64 = 0, part_two_sum: u64 = 0 };

pub fn dayTwo() DayTwoResults {
    const input_path = "inputs/day_two.txt";
    const input: []const u8 = @embedFile(input_path);

    var bytes_processed: usize = 0;
    var part_one_sum: u64 = 0;
    var part_two_sum: u64 = 0;

    while (bytes_processed < input.len) {
        const start_index = bytes_processed;
        var sep_index = std.mem.indexOfScalar(u8, input[start_index..], ',');

        if (sep_index == null) {
            sep_index = input.len - start_index;
        }

        const sep_value = sep_index.?;

        const range = Range.new(input[start_index..(sep_value + start_index)]) catch |err| {
            std.log.err("Error parsing range {s}\n{}", .{ input[start_index..(sep_value + start_index)], err });
            return .{};
        };

        if (range.end < range.start) {
            std.log.err("End of range < start of range. Parse error? {d}-{d}", .{ range.start, range.end });
            return .{};
        }

        for (range.start..range.end + 1) |addr| {
            var buffer: [1024]u8 = undefined;
            const address = std.fmt.bufPrint(&buffer, "{d}", .{addr}) catch |err| {
                std.log.err("Could not convert address {d} to string", .{addr});
                std.log.err("{}", .{err});
                return .{};
            };

            const is_valid_part_one = isAddressValidPartOne(address) catch |err| {
                std.log.err("Could not check if address {d} is valid (part one)\n{}", .{ addr, err });
                return .{};
            };

            const is_valid_part_two = isAddressValidPartTwo(address) catch |err| {
                std.log.err("Could not check if address {d} is valid (part two)\n{}", .{ addr, err });
                return .{};
            };

            if (!is_valid_part_one) {
                part_one_sum += addr;
            }

            if (!is_valid_part_two) {
                part_two_sum += addr;
            }
        }

        bytes_processed += sep_value + 1;
    }

    return .{ .part_one_sum = part_one_sum, .part_two_sum = part_two_sum };
}

pub fn main() !void {
    const results = dayTwo();

    std.log.info("Day 2 part 1 {}", .{results.part_one_sum});
    std.log.info("Day 2 part 2 {}", .{results.part_two_sum});
}
