const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("enum_flags", .{ .root_source_file = b.path("src/enum_flags.zig") });
}