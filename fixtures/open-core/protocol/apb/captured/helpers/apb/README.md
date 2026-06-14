# APB captured-fixture helpers

The APB captured fixture (`apb_axil2apb.fst`) does **not** use cocotb —
ZipCPU/wb2axip ships only formal SymbiYosys flows for its APB cores,
not simulation testbenches. We vendor the two relevant RTL modules
verbatim (with their Apache-2.0 headers preserved) and drive them from
a small Icarus-Verilog testbench. That sidesteps the entire cocotb
2.0 patch tax this corpus otherwise carries — mirrors the no-cocotb
sub-pipeline used for MDIO under
[`../../../ethernet/captured/helpers/mdio/`](../../../ethernet/captured/helpers/mdio/).

Files committed here:

- `axil2apb.v` — vendored from upstream commit
  `df8e7649acf68544a152e39a4589c8e894a4cd0b`. Apache-2.0 header
  preserved. Dan Gisselquist's high-throughput AXI-Lite to APB
  bridge.
- `apbslave.v` — vendored from the same commit, Apache-2.0. The
  demonstration APB slave used as the bridge's downstream target.
  Always-ready (PREADY asserts on the access edge — no wait
  states), PSLVERR tied low. Memory writes honour PWSTRB byte
  enables.
- `skidbuffer.v` — vendored from the same commit, Apache-2.0.
  Required by `axil2apb.v` for AW / W / AR skid buffers.
- `tb_apb.v` — our pure-Verilog testbench. Wires `axil2apb` →
  `apbslave`, drives a sequence of AXI-Lite writes/reads, and
  dumps an FST. SPDX `Apache-2.0`.
- `Makefile` — `make` builds + runs (produces `apb_axil2apb.fst`
  in this directory); `make install` copies the FST into both
  `test/` and `verification/` trees.

Rebuild: `cd helpers/apb && make && make install`. Requires only
`iverilog` + `vvp` from icarus-verilog (already in PATH).

After rebuilding the FST, regenerate the decoded snapshot in both
trees with:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/apb_captured_fixtures_test.dart
cp test/fixtures/protocol/apb/captured/apb_axil2apb.expected_transactions.json \
   verification/fixtures/protocol/apb/captured/apb_axil2apb.expected_transactions.json
```

## Stimulus

The testbench drives ten AXI-Lite operations through the bridge,
producing ten APB transactions on the bridge → slave path:

1. Four 32-bit writes (`0x100`–`0x10C`) with full strobe `0xF`.
2. Four 32-bit reads of the same addresses, verifying memory
   round-trip.
3. One partial-strobe write (`0xC0DE` to `0x100` with `PWSTRB=0x3`,
   updating only bytes [1:0]).
4. One final read of `0x100`, which returns `0xDEADC0DE` — proving
   the byte-strobe semantics through the bridge.

All transactions complete in two cycles (SETUP + ACCESS) because
`apbslave` is always-ready. PSLVERR is tied low, so every
transaction decodes as OKAY.
