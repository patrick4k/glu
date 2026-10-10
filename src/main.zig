const std = @import("std");
const Io = std.Io;
const expect = std.testing.expect;

const glu = @import("glu");

pub fn main() !void {
    const zinput = "comptime";
    var ztok = std.zig.Tokenizer.init(zinput);
    try expect(ztok.next().tag == .keyword_comptime);
    std.debug.print("{}\n", .{ztok});

    const input = "(12.3)";
    var tok = glu.tokenizer.Tokenizer.init(input);
    std.debug.print("{}\n", .{tok});

    const token = tok.next();
    std.debug.print("{}\n", .{token});
}
