pub const Parser = @This();
const Self = Parser;

gpa: std.mem.Allocator,
source: []const u8,
tokens: []const Token,
nodes: ast.NodeGraph,
index: usize = 0,
errors: std.ArrayList(ErrorData) = .empty,

pub const ErrorData = union(enum) { unexpected_token: *const Token, expected_closing: struct {
    *const Token,
    TokenType,
} };

pub const Error = error{
    UnexpectedToken,
    ExpectedClosing,
} || std.mem.Allocator.Error;

pub fn init(gpa: std.mem.Allocator, source: []const u8, tokens: []const Token) Self {
    return .{
        .gpa = gpa,
        .source = source,
        .tokens = tokens,
        .nodes = .init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    self.nodes.deinit();
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
            .expected_closing => |tok_ty| {
                std.log.err("Expected closing '{}'", .{tok_ty});
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

pub fn nextTokenNoStep(self: *Self) *const Token {
    return &self.tokens[self.index + 1];
}

pub fn isEnd(self: *Self) bool {
    return self.index >= self.tokens.len;
}

pub fn parse(self: *Self) !void {
    self.eatNewline();
    const expr = try self.parseExpression(true);
    std.log.debug("\n\nexpr\n", .{});
    expr.dump(&self.nodes);
    const expr2 = try self.parseExpression(true);
    std.log.debug("\n\nexpr2\n", .{}); // WHY THE FUCK IS THE SEG FAULTING
    expr2.dump(&self.nodes);
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

fn parseExpression(self: *Self, check_binary_op: bool) Error!ast.Expr {
    self.eatNewline();
    var tok = self.currToken();

    var prefix_op: ?*const Token = null;
    if (tok.type.isPrefixOp()) {
        prefix_op = tok;
        tok = self.nextToken();
    }

    var expr: ast.Expr = undefined;
    expr = switch (tok.type) {
        .identifier => ast.Expr{ .identifier = tok.* },
        .string_literal => ast.Expr{ .string_lit = tok.* },
        .int_literal => ast.Expr{ .int_lit = tok.* },
        .float_literal => ast.Expr{ .float_lit = tok.* },
        .l_paren => brk: {
            self.step();
            const enclosed_expr = try self.parseExpression(true);
            if (self.currToken().type != TokenType.r_paren) {
                try self.pushError(.{ .expected_closing = .{ self.currToken(), TokenType.r_paren } });
                return Error.ExpectedClosing;
            }
            break :brk ast.Expr{ .paren = try self.nodes.insertExpr(enclosed_expr) };
        },
        else => {
            try self.pushError(.{ .unexpected_token = tok });
            return Error.UnexpectedToken;
        },
    };
    self.step();

    if (prefix_op) |op| {
        const rhs = try self.nodes.insertExpr(expr);
        expr = .{ .prefix_op = .{ .op = op, .rhs = rhs } };
    }

    if (check_binary_op and !self.isEnd() and self.currToken().type.isBinaryOp()) {
        const lhs = try self.nodes.insertExpr(expr);
        const op = self.currToken();
        self.step();
        const rhs = try self.nodes.insertExpr(try self.parseExpression(false));
        expr = .{ .binary_op = .{ .lhs = lhs, .op = op, .rhs = rhs } };
    }

    return expr;
}

const std = @import("std");
const debug = std.debug.print;

const tokenizer = @import("tokenizer.zig");
const Token = tokenizer.Token;
const TokenType = tokenizer.TokenType;
const ast = @import("ast.zig");
