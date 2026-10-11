pub const Parser = @This();
const Self = Parser;

gpa: std.mem.Allocator,
source: []const u8,
tokens: []const Token,
index: usize = 0,
exprs: std.ArrayList(ast.Expr) = .empty,
errors: std.ArrayList(ErrorData) = .empty,

pub const ErrorData = union(enum) { unexpected_token: *const Token };

pub const Error = error{
    UnexpectedToken,
    ExpectedClosing,
} || std.mem.Allocator.Error;

pub fn init(gpa: std.mem.Allocator, source: []const u8, tokens: []const Token) Self {
    return .{
        .gpa = gpa,
        .source = source,
        .tokens = tokens,
    };
}

pub fn deinit(self: *Self) void {
    self.exprs.deinit(self.gpa);
    self.errors.deinit(self.gpa);
}

fn pushError(self: *Self, e: ErrorData) !void {
    return self.errors.append(self.gpa, e);
}
pub fn logErrors(self: *Self) void {
    for (self.errors.items) |err| {
        switch (err) {
            .unexpected_token => |tok| {
                std.log.err("Unexpected token: {}", .{tok});
            },
        }
    }
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
    const expr2 = try self.parseExpression();
    debug("expr2: {}\n", .{expr2});
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

fn pushExpr(self: *Self, expr: ast.Expr) !*const ast.Expr {
    try self.exprs.append(self.gpa, expr);
    return &self.exprs.items[self.exprs.items.len - 1];
}

fn parseExpression(self: *Self) Error!ast.Expr {
    self.eatNewline();
    const tok = self.currToken();
    const expr = switch (tok.type) {
        .identifier => ast.Expr{ .identifier = tok.* },
        .string_literal => ast.Expr{ .string_lit = tok.* },
        .int_literal => ast.Expr{ .int_lit = tok.* },
        .float_literal => ast.Expr{ .float_lit = tok.* },
        .l_paren => {
            self.step();
            const expr = try self.parseExpression();
            if (self.currToken().type != TokenType.r_paren) {
                return Error.ExpectedClosing;
            }
            self.step();
            return .{ .paren = try self.pushExpr(expr) };
        },
        else => {
            try self.pushError(.{ .unexpected_token = tok });
            return Error.UnexpectedToken;
        },
    };
    self.step();

    return expr;
}

const std = @import("std");
const debug = std.debug.print;

const tokenizer = @import("tokenizer.zig");
const Token = tokenizer.Token;
const TokenType = tokenizer.TokenType;
const ast = @import("ast.zig");
