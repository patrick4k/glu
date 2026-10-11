pub const Parser = @This();
const Self = Parser;

gpa: std.mem.Allocator,
source: []const u8,
tokens: []const Token,
index: usize,

exprs: std.ArrayList(ast.Expr),

pub const Error = error{
    UnexpectedToken,
    ExpectedClosing,
} || std.mem.Allocator.Error;

pub fn init(gpa: std.mem.Allocator, source: []const u8, tokens: []const Token) Self {
    return .{ .gpa = gpa, .source = source, .tokens = tokens, .index = 0, .exprs = .empty };
}

pub fn deinit(self: *Self) void {
    self.exprs.deinit(self.gpa);
}

pub fn currToken(self: *const Self) *const Token {
    return &self.tokens[self.index];
}

pub fn step(self: *Self) void {
    self.index += 1;
}

pub fn nextToken(self: *Self) *const Token {
    self.step();
    return self.currToken();
}

pub fn parse(self: *Self) !void {
    self.eatNewline();
    const expr = try self.parseExpression();
    debug("expr: {}\n", .{expr});
}

fn eatNewline(self: *Self) void {
    const tok = self.currToken();
    switch (tok.type) {
        .newline => {
            self.step();
            self.eatNewline();
        },
        else => return,
    }
}

fn parseExpression(self: *Self) Error!ast.Expr {
    const tok = self.currToken();
    switch (tok.type) {
        .identifier => return ast.Expr{ .identifier = tok.* },
        .string_literal => return ast.Expr{ .string_lit = tok.* },
        .int_literal => return ast.Expr{ .int_lit = tok.* },
        .float_literal => return ast.Expr{ .float_lit = tok.* },
        .l_paren => {
            self.step();
            const expr = try self.parseExpression();
            if (self.nextToken().type != TokenType.r_paren) {
                return Error.ExpectedClosing;
            }
            try self.exprs.append(self.gpa, expr);
            const expr_ptr = &self.exprs.items[self.exprs.items.len - 1];
            return .{ .paren = expr_ptr };
        },
        else => return Error.UnexpectedToken,
    }

    return .{};
}

const std = @import("std");
const debug = std.debug.print;

const tokenizer = @import("tokenizer.zig");
const Token = tokenizer.Token;
const TokenType = tokenizer.TokenType;
const ast = @import("ast.zig");
