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

    pub fn doesContainChild(self: *Server, name: []const u8) bool {
        for (self.children) |str| {
            if (std.mem.eql(u8, name, str)) {
                return true;
            }
        }

        return false;
    }
};

const ChildIter = struct {
    target: []const u8,
    servers: []Server,
    index: usize = 0,

    pub fn init(a: []Server, target: []const u8) ChildIter {
        return .{ .target = target, .servers = a };
    }

    pub fn next(self: *ChildIter) ?[]const u8 {
        if (self.index >= self.servers.len) return null;

        for (self.index + 1..self.servers.len) |i| {
            if (self.servers[i].doesContainChild(self.target)) {
                self.index = i;
                return self.servers[self.index].name;
            }
        }

        return null;
    }

    pub fn reset(self: ChildIter) void {
        self.index = 0;
    }
};

fn getServerByName(list: []Server, name: []const u8) ?*Server {
    for (list) |*s| {
        if (std.mem.eql(u8, s.name, name)) {
            return s;
        }
    }

    return null;
}

fn parseInput(alloc: std.mem.Allocator, input: []const u8) ![]Server {
    const line_count = std.mem.countScalar(u8, input, '\n');

    var servers = try std.ArrayList(Server).initCapacity(alloc, line_count);
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        try servers.append(alloc, try .init(alloc, line));
    }

    return servers.toOwnedSlice(alloc);
}

fn runDay(alloc: std.mem.Allocator) !DayResults {
    const input = @embedFile("./inputs/day_eleven_sample.txt");
    const servers = try parseInput(alloc, input);

    defer for (0..servers.len) |i| {
        servers[i].deinit(alloc);
    };

    var iter = ChildIter.init(servers, "out");

    std.log.info("Ways out:", .{});
    while (iter.next()) |c| {
        std.log.info("{s}", .{c});

        const s = getServerByName(servers, c).?;
        std.log.info("self: {s}", .{s.name});
    }

    return .{ .part_one = 0, .part_two = 0 };
}

pub fn main() !void {
    const TOP_BUF_SIZE = (1 * 1024 * 1024);
    comptime std.debug.assert(config.stack_size >= 1.1 * TOP_BUF_SIZE);

    var top_buf: [TOP_BUF_SIZE]u8 = undefined;

    //var allocator = std.heap.DebugAllocator(.{ .verbose_log = false, }).init;
    //defer std.debug.assert(allocator.deinit() == .ok);
    var allocator = std.heap.FixedBufferAllocator.init(&top_buf);

    const alloc = allocator.allocator();
    const day = try runDay(alloc);

    std.log.info("Day 11 part 1 {}", .{day.part_one});
    std.log.info("Day 11 part 2 {}", .{day.part_two});
}
