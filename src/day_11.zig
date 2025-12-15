const std = @import("std");
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

fn runDay(alloc: std.mem.Allocator) !DayResults {
    const input = @embedFile("./inputs/day_eleven_sample.txt");
    const line_count = comptime std.mem.countScalar(u8, input, '\n');

    var servers = try std.ArrayList(Server).initCapacity(alloc, line_count);
    defer servers.deinit(alloc);

    defer for (0..servers.items.len) |i| {
        servers.items[i].deinit(alloc);
    };

    var line_iter = comptime std.mem.tokenizeScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        try servers.append(alloc, try .init(alloc, line));
    }

    for (servers.items) |item| {
        std.log.info("{s}", .{item.name});
        for (item.children) |c| {
            std.log.info("- {s}", .{c});
        }
    }

    return .{ .part_one = 0, .part_two = 0 };
}

pub fn main() !void {
    var allocator = std.heap.DebugAllocator(.{ .verbose_log = false }).init;
    defer std.debug.assert(allocator.deinit() == .ok);

    const day = try runDay(allocator.allocator());
    std.log.info("Day 11 part 1 {}", .{day.part_one});
    std.log.info("Day 11 part 2 {}", .{day.part_two});
}
