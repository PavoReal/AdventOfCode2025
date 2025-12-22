// Advent of Code 2025 - Day 11
// ------------------------------------------
// TODO
//     - [x] Parse input directly into flat list
//     - [ ] Build tree structure
//         - [ ] Find you, build graph of paths
//     - [ ] Count number of paths between you and out nodes, this is part 1
//     - [ ] TBD
//

const std = @import("std");
const config = @import("config");

const DayResults = struct { part_one: u32, part_two: u32 };

const Server = struct {
    name: []const u8 = undefined,
    children: [][]const u8 = undefined,

    pub fn init(alloc: std.mem.Allocator, line: []const u8) !Server {
        const space_count = std.mem.countScalar(u8, line, ' ');

        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        const name = std.mem.trimEnd(u8, iter.next().?, ":");

        var children_slices = try std.ArrayList([]const u8).initCapacity(alloc, space_count);
        errdefer children_slices.deinit(alloc);

        while (iter.next()) |node| {
            try children_slices.append(alloc, node);
        }

        return .{ .name = name, .children = try children_slices.toOwnedSlice(alloc) };
    }

    pub fn deinit(self: *Server, alloc: std.mem.Allocator) void {
        if (self.children.len > 0) alloc.free(self.children);
    }
};

fn parseInput(alloc: std.mem.Allocator, input: []const u8) !std.StringHashMap([][]const u8) {
    var servers = std.StringHashMap([][]const u8).init(alloc);

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const server = try Server.init(alloc, line);
        try servers.put(server.name, server.children);
    }

    return servers;
}
const StackFrame = struct {
    node_name: []const u8,
    child_index: usize = 0,
    paths_sum: u64 = 0,
};

fn runDay(alloc: std.mem.Allocator) !DayResults {
    const input = @embedFile("./inputs/day_eleven.txt");

    const graph = try parseInput(alloc, input);
    var stack = try std.ArrayList(StackFrame).initCapacity(alloc, 128);
    var cache = std.StringHashMap(u64).init(alloc);

    try stack.append(alloc, .{ .child_index = 0, .paths_sum = 0, .node_name = "you" });

    while (stack.items.len > 0) {
        var current_frame = &stack.items[stack.items.len - 1];

        if (current_frame.child_index == 0) {
            if (cache.get(current_frame.node_name)) |val| {
                _ = stack.pop();
                if (stack.items.len > 0) stack.items[stack.items.len - 1].paths_sum += val;
                continue;
            }

            if (std.mem.eql(u8, current_frame.node_name, "out")) {
                _ = stack.pop();
                if (stack.items.len > 0) stack.items[stack.items.len - 1].paths_sum += 1;
                continue;
            }
        }

        const children = graph.get(current_frame.node_name);

        if (children != null and current_frame.child_index < children.?.len) {
            const child_name = children.?[current_frame.child_index];

            current_frame.child_index += 1;

            try stack.append(alloc, .{ .node_name = child_name, .child_index = 0, .paths_sum = 0 });
            continue;
        }

        try cache.put(current_frame.node_name, current_frame.paths_sum);

        const final_result = current_frame.paths_sum;

        _ = stack.pop();

        if (stack.items.len > 0) stack.items[stack.items.len - 1].paths_sum += final_result;
    }

    const pt1 = cache.get("you") orelse 0;

    return .{ .part_one = @intCast(pt1), .part_two = 0 };
}

pub fn main() !void {
    const TOP_BUF_SIZE = (1 * 1024 * 1024);
    comptime std.debug.assert(config.stack_size >= (TOP_BUF_SIZE + (1024 * 1024)));

    var top_buf: [TOP_BUF_SIZE]u8 = undefined;
    var allocator = std.heap.FixedBufferAllocator.init(&top_buf);

    const alloc = allocator.allocator();
    const day = try runDay(alloc);

    std.log.info("Day 11 part 1 {}", .{day.part_one});
    std.log.info("Day 11 part 2 {}", .{day.part_two});
}
