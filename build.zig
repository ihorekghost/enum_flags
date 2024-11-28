const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("enum_flags", .{ .root_source_file = b.path("src/enum_flags.zig") });

    const test_step = b.step("test", "Run enum_flags test");

    const enum_flags_test = b.addTest(.{ .root_source_file = b.path("src/enum_flags.zig") });
    const run_enum_flags_test = b.addRunArtifact(enum_flags_test);

    test_step.dependOn(&run_enum_flags_test.step);
}
