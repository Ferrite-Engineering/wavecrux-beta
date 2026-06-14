// SPDX-License-Identifier: CC0-1.0
//
// PCIe TLP exerciser — emits a sequence of TLP packets on a 32-bit DW
// AXI-Stream-style interface. Same in-house CC0 pattern as the Avalon
// and JTAG exercisers — no permissively-licensed Verilog testbench for
// a streaming PCIe TLP interface exists in the OSS ecosystem at a size
// that's reasonable to vendor here (Corundum's TLP layer is buried
// inside a multi-thousand-line FPGA SoC).
//
// Packet shapes follow the PCI Express Base Specification (PCI-SIG,
// publicly available headers in PCIe Base Spec §2.2):
//
//   1. Memory Write 32-bit (MWr32) — fmt=010, type=00000, payload=1 DW
//   2. Memory Read 32-bit (MRd32)  — fmt=000, type=00000, no payload
//   3. Completion with Data (CplD) — fmt=010, type=01010, payload=1 DW
//   4. Configuration Write Type 0 (CfgWr0) — fmt=010, type=00100, payload=1 DW
//
// Packets are emitted back-to-back with a 2-cycle idle (tlp_valid=0)
// between each. The 32-bit data path means each TLP DW takes one beat.

`timescale 1 ns / 1 ps

module tb_pcie_tlp_exerciser;
  reg clk = 0;
  reg rst_n = 0;
  always #5 clk = ~clk;  // 100 MHz transaction-layer clock

  reg         tlp_valid = 0;
  reg         tlp_sop   = 0;
  reg         tlp_eop   = 0;
  reg  [31:0] tlp_data  = 32'h0;
  reg         tlp_ready = 1'b1;  // always-ready receiver (no backpressure)

  task send_beat(
    input [31:0] data,
    input        sop,
    input        eop
  );
    begin
      @(posedge clk);
      tlp_valid <= 1'b1;
      tlp_sop   <= sop;
      tlp_eop   <= eop;
      tlp_data  <= data;
    end
  endtask

  task idle(input integer cycles);
    integer i;
    begin
      @(posedge clk);
      tlp_valid <= 1'b0;
      tlp_sop   <= 1'b0;
      tlp_eop   <= 1'b0;
      tlp_data  <= 32'h0;
      for (i = 0; i < cycles - 1; i = i + 1) @(posedge clk);
    end
  endtask

  initial begin
    $dumpfile("tb_pcie_tlp_exerciser.vcd");
    $dumpvars(0, tb_pcie_tlp_exerciser);

    repeat (4) @(posedge clk);
    rst_n <= 1'b1;
    @(posedge clk);

    // 1. MWr32 — write data 0xDEADBEEF to address 0x10000000.
    //    DW0: fmt=010 (3DW header + data), type=00000 (Memory) → 7:5=010, 4:0=00000
    //         tc=0, td=0, ep=0, attr=0, length=1 (DW)
    //         Encoded as 32-bit word with byte 0 in bits[31:24]:
    //         byte0=0x40 (fmt=010,type=00000), byte1=0x00 (tc/td/ep/attr),
    //         byte2=0x00 (length hi), byte3=0x01 (length lo = 1)
    send_beat(32'h40_00_00_01, 1'b1, 1'b0);   // SOP
    //    DW1: requester ID = 0x0100 (bus 1, dev 0, fn 0), tag=0x05,
    //         last DW BE = 0x0, first DW BE = 0xF
    send_beat(32'h01_00_05_0F, 1'b0, 1'b0);
    //    DW2: 32-bit byte-aligned address 0x10000000
    send_beat(32'h10_00_00_00, 1'b0, 1'b0);
    //    DW3: payload = 0xDEADBEEF (1 DW)
    send_beat(32'hDE_AD_BE_EF, 1'b0, 1'b1);   // EOP
    idle(2);

    // 2. MRd32 — read 4 bytes from address 0x20000000
    //    DW0: fmt=000 (3DW header, no data), type=00000, length=1
    send_beat(32'h00_00_00_01, 1'b1, 1'b0);
    //    DW1: requester ID 0x0100, tag=0x06, last BE 0, first BE 0xF
    send_beat(32'h01_00_06_0F, 1'b0, 1'b0);
    //    DW2: addr 0x20000000
    send_beat(32'h20_00_00_00, 1'b0, 1'b1);
    idle(2);

    // 3. CplD — completion with data (1 DW) for the MRd above
    //    DW0: fmt=010 (3DW + data), type=01010 (Completion) → byte0=0x4A,
    //         length=1
    send_beat(32'h4A_00_00_01, 1'b1, 1'b0);
    //    DW1: completer ID 0x0000, status=000 (Successful), BCM=0,
    //         byte count = 0x004 (4 bytes)
    send_beat(32'h00_00_00_04, 1'b0, 1'b0);
    //    DW2: requester ID 0x0100, tag=0x06, lower address bits = 0
    send_beat(32'h01_00_06_00, 1'b0, 1'b0);
    //    DW3: payload data = 0xCAFEBABE
    send_beat(32'hCA_FE_BA_BE, 1'b0, 1'b1);
    idle(2);

    // 4. CfgWr0 — configuration write type 0
    //    DW0: fmt=010 (3DW + data), type=00100 (Cfg Type 0) → byte0=0x44,
    //         length=1
    send_beat(32'h44_00_00_01, 1'b1, 1'b0);
    //    DW1: requester ID 0x0100, tag=0x07, first BE = 0xF
    send_beat(32'h01_00_07_0F, 1'b0, 1'b0);
    //    DW2: completer ID 0x0200 (bus 2 dev 0 fn 0), ext reg = 0,
    //         register number = 0x04 (Command/Status)
    send_beat(32'h02_00_00_04, 1'b0, 1'b0);
    //    DW3: payload data = 0x00000506 (memory-space + bus-master enable +
    //         SERR# enable = 0x506)
    send_beat(32'h00_00_05_06, 1'b0, 1'b1);
    idle(4);

    @(posedge clk);
    tlp_valid <= 1'b0;
    tlp_sop   <= 1'b0;
    tlp_eop   <= 1'b0;

    repeat (4) @(posedge clk);
    $finish;
  end
endmodule
