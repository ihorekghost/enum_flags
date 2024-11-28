const std = @import("std");

pub fn EnumFlags(comptime Flag: type) type {
    const enum_info = @typeInfo(Flag).@"enum";

    return packed struct {
        const bit_length = @typeInfo(enum_info.tag_type).int.bits;

        bits: enum_info.tag_type,

        ///Flags with no flags enabled.
        pub fn none() @This() {
            return .{ .bits = 0 };
        }

        pub fn many(flags_slice: []Flag) @This() {
            var flags = @This().none();

            for (flags_slice) |flag| {
                flags.enable(flag);
            }

            return flags;
        }

        ///Flags with all flags enabled.
        pub fn all() @This() {
            return .{ .bits = ~0 };
        }

        ///Flags with only one flag enabled.
        pub fn one(flag: Flag) @This() {
            return .{ .bits = @intFromEnum(flag) };
        }

        ///Check if `flag` is set.
        pub fn isSet(flags: @This(), flag: Flag) bool {
            return (flags.bits & @intFromEnum(flag)) == @intFromEnum(flag);
        }

        ///Enable `flag` if `value` is `true`, disable otherwise.
        pub fn set(flags: @This(), flag: Flag, value: bool) @This() {
            return .{ .bits = (flags.bits & ~@intFromEnum(flag)) | (@intFromEnum(flag) & std.math.boolMask(enum_info.tag_type, value)) };
        }

        ///Enable a flag. Enables bits corresponding to `flag` **one** bits.
        pub fn enable(flags: @This(), flag: Flag) @This() {
            return .{ .bits = flags.bits | @intFromEnum(flag) };
        }

        ///Disable (zero) a flag. Disables bits corresponding to `flag` **zero** bits.
        pub fn disable(flags: @This(), flag: Flag) @This() {
            return .{ .bits = flags.bits & ~@intFromEnum(flag) };
        }

        ///Bitwise **or**.
        pub fn @"or"(flags: @This(), other: @This()) @This() {
            return .{ .bits = flags.bits | other.bits };
        }

        ///Bitwise **and**.
        pub fn @"and"(flags: @This(), other: @This()) @This() {
            return .{ .bits = flags.bits & other.bits };
        }

        ///Bitwise **not**.
        pub fn not(flags: @This()) @This() {
            return .{ .bits = ~flags.bits };
        }

        ///**Exclusive or**.
        pub fn xor(flags: @This(), other: @This()) @This() {
            return .{ .bits = flags.bits ^ other.bits };
        }
    };
}
