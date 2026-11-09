`timescale 1ns/1ps

module control_unit (
    input  wire [5:0]  opcode,
    input  wire [10:0] func,

    output wire        reg_write,
    output wire        alu_src,
    output wire        mem_read,
    output wire        mem_write,
    output wire        mem_to_reg,
    output wire        beq,
    output wire        bne,
    output wire        jump,
    output wire        jr,
    output wire        jal,
    output wire [3:0]  alu_control
);

    // 64x16-bit ROM from your circuit contents
    reg [15:0] rom [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1) rom[i] = 16'h0000;
        rom[0]  = 16'h0001;
        rom[1]  = 16'h0403;
        rom[2]  = 16'h0c03;
        rom[3]  = 16'h1003;
        rom[4]  = 16'h1803;
        rom[5]  = 16'h0417;
        rom[6]  = 16'h040a;
        rom[7]  = 16'h1020;
        rom[8]  = 16'h1040;
        rom[9]  = 16'h0080;
        rom[10] = 16'h0201;
        rom[11] = 16'h0100;
    end

    wire [15:0] rom_data = rom[opcode];

    // ROM bit-slicing
    assign reg_write  = rom_data[0];
    assign alu_src    = rom_data[1];
    assign mem_read   = rom_data[2];
    assign mem_write  = rom_data[3];
    assign mem_to_reg = rom_data[4];
    assign beq        = rom_data[5];
    assign bne        = rom_data[6];
    assign jump       = rom_data[7];
    assign jr         = rom_data[8];
    assign jal        = rom_data[9];
    wire [2:0] alu_op = rom_data[12:10];

    // ALU Decoder instantiation
    wire [3:0] raw_alu_ctrl;
    alu_decoder u_alu_dec (
        .func        (func),
        .alu_op      (alu_op),
        .alu_control (raw_alu_ctrl)
    );

    // MUX network for BEQ/BNE and MemRead/MemWrite override in circuit
    wire is_branch = beq | bne;
    wire is_mem    = mem_read | mem_write;

    wire [3:0] branch_mux = is_branch ? 4'b0001 : raw_alu_ctrl;  // 1: Subtraction
    assign alu_control    = is_mem    ? 4'b0000 : branch_mux;    // 0: Addition
endmodule