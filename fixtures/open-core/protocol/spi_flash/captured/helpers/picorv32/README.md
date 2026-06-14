# SPI-Flash captured-fixture helpers (picorv32 spiflash model)

The SPI-Flash captured fixture (`picorv32_spiflash_single_wire.fst`)
exercises Claire Wolf's `spiflash` behavioral flash model (vendored
verbatim from
[picorv32](https://github.com/YosysHQ/picorv32)'s `picosoc/spiflash.v`,
ISC). Upstream's bundled testbench (`spiflash_tb.v`) mixes single-wire
SPI with quad and DDR-quad reads; the WaveCrux SPI-Flash decoder is
documented as single-wire only, so we author a 0BSD testbench here that
restricts the stimulus to the three single-wire commands that exercise
the decoder cleanly:

1. **Reset (0xFF)** — single-byte unknown-opcode path
2. **Power Up (0xAB)** — `RES` decode path (bare 0xAB without trailing
   ID-read bytes; flags `incomplete_frame`, which matches the JEDEC
   spec for `Read Electronic Signature`)
3. **READ (0x03)** at 24-bit address `0x100000`, 8 data bytes — full
   opcode + address + data-phase decode

Files committed here:

- `spiflash.v` — vendored from picorv32 commit pinned in
  `PROVENANCE.md` (ISC, Copyright © 2017 Claire Xenia Wolf). Header
  preserved.
- `tb_picorv32_spiflash_single_wire.v` — our 0BSD single-wire testbench.
  Replaces upstream `spiflash_tb.v` because the original mixes
  single-wire with quad / DDR-quad reads.
- `firmware.hex` — `$readmemh` source for the flash model. Places the
  byte sequence `93 00 00 00 93 01 00 00` at offset `0x100000`, so the
  READ data phase decodes to recognizable non-X bytes that match the
  word0 = 0x00000093 / word1 = 0x00000193 anchors in upstream's
  `spiflash_tb.v`.
- `Makefile` — `make` builds + runs (produces the FST in this
  directory); `make install` copies the FST into both `test/` and
  `verification/` trees.

Rebuild: `cd helpers/picorv32 && make && make install`. Requires only
`iverilog`, `vvp`, and `vcd2fst` (gtkwave package), all already in PATH.

After rebuilding the FST, regenerate the decoded snapshot in both
trees with:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/spi_flash_captured_fixtures_test.dart
cp test/fixtures/protocol/spi_flash/captured/picorv32_spiflash_single_wire.expected_transactions.json \
   verification/fixtures/protocol/spi_flash/captured/picorv32_spiflash_single_wire.expected_transactions.json
```

## Decoded stream

The capture decodes to three SPI-Flash transactions stacked on the
SPI parent decoder:

| t (ns)            | Decoded   | Fields                                                                  | Error               |
|-------------------|-----------|-------------------------------------------------------------------------|---------------------|
| 5 000 → 100 000   | `0xFF`    | opcode 0xFF (Reset, recognised unknown-opcode path)                     | —                   |
| 110 000 → 205 000 | `RES`     | opcode 0xAB (bare wake from deep power-down, no ID-read tail)           | `incomplete_frame`  |
| 215 000 → 1 245 000 | `READ`  | opcode 0x03, address 0x100000, data `0x93 0x00 0x00 0x00 0x93 0x01 0x00 0x00` | —              |

The READ data bytes exactly match the `word0 = 32'h00000093` and
`word1 = 32'h00000193` values asserted in upstream's `spiflash_tb.v`
(`expect(word0[7:0])` … `expect(word1[31:24])`).
