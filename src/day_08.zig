const std = @import("std");

const DayResults = struct { part_one: u64 = 0, part_two: u64 = 0 };

const JunctionBox = struct {
    x: u64 = 0,
    y: u64 = 0,
    z: u64 = 0,

    pub fn init(line: []const u8) !JunctionBox {
        var coord_iter = std.mem.tokenizeScalar(u8, line, ',');

        const x_line = coord_iter.next().?;
        const x_value = try std.fmt.parseInt(u64, x_line, 10);

        const y_line = coord_iter.next().?;
        const y_value = try std.fmt.parseInt(u64, y_line, 10);

        const z_line = coord_iter.next().?;
        const z_value = try std.fmt.parseInt(u64, z_line, 10);

        return .{ .x = x_value, .y = y_value, .z = z_value };
    }

    pub fn squaredDistance(self: *const JunctionBox, other: *const JunctionBox) u64 {
        const x_diff = @abs(@as(i64, @intCast(other.x)) - @as(i64, @intCast(self.x)));
        const y_diff = @abs(@as(i64, @intCast(other.y)) - @as(i64, @intCast(self.y)));
        const z_diff = @abs(@as(i64, @intCast(other.z)) - @as(i64, @intCast(self.z)));

        return (x_diff * x_diff) + (y_diff * y_diff) + (z_diff * z_diff);
    }

    pub fn find(p: []usize, i: usize) usize {
        var root = i;

        while (root != p[root]) {
            root = p[root];
        }

        var curr = i;
        while (curr != root) {
            const next = p[curr];
            p[curr] = root;
            curr = next;
        }

        return root;
    }
};

const Connection = struct { a: usize = 0, b: usize = 0, dis: u64 = std.math.maxInt(u64) };

fn connectionLessThan(context: void, lhs: Connection, rhs: Connection) bool {
    _ = context;
    return lhs.dis < rhs.dis;
}

fn runDay() !DayResults {
    @setEvalBranchQuota(1000000);
    var results: DayResults = .{};

    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const alloc = allocator.allocator();

    const input = @embedFile("./inputs/day_eight.txt");
    const number_to_connect = 1000; // Sample 10, real 1000

    const input_line_count = comptime std.mem.countScalar(u8, input, '\n');
    var line_iter = comptime std.mem.tokenizeScalar(u8, input, '\n');

    // Parse coords
    var boxes = try std.ArrayList(JunctionBox).initCapacity(alloc, input_line_count);
    defer boxes.deinit(alloc);

    while (line_iter.next()) |line| {
        if (line.len == 0) continue;
        try boxes.append(alloc, try JunctionBox.init(line));
    }

    var connections = try std.ArrayList(Connection).initCapacity(alloc, input_line_count * input_line_count);
    defer connections.deinit(alloc);

    // Calc all possible connections
    for (0..boxes.items.len) |i| {
        const a = boxes.items[i];

        for (i + 1..boxes.items.len) |j| {
            if (i == j) continue;

            const b = &boxes.items[j];
            const dis = a.squaredDistance(b);

            try connections.append(alloc, .{ .a = i, .b = j, .dis = dis });
        }
    }

    std.sort.block(Connection, connections.items, {}, connectionLessThan);

    // Build our network
    var parent: []usize = try alloc.alloc(usize, boxes.items.len);
    var size: []u64 = try alloc.alloc(u64, boxes.items.len);

    for (0..parent.len) |i| {
        parent[i] = i;
        size[i] = 1;
    }

    for (connections.items[0..number_to_connect]) |conn| {
        const rootA = JunctionBox.find(parent, conn.a);
        const rootB = JunctionBox.find(parent, conn.b);

        if (rootA != rootB) {
            if (size[rootA] < size[rootB]) {
                parent[rootA] = rootB;
                size[rootB] += size[rootA];
            } else {
                parent[rootB] = rootA;
                size[rootA] += size[rootB];
            }
        }
    }

    var final_sizes = try std.ArrayList(u64).initCapacity(alloc, boxes.items.len);
    defer final_sizes.deinit(alloc);

    for (0..boxes.items.len) |i| {
        if (parent[i] == i) {
            try final_sizes.append(alloc, size[i]);
        }
    }

    std.sort.block(u64, final_sizes.items, {}, std.sort.desc(u64));

    results.part_one = 1;

    for (0..3) |i| {
        results.part_one *= final_sizes.items[i];
    }

    return results;
}

pub fn main() !void {
    const day = try runDay();

    std.log.info("Day 8 part 1 {}", .{day.part_one});
    std.log.info("Day 8 part 2 {}", .{day.part_two});
}
