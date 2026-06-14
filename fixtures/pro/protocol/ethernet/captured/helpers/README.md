# Ethernet captured-fixture helpers

The Ethernet captured-fixture pipeline shares the AXI4 Full toolchain
(Python 3.13 venv at `~/.venvs/wavecrux-cocotb/`, icarus-verilog,
GTKWave) documented at
[`../../axi4_full/captured/helpers/cocotb_setup.md`](../../axi4_full/captured/helpers/cocotb_setup.md).
This README covers the Ethernet-specific deltas.

## Extra Python dependency: `cocotbext-eth` from git HEAD

`alexforencich/verilog-ethernet`'s testbenches import `cocotbext.eth`
(specifically `RgmiiPhy`, `GmiiFrame`). The PyPI release
`cocotbext-eth==0.1.22` predates cocotb 2.0 and crashes with
`AttributeError: 'Logic' object has no attribute 'integer'` when run
under our cocotb 2.0.1 venv. The fix landed upstream on 2025-09-07 but
has not been released to PyPI. Install the pinned HEAD commit:

```bash
~/.venvs/wavecrux-cocotb/bin/pip install --upgrade --force-reinstall \
  "git+https://github.com/alexforencich/cocotbext-eth.git@c6872e69518e46697f834bc456b4435259e4d507"
```

The pinned SHA matches what was used to produce the captured fixtures
in this directory. Verify the install with:

```bash
~/.venvs/wavecrux-cocotb/bin/python -c \
  "from cocotbext.eth import RgmiiPhy; print(RgmiiPhy.__module__)"
```

## Per-testbench cocotb 2.0 patches

The verilog-ethernet repo itself was marked **deprecated** on
2025-02-27 (commit `77320a9`) and will not receive its own cocotb 2.0
compatibility fixes. Each testbench we capture from carries a local
patch under this directory that fixes the cocotb 2.0 breakages **and**
trims the test sweep to a single link speed (1 GbE) and a smaller frame
size list, keeping the resulting FST small enough to commit.

Currently committed patches:

- [`forencich_eth_mac_1g_rgmii_cocotb2_1gbe.patch`](forencich_eth_mac_1g_rgmii_cocotb2_1gbe.patch)
  — applies to `tb/eth_mac_1g_rgmii/test_eth_mac_1g_rgmii.py`. Produces
  `rgmii_forencich_eth_mac_1g.fst`. See the PROVENANCE entry for the
  full capture command.

Pattern for adding a new MAC variant (RMII, GMII, etc.): copy the patch
as a template, retarget the testbench file, port the `.value.integer` →
`int(.value)` and `dut.X == N` → `int(dut.X.value) == N` rewrites, and
add a fixture entry to `../PROVENANCE.md`.

## MDIO sub-pipeline ([`mdio/`](mdio/))

The MDIO captured fixture (`mdio_forencich_clause22.fst`) does **not**
use cocotb — Forencich's `verilog-ethernet` ships no MDIO testbench, but
his `mdio_master.v` (in `example/VCU118/fpga_1g/rtl/`, MIT) is a clean,
standalone Clause-22 master. We vendor it verbatim and drive it from a
small Icarus-Verilog initial-block testbench plus a per-bit MDIO slave
model. That sidesteps the entire cocotb 2.0 patch tax this directory
otherwise carries.

Files committed under [`mdio/`](mdio/):

- `forencich_mdio_master.v` — vendored from upstream commit
  `77320a9471d19c7dd383914bc049e02d9f4f1ffb`. MIT header preserved.
- `tb_mdio_master.v` — our testbench. Drives 2× write + 2× read with a
  per-bit slave model that responds on TA[1] + 16 data cycles.
- `Makefile` — `make` builds + runs, `make install` copies the FST into
  both `test/` and `verification/` trees.

Rebuild: `cd mdio && make && make install`. Requires only `iverilog` +
`vvp` from icarus-verilog (already in PATH).
