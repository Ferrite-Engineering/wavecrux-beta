// SPDX-License-Identifier: CC0-1.0
//
// Avalon-ST exerciser — single-channel and multi-channel streaming
// traffic for the WaveCrux Pro Avalon-ST decoder.
//
// Follows the public Intel "Avalon Interface Specifications" (document
// MNL-AVABUSREF) — clk / valid / ready / data / startofpacket /
// endofpacket / empty / channel / error semantics.
//
// Like the companion Avalon-MM exerciser, this is an in-house CC0-1.0
// implementation of the documented protocol — no vendor IP is involved.
// See `README.md` in this directory for the rationale (Avalon-ST has no
// permissively-licensed Verilog testbench in the OSS ecosystem).
//
// The source walks five packets, all on a 32-bit (4-byte) data path:
//   1. Single-beat single-channel packet, 4-byte payload
//   2. Two-beat packet on channel 0, 8-byte payload
//   3. Three-beat packet on channel 1 with ready-throttling (sink stalls
//      between beat 1 and beat 2 for 2 cycles)
//   4. Single-beat single-channel packet with `empty=1` (3 valid bytes
//      in the last beat — exercises the empty-on-EOP path)
//   5. Two-beat packet on channel 0 with `error` asserted on the last
//      beat — exercises the error-flag decode path
//
// Pipeline: pure iverilog + vvp + vcd2fst.

`timescale 1 ns / 1 ps

module tb_avalon_st_exerciser;
  // Clock + reset
  reg clk = 0;
  reg reset = 1;
  always #5 clk = ~clk;  // 100 MHz

  // Avalon-ST source → sink wires.
  reg         valid;
  reg  [31:0] data;
  reg         startofpacket;
  reg         endofpacket;
  reg  [1:0]  empty;
  reg  [3:0]  channel;
  reg         error;

  // Sink ready handshake — driven by the sink module.
  wire        ready;

  // Instantiate a tiny pass-through sink so the FST captures the full
  // Avalon-ST handshake. (No data is consumed beyond observation; the
  // sink just drives the `ready` signal back to the source.)
  avalon_st_sink_demo sink (
    .clk(clk),
    .reset(reset),
    .valid(valid),
    .data(data),
    .startofpacket(startofpacket),
    .endofpacket(endofpacket),
    .empty(empty),
    .channel(channel),
    .error(error),
    .ready(ready)
  );

  // ── source helpers ────────────────────────────────────────────────────

  task drive_beat(
    input [31:0] beat_data,
    input        sop,
    input        eop,
    input [1:0]  beat_empty,
    input [3:0]  beat_channel,
    input        beat_error
  );
    begin
      @(posedge clk);
      valid         <= 1'b1;
      data          <= beat_data;
      startofpacket <= sop;
      endofpacket   <= eop;
      empty         <= beat_empty;
      channel       <= beat_channel;
      error         <= beat_error;
      // Wait for the sink to assert ready on the same cycle.
      while (!ready) @(posedge clk);
      // Hold for one full ready-asserted cycle, then deassert valid.
      @(posedge clk);
      valid         <= 1'b0;
      startofpacket <= 1'b0;
      endofpacket   <= 1'b0;
      empty         <= 2'b00;
      channel       <= 4'h0;
      error         <= 1'b0;
    end
  endtask

  task idle(input integer cycles);
    integer i;
    begin
      for (i = 0; i < cycles; i = i + 1) @(posedge clk);
    end
  endtask

  initial begin
    $dumpfile("tb_avalon_st_exerciser.vcd");
    $dumpvars(0, tb_avalon_st_exerciser);

    valid         = 0;
    data          = 0;
    startofpacket = 0;
    endofpacket   = 0;
    empty         = 0;
    channel       = 0;
    error         = 0;

    repeat (4) @(posedge clk);
    reset <= 0;
    repeat (2) @(posedge clk);

    // The sink will drive ready high all the time except during the
    // ready-throttling section below.
    sink.throttle_cycles = 0;

    // Packet 1 — single-beat, channel 0, 4-byte payload "ABCD".
    drive_beat(32'h41424344, 1'b1, 1'b1, 2'b00, 4'h0, 1'b0);
    idle(3);

    // Packet 2 — two-beat, channel 0, 8-byte payload.
    drive_beat(32'h12345678, 1'b1, 1'b0, 2'b00, 4'h0, 1'b0);
    drive_beat(32'hAABBCCDD, 1'b0, 1'b1, 2'b00, 4'h0, 1'b0);
    idle(3);

    // Packet 3 — three-beat on channel 1, with sink stalling 2 cycles
    // between beat 1 and beat 2 to exercise the ready-throttle path.
    drive_beat(32'h01010101, 1'b1, 1'b0, 2'b00, 4'h1, 1'b0);
    sink.throttle_cycles = 2;
    drive_beat(32'h02020202, 1'b0, 1'b0, 2'b00, 4'h1, 1'b0);
    sink.throttle_cycles = 0;
    drive_beat(32'h03030303, 1'b0, 1'b1, 2'b00, 4'h1, 1'b0);
    idle(3);

    // Packet 4 — single-beat with empty=1 (3 valid bytes in the last
    // beat — the low byte is the padded-out byte per Avalon-ST spec).
    drive_beat(32'hDEAD_BEEF, 1'b1, 1'b1, 2'b01, 4'h0, 1'b0);
    idle(3);

    // Packet 5 — two-beat with error asserted on the EOP beat.
    drive_beat(32'h11223344, 1'b1, 1'b0, 2'b00, 4'h0, 1'b0);
    drive_beat(32'hFFFFFFFF, 1'b0, 1'b1, 2'b00, 4'h0, 1'b1);
    idle(5);

    $finish;
  end
endmodule

// Tiny Avalon-ST sink: drives `ready` high in steady state, with an
// optional `throttle_cycles` counter that holds ready low for that many
// cycles after the next `valid` rising edge (exercises the source's
// ready-pacing path). Doesn't store the data — just observes the
// handshake.
module avalon_st_sink_demo (
  input  wire        clk,
  input  wire        reset,
  input  wire        valid,
  input  wire [31:0] data,
  input  wire        startofpacket,
  input  wire        endofpacket,
  input  wire [1:0]  empty,
  input  wire [3:0]  channel,
  input  wire        error,
  output reg         ready
);
  integer throttle_cycles;
  integer throttling;

  initial begin
    ready           = 1'b0;
    throttle_cycles = 0;
    throttling      = 0;
  end

  always @(posedge clk) begin
    if (reset) begin
      ready      <= 1'b0;
      throttling <= 0;
    end else begin
      // If the source raised valid this cycle AND a throttle window is
      // configured, hold ready low for `throttle_cycles` cycles.
      if (valid && !ready && throttle_cycles > 0 && throttling == 0) begin
        throttling <= throttle_cycles;
        ready      <= 1'b0;
      end else if (throttling > 0) begin
        throttling <= throttling - 1;
        ready      <= 1'b0;
      end else begin
        ready      <= 1'b1;
      end
    end
  end
endmodule
