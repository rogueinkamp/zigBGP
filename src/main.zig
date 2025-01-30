const std = @import("std");
const yaml = @import("yaml");
const net = std.net;
const posix = std.posix;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const stdout = std.io.getStdOut().writer();

    // Initialization
    try stdout.print("Starting BGP daemon...\n", .{});
    var bgp_daemon = try BgpDaemon.init(&gpa);
    defer bgp_daemon.deinit();

    // Main loop
    try stdout.print("Entering main loop...\n", .{});
    try bgp_daemon.load_config();
    while (true) {
        try bgp_daemon.run();
        std.time.sleep(10 * std.time.ns_per_s);
        // std.time.sleep(std.time.ns_per_s / 1000000); // Sleep for 100ms to avoid busy-looping
    }
}

const BgpDaemon = struct {
    allocator: std.mem.Allocator,

    pub fn init(gpa: *std.heap.GeneralPurposeAllocator(.{})) !BgpDaemon {
        return BgpDaemon{
            .allocator = gpa.allocator(),
        };
    }

    pub fn deinit(_: *BgpDaemon) void {
        // Clean up resources here if needed
    }
    pub fn load_config(_: *BgpDaemon) !void {
        // Load config from file
        var cwd = std.fs.cwd();
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        defer _ = gpa.deinit();
        // Print the current working directory
        const cwd_path = try cwd.realpathAlloc(allocator, ".");
        defer allocator.free(cwd_path);
        std.debug.print("Current working directory: {s}\n", .{cwd_path});
        const cfg_file = try cwd.openFile("config.yaml", .{ .mode = .read_only });
        // const cfg_file = try cwd.openFile("config.yaml", .{ .read = true });
        defer cfg_file.close();
        const file_content = try cfg_file.readToEndAlloc(allocator, std.math.maxInt(usize));
        defer allocator.free(file_content);
        var parsed_yaml = try yaml.Yaml.load(allocator, file_content);
        defer parsed_yaml.deinit();
        if (parsed_yaml.docs.items.len > 0) {
            const map = parsed_yaml.docs.items[0].map;
            if (map.get("bgp")) |value| {
                switch (value) {
                    .map => |bgp_map| {
                        if (bgp_map.get("as")) |as_value| {
                            switch (as_value) {
                                .string => |str| {
                                    std.debug.print("The value of 'as' is: {s}\n", .{str});
                                },
                                .int => |int| {
                                    std.debug.print("The value of 'as' is: {}\n", .{int});
                                },
                                else => {
                                    std.debug.print("The value of 'as' is of an unsupported type, type: {s}\n", .{@typeName(@TypeOf(as_value))});
                                },
                            }
                        } else {
                            std.debug.print("'as' not found in config\n", .{});
                        }
                    },
                    else => {
                        std.debug.print("'bgp' does not contain the expected structure\n", .{});
                    },
                }
            } else {
                std.debug.print("'bgp' header not found in the YAML\n", .{});
            }
        }
    }

    pub fn listen_for_neighbors(_: *BgpDaemon) !void {
        const address = try std.net.Address.parseIp("127.0.0.1", 5882);
        const tpe: u32 = posix.SOCK.STREAM;
        const protocol = posix.IPPROTO.TCP;
        const listener = try posix.socket(address.any.family, tpe, protocol);
        defer posix.close(listener);
    }

    pub fn run(self: *BgpDaemon) !void {
        // Main BGP processing happens here
        // 1. Handle incoming connections or messages.
        // 2. Send keepalives, updates, or notifications as needed.
        // 3. Update routing table or state.

        // Simulated task processing
        try std.io.getStdOut().writer().print("Processing BGP tasks...\n", .{});
        try self.listen_for_neighbors();
    }
};
