`timescale 1ns/1ps

module registers (
    input  wire        clk,
    input  wire        rst,
    input  wire        reg_write,
    input  wire [4:0]  write_reg,
    input  wire [31:0] write_data,
    input  wire [4:0]  read_reg1,
    input  wire [4:0]  read_reg2,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] rf [0:31];
    integer k;

    // Asynchronous reads with hardwired zero for x0
    assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 : rf[read_reg1];
    assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 : rf[read_reg2];

    // Synchronous write & reset
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < 32; k = k + 1)
                rf[k] <= 32'd0;
        end else if (reg_write && (write_reg != 5'd0)) begin
            rf[write_reg] <= write_data;
        end
    end
endmodule