const std = @import("std");
const DayResults = struct { part_one: u64 = 0, part_two: u64 = 0 };

const Machine = struct {
    lights_target: std.ArrayList(bool) = undefined,
    lights: std.ArrayList(bool) = undefined,
    buttons: std.ArrayList([]u8) = undefined,
    joltage: std.ArrayList(u16) = undefined,

    pub fn init(alloc: std.mem.Allocator, line: []const u8) !Machine {
        var result: Machine = .{};
        errdefer result.deinit(alloc);

        var iter = std.mem.tokenizeSequence(u8, line, " ");

        // Parse lights
        const lights_str = iter.next().?;
        const lights_count = lights_str.len - 2;

        result.lights = try std.ArrayList(bool).initCapacity(alloc, lights_count);
        result.lights_target = try std.ArrayList(bool).initCapacity(alloc, lights_count);

        for (lights_str) |c| {
            if (c == '[') continue;
            if (c == ']') break;

            if (c == '#') {
                try result.lights_target.append(alloc, true);
            } else {
                try result.lights_target.append(alloc, false);
            }

            try result.lights.append(alloc, false);
        }

        // Parse buttons
        result.buttons = try std.ArrayList([]u8).initCapacity(alloc, 12);

        var btn_str = iter.next().?;
        while (btn_str[0] != '{') {
            const trimmed = std.mem.trim(u8, btn_str, "()");

            var tmp_nums = try std.ArrayList(u8).initCapacity(alloc, 12);
            errdefer tmp_nums.deinit(alloc);

            var digit_iter = std.mem.tokenizeScalar(u8, trimmed, ',');
            while (digit_iter.next()) |str| {
                const val = try std.fmt.parseInt(u8, str, 10);
                try tmp_nums.append(alloc, val);
            }

            try result.buttons.append(alloc, try tmp_nums.toOwnedSlice(alloc));
            btn_str = iter.next().?;
        }

        // Parse joltage
        const trimmed = std.mem.trim(u8, std.mem.trim(u8, btn_str, "\r\n"), "{}");
        result.joltage = try std.ArrayList(u16).initCapacity(alloc, trimmed.len);

        var digit_iter = std.mem.tokenizeScalar(u8, trimmed, ',');
        while (digit_iter.next()) |str| {
            const val = try std.fmt.parseInt(u16, str, 10);
            try result.joltage.append(alloc, val);
        }

        return result;
    }

    pub fn deinit(self: *Machine, alloc: std.mem.Allocator) void {
        if (self.lights.capacity > 0) self.lights.deinit(alloc);
        if (self.lights_target.capacity > 0) self.lights_target.deinit(alloc);

        for (0..self.buttons.items.len) |i| {
            alloc.free(self.buttons.items[i]);
        }

        if (self.buttons.capacity > 0) self.buttons.deinit(alloc);
        if (self.joltage.capacity > 0) self.joltage.deinit(alloc);
    }

    pub fn calcMinBtnSeqOwned(self: *Machine, alloc: std.mem.Allocator) ![]u32 {
        _ = self;
        var result_seq = try std.ArrayList(u32).initCapacity(alloc, 10);

        return try result_seq.toOwnedSlice(alloc);
    }
};

fn runDay(alloc: std.mem.Allocator, input: []const u8) !DayResults {
    var result: DayResults = .{};
    const machine_count = std.mem.countScalar(u8, input, '\n');

    var machines = try std.ArrayList(Machine).initCapacity(alloc, machine_count);
    defer machines.deinit(alloc);

    defer for (0..machines.items.len) |i| {
        machines.items[i].deinit(alloc);
    };

    // Parse all machines
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        try machines.append(alloc, try Machine.init(alloc, line));
    }

    for (0..machines.items.len) |i| {
        const seq = try machines.items[i].calcMinBtnSeqOwned(alloc);
        defer alloc.free(seq);

        result.part_one += seq.len;
    }

    return result;
}

pub fn main() !void {
    const input = @embedFile("inputs/day_ten.txt");

    var allocator = std.heap.DebugAllocator(.{ .verbose_log = false }){};
    //var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = allocator.deinit();

    const alloc = allocator.allocator();
    const day = try runDay(alloc, input);

    std.log.info("Day 10 part 1 {}", .{day.part_one});
    std.log.info("Day 10 part 2 {}", .{day.part_two});
}
