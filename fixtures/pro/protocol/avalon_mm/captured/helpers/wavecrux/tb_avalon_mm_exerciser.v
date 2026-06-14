// SPDX-License-Identifier: CC0-1.0
//
// Avalon-MM exerciser — single-master, single-slave, pipelined-read
// Avalon-MM bus traffic for decoder testing.
//
// Follows the public Intel "Avalon Interface Specifications" (document
// MNL-AVABUSREF) — clk / address / read / write / waitrequest /
// readdatavalid / writedata / readdata / byteenable / burstcount /
// response semantics.
//
// The DUT is a tiny memory-mapped slave with:
//   - 256 × 32-bit storage at byte-addresses 0x000..0x3FC
//   - 1-cycle waitrequest pulses on every transfer (validates the
//     decoder's waitrequest handling)
//   - 2-cycle readdatavalid latency (pipelined read response)
//   - "response" returned as Avalon 2-bit OKAY/RESERVED/SLAVE_ERROR/
//     DECODE_ERROR; SLAVE_ERROR injected on addresses ≥ 0x400 to
//     exercise the decoder's error-response path
//
// The master walks a small program:
//   1. Single write 0xDEADBEEF → 0x00, all byteenables asserted
//   2. Single read from 0x00 (expect 0xDEADBEEF)
//   3. Single write 0x12345678 → 0x10 with byteenable 4'b0011 (low 16 bits only)
//   4. Single read from 0x10 (expect 0x00005678 — high half left at 0)
//   5. Read from 0x400 — triggers SLAVE_ERROR response
//
// (Burst transfers exercised in the generated/ corpus, not here — the
// decoder's burst-read tracking interacts in nontrivial ways with the
// per-beat readdatavalid timing of a free-running pipelined slave, which
// adds error-class noise that would obscure the single-beat anchors.)
//
// Pipeline: pure iverilog + vvp + vcd2fst.

`timescale 1 ns / 1 ps

module tb_avalon_mm_exerciser;
  // Clock + reset
  reg clk = 0;
  reg reset = 1;
  always #5 clk = ~clk;  // 100 MHz

  // Avalon-MM master → slave wires (master drives address/read/write/writedata/
  // byteenable/burstcount; slave drives readdata/readdatavalid/waitrequest/
  // response).
  reg  [11:0] address;
  reg         read;
  reg         write;
  reg  [31:0] writedata;
  reg  [3:0]  byteenable;
  reg  [3:0]  burstcount;
  wire [31:0] readdata;
  wire        readdatavalid;
  wire        waitrequest;
  wire [1:0]  response;

  // Instantiate the tiny slave model under test.
  avalon_mm_slave_demo slave (
    .clk(clk),
    .reset(reset),
    .address(address),
    .read(read),
    .write(write),
    .writedata(writedata),
    .byteenable(byteenable),
    .burstcount(burstcount),
    .readdata(readdata),
    .readdatavalid(readdatavalid),
    .waitrequest(waitrequest),
    .response(response)
  );

  // ── master command program ─────────────────────────────────────────────

  task do_write(
    input [11:0] addr,
    input [31:0] data,
    input [3:0]  be
  );
    begin
      @(posedge clk);
      address    <= addr;
      writedata  <= data;
      byteenable <= be;
      burstcount <= 4'd1;
      write      <= 1'b1;
      read       <= 1'b0;
      @(posedge clk);
      while (waitrequest) @(posedge clk);
      write      <= 1'b0;
      address    <= 12'b0;
      writedata  <= 32'b0;
      byteenable <= 4'b0;
      burstcount <= 4'd0;
    end
  endtask

  task do_read(
    input [11:0] addr,
    input [3:0]  burst
  );
    begin
      @(posedge clk);
      address    <= addr;
      byteenable <= 4'hF;
      burstcount <= burst;
      read       <= 1'b1;
      write      <= 1'b0;
      @(posedge clk);
      while (waitrequest) @(posedge clk);
      read       <= 1'b0;
      address    <= 12'b0;
      byteenable <= 4'b0;
      burstcount <= 4'd0;
    end
  endtask

  initial begin
    $dumpfile("tb_avalon_mm_exerciser.vcd");
    $dumpvars(0, tb_avalon_mm_exerciser);

    address    = 0;
    read       = 0;
    write      = 0;
    writedata  = 0;
    byteenable = 0;
    burstcount = 0;

    // Hold reset for a few cycles.
    repeat (4) @(posedge clk);
    reset <= 0;
    repeat (2) @(posedge clk);

    // 1. Write 0xDEADBEEF → 0x00
    do_write(12'h000, 32'hDEADBEEF, 4'b1111);
    repeat (2) @(posedge clk);

    // 2. Read 0x00
    do_read(12'h000, 4'd1);
    // Wait for readdatavalid to come back.
    while (!readdatavalid) @(posedge clk);
    @(posedge clk);

    // 3. Partial write 0x12345678 → 0x10, byteenable = lower 16 bits
    do_write(12'h010, 32'h12345678, 4'b0011);
    repeat (2) @(posedge clk);

    // 4. Read 0x10
    do_read(12'h010, 4'd1);
    while (!readdatavalid) @(posedge clk);
    @(posedge clk);

    // 5. Erroring read to 0x400 — slave returns SLAVE_ERROR response
    do_read(12'h400, 4'd1);
    repeat (8) @(posedge clk);

    repeat (4) @(posedge clk);
    $finish;
  end
endmodule

// Tiny Avalon-MM slave model: 256 × 32 bits of storage at byte-addresses
// 0x000..0x3FC. Asserts `waitrequest` for one cycle on every read/write
// transfer, and emits `readdatavalid` two cycles after the accepted read.
// Addresses ≥ 0x400 return SLAVE_ERROR (response = 2'b10) on read.
module avalon_mm_slave_demo (
  input  wire        clk,
  input  wire        reset,
  input  wire [11:0] address,
  input  wire        read,
  input  wire        write,
  input  wire [31:0] writedata,
  input  wire [3:0]  byteenable,
  input  wire [3:0]  burstcount,
  output reg  [31:0] readdata,
  output reg         readdatavalid,
  output reg         waitrequest,
  output reg  [1:0]  response
);
  reg [31:0] mem [0:255];

  reg        rd_pending_d1;
  reg [11:0] rd_addr_d1;
  reg [3:0]  rd_burst_remaining;
  reg [11:0] rd_burst_addr;
  reg        rd_busy;
  reg        rd_error_pending;
  integer    i;

  initial begin
    for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;
  end

  always @(posedge clk) begin
    if (reset) begin
      readdata           <= 32'h0;
      readdatavalid      <= 1'b0;
      waitrequest        <= 1'b0;
      response           <= 2'b00;
      rd_pending_d1      <= 1'b0;
      rd_addr_d1         <= 12'h0;
      rd_burst_remaining <= 4'h0;
      rd_burst_addr      <= 12'h0;
      rd_busy            <= 1'b0;
      rd_error_pending   <= 1'b0;
    end else begin
      // 1-cycle waitrequest pulse on every new transfer.
      if ((read || write) && !waitrequest && !rd_busy) begin
        waitrequest <= 1'b1;
      end else begin
        waitrequest <= 1'b0;
      end

      // Handle write on the accepted cycle (when waitrequest just dropped).
      if (write && !waitrequest) begin
        if (address < 12'h400) begin
          if (byteenable[0]) mem[address[9:2]][7:0]   <= writedata[7:0];
          if (byteenable[1]) mem[address[9:2]][15:8]  <= writedata[15:8];
          if (byteenable[2]) mem[address[9:2]][23:16] <= writedata[23:16];
          if (byteenable[3]) mem[address[9:2]][31:24] <= writedata[31:24];
        end
      end

      // Accept new read on the cycle waitrequest drops.
      if (read && !waitrequest && !rd_busy) begin
        if (address >= 12'h400) begin
          rd_error_pending <= 1'b1;
          rd_addr_d1       <= address;
        end else begin
          rd_pending_d1      <= 1'b1;
          rd_addr_d1         <= address;
          rd_burst_remaining <= burstcount;
          rd_burst_addr      <= address;
          rd_busy            <= (burstcount > 4'd1);
        end
      end

      // 2-cycle readdatavalid latency for OK reads. Continue burst.
      readdatavalid <= 1'b0;
      response      <= 2'b00;
      if (rd_pending_d1) begin
        readdatavalid <= 1'b1;
        readdata      <= mem[rd_addr_d1[9:2]];
        response      <= 2'b00;       // OKAY
        rd_pending_d1 <= 1'b0;
        if (rd_burst_remaining > 4'd1) begin
          rd_burst_remaining <= rd_burst_remaining - 4'd1;
          rd_burst_addr      <= rd_burst_addr + 12'd4;
          rd_pending_d1      <= 1'b1;
          rd_addr_d1         <= rd_burst_addr + 12'd4;
        end else begin
          rd_burst_remaining <= 4'h0;
          rd_busy            <= 1'b0;
        end
      end

      if (rd_error_pending) begin
        readdatavalid    <= 1'b1;
        readdata         <= 32'hDEADBADE;
        response         <= 2'b10;     // SLAVE_ERROR
        rd_error_pending <= 1'b0;
      end
    end
  end
endmodule
