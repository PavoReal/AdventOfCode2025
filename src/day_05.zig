const std = @import("std");

const Range = struct {
    high: u64 = 0,
    low: u64 = 0,

    pub fn init(str: []const u8) Range {
        const sep_ = std.mem.findScalar(u8, str, '-');

        if (sep_ == null) {
            std.log.err("Couldn't find sep in range {s}", .{str});
            return .{};
        }

        const sep = sep_.?;

        const low_str = str[0..sep];
        const high_str = str[sep + 1 ..];

        var result: Range = .{};

        result.low = std.fmt.parseInt(u64, low_str, 10) catch {
            std.log.err("Low range parse error {s} = {s}-{s}", .{ str, low_str, high_str });
            return .{};
        };

        result.high = std.fmt.parseInt(u64, high_str, 10) catch {
            std.log.err("High range parse error {s} = {s}-{s}", .{ str, low_str, high_str });
            return .{};
        };

        return result;
    }

    pub fn scalarInRange(self: *const Range, a: u64) bool {
        return (a <= self.high) and (a >= self.low);
    }
};

fn lessThanRange(
    _context: void,
    lhs: Range,
    rhs: Range,
) bool {
    _ = _context;

    return lhs.low < rhs.low;
}
const DayFive = struct {
    part_one: u64 = 0,
    part_two: u64 = 0,
};

fn runDay() DayFive {
    @setEvalBranchQuota(1000000);
    var result: DayFive = .{};

    const input = @embedFile("./inputs/day_five.txt");
    const range_count_upper_bound = comptime std.mem.countScalar(u8, input, '\n');

    var ranges: [range_count_upper_bound]Range = undefined;
    var merged_ranges: [range_count_upper_bound]Range = undefined;

    @memset(&ranges, .{});
    @memset(&merged_ranges, .{});

    var range_i: usize = 0;
    var merged_i: usize = 0;
    var line_start: usize = 0;

    // Step 1 parse ranges
    while (true) {
        const line_end_ = std.mem.findScalar(u8, input[line_start..], '\n');

        if (line_end_ == null) {
            std.log.err("Could not find line ending when parsing input ranges", .{});
            return result;
        }

        const line_end = line_start + line_end_.?;

        if (line_start == line_end) {
            break;
        }

        ranges[range_i] = Range.init(input[line_start..line_end]);
        range_i += 1;
        line_start = line_end + 1;
    }

    // check ids if in a range then valid
    line_start += 1;

    // Check IDs for part 1

    while (line_start < input.len) {
        const line_end_ = std.mem.findScalar(u8, input[line_start..], '\n');

        if (line_end_ == null) {
            break;
        }

        const line_end = line_start + line_end_.?;

        const id = std.fmt.parseInt(u64, input[line_start..line_end], 10) catch {
            std.log.err("ID parse error {s}", .{input[line_start..line_end]});
            break;
        };

        for (0..range_i) |i| {
            if (ranges[i].scalarInRange(id)) {
                result.part_one += 1;
                break;
            }
        }

        line_start = line_end + 1;
    }

    // Part 2
    std.mem.sort(Range, ranges[0..range_i], {}, lessThanRange);

    merged_ranges[0] = ranges[0];
    merged_i += 1;

    for (1..range_i) |i| {
        const current = ranges[i];
        const last_merged = &merged_ranges[merged_i - 1];

        if (current.low <= last_merged.high + 1) {
            if (current.high > last_merged.high) {
                last_merged.high = current.high;
            }
        } else {
            merged_ranges[merged_i] = current;
            merged_i += 1;
        }
    }

    for (0..merged_i) |i| {
        result.part_two += merged_ranges[i].high - merged_ranges[i].low + 1;
    }

    return result;
}

pub fn main() void {
    const day = runDay();

    std.log.info("Day 5 part 1: {d}", .{day.part_one});
    std.log.info("Day 5 part 2: {d}", .{day.part_two});
}
