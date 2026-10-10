const std = @import("std");

pub const TokenType = enum {
    identifier,
    string_literal,
    l_paren,
    r_paren,
    l_brace,
    r_brace,
    l_bracket,
    r_bracket,
    eof,
};

pub const Token = struct {
    type: TokenType,
    start: usize,
    end: usize,
};

pub const Tokenizer = struct {
    const Self = @This();

    buffer: [:0]const u8,
    index: usize,

    pub fn init(buffer: [:0]const u8) Self {
        return Self{
            .buffer = buffer,
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0,
        };
    }

    pub fn next(self: *Self) Token {
        return Token{ .type = .identifier, .start = 0, .end = self.buffer.len };
    }
};
