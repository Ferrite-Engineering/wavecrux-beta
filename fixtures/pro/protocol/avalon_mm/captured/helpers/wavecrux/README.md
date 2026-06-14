# Avalon-MM captured-fixture helpers (own exerciser)

The Avalon-MM captured fixture (`wavecrux_avalon_mm_exerciser.fst`)
exercises an in-house pure-Verilog Avalon-MM master+slave exerciser
(`tb_avalon_mm_exerciser.v`, SPDX `CC0-1.0`) that we authored from the
public Intel "Avalon Interface Specifications" (document
MNL-AVABUSREF). No vendor IP is involved — only the published spec.

## Why a hand-authored exerciser

Unlike the SPI, I²C, AXI4-Full, AXIS, MDIO, AHB-Lite, APB, Wishbone,
RISC-V, and Ethernet RGMII fixtures (which vendor a permissively-licensed
RTL core from a real OSS project), Avalon-MM has no readily-available
permissive-license Verilog testbench in the open-source ecosystem:
Intel's BFMs ship with proprietary Quartus, LiteX's Avalon support is
Migen/Python-based without a standalone Verilog testbench, and the
opencores Avalon adapters are LGPL (off the allow-list — see
`test/static/captured_fixture_licenses_test.dart`). Since wavecrux-pro
is closed-source, GPL/LGPL captures carry attribution obligations
incompatible with the distribution model.

So the corpus-tier rule is satisfied by authoring our own exerciser
under CC0-1.0 (public-domain dedication), driven by the documented
protocol — the same way one would write a custom unit-under-test wrapper
in any test suite. The fixture is "captured" in the sense that it
generates real bus traffic from real Verilog that implements the
documented Avalon-MM protocol.

## Files committed here

- `tb_avalon_mm_exerciser.v` — CC0-1.0 master + slave exerciser. Slave
  models 256 × 32-bit storage at addresses `0x000..0x3FC`, with 1-cycle
  `waitrequest` pulses on transfer acceptance, 2-cycle `readdatavalid`
  latency for OK reads, and SLAVE_ERROR response on addresses ≥ `0x400`.
  Master walks a five-step program — single write, read-back, partial
  byteenable write, read-back, erroring read.
- `Makefile` — `make` builds + runs; `make install` copies the FST into
  both `test/` and `verification/` trees.

Rebuild: `cd helpers/wavecrux && make && make install`. Requires only
`iverilog`, `vvp`, and `vcd2fst`, all already in PATH.

After rebuilding the FST, regenerate the decoded snapshot in both
trees with:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/avalon_mm_captured_fixtures_test.dart
cp test/fixtures/protocol/avalon_mm/captured/wavecrux_avalon_mm_exerciser.expected_transactions.json \
   verification/fixtures/protocol/avalon_mm/captured/wavecrux_avalon_mm_exerciser.expected_transactions.json
```

## Decoded stream

The capture decodes to five Avalon-MM transactions:

| t (ns)          | Decoded                                  | Notes                                              |
|-----------------|------------------------------------------|----------------------------------------------------|
| 65              | `WRITE 0x0 = 0xdeadbeef`                 | byteenable `1111` (full word)                      |
| 105 → 125       | `READ 0x0 → 0xdeadbeef`                  | round-trip read of step 1                          |
| 155             | `WRITE 0x10 = 0x12345678`                | byteenable `0011` (low 16 bits only)               |
| 195 → 215       | `READ 0x10 → 0x5678`                     | upper half remained zero (partial byteenable)      |
| 245 → 265       | `READ 0x400 → 0xdeadbade` (SLAVE_ERROR)  | exercises the error-response decode path          |

Burst transfers are exercised in the generated/ corpus rather than here
— the decoder's burst-read state machine interacts in nontrivial ways
with the per-beat `readdatavalid` timing of a free-running pipelined
slave, which would add error-class noise that would obscure the
single-beat anchors.
