const std = @import("std");
const DayResults = struct { part_one: u64 = 0, part_two: u64 = 0 };

fn BitMatrixGF2() type {
    return struct {
        const Self = @This();

        pub const Error = error{
            DimensionMismatch,
            OutOfBounds,
        };

        rows: usize,
        cols: usize,
        stride_words: usize,
        items: []u64,

        pub fn init(alloc: std.mem.Allocator, rows: usize, cols: usize) !Self {
            const stride_words = (cols + 63) / 64;
            const count = try std.math.mul(usize, rows, stride_words);

            const buf = try alloc.alloc(u64, count);
            @memset(buf, 0);

            return .{
                .rows = rows,
                .cols = cols,
                .stride_words = stride_words,
                .items = buf,
            };
        }

        pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
            alloc.free(self.items);
            self.rows = 0;
            self.cols = 0;
            self.stride_words = 0;
            self.items = @constCast(&[_]u64{}); // harmless empty slice
        }

        inline fn base(self: Self, r: usize) usize {
            return r * self.stride_words;
        }

        inline fn wordOf(c: usize) usize {
            return c >> 6; // /64
        }

        inline fn shiftOf(c: usize) u6 {
            return @intCast(c & 63);
        }

        inline fn maskOf(c: usize) u64 {
            return (@as(u64, 1) << shiftOf(c));
        }

        pub fn rowSlice(self: Self, r: usize) []u64 {
            std.debug.assert(r < self.rows);
            const start = self.base(r);
            return self.items[start .. start + self.stride_words];
        }

        pub fn get(self: Self, r: usize, c: usize) u1 {
            std.debug.assert(r < self.rows and c < self.cols);
            const idx = self.base(r) + wordOf(c);
            return @intFromBool((self.items[idx] & maskOf(c)) != 0);
        }

        pub fn set(self: *Self, r: usize, c: usize, value: u1) void {
            std.debug.assert(r < self.rows and c < self.cols);
            const idx = self.base(r) + wordOf(c);
            const m = maskOf(c);

            if (value == 1) {
                self.items[idx] |= m;
            } else {
                self.items[idx] &= ~m;
            }
        }

        pub fn toggle(self: *Self, r: usize, c: usize) void {
            std.debug.assert(r < self.rows and c < self.cols);
            const idx = self.base(r) + wordOf(c);
            self.items[idx] ^= maskOf(c);
        }

        /// dst_row ^= src_row
        pub fn xorRowInto(self: *Self, dst_row: usize, src_row: usize) void {
            std.debug.assert(dst_row < self.rows and src_row < self.rows);
            const dst = self.base(dst_row);
            const src = self.base(src_row);

            for (0..self.stride_words) |w| {
                self.items[dst + w] ^= self.items[src + w];
            }
        }

        pub fn swapRows(self: *Self, a: usize, b: usize) void {
            std.debug.assert(a < self.rows and b < self.rows);
            if (a == b) return;

            const ab = self.base(a);
            const bb = self.base(b);

            for (0..self.stride_words) |w| {
                std.mem.swap(u64, &self.items[ab + w], &self.items[bb + w]);
            }
        }

        pub fn clear(self: *Self) void {
            @memset(self.items, 0);
        }
    };
}

fn MatrixMxN(comptime T: type) type {
    return struct {
        const Self = @This();

        rows: usize,
        cols: usize,
        items: []T,

        pub fn init(alloc: std.mem.Allocator, rows: usize, cols: usize) !Self {
            const count = try std.math.mul(usize, rows, cols);
            const buf = try alloc.alloc(T, count);
            @memset(buf, 0);

            return .{ .rows = rows, .cols = cols, .items = buf };
        }

        pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
            alloc.free(self.items);
            self.rows = 0;
            self.cols = 0;
        }

        inline fn index(self: Self, r: usize, c: usize) usize {
            return r * self.cols + c;
        }

        pub fn get(self: Self, r: usize, c: usize) T {
            return self.items[self.index(r, c)];
        }

        pub fn set(self: *Self, r: usize, c: usize, value: T) void {
            self.items[self.index(r, c)] = value;
        }

        pub fn mulVecOwned(self: Self, alloc: std.mem.Allocator, v: []T) ![](T) {
            if (v.items.len != self.cols) return error.DimensionMismatch;

            var out = try alloc.alloc(T, self.rows);

            for (0..self.rows) |r| {
                var acc: T = std.mem.zeroes(T);

                for (0..self.cols) |c| {
                    acc += self.get(r, c) * v.items[c];
                }
                out[r] = acc;
            }

            return out;
        }

        pub fn mulVecInto(self: Self, v: []const T, out: []T) !void {
            if (v.len != self.cols or out.len != self.rows) return error.DimensionMismatch;

            for (0..self.rows) |r| {
                var acc: T = std.mem.zeroes(T);
                for (0..self.cols) |c| {
                    acc += self.get(r, c) * v[c];
                }
                out[r] = acc;
            }
        }
    };
}

const Machine = struct {
    b: []u8 = undefined,
    a: [][]u8 = undefined,
    joltage: []u16 = undefined,

    pub fn init(alloc: std.mem.Allocator, line: []const u8) !Machine {
        var result: Machine = .{};
        errdefer result.deinit(alloc);

        var iter = std.mem.tokenizeSequence(u8, line, " ");

        // Parse and build b
        const lights_str = iter.next().?;
        const lights_count = lights_str.len - 2;
        var tmp = try std.ArrayList(u8).initCapacity(alloc, lights_count);

        for (lights_str) |c| {
            if (c == '[') continue;
            if (c == ']') break;

            if (c == '#') {
                try tmp.append(alloc, 1);
            } else {
                try tmp.append(alloc, 0);
            }
        }

        result.b = try tmp.toOwnedSlice(alloc);

        // Parse build a
        var tmp2 = try std.ArrayList([]u8).initCapacity(alloc, 12);

        var btn_str = iter.next().?;
        while (btn_str[0] != '{') {
            const trimmed = std.mem.trim(u8, btn_str, "()");

            var tmp_nums = try std.ArrayList(u8).initCapacity(alloc, 12);
            var digit_iter = std.mem.tokenizeScalar(u8, trimmed, ',');

            while (digit_iter.next()) |str| {
                const val = try std.fmt.parseInt(u8, str, 10);
                try tmp_nums.append(alloc, val);
            }

            try tmp2.append(alloc, try tmp_nums.toOwnedSlice(alloc));
            btn_str = iter.next().?;
        }

        result.a = try tmp2.toOwnedSlice(alloc);

        // Parse joltage
        const trimmed = std.mem.trim(u8, std.mem.trim(u8, btn_str, "\r\n"), "{}");
        var joltage = try std.ArrayList(u16).initCapacity(alloc, trimmed.len);

        var digit_iter = std.mem.tokenizeScalar(u8, trimmed, ',');
        while (digit_iter.next()) |str| {
            const val = try std.fmt.parseInt(u16, str, 10);
            try joltage.append(alloc, val);
        }

        result.joltage = try joltage.toOwnedSlice(alloc);

        return result;
    }

    pub fn deinit(self: *Machine, alloc: std.mem.Allocator) void {
        if (self.b.len > 0) alloc.free(self.b);

        for (0..self.a.len) |i| {
            if (self.a.ptr[i].len > 0) alloc.free(self.a.ptr[i]);
        }
        if (self.a.len > 0) alloc.free(self.a);

        if (self.joltage.len > 0) alloc.free(self.joltage);
    }

    pub fn calcMinBtnSeqOwned(self: *Machine, alloc: std.mem.Allocator) ![]u32 {
        const BitMat = BitMatrixGF2();

        const n_lights = self.b.len;
        const n_btns = self.a.len;
        const b_col = n_btns;

        var result_seq = try std.ArrayList(u32).initCapacity(alloc, n_btns);

        var aug = try BitMat.init(alloc, n_lights, n_btns + 1);
        defer aug.deinit(alloc);

        // Fill A (button columns)
        for (self.a, 0..) |btn_lights, c| {
            for (btn_lights) |light_u8| {
                const r: usize = @intCast(light_u8);
                std.debug.assert(r < n_lights);
                aug.toggle(r, c);
            }
        }

        // Fill b (augmented column)
        for (self.b, 0..) |bit, r| {
            if ((bit & 1) == 1) aug.set(r, b_col, 1);
        }

        const max_pivots = @min(n_lights, n_btns);
        var pivot_cols = try alloc.alloc(usize, max_pivots);
        defer alloc.free(pivot_cols);
        var pivot_count: usize = 0;
        var pivot_row: usize = 0;

        // Forward elimination to row echelon form
        for (0..n_btns) |col| {
            var r = pivot_row;
            while (r < n_lights and aug.get(r, col) == 0) : (r += 1) {}
            if (r == n_lights) continue;

            aug.swapRows(pivot_row, r);
            pivot_cols[pivot_count] = col;
            pivot_count += 1;

            var rr = pivot_row + 1;
            while (rr < n_lights) : (rr += 1) {
                if (aug.get(rr, col) == 1) {
                    aug.xorRowInto(rr, pivot_row);
                }
            }

            pivot_row += 1;
            if (pivot_row == n_lights) break;
        }

        // Check for inconsistency: 0 = 1 rows.
        for (pivot_count..n_lights) |r| {
            var any_one = false;
            for (0..n_btns) |c| {
                if (aug.get(r, c) == 1) {
                    any_one = true;
                    break;
                }
            }
            if (!any_one and aug.get(r, b_col) == 1) {
                return error.NoSolution;
            }
        }

        // Backward elimination to reduced row echelon form.
        var i = pivot_count;
        while (i > 0) {
            i -= 1;
            const col = pivot_cols[i];
            var r2: usize = 0;
            while (r2 < i) : (r2 += 1) {
                if (aug.get(r2, col) == 1) {
                    aug.xorRowInto(r2, i);
                }
            }
        }

        var is_pivot = try alloc.alloc(bool, n_btns);
        defer alloc.free(is_pivot);
        @memset(is_pivot, false);
        for (pivot_cols[0..pivot_count]) |c| {
            is_pivot[c] = true;
        }

        const free_count = n_btns - pivot_count;
        var free_cols = try alloc.alloc(usize, free_count);
        defer alloc.free(free_cols);
        var free_idx: usize = 0;
        for (0..n_btns) |c| {
            if (!is_pivot[c]) {
                free_cols[free_idx] = c;
                free_idx += 1;
            }
        }

        const sol_words = (n_btns + 63) / 64;
        var particular = try alloc.alloc(u64, sol_words);
        defer alloc.free(particular);
        @memset(particular, 0);
        for (0..pivot_count) |r| {
            const pc = pivot_cols[r];
            if (aug.get(r, b_col) == 1) {
                particular[pc >> 6] |= (@as(u64, 1) << @intCast(pc & 63));
            }
        }

        var basis = try alloc.alloc(u64, free_count * sol_words);
        defer alloc.free(basis);
        @memset(basis, 0);
        for (free_cols, 0..) |fc, j| {
            const off = j * sol_words;
            basis[off + (fc >> 6)] |= (@as(u64, 1) << @intCast(fc & 63));
            for (0..pivot_count) |r| {
                const pc = pivot_cols[r];
                if (aug.get(r, fc) == 1) {
                    basis[off + (pc >> 6)] |= (@as(u64, 1) << @intCast(pc & 63));
                }
            }
        }

        const popcountWords = struct {
            fn count(words: []const u64, bits: usize) usize {
                var total: usize = 0;
                if (words.len == 0) return 0;
                const full_words = bits / 64;
                for (0..full_words) |w| {
                    total += @popCount(words[w]);
                }
                const rem = bits & 63;
                if (rem != 0) {
                    const mask: u64 = (@as(u64, 1) << @intCast(rem)) - 1;
                    total += @popCount(words[full_words] & mask);
                }
                return total;
            }
        };

        var best_words = try alloc.alloc(u64, sol_words);
        defer alloc.free(best_words);
        std.mem.copyForwards(u64, best_words, particular);
        var best_weight = popcountWords.count(best_words, n_btns);

        if (free_count > 0) {
            if (free_count > 63) {
                return error.TooManyFreeVariables;
            }
            const combos: u64 = @as(u64, 1) << @intCast(free_count);
            var mask_val: u64 = 1;
            var tmp_words = try alloc.alloc(u64, sol_words);
            defer alloc.free(tmp_words);

            while (mask_val < combos) : (mask_val += 1) {
                std.mem.copyForwards(u64, tmp_words, particular);
                var tmask = mask_val;
                var j: usize = 0;
                while (tmask != 0) : (j += 1) {
                    if ((tmask & 1) != 0) {
                        const off = j * sol_words;
                        for (0..sol_words) |w| {
                            tmp_words[w] ^= basis[off + w];
                        }
                    }
                    tmask >>= 1;
                }

                const weight = popcountWords.count(tmp_words, n_btns);
                if (weight < best_weight) {
                    best_weight = weight;
                    std.mem.copyForwards(u64, best_words, tmp_words);
                }
            }
        }

        for (0..n_btns) |c| {
            const w = c >> 6;
            const bit: u64 = (@as(u64, 1) << @intCast(c & 63));
            if ((best_words[w] & bit) != 0) {
                try result_seq.append(alloc, @intCast(c));
            }
        }

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
