const std = @import("std");
const Token = @import("tokenizer.zig").Token;

pub const NodeGraph = struct {
    const Self = @This();
    const ExprIdx = struct { idx: usize };

    gpa: std.mem.Allocator,
    exprs: std.ArrayList(Expr) = .empty,

    pub fn init(gpa: std.mem.Allocator) Self {
        return .{
            .gpa = gpa,
        };
    }

    pub fn deinit(self: *Self) void {
        self.exprs.deinit(self.gpa);
    }

    pub fn insertExpr(self: *Self, expr: Expr) !ExprIdx {
        try self.exprs.append(self.gpa, expr);
        return .{ .idx = self.exprs.items.len - 1 };
    }

    pub fn getExprUnchecked(self: *const Self, idx: ExprIdx) *const Expr {
        return &self.exprs.items[idx.idx];
    }

    pub fn getExpr(self: *const Self, idx: ExprIdx) ?*const Expr {
        if (self.exprs.items.len - 1 < idx.idx) {
            return null;
        }
        return self.getExprUnchecked(idx);
    }
};

pub const Node = union(enum) { expr: Expr };

pub const Expr = union(enum) {
    identifier: Token,
    string_lit: Token,
    int_lit: Token,
    float_lit: Token,
    paren: NodeGraph.ExprIdx,
    binary_op: BinaryOpExpr,
    prefix_op: PrefixOpExpr,
    suffix_op: SuffixOpExpr,

    pub fn dump(self: *const Expr, nodes: *const NodeGraph) void {
        switch (self.*) {
            .paren => |expr_idx| {
                const expr = nodes.getExpr(expr_idx);
                if (expr) |e| {
                    e.dump(nodes);
                }
            },
            .identifier, .string_lit, .int_lit => |token| {
                std.log.debug("{}", .{token.type});
            },
            .binary_op => |expr| {
                std.log.debug("binary op\n{}", .{expr});
            },
            else => {
                std.log.debug("unknown dump expr", .{});
            },
        }
    }
};

pub const PrefixOpExpr = struct {
    op: *const Token,
    rhs: NodeGraph.ExprIdx,
};

pub const SuffixOpExpr = struct {
    lhs: NodeGraph.ExprIdx,
    op: *const Token,
};

pub const BinaryOpExpr = struct {
    lhs: NodeGraph.ExprIdx,
    op: *const Token,
    rhs: NodeGraph.ExprIdx,
};
