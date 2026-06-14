# SPI captured-fixture helpers (nandland spi-master)

The SPI captured fixture (`nandland_spi_master_mode3_loopback.fst`)
exercises Russell Merrick's `SPI_Master_With_Single_CS` (vendored from
nandland's [spi-master](https://github.com/nandland/spi-master), MIT)
driven by its bundled SystemVerilog testbench with MISO tied back to
MOSI in loopback. The pipeline is pure iverilog + vvp + vcd2fst — no
cocotb, no Python.

Files committed here:

- `SPI_Master.v` — vendored from upstream commit
  `1ab581969f8ea2f794072a144b55cd74e5a54f34` (2025). MIT header preserved.
- `SPI_Master_With_Single_CS.v` — vendored from the same upstream commit. MIT.
- `SPI_Master_With_Single_CS_TB.sv` — Russell Merrick's bundled
  SystemVerilog testbench, vendored verbatim (same commit, MIT). Sends
  two back-to-back bytes (0xC1, 0xC2) to the master with `SPI_MODE=3`
  (CPOL=1, CPHA=1), `CLKS_PER_HALF_BIT=4`, `MAX_BYTES_PER_CS=2`. MISO is
  wired back to MOSI in the testbench (`.i_SPI_MISO(w_SPI_MOSI)`), so the
  decoded MOSI and MISO streams are identical.
- `Makefile` — `make` builds + runs (produces
  `nandland_spi_master_mode3_loopback.fst` in this directory); `make
  install` copies the FST into both `test/` and `verification/` trees.

Rebuild: `cd helpers/nandland && make && make install`. Requires only
`iverilog`, `vvp`, and `vcd2fst` (gtkwave package), all already in PATH.

After rebuilding the FST, regenerate the decoded snapshot in both
trees with:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/spi_captured_fixtures_test.dart
cp test/fixtures/protocol/spi/captured/nandland_spi_master_mode3_loopback.expected_transactions.json \
   verification/fixtures/protocol/spi/captured/nandland_spi_master_mode3_loopback.expected_transactions.json
```

## Decoded stream

The capture decodes to a single SPI burst (the master holds CS asserted
across both bytes thanks to `MAX_BYTES_PER_CS=2`):

| t (sim units)     | Decoded         | MOSI         | MISO         | Notes |
|-------------------|-----------------|--------------|--------------|-------|
| 86 → 618          | `SPI 2 words`   | `0xC1 0xC2`  | `0xC1 0xC2`  | CS held low across both bytes (loopback MISO) |

The two bytes match `$display` output from the testbench
(`Sent out 0xC1, Received 0xc1`, `Sent out 0xC2, Received 0xc2`).
Numeric timestamps are in raw simulation units (the bundled testbench
has no explicit `\`timescale`, so iverilog defaults to 1 s/1 s — the
absolute number is irrelevant for the decoder, which is bus-clockless).
