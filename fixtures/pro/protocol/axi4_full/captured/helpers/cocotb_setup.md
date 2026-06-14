# cocotb setup for AXI4 Full captured fixtures

The AXI4 Full captured fixtures in this directory are produced by running
[Alex Forencich's cocotb testbenches](https://github.com/alexforencich/verilog-axi)
locally and capturing the FST waveform output. This document describes the
one-time toolchain setup and the per-fixture capture workflow.

## One-time toolchain setup

### Python 3.13 + venv

cocotb 2.0.1 requires Python ≤ 3.13. On a macOS Homebrew system where
`python3` is 3.14, install `python@3.13` and create a dedicated venv:

```bash
brew install python@3.13
python3 -m venv ~/.venvs/wavecrux-cocotb     # if 3.13 is now the default
# OR explicitly:
/opt/homebrew/bin/python3.13 -m venv ~/.venvs/wavecrux-cocotb

~/.venvs/wavecrux-cocotb/bin/pip install --upgrade pip
~/.venvs/wavecrux-cocotb/bin/pip install \
  cocotb cocotbext-axi cocotb-bus cocotb-test pytest
```

Verify:

```bash
~/.venvs/wavecrux-cocotb/bin/python -c "import cocotb, cocotb_bus, cocotbext.axi; \
  print('cocotb:', cocotb.__version__)"
```

### Verilog simulator

The verilog-axi testbenches default to `SIM=icarus`. Install via Homebrew:

```bash
brew install icarus-verilog gtkwave   # gtkwave provides fst2vcd for inspection
```

Verilator works too (`SIM=verilator`) but is not required for the captured
fixtures here.

## Per-fixture capture workflow

Each captured fixture follows the same shape:

1. **Clone the upstream source** to a scratch dir (e.g. `/tmp/wcrux-captures/`).
   Capture the commit SHA — it goes into PROVENANCE.md.

2. **Patch `iverilog_dump.v` to add an `aresetn` net** (see "Why we patch
   `iverilog_dump.v`" below). The patch is copied verbatim from
   `helpers/forencich_aresetn_dump.patch` and applied with `patch -p1`:

   ```bash
   cd /tmp/wcrux-captures/verilog-axi/tb/<testbench>
   patch -p1 < /path/to/this/helpers/forencich_aresetn_dump.patch
   ```

3. **Run the testbench with `WAVES=1`** so iverilog dumps the FST:

   ```bash
   PATH=~/.venvs/wavecrux-cocotb/bin:$PATH make WAVES=1 SIM=icarus
   ```

   This produces `<testbench>.fst` in the testbench directory.

4. **Copy the FST into both fixture trees** (`test/` and `verification/`),
   renaming to a `forencich_<scenario>.fst` slug:

   ```bash
   cp /tmp/wcrux-captures/verilog-axi/tb/axi_ram/axi_ram.fst \
      <repo>/test/fixtures/protocol/axi4_full/captured/forencich_axi_ram_full.fst
   cp /tmp/wcrux-captures/verilog-axi/tb/axi_ram/axi_ram.fst \
      <repo>/verification/fixtures/protocol/axi4_full/captured/forencich_axi_ram_full.fst
   ```

5. **Write the `<name>.fixture.json` sidecar** with the per-fixture signal
   bindings. See `forencich_axi_ram_full.fixture.json` for the canonical
   pattern — every required Pro AXI4 Full signal name maps to a
   `<scope>.<signal>` path inside the FST.

6. **Regenerate the snapshot:**

   ```bash
   REGENERATE=1 flutter test \
     test/services/decoders/axi4_full_captured_fixtures_test.dart
   ```

   This populates `<name>.expected_transactions.json`. Mirror the snapshot
   into `verification/fixtures/protocol/axi4_full/captured/` too.

7. **Hand-verify 2–3 anchor transactions** by opening the FST in WaveCrux
   (or eyeballing the testbench's expected output in the cocotb log) and
   confirming they appear in the snapshot. Document these in
   `PROVENANCE.md` under the fixture's entry.

## Why we patch `iverilog_dump.v`

The Pro `Axi4FullDecoder` requires an `aresetn` signal binding (active-low
synchronous reset, per the AXI4 spec). Forencich's testbenches drive an
active-**high** `rst` signal, so a direct binding would have inverted
semantics — the decoder would skip every clock cycle when the bus is live
and process every cycle when the bus is in reset.

The cleanest fix is in the simulator dump scope: `iverilog_dump.v` is a
testbench-side module that controls what gets written into the FST. We add
a single `wire aresetn = !axi_ram.rst;` declaration plus a
`$dumpvars(0, iverilog_dump.aresetn);` line, so the FST grows by exactly
one signal — the inverted reset — without touching the DUT or the cocotb
test runner.

The patch lives at `helpers/forencich_aresetn_dump.patch` and is committed
alongside this guide so future contributors can reproduce the capture
exactly.
