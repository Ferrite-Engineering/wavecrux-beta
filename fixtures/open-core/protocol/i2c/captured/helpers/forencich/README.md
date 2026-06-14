# I²C captured-fixture helpers (forencich verilog-i2c)

The I²C captured fixture (`i2c_forencich_master_slave.fst`) does
**not** use cocotb or Python. Alex Forencich's `verilog-i2c` (MIT)
ships its testbench stimulus in MyHDL/Python, which is a deprecated
toolchain. We sidestep that by vendoring `i2c_master.v` + `i2c_slave.v`
verbatim and driving them from a small pure-Verilog testbench that
wires both onto a shared open-drain SDA/SCL bus with explicit
`pullup()` resolution. Pipeline matches the picorv32 captures (APB,
Wishbone, RISC-V): iverilog + vvp only.

Files committed here:

- `i2c_master.v` — vendored from upstream commit
  `a65be4045e898a52e791c6ee71f8f79a7cd2e129` (2025-02-27). MIT header
  preserved.
- `i2c_slave.v` — vendored from the same upstream commit. MIT.
- `tb_i2c_master_slave.v` — our pure-Verilog testbench. Instantiates
  one of each, ties them onto a shared open-drain bus
  (`assign scl = m_scl_t ? 1'bz : m_scl_o;` etc. plus `pullup(scl);`),
  drives the master with an AXIS command program that performs two
  back-to-back writes to slave address 0x50 (multi-byte 0xAB/0xCD,
  then single-byte 0x42). SPDX `0BSD` (public domain).
- `Makefile` — `make` builds + runs (produces
  `i2c_forencich_master_slave.fst` in this directory); `make install`
  copies the FST into both `test/` and `verification/` trees.

Rebuild: `cd helpers/forencich && make && make install`. Requires only
`iverilog` + `vvp` from icarus-verilog (already in PATH).

After rebuilding the FST, regenerate the decoded snapshot in both
trees with:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/i2c_captured_fixtures_test.dart
cp test/fixtures/protocol/i2c/captured/i2c_forencich_master_slave.expected_transactions.json \
   verification/fixtures/protocol/i2c/captured/i2c_forencich_master_slave.expected_transactions.json
```

## Decoded stream

The capture decodes to two I²C bus transactions, both writes to the
slave at 7-bit address 0x50:

| t (ns)              | Decoded             | Data         | ACK pattern |
|---------------------|---------------------|--------------|-------------|
| 180 → 29970         | `I²C 0x50 W 2 bytes`| `0xAB 0xCD`  | `ACK ACK`   |
| 30410 → 50600       | `I²C 0x50 W 0x42`   | `0x42`       | `ACK`       |

Bus clocking: 100 MHz tb clock, prescale=25 → ~1 MHz SCL (fast-mode
I²C). Standard-mode 100 kHz would give a much larger FST without
changing the decoded result; the decoder is bus-clockless.

## Why no read transaction

Forencich's `i2c_slave` exposes its TX data via a strict AXIS handshake
that's easy to race against from a synchronous testbench: presenting
the next byte before the slave's `tready` rising-edge can either
double-consume the current byte or drop the new one. The simpler, more
deterministic shape — two back-to-back writes — already covers the
decoder's START / addr+W / multi-byte data / per-byte ACK / STOP
paths, so we ship that and leave a read-side capture for a future
iteration if useful coverage gaps emerge.
