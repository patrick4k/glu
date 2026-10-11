pub const Parser = @This();
const Self = Parser;

source: []const u8,
tokens: []const Token,
index: usize,

pub fn init(source: []const u8, tokens: []const Token) Self {
    return .{ .source = source, .tokens = tokens, .index = 0 };
}

pub fn currToken(self: *const Self) *const Token {
    return &self.tokens[self.index];
}

pub fn nextToken(self: *Self) *const Token {
    self.index += 1;
    return self.currToken();
}

pub fn parse(self: *Self) !void {
    debug("first token: {}\n", .{self.currToken()});
    debug("second token: {}\n", .{self.nextToken()});
}

const std = @import("std");
const debug = std.debug.print;

const Token = @import("tokenizer.zig").Token;
