# JTAG captured-fixture helpers (own TAP exerciser)

The JTAG captured fixture (`wavecrux_jtag_tap_exerciser.fst`) exercises
an in-house pure-Verilog IEEE 1149.1 TAP plus a small driver. SPDX
`CC0-1.0`. Same rationale as the Avalon-MM/ST exercisers — most
OSS JTAG TAP cores live inside larger debug-module repos behind
heavier license footprints (Solderpad, LGPL, etc.) or under SystemVerilog
constructs iverilog can't compile.

## Files committed here

- `tb_jtag_tap_exerciser.v` — TAP module + driver:
  - TAP implements the full 16-state IEEE 1149.1 state machine with
    a 4-bit IR that recognises IDCODE (0x1) and BYPASS (0xF).
  - IDCODE register holds the constant `0x_DEAD_BEEF` (bit 0 = 1, per
    IEEE 1149.1 §6.1.1.2 mandate).
  - On `trst_n` deassertion, `ir` resets to IDCODE per spec.
  - Driver walks: TLR via 5 TMS=1 → load IDCODE in IR → 32-bit DR shift
    of IDCODE → load BYPASS in IR → 4-bit shift `1010` through BYPASS →
    return to TLR.
- `Makefile` — `make` builds + runs; `make install` mirrors the FST
  into both fixture trees.

## Decoded stream

| t (ns)        | Decoded             | Notes                                              |
|---------------|---------------------|----------------------------------------------------|
| 110 → 170     | `IR = 0x8`          | TDI bits `1000 (MSB first)` = `0001` LSB-first = IDCODE instruction |
| 200 → 540     | `DR = 0x... (32 bits)` | IDCODE register, 32-bit shift                  |
| 580 → 640     | `IR = 0xF`          | TDI bits `1111` = BYPASS instruction              |
| 670 → 730     | `DR = 0x5 (4 bits)` | TDI `0101 (MSB first)` = `1010` LSB-first; bypass register output trails TDI by one cycle |

The MSB-first hex displayed by the decoder is the shift-order
interpretation (first bit shifted is shown as the MSB of the hex
value). LSB-first interpretation can be derived by reversing the bit
order — for example, the IR's `0x8 (1000 MSB-first)` corresponds to
`0x1 (0001 LSB-first)`, the standard IDCODE opcode.

## TDO timing — IEEE 1149.1 §6.2.1.1 compliance

TDO is a registered output that updates only on the **falling** edge of
TCK ("data on TDO shall change only on the negative edge of TCK"). The
exerciser models this with an explicit `tdo_reg` flip-flop driven by an
`always @(negedge tck or negedge trst_n)` block, so the simulation
matches real-silicon timing: at each rising TCK the value the master
samples on TDO is the LSB of the shift register *before* this edge's
shift, not the combinational post-shift value. An earlier revision
used `assign tdo = ...` (combinational); that worked under the iverilog
simulator but shifted every captured DR value right by one bit when
fed through the decoder. Fixed 2026-05-31 alongside this corpus's
real-world-correctness pass.

The `PASS: IDCODE = 0xDEADBEEF` line in the simulator output confirms
the driver-side TDO sampling matches the planted IDCODE round-trip.
