# AHB-Lite captured-fixture helpers (shalan MS_DMAC_AHBL)

The AHB-Lite captured fixture (`ahb_lite_shalan_dmac.fst`) wraps
Mohamed Shalan's `MS_DMAC_AHBL` DMA controller (Apache-2.0) — a real
educational/ASIC-grade AHB-Lite IP with both slave and master ports —
in a hand-written pure-Verilog testbench. The testbench configures
the DMAC's slave port (CTRL/SADDR/DADDR/SIZE + software trigger) and
captures the master port, where the DMAC drives the actual word
reads from `0x4000_0000` and writes to `0x5000_0000`.

Why this source: the obvious first candidate for an AHB-Lite capture
was OpenTitan's `hw/ip/...` library, but OpenTitan's verification
flow is UVM-based (Synopsys VCS), which iverilog and verilator
don't support. Mohamed Shalan's MS_DMAC_AHBL ships clean
Apache-2.0 Verilog RTL with no UVM dependency, matches the
"vendor the RTL + write our own testbench" pattern used for the
picorv32 (Wishbone, RISC-V), apb (wb2axip), and i2c (forencich)
captures, and exposes both AHB-Lite roles in a single module so a
single testbench produces meaningful bus traffic.

The DMAC implements only SINGLE-beat transfers and never raises an
error response, so HBURST and HRESP (both required by the WaveCrux
AHB-Lite decoder) are tied to constants (`SINGLE` / `OKAY`) in the
testbench and exposed as named wires the decoder binds to. Burst
fixtures are well-covered by the synthetic `generated/` corpus next
door; the captured fixture's job is to validate against real RTL,
not to provide novel burst coverage.

Files committed here:

- `MS_DMAC_AHBL.v` — vendored from upstream commit
  `d2ea9e38e7ad9392f6675861f8cfcd3ee137c62c` (2024-10-06). Apache-2.0
  header preserved.
- `ahbl_util.vh` — supporting macros (`AHB_SLAVE_IFC`, `AHB_REG`,
  `AHB_SLAVE_EPILOGUE`, …) vendored from the same upstream commit.
  Apache-2.0 header preserved.
- `tb_ms_dmac_ahbl.v` — our pure-Verilog testbench. Drives the
  DMAC's slave port through four AHB-Lite register writes (SADDR,
  DADDR, SIZE, CTRL) followed by a software trigger; models a
  trivial combinational master-side memory that returns
  `0xC0FFEE00 | byte_offset` on every read and silently accepts
  writes; ties `M_HBURST = 3'b000` (SINGLE) and `M_HRESP = 1'b0`
  (OKAY). SPDX `0BSD` (public domain).
- `Makefile` — `make` builds + runs (produces
  `ahb_lite_shalan_dmac.fst` in this directory); `make install`
  copies the FST into both `test/` and `verification/` trees.

Rebuild: `cd helpers/shalan && make && make install`. Requires only
`iverilog` + `vvp` from icarus-verilog (already in PATH).

After rebuilding the FST, regenerate the decoded snapshot in both
trees with:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/ahb_lite_captured_fixtures_test.dart
cp test/fixtures/protocol/ahb_lite/captured/ahb_lite_shalan_dmac.expected_transactions.json \
   verification/fixtures/protocol/ahb_lite/captured/ahb_lite_shalan_dmac.expected_transactions.json
```

## Decoded stream

10 AHB-Lite SINGLE-beat transactions covering 5 word-stride
read+write pairs marching through the source/destination regions:

| t (ns) | Transaction                  |
|--------|------------------------------|
| 450    | `R 0x40000000 → 0xC0FFEE00`  |
| 490    | `W 0x50000000 = 0xC0FFEE00`  |
| 530    | `R 0x40000004 → 0xC0FFEE04`  |
| 570    | `W 0x50000004 = 0xC0FFEE04`  |
| 610    | `R 0x40000008 → 0xC0FFEE08`  |
| 650    | `W 0x50000008 = 0xC0FFEE08`  |
| 690    | `R 0x4000000C → 0xC0FFEE0C`  |
| 730    | `W 0x5000000C = 0xC0FFEE0C`  |
| 770    | `R 0x40000010 → 0xC0FFEE10`  |
| 810    | `W 0x50000010 = 0xC0FFEE10`  |

(The DMAC's CNTR comparison `CNTR == SIZE_REG` runs CNTR through 0…4
when SIZE=4, producing 5 read+write pairs rather than 4. The pattern
is deterministic and matches the upstream RTL behavior.)

Every transaction is SINGLE-beat (HBURST=000), OKAY response
(HRESP=0), 32-bit (HSIZE=2), zero wait states.

## CTRL register field layout

The MS_DMAC_AHBL file-header comment block lists a CTRL field layout
that does NOT match the RTL. The actual fields (from the
`REG_FIELD` declarations in the source) are:

| Bits   | Field      | Notes                                          |
|--------|------------|------------------------------------------------|
| 0      | EN         | DMAC enable                                    |
| 11:8   | TRIGGER    | Unused in the SW-trigger flow                  |
| 17:16  | SRC_TYPE   | 0=byte, 1=halfword, 2=word                     |
| 20:18  | SRC_AI     | Auto-increment stride: 0=none, 1, 2, or 4 bytes|
| 25:24  | DEST_TYPE  | Same encoding as SRC_TYPE                      |
| 28:26  | DEST_AI    | Same encoding as SRC_AI                        |

For word-typed transfers with word-stride auto-increment on both
ends, write CTRL = `(4<<26) | (2<<24) | (4<<18) | (2<<16) | 1`
= `0x12120001`. The testbench uses this value; getting it wrong
yields byte-typed transfers and misaligned-HADDR violations from
the decoder.
