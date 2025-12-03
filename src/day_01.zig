const std = @import("std");

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

const DayOneResults = struct { zero_landings: u32 = 0, zero_crosses: u32 = 0 };

pub fn dayOne() DayOneResults {
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

    return .{ .zero_crosses = zero_crosses, .zero_landings = zero_landings };
}

pub fn main() !void {
    @setEvalBranchQuota(500000);
    const result = comptime dayOne();

    std.log.info("Day 1 part 1: {d}", .{result.zero_landings});
    std.log.info("Day 1 part 2: {d}", .{result.zero_landings + result.zero_crosses});
}
