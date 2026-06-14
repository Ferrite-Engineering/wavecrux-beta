// SPDX-License-Identifier: CC0-1.0
//
// JTAG TAP exerciser — drives a small IEEE 1149.1 TAP through IDCODE
// and BYPASS sequences for decoder testing.
//
// Like the Avalon exercisers, this is an in-house CC0-1.0
// implementation of the published protocol (IEEE 1149.1) — no vendor
// IP is involved. See `README.md` in this directory for the rationale.
//
// The TAP exposes a 4-bit IR with two recognised instructions:
//   0x1 IDCODE — exposes a 32-bit ID register (0xDEADBEEF, with bit 0 = 1
//                per IEEE 1149.1 §6.1.1.2 mandatory `1` in IDCODE LSB)
//   0xF BYPASS — exposes a 1-bit bypass register
//
// The driver walks the TAP through:
//   1. Test-Logic-Reset via 5 TMS=1 clocks
//   2. Run-Test/Idle
//   3. Capture-IR → Shift-IR → load `0001` (IDCODE) → Update-IR
//   4. Capture-DR → Shift-DR → shift out 32 bits of IDCODE → Update-DR
//   5. Capture-IR → Shift-IR → load `1111` (BYPASS) → Update-IR
//   6. Capture-DR → Shift-DR → shift `1 0 1 0` through BYPASS (4 bits) → Update-DR
//   7. Test-Logic-Reset

`timescale 1 ns / 1 ps

module tb_jtag_tap_exerciser;
  reg tck = 0;
  reg tms = 1;
  reg tdi = 0;
  wire tdo;
  reg trst_n = 0;

  jtag_tap_demo dut (
    .tck(tck),
    .tms(tms),
    .tdi(tdi),
    .tdo(tdo),
    .trst_n(trst_n)
  );

  task tick(input [0:0] tms_val, input [0:0] tdi_val);
    begin
      tms <= tms_val;
      tdi <= tdi_val;
      #5 tck = 1;
      #5 tck = 0;
    end
  endtask

  integer i;
  reg [31:0] idcode_observed;
  reg [3:0]  bypass_pattern;
  reg [3:0]  bypass_observed;

  initial begin
    $dumpfile("tb_jtag_tap_exerciser.vcd");
    $dumpvars(0, tb_jtag_tap_exerciser);

    tck = 0; tms = 1; tdi = 0; trst_n = 0;
    #20 trst_n = 1;
    #5;

    // 1. Reach Test-Logic-Reset via 5 TMS=1 clocks (TAP recovers from
    //    any unknown state within 5 such cycles per IEEE 1149.1 §6.1).
    for (i = 0; i < 5; i = i + 1) tick(1'b1, 1'b0);

    // 2. Test-Logic-Reset → Run-Test/Idle: TMS=0
    tick(1'b0, 1'b0);

    // 3. Capture-IR → Shift-IR → load IDCODE (4'b0001) LSB-first → Update-IR
    tick(1'b1, 1'b0);   // Run-Test/Idle → Select-DR-Scan
    tick(1'b1, 1'b0);   // Select-DR-Scan → Select-IR-Scan
    tick(1'b0, 1'b0);   // Select-IR-Scan → Capture-IR
    tick(1'b0, 1'b0);   // Capture-IR → Shift-IR
    tick(1'b0, 1'b1);   // Shift-IR bit 0 = 1
    tick(1'b0, 1'b0);   // Shift-IR bit 1 = 0
    tick(1'b0, 1'b0);   // Shift-IR bit 2 = 0
    tick(1'b1, 1'b0);   // Shift-IR bit 3 = 0  (TMS=1 exits Shift-IR → Exit1-IR)
    tick(1'b1, 1'b0);   // Exit1-IR → Update-IR
    tick(1'b0, 1'b0);   // Update-IR → Run-Test/Idle

    // 4. Capture-DR → Shift-DR → shift 32 bits → Update-DR
    tick(1'b1, 1'b0);   // Run-Test/Idle → Select-DR-Scan
    tick(1'b0, 1'b0);   // Select-DR-Scan → Capture-DR
    tick(1'b0, 1'b0);   // Capture-DR → Shift-DR

    idcode_observed = 32'b0;
    for (i = 0; i < 31; i = i + 1) begin
      tick(1'b0, 1'b0);
      // Sample TDO at the rising edge of TCK: it's now stable.
      idcode_observed[i] = tdo;
    end
    // Final bit + leave Shift-DR
    tick(1'b1, 1'b0);   // Shift-DR last bit + exit to Exit1-DR
    idcode_observed[31] = tdo;
    tick(1'b1, 1'b0);   // Exit1-DR → Update-DR
    tick(1'b0, 1'b0);   // Update-DR → Run-Test/Idle

    if (idcode_observed === 32'hDEADBEEF) begin
      $display("PASS: IDCODE = 0xDEADBEEF");
    end else begin
      $display("INFO: IDCODE observed = %h (expected 0xDEADBEEF)", idcode_observed);
    end

    // 5. Capture-IR → Shift-IR → load BYPASS (4'b1111) LSB-first → Update-IR
    tick(1'b1, 1'b0);   // Run-Test/Idle → Select-DR-Scan
    tick(1'b1, 1'b0);   // Select-DR-Scan → Select-IR-Scan
    tick(1'b0, 1'b0);   // Select-IR-Scan → Capture-IR
    tick(1'b0, 1'b0);   // Capture-IR → Shift-IR
    tick(1'b0, 1'b1);   // Shift-IR bit 0 = 1
    tick(1'b0, 1'b1);   // Shift-IR bit 1 = 1
    tick(1'b0, 1'b1);   // Shift-IR bit 2 = 1
    tick(1'b1, 1'b1);   // Shift-IR bit 3 = 1 (TMS=1 exits Shift-IR)
    tick(1'b1, 1'b0);   // Exit1-IR → Update-IR
    tick(1'b0, 1'b0);   // Update-IR → Run-Test/Idle

    // 6. Capture-DR → Shift-DR → shift `1 0 1 0` through BYPASS, observe
    //    the bypass register's previous-bit output. BYPASS resets to 0,
    //    so first observed bit is 0; subsequent bits trail TDI by one.
    bypass_pattern = 4'b1010;
    bypass_observed = 4'b0;
    tick(1'b1, 1'b0);   // Run-Test/Idle → Select-DR-Scan
    tick(1'b0, 1'b0);   // Select-DR-Scan → Capture-DR
    tick(1'b0, 1'b0);   // Capture-DR → Shift-DR
    for (i = 0; i < 3; i = i + 1) begin
      tick(1'b0, bypass_pattern[i]);
      bypass_observed[i] = tdo;
    end
    tick(1'b1, bypass_pattern[3]);  // last bit + exit Shift-DR
    bypass_observed[3] = tdo;
    tick(1'b1, 1'b0);   // Exit1-DR → Update-DR
    tick(1'b0, 1'b0);   // Update-DR → Run-Test/Idle

    $display("INFO: BYPASS pattern = %b, observed = %b", bypass_pattern, bypass_observed);

    // 7. Back to Test-Logic-Reset
    for (i = 0; i < 5; i = i + 1) tick(1'b1, 1'b0);

    #20 $finish;
  end
endmodule

// IEEE 1149.1 TAP with two recognised instructions: IDCODE (0x1) and
// BYPASS (0xF). On reset, IR = IDCODE (mandated by the standard).
module jtag_tap_demo (
  input  wire tck,
  input  wire tms,
  input  wire tdi,
  output wire tdo,
  input  wire trst_n
);
  // State encoding per IEEE 1149.1 §6.1 (16-state TAP controller).
  localparam [3:0]
    TLR     = 4'h0, // Test-Logic-Reset
    RTI     = 4'h1, // Run-Test/Idle
    SDRS    = 4'h2, // Select-DR-Scan
    CDR     = 4'h3, // Capture-DR
    SHDR    = 4'h4, // Shift-DR
    EX1DR   = 4'h5, // Exit1-DR
    PDR     = 4'h6, // Pause-DR
    EX2DR   = 4'h7, // Exit2-DR
    UDR     = 4'h8, // Update-DR
    SIRS    = 4'h9, // Select-IR-Scan
    CIR     = 4'hA, // Capture-IR
    SHIR    = 4'hB, // Shift-IR
    EX1IR   = 4'hC, // Exit1-IR
    PIR     = 4'hD, // Pause-IR
    EX2IR   = 4'hE, // Exit2-IR
    UIR     = 4'hF; // Update-IR

  reg [3:0] state;
  reg [3:0] ir_shift;
  reg [3:0] ir;
  reg [31:0] idcode_shift;
  reg        bypass_reg;

  localparam [3:0] INSTR_IDCODE = 4'h1;
  localparam [3:0] INSTR_BYPASS = 4'hF;
  localparam [31:0] IDCODE_VALUE = 32'hDEADBEEF;

  // TDO is registered and updated on the FALLING edge of TCK per
  // IEEE 1149.1 §6.2.1.1 ("data on TDO shall change only on the negative
  // edge of TCK"). Combinational TDO would change on rising edges during
  // the NBA settle, which is non-conformant and shifts every captured
  // value right by one bit at the protocol decoder.
  reg tdo_reg = 1'b0;
  assign tdo = tdo_reg;

  always @(negedge tck or negedge trst_n) begin
    if (!trst_n) begin
      tdo_reg <= 1'b0;
    end else begin
      case (state)
        SHIR: tdo_reg <= ir_shift[0];
        SHDR: tdo_reg <= (ir == INSTR_IDCODE) ? idcode_shift[0] : bypass_reg;
        default: tdo_reg <= 1'b0;
      endcase
    end
  end

  always @(posedge tck or negedge trst_n) begin
    if (!trst_n) begin
      state       <= TLR;
      ir_shift    <= 4'h0;
      ir          <= INSTR_IDCODE; // mandated by IEEE 1149.1 §6.1.1.1.b
      idcode_shift<= 32'h0;
      bypass_reg  <= 1'b0;
    end else begin
      case (state)
        TLR:   state <= tms ? TLR  : RTI;
        RTI:   state <= tms ? SDRS : RTI;
        SDRS:  state <= tms ? SIRS : CDR;
        CDR: begin
          state <= tms ? EX1DR : SHDR;
          if (ir == INSTR_IDCODE) idcode_shift <= IDCODE_VALUE;
          else                    bypass_reg   <= 1'b0;
        end
        SHDR: begin
          if (ir == INSTR_IDCODE) idcode_shift <= {1'b0, idcode_shift[31:1]};
          else                    bypass_reg   <= tdi;
          state <= tms ? EX1DR : SHDR;
        end
        EX1DR: state <= tms ? UDR : PDR;
        PDR:   state <= tms ? EX2DR : PDR;
        EX2DR: state <= tms ? UDR : SHDR;
        UDR:   state <= tms ? SDRS : RTI;
        SIRS:  state <= tms ? TLR  : CIR;
        CIR: begin
          ir_shift <= ir;
          state <= tms ? EX1IR : SHIR;
        end
        SHIR: begin
          ir_shift <= {tdi, ir_shift[3:1]};
          state <= tms ? EX1IR : SHIR;
        end
        EX1IR: state <= tms ? UIR : PIR;
        PIR:   state <= tms ? EX2IR : PIR;
        EX2IR: state <= tms ? UIR : SHIR;
        UIR: begin
          ir <= ir_shift;
          state <= tms ? SDRS : RTI;
        end
        default: state <= TLR;
      endcase
    end
  end
endmodule
