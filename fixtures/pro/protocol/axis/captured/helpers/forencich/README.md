# AXIS captured-fixture helpers (forencich verilog-axis)

The AXIS captured fixture (`forencich_axis_register.fst`) exercises
Alex Forencich's `axis_register` RTL via the upstream cocotb
testbench. Identical toolchain shape to the AXI4-Full pilots — see
[`test/fixtures/protocol/axi4_full/captured/helpers/cocotb_setup.md`](../../../axi4_full/captured/helpers/cocotb_setup.md)
for the one-time Python 3.13 venv + cocotb 2.0.1 setup.

## Files committed here

- `iverilog_dump.v` — drop-in replacement for the auto-generated dump
  module under `verilog-axis/tb/axis_register/`. Augments the FST dump
  with an `aresetn = !axis_register.rst` net so the Pro AXIS decoder's
  active-low reset binding has a native target. (Forencich's
  testbenches drive `rst` active-high. Same trick as the AXI4-Full
  `forencich_aresetn_dump.patch`, but as a full file rather than a
  patch because the verilog-axis Makefile auto-generates this file
  per-build and an `iverilog_dump.v` already present in the directory
  is left untouched by the target.)

## Per-capture workflow

```bash
# 1. Clone the upstream source
cd /tmp/wcrux-captures
git clone https://github.com/alexforencich/verilog-axis.git
cd verilog-axis/tb/axis_register

# 2. Drop in our augmented iverilog_dump.v
cp /<repo_root>/test/fixtures/protocol/axis/captured/helpers/forencich/iverilog_dump.v .

# 3. Run the cocotb test with WAVES=1
PATH=~/.venvs/wavecrux-cocotb/bin:$PATH make WAVES=1 SIM=icarus

# 4. Copy the FST into both fixture trees
cp axis_register.fst /<repo_root>/test/fixtures/protocol/axis/captured/forencich_axis_register.fst
cp axis_register.fst /<repo_root>/verification/fixtures/protocol/axis/captured/forencich_axis_register.fst

# 5. Regenerate the snapshot
cd /<repo_root>
REGENERATE=1 flutter test test/services/decoders/axis_captured_fixtures_test.dart
cp test/fixtures/protocol/axis/captured/forencich_axis_register.expected_transactions.json \
   verification/fixtures/protocol/axis/captured/forencich_axis_register.expected_transactions.json
```

## Determinism note

The upstream `test_axis_register.py` uses `random` without an explicit
seed, so the per-beat ID / dest / data sequences differ slightly
between runs. The committed FST is a one-time frozen capture; the
snapshot is regenerated against that frozen FST whenever the decoder
output format changes. Don't regenerate the FST unless the upstream
RTL or test logic itself changes.

## Decoded stream summary

9 cocotb sub-tests run back-to-back across ~226 µs of simulated time,
producing 789 decoded AXIS packets. Coverage spans:

- single-beat packets (`run_test_001`)
- 1..16-byte packets walking the packet-length axis (`run_test_002` /
  `003` / `004`)
- a `run_test_tuser_assert_001` packet that fires the AMBA `tuser`-as-
  packet-error convention
- four `run_stress_test_*` runs that pseudo-randomly interleave bursts
  with back-to-back, tready-paced, and tvalid-paced patterns

Hand-verified anchors documented in `PROVENANCE.md`.
