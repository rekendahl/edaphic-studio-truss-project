module intelligent_ligatures(
input clk,
input [32:0] b,
output a,
);
    always @clk
    a <= (b <= 'hFF)? 1'b1 : 1'b0;
endmodule