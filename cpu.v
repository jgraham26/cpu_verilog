`timescale 1ns/1ps

module cpu_top (
    input  wire clk,
    input  wire rst
);

    // ==========================================
    // 1. Program Counter & Instruction Fetch
    // ==========================================
    reg  [31:0] pc;
    wire [31:0] pc_plus_4 = pc + 32'd4;
    wire [31:0] next_pc;

    // 24-bit Word-Addressed ROM
    reg [31:0] rom_mem [0:1023];
    initial begin
        // Pre-loaded instructions from your Logisim ROM
        rom_mem[0] = 32'h0403000a;
        rom_mem[1] = 32'h04620005;
        rom_mem[2] = 32'h00430809;
    end
    wire [31:0] instr = rom_mem[pc[25:2]]; // Word aligned access

    // ==========================================
    // 2. Instruction Decoder
    // ==========================================
    wire [25:0] jump_addr;
    wire [15:0] imm;
    wire [5:0]  opcode;
    wire [4:0]  rs, rt_rd, rd;
    wire [10:0] func;

    instruction_decoder u_dec (
        .instr     (instr),
        .jump_addr (jump_addr),
        .imm       (imm),
        .opcode    (opcode),
        .rs        (rs),
        .rt_rd     (rt_rd),
        .rd        (rd),
        .func      (func)
    );

    // ==========================================
    // 3. Control Unit
    // ==========================================
    wire reg_write, alu_src, mem_read, mem_write, mem_to_reg;
    wire beq, bne, jump, jr, jal;
    wire [3:0] alu_control;

    control_unit u_control (
        .opcode      (opcode),
        .func        (func),
        .reg_write   (reg_write),
        .alu_src     (alu_src),
        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .mem_to_reg  (mem_to_reg),
        .beq         (beq),
        .bne         (bne),
        .jump        (jump),
        .jr          (jr),
        .jal         (jal),
        .alu_control (alu_control)
    );

    // ==========================================
    // 4. Register File & Write-Back Logic
    // ==========================================
    wire [31:0] read_data1, read_data2;
    wire [31:0] final_write_data;

    // Register Destination MUX (RegDst logic in your schematic)
    wire is_opcode_zero = (opcode == 6'b000000);
    wire [4:0] reg_dest_step1 = is_opcode_zero ? rd : rt_rd;
    wire [4:0] write_reg      = jal ? 5'd31 : reg_dest_step1;

    registers u_registers (
        .clk        (clk),
        .rst        (rst),
        .reg_write  (reg_write),
        .write_reg  (write_reg),
        .write_data (final_write_data),
        .read_reg1  (rs),
        .read_reg2  (rt_rd),
        .read_data1 (read_data1),
        .read_data2 (read_data2)
    );

    // ==========================================
    // 5. ALU & Execution
    // ==========================================
    // Immediate Extension Logic (Schematic OR gate to select Zero vs Sign extension)
    wire is_andi_ori = (opcode == 6'b001100) || (opcode == 6'b001101) || (opcode == 6'b001000);
    wire is_zero_ext = (opcode == 6'd2) || (opcode == 6'd3);
    wire [31:0] imm_zero_ext = {16'b0, imm};
    wire [31:0] imm_sign_ext = {{16{imm[15]}}, imm};
    wire [31:0] extended_imm = is_zero_ext ? imm_zero_ext : imm_sign_ext;
    
    wire [31:0] alu_operand_b = alu_src ? extended_imm : read_data2;
    wire [31:0] alu_result;
    wire        zero_flag;

    alu u_alu (
        .a           (read_data1),
        .b           (alu_operand_b),
        .alu_control (alu_control),
        .alu_result  (alu_result),
        .zero        (zero_flag)
    );

    // ==========================================
    // 6. Data RAM
    // ==========================================
    reg [31:0] data_ram [0:1023];
    wire [31:0] mem_read_data = data_ram[alu_result[11:2]];

    always @(posedge clk) begin
        if (mem_write) begin
            data_ram[alu_result[11:2]] <= read_data2;
        end
    end

    // ==========================================
    // 7. LUI & Write-back MUX Network
    // ==========================================
    wire [31:0] base_write_data = mem_to_reg ? mem_read_data : alu_result;
    wire is_lui = (opcode == 6'b001111); // LUI opcode comparator
    wire [31:0] lui_data = extended_imm << 16;
    wire [31:0] wb_data_lui_mux = is_lui ? lui_data : base_write_data;

    // JAL saves PC + 4 to $ra
    assign final_write_data = jal ? pc_plus_4 : wb_data_lui_mux;

    // ==========================================
    // 8. Branch & Jump PC Redirection Logic
    // ==========================================
    wire [31:0] branch_target = pc_plus_4 + extended_imm;
    wire branch_condition = (beq & zero_flag) | (bne & ~zero_flag);

    wire [31:0] pc_branch_mux = branch_condition ? branch_target : pc_plus_4;
    wire [31:0] jump_target = {pc_plus_4[31:26], jump_addr};
    wire [31:0] pc_jump_mux   = (jump | jal) ? jump_target : pc_branch_mux;

    // JR redirects to Register 31 / rs address
    assign next_pc = jr ? read_data1 : pc_jump_mux;

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'h00000000;
        end else begin
            pc <= next_pc;
        end
    end

endmodule