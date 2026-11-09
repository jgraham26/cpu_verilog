`timescale 1ns/1ps

module tb_cpu;

    reg clk;
    reg rst;

    // Instantiate CPU Top
    cpu_top uut (
        .clk(clk),
        .rst(rst)
    );

    // 100 MHz clock generation (10ns period)
    always #5 clk = ~clk;

    integer file;
    integer bytes_read;
    integer i;

    initial begin
        // Waveform dump setup
        $dumpfile("cpu_waves.vcd");
        $dumpvars(0, tb_cpu);

        // Initialize signals
        clk = 0;
        rst = 1;

        // Clear ROM memory before loading
        for (i = 0; i < 1024; i = i + 1) begin
            uut.rom_mem[i] = 32'h00000000;
        end

        // -----------------------------------------------------------------
        // Load rom.bin from working directory
        // -----------------------------------------------------------------
        file = $fopen("rom.bin", "rb");
        if (file == 0) begin
            $display("=================================================");
            $display("[ERROR] Could not open 'rom.bin' in working directory!");
            $display("=================================================");
            $finish;
        end

        // Read raw binary words directly into ROM memory (Big-Endian format)
        // If your assembler outputs raw binary, $fread streams bytes directly.
        bytes_read = $fread(uut.rom_mem, file);
        $display("[INFO] Successfully loaded %0d bytes from rom.bin into ROM.", bytes_read);
        $fclose(file);

        // Optional: If rom.bin was compiled little-endian and your CPU expects big-endian,
        // swap byte order:
        /*
        for (i = 0; i < (bytes_read / 4); i = i + 1) begin
            uut.rom_mem[i] = {uut.rom_mem[i][7:0], 
                              uut.rom_mem[i][15:8], 
                              uut.rom_mem[i][23:16], 
                              uut.rom_mem[i][31:24]};
        end
        */

        // Hold reset for 2 clock cycles
        #20;
        @(negedge clk);
        rst = 0;
        $display("[INFO] Released reset. Starting execution...");
        $display("-------------------------------------------------");
        $display(" Cycle |     PC     |   Instr    | R1 (at)  | R2 (v0)  | R3 (v1)  ");
        $display("-------------------------------------------------");

        // Run simulation for 200 cycles or until infinite loop detected
        for (i = 0; i < 200; i = i + 1) begin
            @(posedge clk);
            #1; // Wait 1ns after clock edge for registers to settle
            $display("%6d | 0x%08h | 0x%08h | 0x%08h | 0x%08h | 0x%08h",
                     i,
                     uut.pc,
                     uut.instr,
                     uut.u_registers.rf[1],
                     uut.u_registers.rf[2],
                     uut.u_registers.rf[3]
            );

            // Halt if an infinite loop branch/jump is reached (e.g., self-jump j .)
            if (uut.pc == uut.next_pc && !rst) begin
                $display("[INFO] Detected self-loop / termination at PC = 0x%08h", uut.pc);
                break;
            end
        end

        $display("-------------------------------------------------");
        $display("[INFO] Simulation finished.");
        $display("Final Register Dump (Non-zero):");
        for (i = 0; i < 32; i = i + 1) begin
            if (uut.u_registers.rf[i] !== 32'd0) begin
                $display("  R%-2d: 0x%08h (%0d)", i, uut.u_registers.rf[i], $signed(uut.u_registers.rf[i]));
            end
        end
        $display("=================================================");

        $finish;
    end

endmodule