const Token = @import("tokenizer.zig").Token;

pub const Node = union(enum) { expr: Expr };

pub const Expr = union(enum) { identifier: Token, string_lit: Token, int_lit: Token, float_lit: Token, paren: *const Expr };

pub const OpExpr = struct {
    lhs: Token,
    op: Token,
    rhs: Token,
};
