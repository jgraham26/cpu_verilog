`timescale 1ns/1ps

module instruction_decoder (
    input  wire [31:0] instr,
    output wire [25:0] jump_addr,
    output wire [15:0] imm,
    output wire [5:0]  opcode,
    output wire [4:0]  rs,
    output wire [4:0]  rt_rd,
    output wire [4:0]  rd,
    output wire [10:0] func
);
    assign jump_addr = instr[25:0];
    assign imm       = instr[15:0];
    assign opcode    = instr[31:26];
    assign rs        = instr[25:21];
    assign rt_rd     = instr[20:16];
    assign rd        = instr[15:11];
    assign func      = instr[10:0];
endmodule