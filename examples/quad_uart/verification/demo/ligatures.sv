module intelligent_ligatures(
    input        clk,
    input [32:0] b,
    output       a,
);
    always @clk
    a <= (b <= 'hFF)? 1'b1 : 1'b0;
endmodule

function foo;
    if (a != b) a = b;
    else if (a >= c) a += c;
endfunction