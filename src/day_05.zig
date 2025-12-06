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

    pub fn scalarInRange(self: *Range, a: u64) bool {
        return (a <= self.high) and (a >= self.low);
    }
};

const DayFive = struct {
    part_one: u32 = 0,
    part_two: u32 = 0,
};

fn runDay() DayFive {
    const input = @embedFile("./inputs/day_five_sample.txt");
    const range_count_upper_bound = comptime std.mem.countScalar(u8, input, '\n');

    var ranges: [range_count_upper_bound]Range = undefined;
    @memset(&ranges, .{});
    var range_i: usize = 0;

    var done_parsing_ranges = false;

    while (!done_parsing_ranges) {
        // Parse ranges
        var line_start: usize = 0;
        const line_end_ = std.mem.findScalar(u8, input[line_start..], '\n');

        if (line_end_ == null) {
            @panic("Could not find line ending when parsing input ranges");
        }

        const line_end = line_end_.?;

        if (line_start == line_end) {
            done_parsing_ranges = true;
            break;
        }

        ranges[range_i] = Range.init(input[line_start..line_end]);
        range_i += 1;

        line_start = line_end + 1;
    }

    std.log.info("Found {} ranges", .{range_i});

    // check ids if in a range then valid

    return .{};
}

pub fn main() void {
    const day = runDay();

    std.log.info("Day 5 part 1: {d}", .{day.part_one});
    std.log.info("Day 5 part 2: {d}", .{day.part_two});
}
