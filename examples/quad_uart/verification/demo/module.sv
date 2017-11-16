// Example where names gets legally resused.
module Module(
    input Input
);
endmodule

module AnotherModule(
    input Input
);
    Module Module(.Input(Input));
    initial force Module.Input = 0;
endmodule