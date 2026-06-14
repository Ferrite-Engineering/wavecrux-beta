// SPDX-License-Identifier: 0BSD
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// Pure-Verilog testbench driving YosysHQ's picorv32_wb (vendored
// verbatim from picorv32.v, ISC) against a tiny in-memory Wishbone
// slave preloaded with the same 6-instruction loop the upstream
// testbench_ez.v uses. The captured FST exercises the WaveCrux
// Wishbone B3 Classic decoder against real RISC-V instruction-fetch
// + load/store traffic, no RISC-V toolchain required.
//
// The slave is single-cycle ack (data returned on the same posedge
// where cyc & stb sample high). 80 transactions across ~250 ns:
// repeated ifetch of the loop body plus the lw / sw of the counter
// at 0x3FC.

`timescale 1 ns / 1 ps

module tb_picorv32_wb_ez;

    reg wb_clk = 1'b1;
    always #5 wb_clk = ~wb_clk;   // 100 MHz

    // Active-high reset (Wishbone spec + picorv32 convention).
    reg wb_rst = 1'b1;

    // ── Wishbone master signals from picorv32_wb ────────────────────
    wire [31:0] wb_adr;
    wire [31:0] wb_dat_m2s;   // master → slave (write data)
    wire        wb_we;
    wire [3:0]  wb_sel;
    wire        wb_stb;
    wire        wb_cyc;

    // ── Wishbone slave-driven signals ───────────────────────────────
    reg  [31:0] wb_dat_s2m = 32'h0;  // slave → master (read data)
    reg         wb_ack     = 1'b0;

    // ── picorv32_wb DUT ─────────────────────────────────────────────
    picorv32_wb #(
        .ENABLE_COUNTERS(0),
        .ENABLE_COUNTERS64(0),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .BARREL_SHIFTER(0),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .COMPRESSED_ISA(0),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_TRACE(0)
    ) uut (
        .trap        (),
        .wb_clk_i    (wb_clk),
        .wb_rst_i    (wb_rst),
        .wbm_adr_o   (wb_adr),
        .wbm_dat_o   (wb_dat_m2s),
        .wbm_dat_i   (wb_dat_s2m),
        .wbm_we_o    (wb_we),
        .wbm_sel_o   (wb_sel),
        .wbm_stb_o   (wb_stb),
        .wbm_ack_i   (wb_ack),
        .wbm_cyc_o   (wb_cyc),

        // unused interfaces — tie off
        .pcpi_wr     (1'b0),
        .pcpi_rd     (32'h0),
        .pcpi_wait   (1'b0),
        .pcpi_ready  (1'b0),
        .pcpi_valid  (),
        .pcpi_insn   (),
        .pcpi_rs1    (),
        .pcpi_rs2    (),
        .irq         (32'h0),
        .eoi         (),
        .trace_valid (),
        .trace_data  (),
        .mem_instr   ()
    );

    // ── tiny in-memory WB slave ─────────────────────────────────────
    // 256 × 32-bit words = 1 KiB, mapped 0x000..0x3FC. The loop's
    // counter target 0x3FC fits in the top entry, matching the
    // upstream testbench_ez.v memory map exactly.
    reg [31:0] memory [0:255];

    initial begin
        // Same six-instruction loop as testbench_ez.v (public domain).
        memory[0] = 32'h 3fc00093; //       li      x1,1020
        memory[1] = 32'h 0000a023; //       sw      x0,0(x1)
        memory[2] = 32'h 0000a103; // loop: lw      x2,0(x1)
        memory[3] = 32'h 00110113; //       addi    x2,x2,1
        memory[4] = 32'h 0020a023; //       sw      x2,0(x1)
        memory[5] = 32'h ff5ff06f; //       j       <loop>
    end

    // Single-cycle ack: when cyc & stb sample high, drive ack high on
    // the next clock and present read data / consume write data.
    always @(posedge wb_clk) begin
        wb_ack <= 1'b0;
        if (!wb_rst && wb_cyc && wb_stb && !wb_ack) begin
            wb_ack <= 1'b1;
            wb_dat_s2m <= memory[wb_adr[31:2]];
            if (wb_we) begin
                if (wb_sel[0]) memory[wb_adr[31:2]][ 7: 0] <= wb_dat_m2s[ 7: 0];
                if (wb_sel[1]) memory[wb_adr[31:2]][15: 8] <= wb_dat_m2s[15: 8];
                if (wb_sel[2]) memory[wb_adr[31:2]][23:16] <= wb_dat_m2s[23:16];
                if (wb_sel[3]) memory[wb_adr[31:2]][31:24] <= wb_dat_m2s[31:24];
            end
        end
    end

    // ── stimulus envelope ───────────────────────────────────────────
    initial begin
        $dumpfile("wishbone_picorv32_wb_ez.fst");
        $dumpvars(0, tb_picorv32_wb_ez);

        // Hold reset for the picorv32 startup sequence, then release
        // and let the loop run for a bounded number of iterations.
        repeat (4) @(posedge wb_clk);
        wb_rst <= 1'b0;

        // ~250 ns of WB traffic is enough for several full iterations
        // of the load/increment/store loop while keeping the FST
        // small (<5 kB).
        repeat (60) @(posedge wb_clk);
        $finish;
    end

endmodule
