// SPDX-License-Identifier: CC0-1.0
//
// CAN 2.0A exerciser — emits a Classical-CAN Standard Data Frame on
// can_rx. In-house CC0 pattern: most OSS CAN cores live behind GPL/
// LGPL/Bosch refmodel licenses that conflict with this corpus's
// allow-list (see helpers/README.md).
//
// Bit timing: 500 kbit/s nominal → 2 µs/bit.
//
// Frame emitted: Standard Data Frame, ID = 0x123, DLC = 2, data bytes
// = 0xAB 0xCD. The CRC15 over the SOF + ID + control + data fields is
// computed on-the-fly.
//
// IMPORTANT — no bit stuffing. The wavecrux CAN decoder operates on the
// de-stuffed application-layer signal (see decoder source — the comment
// at the "bit stuffing note" line explains that simulation VCDs record
// the controller's logical signal, not the raw physical bus). We emit
// raw logical bits 1-to-1 here; the decoder consumes them without
// destuffing.

`timescale 1 ns / 1 ps

module tb_can_exerciser;
  // Bus is recessive (1) when idle.
  reg can_rx = 1'b1;

  // 2 µs / bit = 500 kbit/s. The decoder auto-derives from first SOF.
  parameter integer BIT_NS = 2000;

  // Frame fields (Classical CAN 2.0A Standard Data Frame).
  localparam [10:0] FRAME_ID = 11'h123;
  localparam [3:0]  DLC      = 4'd2;
  localparam [15:0] DATA     = 16'hABCD;

  // ── CRC15 computation ─────────────────────────────────────────────────────
  // Poly: x^15+x^14+x^10+x^8+x^7+x^4+x^3+1 = 0xC599 / shifted = 0x4599
  // Matches the wavecrux generator's _crc15 (and the decoder's
  // _computeCanCrc15) bit-for-bit: shift in `bit_in` at the LSB, then
  // XOR with the polynomial if (top ^ bit_in) was set.
  function automatic [14:0] crc15_step;
    input [14:0] crc_in;
    input        bit_in;
    reg          top;
    reg [14:0]   shifted;
    begin
      top = crc_in[14];
      shifted = ((crc_in << 1) | (bit_in & 1)) & 15'h7FFF;
      crc15_step = (top ^ bit_in) ? (shifted ^ 15'h4599) : shifted;
    end
  endfunction

  // ── bit-time helpers ──────────────────────────────────────────────────────
  reg [14:0] crc_acc;
  integer    i;

  task drive_bit(input b, input also_crc);
    begin
      can_rx = b;
      if (also_crc) crc_acc = crc15_step(crc_acc, b);
      #BIT_NS;
    end
  endtask

  // Emit a multi-bit field MSB-first.
  task drive_field(input [31:0] data, input integer width, input also_crc);
    integer k;
    begin
      for (k = width - 1; k >= 0; k = k - 1)
        drive_bit(data[k], also_crc);
    end
  endtask

  initial begin
    $dumpfile("tb_can_exerciser.vcd");
    $dumpvars(0, tb_can_exerciser);

    can_rx        = 1'b1;
    crc_acc       = 15'h0;

    // Hold recessive for an IFS-equivalent gap before the frame.
    #(8 * BIT_NS);

    // ── Standard Data Frame (ISO 11898-1 Classical CAN 2.0A):
    //    SOF | ID(11) | RTR | IDE | r0 | DLC(4) | Data(8*DLC) | CRC(15) |
    //    CRC-delim | ACK | ACK-delim | EOF(7) | IFS(3).
    // No FDF bit in classical CAN — the bit after r0 is the first DLC bit.
    drive_bit(1'b0, 1'b1);           // SOF (dominant)
    drive_field({21'b0, FRAME_ID}, 11, 1'b1);  // 11-bit identifier
    drive_bit(1'b0, 1'b1);           // RTR = 0 (data frame)
    drive_bit(1'b0, 1'b1);           // IDE = 0 (standard)
    drive_bit(1'b0, 1'b1);           // r0  = 0 (reserved dominant)
    drive_field({28'b0, DLC}, 4, 1'b1);  // DLC = 2
    drive_field({16'b0, DATA}, 16, 1'b1);  // 2 data bytes (16 bits MSB-first)

    // CRC field — emit the computed 15-bit CRC.
    drive_field({17'b0, crc_acc}, 15, 1'b0);  // not CRC-tracked further

    // CRC delimiter (1 bit, recessive) — bit stuffing OFF from here.
    can_rx = 1'b1;
    #BIT_NS;

    // ACK slot — drive dominant to simulate a successful receiver ACK.
    // (The wavecrux CAN decoder expects ACK to be dominant for a healthy
    // frame; leaving it recessive flags the frame as truncated.)
    can_rx = 1'b0;
    #BIT_NS;

    // ACK delimiter (1 bit recessive)
    can_rx = 1'b1;
    #BIT_NS;

    // EOF (7 bits recessive)
    for (i = 0; i < 7; i = i + 1) begin
      can_rx = 1'b1;
      #BIT_NS;
    end

    // IFS (3 bits recessive)
    for (i = 0; i < 3; i = i + 1) begin
      can_rx = 1'b1;
      #BIT_NS;
    end

    // Trailing idle.
    #(8 * BIT_NS);
    $finish;
  end
endmodule
