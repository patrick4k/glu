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

    // const input =
    //     \\
    //     \\ ("fooo baaar")
    //     \\ "fooo baaar"
    //     \\{( foobar;:?, )}
    //     \\ "bar\"baz"
    //     \\ // this is a comment
    //     \\ 1234 + ** -= // this is also a comment
    //     \\ 10.23
    //     \\ let fn for while if unless until else
    //     \\
    // ;
    const input =
        \\ ((1.0 + 2.0))
        \\ 12 + foobar
    ;
    var tok = glu.tokenizer.Tokenizer.init(input);
    debug("{}\n", .{tok});

    const DebugAlloc = std.heap.DebugAllocator(.{});
    var gpa = DebugAlloc.init;
    defer _ = gpa.deinit();

    const Tokens = std.ArrayList(glu.tokenizer.Token);
    var tokens = Tokens.empty;
    defer tokens.deinit(gpa.allocator());

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

    var parser = glu.Parser.init(gpa.allocator(), input, tokens.items);
    defer parser.deinit();

    parser.parse() catch |e| {
        std.log.err("Failed to parse sample: {}", .{e});
        parser.logErrors();
        return;
    };
    std.log.info("Successfully parsed sample", .{});
}
