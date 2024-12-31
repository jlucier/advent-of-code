const std = @import("std");

pub const ANSI_RED = "\u{001b}[31m";
pub const ANSI_GREEN = "\u{001b}[32m";
pub const ANSI_RESET = "\u{001b}[m";

pub fn printRed(s: []const u8) void {
    return std.debug.print("{s}{s}{s}", .{ ANSI_RED, s, ANSI_RESET });
}
