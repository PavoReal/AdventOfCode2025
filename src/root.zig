//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

///////////////////////////////////////////////////////////
// Day 1                                                 //
///////////////////////////////////////////////////////////
const Direction = enum {
    DEC,
    INC,
};
const DirectionParseError = error{UNKNOWN_CHAR};

fn charToDirection(c: u8) !Direction {
    return switch (c) {
        'R' => .INC,
        'L' => .DEC,
        else => DirectionParseError.UNKNOWN_CHAR,
    };
}

const Action = struct {
    dir: Direction,
    mag: i32,

    pub fn new(line: []const u8) !Action {
        var result: Action = undefined;

        result.dir = try charToDirection(line[0]);
        result.mag = try std.fmt.parseInt(i32, line[1..], 10);

        return result;
    }
};

const Dial = struct {
    max: i32 = 100,
    current: i32 = 50,

    pub fn process_action(self: *Dial, action: Action) u32 {
        const step = if (action.dir == .INC) action.mag else -action.mag;
        const start = self.current;
        const target = start + step;

        var wraps: i32 = 0;

        if (target > start) {
            wraps = @divFloor(target, self.max) - @divFloor(start, self.max);
        } else {
            wraps = @divFloor(start - 1, self.max) - @divFloor(target - 1, self.max);
        }

        if (@mod(target, self.max) == 0 and wraps > 0) {
            wraps -= 1;
        }

        self.current = @mod(target, self.max);

        return @abs(wraps);
    }
};

pub fn dayOne() void {
    const input_path = "inputs/day_one.txt";

    const input: []const u8 = @embedFile(input_path);

    var bytes_processed: usize = 0;
    var dial: Dial = .{};
    var zero_landings: u32 = 0;
    var zero_crosses: u32 = 0;

    while (bytes_processed < input.len) {
        const endl_index = std.mem.indexOfScalar(u8, input[bytes_processed..], '\n');

        if (endl_index) |offset| {
            const index = offset + bytes_processed;

            const line = input[bytes_processed..index];
            bytes_processed = index + 1;

            const action = Action.new(line) catch |err| {
                std.log.err("Failed to parse line {s}, skipping... {}", .{ line, err });
                continue;
            };

            const wraps = dial.process_action(action);
            zero_crosses += wraps;

            if (dial.current == 0) {
                zero_landings += 1;
            }
        } else {
            break;
        }
    }

    std.log.info("Part 1: {d}", .{zero_landings});
    std.log.info("Part 2: {d}", .{zero_landings + zero_crosses});
}

///////////////////////////////////////////////////////////
// Day 2                                                 //
///////////////////////////////////////////////////////////

fn isAddressValid(addr: u64) !bool {
    var buffer: [1024]u8 = undefined;

    const address = try std.fmt.bufPrint(&buffer, "{d}", .{addr});

    if ((address.len % 2) != 0) {
        return true;
    }

    const middle = address.len / 2;
    const lhs = address[0..middle];
    const rhs = address[middle..];

    const is_valid = ~std.mem.eql(u8, lhs, rhs);

    return is_valid;
}

test "Test isAddressValid" {
    std.testing.log_level = .debug;
    try std.testing.expect(isAddressValid("9"));
    try std.testing.expect(isAddressValid("10"));
    try std.testing.expect(!isAddressValid("11"));
    try std.testing.expect(!isAddressValid("1188511885"));
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
        result.end = try std.fmt.parseInt(u64, std.mem.trimRight(u8, end, "\n\r"), 10);

        return result;
    }
};

pub fn dayTwo() void {
    const input_path = "inputs/day_two.txt";
    const input: []const u8 = @embedFile(input_path);

    var bytes_processed: usize = 0;
    var invalid_sum: u64 = 0;

    while (bytes_processed < input.len) {
        const start_index = bytes_processed;
        var sep_index = std.mem.indexOfScalar(u8, input[start_index..], ',');

        if (sep_index == null) {
            sep_index = input.len - start_index;
        }

        const sep_value = sep_index.?;

        const range = Range.new(input[start_index..(sep_value + start_index)]) catch |err| {
            std.log.err("Error parsing range {s}\n{}", .{ input[start_index..(sep_value + start_index)], err });
            return;
        };

        // std.log.debug("Start {d} - End {d}", .{ range.start, range.end });

        if (range.end < range.start) {
            std.log.err("End of range < start of range. Parse error? {d}-{d}", .{ range.start, range.end });
            return;
        }

        for (range.start..range.end + 1) |addr| {
            const is_valid = isAddressValid(addr) catch |err| {
                std.log.err("Could not check if address {d} is valid\n{}", .{ addr, err });
                return;
            };

            if (!is_valid) {
                // std.log.info("Address {} is invalid", .{addr});
                invalid_sum += addr;
            }
        }

        bytes_processed += sep_value + 1;
    }

    std.log.info("Part 1 {}", .{invalid_sum});
}
