# Wishbone captured-fixture helpers (picorv32_wb)

The Wishbone captured fixture (`wishbone_picorv32_wb_ez.fst`) does
**not** use cocotb — YosysHQ's `picorv32` ships its own Icarus +
firmware testbenches, but the upstream `testbench_wb.v` flow requires
a RISC-V GNU toolchain to build `firmware/firmware.hex`. To sidestep
that prerequisite we vendor `picorv32.v` verbatim (ISC) and drive its
`picorv32_wb` variant from a small in-tree testbench whose memory is
preloaded with the same six-instruction loop the upstream
`testbench_ez.v` uses (public domain). That gives us real RISC-V
instruction-fetch + load/store traffic on a Wishbone B3 Classic bus
without ever invoking `riscv32-unknown-elf-gcc`.

Files committed here:

- `picorv32.v` — vendored from upstream commit
  `87c89acc18994c8cf9a2311e871818e87d304568`. ISC header preserved.
  Claire Xenia Wolf's RV32I core, including the `picorv32_wb`
  Wishbone-master wrapper.
- `tb_picorv32_wb_ez.v` — our pure-Verilog testbench. Wires
  `picorv32_wb` to a 256-word in-memory WB slave preloaded with the
  upstream `testbench_ez.v` loop body (`li x1, 1020` / `sw x0, 0(x1)` /
  `lw x2, 0(x1)` / `addi x2, x2, 1` / `sw x2, 0(x1)` / `j loop`).
  SPDX `0BSD` (public domain).
- `Makefile` — `make` builds + runs (produces
  `wishbone_picorv32_wb_ez.fst` in this directory); `make install`
  copies the FST into both `test/` and `verification/` trees.

Rebuild: `cd helpers/picorv32 && make && make install`. Requires only
`iverilog` + `vvp` from icarus-verilog (already in PATH).

After rebuilding the FST, regenerate the decoded snapshot in both
trees with:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/wishbone_captured_fixtures_test.dart
cp test/fixtures/protocol/wishbone/captured/wishbone_picorv32_wb_ez.expected_transactions.json \
   verification/fixtures/protocol/wishbone/captured/wishbone_picorv32_wb_ez.expected_transactions.json
```

## Bus traffic

The testbench releases reset, lets picorv32 fetch + execute the
six-instruction loop, and `$finish`es after a bounded number of
cycles. The resulting trace captures 10 Wishbone B3 Classic
transactions covering:

- Sequential ifetch of the loop body (`R 0x00 → 0x3FC00093` … `R 0x14
  → 0xFF5FF06F`).
- The counter init (`W 0x3FC = 0x00000000`).
- The counter readback (`R 0x3FC → 0x00000000`).
- The first counter increment store (`W 0x3FC = 0x00000001`).
- An ifetch of the loop branch target (`R 0x08 → 0x0000A103` —
  confirming the `j loop` jumped back).

Every transaction terminates with ACK. The slave is single-cycle
(`ack` asserted on the same posedge `cyc & stb` sample high), so
each transaction is one PCLK long.
