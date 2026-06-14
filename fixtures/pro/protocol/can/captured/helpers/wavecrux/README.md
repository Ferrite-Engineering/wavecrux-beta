# CAN captured-fixture helpers (own exerciser)

The CAN captured fixture (`wavecrux_can_exerciser.fst`) exercises an
in-house pure-Verilog Classical-CAN 2.0A Standard Data Frame exerciser
(`tb_can_exerciser.v`, SPDX `CC0-1.0`). Same rationale as the Avalon /
JTAG / PCIe TLP exercisers — public open-source CAN cores tend to
live behind GPL/LGPL or Bosch reference-model licenses incompatible
with the corpus allow-list, so we author the trace from the public
ISO 11898-1 standard.

## One non-obvious convention

The exerciser matches one implementation choice the wavecrux CAN
decoder requires (and the bundled generator at
`tool/generate_can_fixtures.dart` follows):

1. **De-stuffed application-layer signal.** Per the comment in
   `lib/services/decoders/can_decoder.dart` (`// ── bit stuffing
   note ──`), the decoder consumes the logical signal an RTL CAN
   controller presents to the application, not the raw physical bus.
   The exerciser therefore drives raw bits 1-to-1 with no stuff-bit
   insertion. Long runs of identical bits are valid data on this
   signal.

The frame format is straight ISO 11898-1 classical CAN 2.0A: the bit
after `r0` is the first DLC bit. Earlier revisions of this exerciser
emitted a spurious FDF=0 placeholder between `r0` and DLC to match an
out-of-spec position-dependent FDF read in the decoder; both the
decoder and exerciser were corrected in 2026-05-31 so that real-world
CAN traces from public IP decode correctly.

## Files committed here

- `tb_can_exerciser.v` — CC0-1.0 master that drives a single Standard
  Data Frame: ID `0x123`, DLC `2`, data `0xAB 0xCD`. Bit timing
  500 kbit/s nominal (2 µs / bit). CRC15 is computed inline matching
  the decoder's polynomial (0x4599) and shift order — left-shift-then-
  OR-the-input-bit, then conditionally XOR with the polynomial.
- `Makefile` — `make` builds + runs; `make install` mirrors the FST
  into both fixture trees.

## Decoded stream

| t (ns)         | Decoded            | Notes                                              |
|----------------|--------------------|----------------------------------------------------|
| 16 000         | `DATA 0x123 [2]`   | ID=`0x123`, DLC=`2`, data=`AB CD`, IDE=Standard, no errors |

The frame structure on the wire (after SOF dominant, before EOF):
`SOF | ID(11) | RTR | IDE=0 | r0=0 | DLC(4) | Data(16) | CRC(15) | CRC-delim=1 | ACK=0 | ACK-delim=1 | EOF(7=1) | IFS(3=1)`.
The ACK slot is driven dominant (simulating a listening node) so the
decoder doesn't flag the frame as truncated.
