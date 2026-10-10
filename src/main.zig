const std = @import("std");
const Io = std.Io;
const expect = std.testing.expect;

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
        \\
    ;
    var tok = glu.tokenizer.Tokenizer.init(input);
    std.debug.print("{}\n", .{tok});

    while (true) {
        const token = tok.next();
        const str = tok.stringify(token);
        std.debug.print("'{s}' = {}\n\n", .{ str, token });
        switch (token.type) {
            .eof => break,
            else => {},
        }
    }
}
