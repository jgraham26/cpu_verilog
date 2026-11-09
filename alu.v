`timescale 1ns/1ps

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] alu_result,
    output wire        zero
);

    always @(*) begin
        case (alu_control)
            4'b0000: alu_result = a + b;                          // ADD
            4'b0001: alu_result = a - b;                          // SUB
            4'b0010: alu_result = a & b;                          // AND
            4'b0011: alu_result = a | b;                          // OR
            4'b0100: alu_result = a ^ b;                          // XOR
            4'b0101: alu_result = a << b[4:0];                    // SLL
            4'b0110: alu_result = a >> b[4:0];                    // SRL
            4'b0111: alu_result = $signed(a) >>> b[4:0];          // SRA
            4'b1000: alu_result = (a[31] != b[31]) ? (a[31] ? 32'd1 : 32'd0) : ((a < b) ? 32'd1 : 32'd0); // SLT bit-31 sign fix
            4'b1001: alu_result = a * b;                          // MUL
            default: alu_result = 32'd0;
        endcase
    end

    // 32-input NOR gate
    assign zero = (alu_result == 32'd0);
endmodule