const std = @import("std");
const Io = std.Io;
const expect = std.testing.expect;
const debug = std.debug.print;

const glu = @import("glu");

pub fn main() !void {
    const zinput = "comptime";
    var ztok = std.zig.Tokenizer.init(zinput);
    try expect(ztok.next().tag == .keyword_comptime);
    std.debug.print("{}\n", .{ztok});

    const input =
        \\
        \\
        \\
        \\{( foobar;:?, )}
        \\ "bar\"baz"
        \\ 1234
        \\ 10.23
        \\ let fn for while if unless until else
        \\
    ;
    var tok = glu.tokenizer.Tokenizer.init(input);
    debug("{}\n", .{tok});

    const DebugAlloc = std.heap.DebugAllocator(.{});
    var gpa = DebugAlloc.init;
    const Tokens = std.ArrayList(glu.tokenizer.Token);
    var tokens = Tokens.empty;

    while (true) {
        const token = tok.next();
        const str = tok.stringify(token);
        debug("'{s}' = {}\n\n", .{ str, token });
        switch (token.type) {
            .eof => break,
            else => {},
        }
        try tokens.append(gpa.allocator(), token);
    }
    debug("found {} tokens!\n", .{tokens.items.len});

    var parser = glu.Parser.init(input, tokens.items);
    try parser.parse();
}
