// Copyright (c) WaveCrux contributors.
// SPDX-License-Identifier: 0BSD
//
// Minimal testbench around lowRISC's ibex_top with the RISC-V Formal
// Interface (RVFI) compiled in, used to capture a real-core RVFI trace for
// the WaveCrux fixture corpus.
//
// Ibex itself is vendored verbatim under ibex/ (Apache-2.0); nothing in the
// core is modified. This file is ours and only provides clock, reset, a
// 1 KiB dual-port memory and the tie-offs copied from upstream's own
// examples/simple_system/rtl/ibex_simple_system.sv instantiation.
//
// Memory map (byte addresses, 1 KiB):
//   0x000  trap handler   (mtvec resets to boot_addr_i, vectored)
//   0x080  reset vector   (Ibex resets to boot_addr_i + 0x80)
//   0x200  data scratch
// The image is produced by assemble.py -- no RISC-V toolchain required.

`timescale 1ns / 1ps

module tb_ibex_rvfi;

  localparam int unsigned MemWords = 256;  // 1 KiB
  localparam int unsigned AddrMsb = 9;  // byte address bits used: [9:2]

  logic clk = 1'b0;
  logic rst_n = 1'b0;

  always #5 clk = ~clk;  // 100 MHz

  logic [31:0] mem[MemWords];

  // ---------------------------------------------------------------------
  // Instruction port
  // ---------------------------------------------------------------------
  logic        instr_req;
  logic        instr_gnt;
  logic        instr_rvalid;
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;

  // ---------------------------------------------------------------------
  // Data port
  // ---------------------------------------------------------------------
  logic        data_req;
  logic        data_gnt;
  logic        data_rvalid;
  logic        data_we;
  logic [ 3:0] data_be;
  logic [31:0] data_addr;
  logic [31:0] data_wdata;
  logic [31:0] data_rdata;

  assign instr_gnt = instr_req;
  assign data_gnt  = data_req;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      instr_rvalid <= 1'b0;
      instr_rdata  <= 32'h0;
      data_rvalid  <= 1'b0;
      data_rdata   <= 32'h0;
    end else begin
      instr_rvalid <= instr_req;
      if (instr_req) begin
        instr_rdata <= mem[instr_addr[AddrMsb:2]];
      end

      data_rvalid <= data_req;
      if (data_req) begin
        if (data_we) begin
          for (int unsigned b = 0; b < 4; b++) begin
            if (data_be[b]) mem[data_addr[AddrMsb:2]][8*b+:8] <= data_wdata[8*b+:8];
          end
          data_rdata <= 32'h0;
        end else begin
          data_rdata <= mem[data_addr[AddrMsb:2]];
        end
      end
    end
  end

  // ---------------------------------------------------------------------
  // DUT -- lowRISC Ibex, `small` configuration, RVFI compiled in
  // ---------------------------------------------------------------------
  ibex_top #(
      .PMPEnable       (1'b0),
      .PMPGranularity  (0),
      .PMPNumRegions   (4),
      .MHPMCounterNum  (0),
      .MHPMCounterWidth(40),
      .RV32E           (1'b0),
      .RV32M           (ibex_pkg::RV32MFast),
      .RV32B           (ibex_pkg::RV32BNone),
      .RV32ZC          (ibex_pkg::RV32Zca),
      .RegFile         (ibex_pkg::RegFileFF),
      .BranchTargetALU (1'b0),
      .WritebackStage  (1'b0),
      .ICache          (1'b0),
      .ICacheECC       (1'b0),
      .ICacheScramble  (1'b0),
      .BranchPredictor (1'b0),
      .DbgTriggerEn    (1'b0),
      .SecureIbex      (1'b0),
      .DmBaseAddr      (32'h1A110000),
      .DmAddrMask      (32'h00000FFF),
      .DmHaltAddr      (32'h1A110800),
      .DmExceptionAddr (32'h1A110808)
  ) u_ibex_top (
      .clk_i (clk),
      .rst_ni(rst_n),

      .test_en_i            (1'b0),
      .scan_rst_ni          (1'b1),
      .ram_cfg_icache_tag_i ('{default: prim_ram_1p_pkg::RAM_1P_CFG_REQ_DEFAULT}),
      .ram_cfg_icache_tag_o (),
      .ram_cfg_icache_data_i('{default: prim_ram_1p_pkg::RAM_1P_CFG_REQ_DEFAULT}),
      .ram_cfg_icache_data_o(),

      .hart_id_i  (32'b0),
      // First instruction executed is at boot_addr_i + 0x80.
      .boot_addr_i(32'h0000_0000),

      .instr_req_o       (instr_req),
      .instr_gnt_i       (instr_gnt),
      .instr_rvalid_i    (instr_rvalid),
      .instr_addr_o      (instr_addr),
      .instr_rdata_i     (instr_rdata),
      .instr_rdata_intg_i(7'b0),
      .instr_err_i       (1'b0),

      .data_req_o       (data_req),
      .data_gnt_i       (data_gnt),
      .data_rvalid_i    (data_rvalid),
      .data_we_o        (data_we),
      .data_be_o        (data_be),
      .data_addr_o      (data_addr),
      .data_wdata_o     (data_wdata),
      .data_wdata_intg_o(),
      .data_rdata_i     (data_rdata),
      .data_rdata_intg_i(7'b0),
      .data_err_i       (1'b0),

      .irq_software_i(1'b0),
      .irq_timer_i   (1'b0),
      .irq_external_i(1'b0),
      .irq_fast_i    (15'b0),
      .irq_nm_i      (1'b0),

      .scramble_key_valid_i('0),
      .scramble_key_i      ('0),
      .scramble_nonce_i    ('0),
      .scramble_req_o      (),

      .debug_req_i        (1'b0),
      .crash_dump_o       (),
      .double_fault_seen_o(),

      .fetch_enable_i        (ibex_pkg::IbexMuBiOn),
      .mcounteren_writable_i (ibex_pkg::IbexMuBiOn),
      .alert_minor_o         (),
      .alert_major_internal_o(),
      .alert_major_bus_o     (),
      .core_sleep_o          (),

      .lockstep_cmp_en_o(),

      .data_req_shadow_o       (),
      .data_we_shadow_o        (),
      .data_be_shadow_o        (),
      .data_addr_shadow_o      (),
      .data_wdata_shadow_o     (),
      .data_wdata_intg_shadow_o(),

      .instr_req_shadow_o (),
      .instr_addr_shadow_o()
  );

  // ---------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------
  initial begin
    $readmemh("prog.hex", mem);

    $dumpfile("riscv_ibex_rvfi_trap.fst");
    $dumpvars;

    repeat (4) @(posedge clk);
    rst_n <= 1'b1;

    // Long enough for the program to run to the wfi in the trap handler.
    repeat (300) @(posedge clk);
    $finish;
  end

endmodule
