// SPDX-License-Identifier: 0BSD
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// Pure-Verilog testbench wrapping Mohamed Shalan's MS_DMAC_AHBL DMA
// controller (vendored verbatim from shalan/MS_DMAC_AHBL, Apache-2.0).
// The DMAC has two AHB-Lite interfaces:
//
//   * Slave interface (HSEL/HADDR/HTRANS/...) — exposes its config
//     registers (CTRL, STATUS, SADDR, DADDR, SIZE, TRIG).
//   * Master interface (M_HADDR/M_HTRANS/...) — drives the actual data
//     movement on the bus.
//
// The captured FST is intended to feed the WaveCrux AHB-Lite decoder
// against the **master** interface — that's where the real bus traffic
// lives: a series of SINGLE reads from the source region followed by
// SINGLE writes to the destination region. Because the upstream DMAC
// doesn't model burst transfers or error responses, HBURST and HRESP
// are tied to constants (SINGLE / OKAY) at the testbench level and
// exposed as named wires so the decoder can bind them.
//
// Stimulus shape:
//   1. Reset HCLK + HRESETn (active-low).
//   2. Configure the DMAC: SADDR=0x40000000, DADDR=0x50000000, SIZE=4
//      words, CTRL=word/word + auto-increment both ends + EN.
//   3. Software-trigger via TRIG_REG (offset 0x14).
//   4. Let the DMAC march through 4 read+write beats on M_*.
//   5. $finish.
//
// The master-side "memory" is a trivial combinational model: every
// read returns 0xC0FFEE00 | byte_offset, every write is silently
// accepted. M_HREADY tied high (no wait states); M_HRESP tied low
// (no errors). That keeps the decoded fixture deterministic.

`timescale 1 ns / 1 ps
`default_nettype none

module tb_ms_dmac_ahbl;

    // ── tb clock + active-low reset ─────────────────────────────────
    reg        HCLK    = 1'b0;
    reg        HRESETn = 1'b0;
    always #10 HCLK = ~HCLK;          // 50 MHz HCLK

    // ── DMAC slave-interface signals (CPU side) ─────────────────────
    reg         HSEL    = 1'b0;
    reg  [31:0] HADDR   = 32'h0;
    reg  [1:0]  HTRANS  = 2'b00;
    reg         HWRITE  = 1'b0;
    reg         HREADY  = 1'b1;
    reg  [31:0] HWDATA  = 32'h0;
    reg  [2:0]  HSIZE   = 3'b010;     // 32-bit transfers (word)
    wire        HREADYOUT;
    wire [31:0] HRDATA;

    // ── DMAC master-interface signals (memory side) ─────────────────
    wire [31:0] M_HADDR;
    wire [1:0]  M_HTRANS;
    wire [2:0]  M_HSIZE;
    wire        M_HWRITE;
    wire [31:0] M_HWDATA;
    wire        M_HREADY = 1'b1;       // no wait states
    wire [31:0] M_HRDATA;

    // ── decoder bindings — AHB-Lite extras the DMAC doesn't model ───
    // The WaveCrux AHB-Lite decoder requires HBURST and HRESP bindings.
    // The DMAC issues only SINGLE-beat transfers and never raises an
    // error response, so both are constant; we expose them as named
    // wires so the decoder sees stable values throughout the trace.
    wire [2:0]  M_HBURST = 3'b000;     // SINGLE
    wire        M_HRESP  = 1'b0;        // OKAY

    wire        IRQ;

    // ── tiny combinational master-side "memory" ─────────────────────
    // The DMAC reads from M_HADDR; we return 0xC0FFEE00 | byte-offset
    // so consecutive read beats produce 0xC0FFEE00, 0xC0FFEE04, …
    // The DMAC writes to M_HADDR; we silently accept and tie M_HREADY
    // permanently high.
    assign M_HRDATA = {24'hC0FFEE, M_HADDR[7:0]};

    // ── DUT ─────────────────────────────────────────────────────────
    MS_DMAC_AHBL DUV (
        .HCLK(HCLK),
        .HRESETn(HRESETn),

        .IRQ(IRQ),

        // Slave interface
        .HSEL(HSEL),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HREADY(HREADY),
        .HWDATA(HWDATA),
        .HSIZE(HSIZE),
        .HREADYOUT(HREADYOUT),
        .HRDATA(HRDATA),

        // Master interface
        .M_HADDR(M_HADDR),
        .M_HTRANS(M_HTRANS),
        .M_HSIZE(M_HSIZE),
        .M_HWRITE(M_HWRITE),
        .M_HWDATA(M_HWDATA),
        .M_HREADY(M_HREADY),
        .M_HRDATA(M_HRDATA)
    );

    // ── AHB-Lite slave-side write task (CPU configures the DMAC) ────
    task ahbl_w_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            wait (HREADYOUT == 1'b1);
            @(posedge HCLK); #1;
            HSEL   = 1'b1;
            HTRANS = 2'b10;             // NONSEQ
            HADDR  = addr;
            HWRITE = 1'b1;
            HSIZE  = 3'b010;            // word
            @(posedge HCLK);
            HWDATA = data;
            HSEL   = 1'b0;
            HTRANS = 2'b00;             // IDLE
            #2;
            wait (HREADYOUT == 1'b1);
        end
    endtask

    // ── stimulus ────────────────────────────────────────────────────
    initial begin
        $dumpfile("ahb_lite_shalan_dmac.fst");
        $dumpvars(0, tb_ms_dmac_ahbl);

        // Hold reset.
        #100;
        @(posedge HCLK) HRESETn = 1'b1;
        repeat (5) @(posedge HCLK);

        // Configure DMAC. CTRL register field layout (per the actual
        // RTL, which differs from the file-header comment block):
        //   bit  0     : EN
        //   bits[11:8] : TRIGGER  (unused in the SW-trigger flow)
        //   bits[17:16]: SRC_TYPE (0=byte, 1=half, 2=word)
        //   bits[20:18]: SRC_AI   (auto-increment stride in bytes;
        //                          0=none, 1=byte, 2=half, 4=word)
        //   bits[25:24]: DEST_TYPE
        //   bits[28:26]: DEST_AI
        //
        // For a 4-word DMA from 0x4000_0000 to 0x5000_0000, word-typed
        // on both sides with word-stride auto-increment:
        //   EN=1, SRC_TYPE=2, SRC_AI=4, DEST_TYPE=2, DEST_AI=4
        //   → (4<<26) | (2<<24) | (4<<18) | (2<<16) | 1 = 0x12120001
        ahbl_w_write(32'h0000_0008, 32'h4000_0000);  // SADDR
        ahbl_w_write(32'h0000_000C, 32'h5000_0000);  // DADDR
        ahbl_w_write(32'h0000_0010, 32'h0000_0004);  // SIZE = 4
        ahbl_w_write(32'h0000_0000, 32'h1212_0001);  // CTRL

        // SW-trigger the DMA. Write any value with bit 0 = 1.
        ahbl_w_write(32'h0000_0014, 32'h0000_0001);

        // Wait for completion. IRQ rises when done.
        @(posedge IRQ);
        repeat (10) @(posedge HCLK);

        $finish;
    end

    // ── safety timeout ──────────────────────────────────────────────
    initial begin
        #200000;
        $display("FATAL: tb timeout — DMA did not complete");
        $finish;
    end

endmodule
