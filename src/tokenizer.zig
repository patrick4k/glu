const std = @import("std");
const debug = std.debug.print;

pub const TokenType = enum {
    invalid,
    comment,

    identifier,
    string_literal,
    int_literal,
    float_literal,

    // symbols
    semicolon,
    comma,
    question_mark,
    colon,
    newline,

    // ops
    plus, // +
    plus_eq, // +=
    plus_plus, // ++
    minus, // -
    minus_eq, // -=
    minus_minus, // --
    star, // *
    star_eq, // *=
    star_star, // **
    slash, // /
    slash_eq, // /=
    slash_slash, // //
    pipe, // |
    pipe_eq, // |=
    pipe_pipe, // ||
    ampersand, // &
    ampersand_eq, // &=
    ampersand_ampersand, // &&
    mod, // %
    mod_eq, // %=
    mod_mod, // %%
    caret, // ^
    caret_eq, // ^=
    caret_caret, // ^^
    eq, // =
    eq_eq, // ==
    bang_eq, // !=
    bang, // !
    dot, // .
    dot_eq, // .=
    dot_dot, // ..
    question, // ?
    question_question, // ??
    at, // @
    dollar, // $

    lt, // <
    lt_eq, // <=
    lt_lt, // <<
    gt, // >
    gt_eq, // >=
    gt_gt, // >>

    // ([{}])
    l_paren,
    r_paren,
    l_brace,
    r_brace,
    l_bracket,
    r_bracket,

    // keywords,
    kw_let,
    kw_fn,
    kw_if,
    kw_unless,
    kw_else,
    kw_for,
    kw_while,
    kw_until,

    eof,
};

const keywords = std.StaticStringMap(TokenType).initComptime(.{
    .{ "let", .kw_let },
    .{ "fn", .kw_fn },
    .{ "if", .kw_if },
    .{ "unless", .kw_unless },
    .{ "else", .kw_else },
    .{ "for", .kw_for },
    .{ "while", .kw_while },
    .{ "until", .kw_until },
});

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

    fn nextChar(self: *Self) u8 {
        self.index += 1;
        return self.currChar();
    }

    fn currChar(self: *Self) u8 {
        return self.buffer[self.index];
    }

    fn prevChar(self: *Self) u8 {
        return self.buffer[self.index - 1];
    }

    pub fn stringify(self: *Self, tok: Token) []const u8 {
        return self.buffer[tok.start..tok.end];
    }

    pub fn next(self: *Self) Token {
        var token = Token{ .type = undefined, .start = self.index, .end = undefined };

        next: switch (State.start) {
            .start => switch (self.currChar()) {
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
                    _ = self.nextChar();
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
                '0'...'9' => {
                    token.type = .int_literal;
                    continue :next .int_literal;
                },
                '"' => {
                    token.type = .string_literal;
                    continue :next .string_literal;
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
                '+' => {
                    token.type = switch (self.nextChar()) {
                        '=' => brk: {
                            self.index += 1;
                            break :brk .plus_eq;
                        },
                        '+' => brk: {
                            self.index += 1;
                            break :brk .plus_plus;
                        },
                        else => .plus,
                    };
                },
                '-' => {
                    token.type = switch (self.nextChar()) {
                        '=' => brk: {
                            self.index += 1;
                            break :brk .minus_eq;
                        },
                        '-' => brk: {
                            self.index += 1;
                            break :brk .minus_minus;
                        },
                        else => .minus,
                    };
                },
                '*' => {
                    token.type = switch (self.nextChar()) {
                        '=' => brk: {
                            self.index += 1;
                            break :brk .star_eq;
                        },
                        '*' => brk: {
                            self.index += 1;
                            break :brk .star_star;
                        },
                        else => .star,
                    };
                },
                '/' => {
                    token.type = switch (self.nextChar()) {
                        '=' => brk: {
                            self.index += 1;
                            break :brk .slash_eq;
                        },
                        '/' => {
                            self.index += 1;
                            continue :next .comment;
                        },
                        else => .slash,
                    };
                },
                else => continue :next .invalid,
            },
            .invalid => {
                switch (self.nextChar()) {
                    0 => if (self.index == self.buffer.len) {
                        token.type = .invalid;
                    } else {
                        continue :next .invalid;
                    },
                    '\n' => token.type = .invalid,
                    else => continue :next .invalid,
                }
            },
            .identifier => switch (self.nextChar()) {
                'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :next .identifier,
                else => {
                    const ident = self.buffer[token.start..self.index];
                    var tokty = TokenType.identifier;
                    if (keywords.get(ident)) |kw_tokty| {
                        tokty = kw_tokty;
                    }
                    token.type = tokty;
                },
            },
            .newline => switch (self.nextChar()) {
                '\n', '\r' => continue :next .newline,
                else => {},
            },
            .string_literal => switch (self.nextChar()) {
                '"' => {
                    if (self.prevChar() == '\\') {
                        continue :next .string_literal;
                    }
                    self.index += 1;
                },
                else => continue :next .string_literal,
            },
            .int_literal => switch (self.nextChar()) {
                '0'...'9' => continue :next .int_literal,
                '.' => {
                    token.type = .float_literal;
                    continue :next .float_literal;
                },
                else => {},
            },
            .float_literal => switch (self.nextChar()) {
                '0'...'9' => continue :next .float_literal,
                else => {},
            },
            .comment => {
                switch (self.nextChar()) {
                    '\n', '\r' => token.type = .comment,
                    else => continue :next .comment,
                }
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
    string_literal,
    int_literal,
    float_literal,
    comment,
};
