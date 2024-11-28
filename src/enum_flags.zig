const std = @import("std");

///Checks if every field of `Flag` enum is a power of two, meaning that it occupies its unique bit in underlying integer value.
pub fn fieldsUnique(comptime Flag: type) bool {
    switch (@typeInfo(Flag)) {
        .@"enum" => |enum_info| {
            for (enum_info.fields) |field| {
                if ((field.value & (field.value - 1)) != 0) return false;
            }

            return true;
        },
        else => unreachable, //Not an enum.
    }
}

///Overlapping enum flags are allowed. It means, that for enum like this:
///```
///enum(u8) {
///     foo = 1, //0b01
///     bar = 3, //0b11
///}
///```
///enabling flag `bar` will also enable flag `foo`. If you want to avoid this behaviour, make sure all of your flags values are unique powers of two. `fieldsUnique(...)` can help with this.
pub fn EnumFlags(comptime Flag: type) type {
    const enum_info = @typeInfo(Flag).@"enum";

    return packed struct {
        pub const bit_length = @typeInfo(enum_info.tag_type).int.bits;

        bits: enum_info.tag_type,

        ///Flags with no flags enabled.
        pub fn none() @This() {
            return .{ .bits = 0 };
        }

        ///Flags with every flag in `flags_slice` enabled.
        pub fn many(flags_slice: []const Flag) @This() {
            var flags = @This().none();

            for (flags_slice) |flag| {
                flags = flags.enable(flag);
            }

            return flags;
        }

        ///Flags with all flags enabled.
        pub fn all() @This() {
            return .{ .bits = ~@as(enum_info.tag_type, 0) };
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
        pub fn mix(flags: @This(), other: @This()) @This() {
            return .{ .bits = flags.bits | other.bits };
        }

        ///Bitwise **and**.
        pub fn mask(flags: @This(), other: @This()) @This() {
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

test "test" {
    const expect = std.testing.expect;
    const assert = std.debug.assert;

    const WindowFlag = enum(u4) {
        comptime {
            assert(!fieldsUnique(@This()));
        }

        windowed = 1,
        borderless = 2,
        title = 4,
        /// `windowed` | `title`
        titled_window = 5,
        double_buffered = 8,
    };

    const WindowFlags = EnumFlags(WindowFlag);

    var flags = WindowFlags.none();

    //`none` initialization test
    {
        try expect(flags.bits == 0);
    }

    {
        flags = WindowFlags.many(&.{ .title, .windowed });

        inline for (.{ WindowFlag.borderless, WindowFlag.double_buffered }) |flag| {
            try expect(!flags.isSet(flag));
        }

        try expect(flags.isSet(.title));
        try expect(flags.isSet(.windowed));

        try expect(flags.isSet(.titled_window));

        flags = flags.disable(.title);

        try expect(!flags.isSet(.titled_window));
    }

    {
        flags = WindowFlags.all().mask(.many(&.{ .windowed, .double_buffered }));

        try expect(flags.isSet(.windowed));
        try expect(flags.isSet(.double_buffered));

        try expect(!flags.isSet(.borderless));
        try expect(!flags.isSet(.titled_window));
    }

    {
        flags = WindowFlags.none().set(.title, true);

        try expect(flags.isSet(.title));

        inline for (.{ WindowFlag.borderless, WindowFlag.double_buffered, WindowFlag.windowed, WindowFlag.titled_window }) |flag| {
            try expect(!flags.isSet(flag));
        }

        flags = flags.set(.title, false);

        inline for (.{ WindowFlag.borderless, WindowFlag.double_buffered, WindowFlag.windowed, WindowFlag.titled_window }) |flag| {
            try expect(!flags.isSet(flag));
        }

        try expect(!flags.isSet(.title));
    }
}
