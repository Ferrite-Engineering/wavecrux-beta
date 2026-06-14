# Avalon-ST captured-fixture helpers (own exerciser)

The Avalon-ST captured fixture (`wavecrux_avalon_st_exerciser.fst`)
exercises an in-house pure-Verilog Avalon-ST source+sink exerciser
(`tb_avalon_st_exerciser.v`, SPDX `CC0-1.0`) authored from the public
Intel "Avalon Interface Specifications" (document MNL-AVABUSREF). Same
rationale as the Avalon-MM helpers — Avalon-ST has no readily-available
permissive-license Verilog testbench in the OSS ecosystem.

## Files committed here

- `tb_avalon_st_exerciser.v` — CC0-1.0 source + sink. Source walks five
  packets covering single-beat single-channel, multi-beat multi-channel,
  ready-throttling on a mid-packet beat, `empty=1` on the EOP beat, and
  the `error` sideband.
- `Makefile` — `make` builds + runs; `make install` copies the FST into
  both `test/` and `verification/` trees.

Rebuild: `cd helpers/wavecrux && make && make install`.

## Decoded stream

| t (ns)     | Decoded                                  | Notes                                             |
|------------|------------------------------------------|---------------------------------------------------|
| 65         | 1 beat, 4 bytes (ch 0), payload `44434241` | ASCII `'A','B','C','D'` in little-endian byte order |
| 115 → 135  | 2 beats, 8 bytes (ch 0), `78563412ddccbbaa` | multi-beat packet                                |
| 185 → 225  | 3 beats, 12 bytes (ch 1), `0x01..0x03` × 4 | ready-throttled mid-packet                       |
| 275        | 1 beat, 3 bytes (ch 0), `efbead`         | `empty=1` on EOP — 3 valid bytes in the last beat |
| 325 → 345  | 2 beats, 8 bytes (ch 0), error asserted on EOP | exercises error-sideband decode path           |

The "3-bytes" packet at t=275 reflects the Avalon-ST `empty` semantics:
`empty=N` on the EOP beat means N invalid bytes at the end, so a 4-byte
beat with `empty=1` carries 3 valid bytes (the low byte is the padded
position per the AMBA convention).
