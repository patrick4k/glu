const std = @import("std");

pub const TokenType = enum {
    invalid,

    identifier,
    string_literal,

    // symbols
    semicolon,
    comma,
    question_mark,
    colon,
    newline,

    // ([{}])
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

    fn next_char(self: *Self) u8 {
        self.index += 1;
        return self.curr_char();
    }

    fn curr_char(self: *Self) u8 {
        return self.buffer[self.index];
    }

    pub fn stringify(self: *Self, tok: Token) []const u8 {
        return self.buffer[tok.start..tok.end];
    }

    pub fn next(self: *Self) Token {
        var token = Token{ .type = undefined, .start = self.index, .end = undefined };

        next: switch (State.start) {
            .start => switch (self.curr_char()) {
                0 => {
                    if (self.index == self.buffer.len) {
                        token = .{
                            .type = .eof,
                            .start = self.index,
                            .end = self.index,
                        };
                    } else {
                        continue :next .invalid;
                    }
                },

                // ignore
                ' ', '\t' => {
                    _ = self.next_char();
                    return self.next();
                },
                '\n', '\r' => {
                    token.type = .newline;
                    // self.index += 1;
                    continue :next .newline;
                },
                'a'...'z', 'A'...'Z', '_' => {
                    token.type = .identifier;
                    continue :next .identifier;
                },
                '(' => {
                    token.type = .l_paren;
                    self.index += 1;
                },
                ')' => {
                    token.type = .r_paren;
                    self.index += 1;
                },
                '[' => {
                    token.type = .l_bracket;
                    self.index += 1;
                },
                ']' => {
                    token.type = .r_bracket;
                    self.index += 1;
                },
                '{' => {
                    token.type = .l_brace;
                    self.index += 1;
                },
                '}' => {
                    token.type = .r_brace;
                    self.index += 1;
                },
                ';' => {
                    token.type = .semicolon;
                    self.index += 1;
                },
                ',' => {
                    token.type = .comma;
                    self.index += 1;
                },
                '?' => {
                    token.type = .question_mark;
                    self.index += 1;
                },
                ':' => {
                    token.type = .colon;
                    self.index += 1;
                },
                else => continue :next .invalid,
            },
            .invalid => {
                switch (self.next_char()) {
                    0 => if (self.index == self.buffer.len) {
                        token.type = .invalid;
                    } else {
                        continue :next .invalid;
                    },
                    '\n' => token.type = .invalid,
                    else => continue :next .invalid,
                }
            },
            .identifier => switch (self.next_char()) {
                'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :next .identifier,
                else => {
                    // TODO: Handle keywords
                    _ = self.buffer[token.start..self.index];
                    token.type = .identifier;
                },
            },
            .newline => switch (self.next_char()) {
                '\n', '\r' => continue :next .newline,
                else => {},
            },
        }

        token.end = self.index;
        return token;
    }
};

const State = enum {
    start,
    invalid,
    identifier,
    newline,
};
