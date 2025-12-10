const std = @import("std");

const DayResults = struct { part_one: u64 = 0, part_two: u64 = 0 };

const Point = struct {
    x: u64 = 0,
    y: u64 = 0,

    pub fn init(line: []const u8) !Point {
        var iter = std.mem.tokenizeScalar(u8, line, ',');

        const x_digits = iter.next().?;
        const x = try std.fmt.parseInt(u64, x_digits, 10);

        const y_digits = iter.next().?;
        const y = try std.fmt.parseInt(u64, y_digits, 10);

        return .{ .x = x, .y = y };
    }
};

const Grid = struct {
    grid_width: u64 = 0,
    grid_height: u64 = 0,

    min_x: u64 = std.math.maxInt(u64),
    max_x: u64 = 0,
    min_y: u64 = std.math.maxInt(u64),
    max_y: u64 = 0,

    grid: []bool = undefined,

    prefix_sum: []u64 = undefined,

    pub fn init(alloc: std.mem.Allocator, points: []Point) !Grid {
        var result: Grid = .{};

        for (points) |p| {
            result.max_x = @max(result.max_x, p.x);
            result.max_y = @max(result.max_y, p.y);
            result.min_x = @min(result.min_x, p.x);
            result.min_y = @min(result.min_y, p.y);
        }

        result.grid_width = result.max_x - result.min_x + 1;
        result.grid_height = result.max_y - result.min_y + 1;

        result.grid = try alloc.alloc(bool, result.grid_width * result.grid_height);
        @memset(result.grid, false);

        return result;
    }

    pub fn deinit(self: *Grid, alloc: std.mem.Allocator) void {
        alloc.free(self.grid);
        if (self.prefix_sum.len > 0) alloc.free(self.prefix_sum);
    }

    pub fn set(self: *Grid, p: Point, val: bool) void {
        const index: usize = ((p.y - self.min_y) * self.grid_width) + (p.x - self.min_x);
        self.grid[index] = val;
    }

    pub fn get(self: *Grid, p: Point) bool {
        const index: usize = ((p.y - self.min_y) * self.grid_width) + (p.x - self.min_x);
        return self.grid[index];
    }

    pub fn setLine(self: *Grid, a: Point, b: Point, val: bool) void {
        var x0 = a.x;
        var y0 = a.y;
        const x1 = b.x;
        const y1 = b.y;

        const dx_u = if (x1 > x0) x1 - x0 else x0 - x1;
        const dy_u = if (y1 > y0) y1 - y0 else y0 - y1;

        const dx = @as(i64, @intCast(dx_u));
        const dy = -@as(i64, @intCast(dy_u));

        const sx: i2 = if (x0 < x1) 1 else -1;
        const sy: i2 = if (y0 < y1) 1 else -1;

        var err = dx + dy;

        while (true) {
            self.set(.{ .x = x0, .y = y0 }, val);

            if (x0 == x1 and y0 == y1) break;

            const e2 = 2 * err;

            if (e2 >= dy) {
                if (x0 == x1) break;
                err += dy;

                if (sx == 1) x0 += 1 else x0 -= 1;
            }

            if (e2 <= dx) {
                if (y0 == y1) break;
                err += dx;

                if (sy == 1) y0 += 1 else y0 -= 1;
            }
        }
    }

    fn checkAndPush(self: *Grid, alloc: std.mem.Allocator, x: u64, y: u64, stack: *std.ArrayList(Point), outside: *std.bit_set.DynamicBitSet) !void {
        const index = (y * self.grid_width) + x;

        if (self.grid[index] or outside.isSet(index)) return;

        outside.set(index);
        try stack.append(alloc, .{ .x = x, .y = y });
    }

    pub fn floodFill(self: *Grid, alloc: std.mem.Allocator) !void {
        var outside = try std.bit_set.DynamicBitSet.initEmpty(alloc, self.grid.len);
        defer outside.deinit();

        var stack = try std.ArrayList(Point).initCapacity(alloc, 400000);
        defer stack.deinit(alloc);

        const w = self.grid_width;
        const h = self.grid_height;

        for (0..w) |x| {
            try self.checkAndPush(alloc, x, 0, &stack, &outside);
            try self.checkAndPush(alloc, x, h - 1, &stack, &outside);
        }

        for (0..h) |y| {
            try self.checkAndPush(alloc, 0, y, &stack, &outside);
            try self.checkAndPush(alloc, w - 1, y, &stack, &outside);
        }

        while (stack.pop()) |p| {
            const x = p.x;
            const y = p.y;

            if (x > 0) try self.checkAndPush(alloc, x - 1, y, &stack, &outside);
            if (x < w - 1) try self.checkAndPush(alloc, x + 1, y, &stack, &outside);
            if (y > 0) try self.checkAndPush(alloc, x, y - 1, &stack, &outside);
            if (y < h - 1) try self.checkAndPush(alloc, x, y + 1, &stack, &outside);
        }

        var it = outside.iterator(.{ .kind = .unset });
        while (it.next()) |i| {
            if (!self.grid[i]) {
                self.grid[i] = true;
            }
        }
    }
    pub fn buildPrefixSum(self: *Grid, alloc: std.mem.Allocator) !void {
        const w = self.grid_width;
        const h = self.grid_height;

        self.prefix_sum = try alloc.alloc(u64, (w + 1) * (h + 1));
        @memset(self.prefix_sum, 0);

        for (0..h) |y| {
            for (0..w) |x| {
                const val: u64 = if (self.grid[y * w + x]) 1 else 0;

                const left = self.prefix_sum[(y + 1) * (w + 1) + x];
                const top = self.prefix_sum[y * (w + 1) + (x + 1)];
                const top_left = self.prefix_sum[y * (w + 1) + x];

                self.prefix_sum[(y + 1) * (w + 1) + (x + 1)] = val + left + top - top_left;
            }
        }
    }

    pub fn isRectValid(self: *Grid, min_p: Point, max_p: Point) bool {
        const x1 = min_p.x - self.min_x;
        const y1 = min_p.y - self.min_y;
        const x2 = max_p.x - self.min_x;
        const y2 = max_p.y - self.min_y;

        const p_w = self.grid_width + 1;

        const D = self.prefix_sum[(y2 + 1) * p_w + (x2 + 1)];
        const B = self.prefix_sum[(y1) * p_w + (x2 + 1)];
        const C = self.prefix_sum[(y2 + 1) * p_w + (x1)];
        const A = self.prefix_sum[(y1) * p_w + (x1)];

        const sum = (D - B) - (C - A);

        const area = (x2 - x1 + 1) * (y2 - y1 + 1);

        return sum == area;
    }
};

fn isRectValid(valid: *[]const bool, grid: *const Grid, min_x: u64, max_x: u64, min_y: u64, max_y: u64) void {
    valid = true;
    for (min_x..max_x + 1) |x| {
        for (min_y..max_y + 1) |y| {
            if (!grid.get(.{ .x = x, .y = y })) {
                valid = false;
                break;
            }
        }

        if (!valid) break;
    }
}

fn runDay(alloc: std.mem.Allocator) !DayResults {
    @setEvalBranchQuota(1000000);

    const input = @embedFile("./inputs/day_nine.txt");
    const input_num_lines = comptime std.mem.countScalar(u8, input, '\n');
    var line_iter = comptime std.mem.tokenizeScalar(u8, input, '\n');

    var points_buffer: [input_num_lines]Point = undefined;
    @memset(&points_buffer, .{});

    var points = std.ArrayList(Point).initBuffer(&points_buffer);
    while (line_iter.next()) |line| {
        points.appendAssumeCapacity(try Point.init(line));
    }

    // Part 1 - Brute force all rects, save largest area
    var max_area: u64 = 0;
    for (points.items, 0..) |p1, i| {
        for (i + 1..points.items.len) |j| {
            const p2 = &points.items[j];

            const dx = @abs(@as(i64, @intCast(p2.x)) - @as(i64, @intCast(p1.x))) + 1;
            const dy = @abs(@as(i64, @intCast(p2.y)) - @as(i64, @intCast(p1.y))) + 1;

            const area = dx * dy;
            max_area = @max(area, max_area);
        }
    }

    std.log.info("Part 1 done", .{});

    // Part 2
    var grid = try Grid.init(alloc, points.items);
    defer grid.deinit(alloc);

    var i: usize = 0;
    while (i < points.items.len - 1) : (i += 1) {
        const a = points.items[i];
        const b = points.items[i + 1];

        grid.setLine(a, b, true);
    }
    grid.setLine(points.items[0], points.items[points.items.len - 1], true);

    std.log.debug("Borders created", .{});

    std.log.debug("Starting flood", .{});
    try grid.floodFill(alloc);

    std.log.debug("Building prefix sum", .{});
    try grid.buildPrefixSum(alloc);

    std.log.debug("Searching for max rect", .{});

    var pt2_area: u64 = 0;
    for (points.items, 0..) |a, ai| {
        for (ai + 1..points.items.len) |j| {
            const b = &points.items[j];

            const min_x = @min(a.x, b.x);
            const max_x = @max(a.x, b.x);
            const min_y = @min(a.y, b.y);
            const max_y = @max(a.y, b.y);

            if (grid.isRectValid(.{ .x = min_x, .y = min_y }, .{ .x = max_x, .y = max_y })) {
                const dx = max_x - min_x + 1;
                const dy = max_y - min_y + 1;
                pt2_area = @max(pt2_area, dx * dy);
            }
        }
    }

    return .{ .part_one = max_area, .part_two = pt2_area };
}

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const alloc = allocator.allocator();
    const results = try runDay(alloc);

    std.log.info("Day 9 part 1 {}", .{results.part_one});
    std.log.info("Day 9 part 2 {}", .{results.part_two});
}
