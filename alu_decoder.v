`timescale 1ns/1ps

module alu_decoder (
    input  wire [10:0] func,
    input  wire [2:0]  alu_op,
    output wire [3:0]  alu_control
);
    // In your circuit: if alu_op == 0, pass func; else pass (alu_op - 1)
    wire [10:0] sub_res = {8'b0, alu_op} - 11'd1;
    wire [10:0] mux_out = (alu_op == 3'b000) ? func : sub_res;

    assign alu_control = mux_out[3:0];
endmodule