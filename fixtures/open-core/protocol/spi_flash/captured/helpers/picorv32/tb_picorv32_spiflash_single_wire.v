// SPDX-License-Identifier: 0BSD
//
// Single-wire SPI exercise around Claire Wolf's picorv32/picosoc/spiflash.v
// model (ISC, vendored from picorv32 commit pinned in PROVENANCE.md).
//
// The model itself is a behavioral SPI/QSPI/DDR-QSPI flash that supports
// 0xFF Reset, 0xAB Power Up, 0xB9 Deep Sleep, 0x03 single-wire READ,
// 0xBB/0xEB/0xED dual/quad/DDR reads. The wavecrux SPI-Flash decoder is
// documented as single-wire only, so this testbench exercises just the
// three single-wire commands: Reset → Power Up → READ at offset 0x100000.
//
// Compared with the upstream `spiflash_tb.v`, we drop the QSPI / DDR-QSPI
// sections (which would generate garbled output from a single-wire
// decoder), and finish via `$finish` after the READ. Firmware.hex places
// the recognizable byte sequence `93 00 00 00 93 01 00 00` at offset
// 0x100000 so the READ data bytes are non-X.

`timescale 1 ns / 1 ps

module tb_picorv32_spiflash_single_wire;
  reg flash_csb = 1;
  reg flash_clk = 0;

  wire flash_io0;
  wire flash_io1;
  wire flash_io2;
  wire flash_io3;

  reg flash_io0_oe = 0;
  reg flash_io0_dout = 0;

  // Single-wire framing: io0 = MOSI (driven by master), io1 = MISO (driven
  // by flash model). io2/io3 are high-Z.
  assign flash_io0 = flash_io0_oe ? flash_io0_dout : 1'bz;

  spiflash uut (
    .csb(flash_csb),
    .clk(flash_clk),
    .io0(flash_io0),
    .io1(flash_io1),
    .io2(flash_io2),
    .io3(flash_io3)
  );

  task xfer_begin;
    begin
      #5;
      flash_csb = 0;
      #5;
    end
  endtask

  task xfer_end;
    begin
      #5;
      flash_csb = 1;
      flash_io0_oe = 0;
      #5;
    end
  endtask

  // Single-wire SPI byte transfer (MSB-first). MOSI driven on io0; MISO
  // sampled from io1. Matches the upstream picorv32 spiflash_tb encoding.
  task xfer_spi;
    input [7:0] data;
    integer i;
    begin
      flash_io0_oe = 1;
      for (i = 0; i < 8; i = i + 1) begin
        flash_io0_dout = data[7 - i];
        #5;
        flash_clk = 1;
        #5;
        flash_clk = 0;
      end
      #5;
    end
  endtask

  initial begin
    $dumpfile("tb_picorv32_spiflash_single_wire.vcd");
    $dumpvars(0, tb_picorv32_spiflash_single_wire);

    // 1) Reset (0xFF)
    xfer_begin;
    xfer_spi(8'hFF);
    xfer_end;

    // 2) Power Up (0xAB) — required before READ
    xfer_begin;
    xfer_spi(8'hAB);
    xfer_end;

    // 3) READ (0x03) at 24-bit address 0x100000, 8 data bytes
    xfer_begin;
    xfer_spi(8'h03);
    xfer_spi(8'h10);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_spi(8'h00);
    xfer_end;

    #20;
    $finish;
  end
endmodule
