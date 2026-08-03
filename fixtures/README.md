# WaveCrux Test Fixtures

**This is what WaveCrux tests against.** Every file here is part of the WaveCrux
test suite — each waveform has a known-correct expected result, and the decoders
and parsers are validated against it on every change. We publish the corpus so
you can see exactly how WaveCrux is verified, run the traces yourself, and
[contribute your own](../docs/SUBMITTING_FIXTURES.md).

During the public beta all features are unlocked, so you can open both the
open-core and the Pro fixtures in the app and watch the decoders and Stage
widgets work against them.

> ⚙️ **This tree is generated.** It's mirrored from the WaveCrux test suite by
> tooling — don't edit it here. To contribute a fixture, use the
> **[fixture submission form](../../issues/new?template=fixture_submission.yml)**;
> see [SUBMITTING_FIXTURES.md](../docs/SUBMITTING_FIXTURES.md).

## Layout

```
fixtures/
├── open-core/        # Fixtures for the free, open-core decoders & Stage widgets
│   ├── protocol/<decoder>/
│   └── stage/
└── pro/              # Fixtures for the Pro decoders & Pro Stage widget pack
    ├── protocol/<decoder>/
    └── stage/
```

Every protocol decoder directory is split into two tiers:

- **`generated/`** — deterministic traces emitted by WaveCrux's own fixture
  generators. 100% reproducible; the unit-test backbone. Each `.vcd` / `.fst`
  has a sibling `.expected_transactions.json` describing the transactions the
  decoder must produce.
- **`captured/`** — traces acquired or rebuilt from **permissively-licensed
  open-source projects**, exercising the decoder against real-world bus traffic.
  Each `captured/` directory carries a **`PROVENANCE.md`** recording the source
  project, version/commit, license, and how the trace was produced, plus the
  same `.expected_transactions.json` companion.

## Protocols covered

**Open core:** AHB-Lite, APB, AXI4-Lite, I²C, SPI, SPI flash, UART, Wishbone,
RISC-V trace.

**Pro:** AXI4-Full, AXI-Stream, Avalon-MM, Avalon-ST, CAN, Ethernet (MII / RMII /
GMII / RGMII / AXIS), JTAG, MDIO, PCIe TLP, USB. *(The `pro/protocol/bus_dashboard`
directory is a Stage **widget** input corpus, not a decoder corpus — it feeds the
SPI/I²C Bus Dashboard widget.)*

## Licensing

`generated/` fixtures are produced by WaveCrux's own generators and are released
into the public domain (CC0).

`captured/` fixtures retain the license of the upstream project they were derived
from — always one of **MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, ISC, CC0, or
public domain**. The exact source and license for each is in that directory's
`PROVENANCE.md`. WaveCrux's tooling refuses to publish a captured fixture that
lacks a provenance record, and the test suite blocks any fixture outside the
license allow-list.

If you reuse a captured fixture, honor the upstream license named in its
`PROVENANCE.md`.
