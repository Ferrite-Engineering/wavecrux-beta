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

Looking for something to *open* rather than something to read? The
[`examples/`](../examples/) tree next door holds ready-to-open `.wavecrux`
sessions. See [`examples/README.md`](../examples/README.md).

## Layout

```
fixtures/
├── open-core/       # Fixtures for the free, open-core decoders & Stage widgets
│   ├── protocol/<decoder>/{generated,captured}/
│   └── stage/       # the Stage demo trace and the sample-widget corpus
└── pro/             # Fixtures for the Pro decoders & Pro Stage widget pack
    ├── protocol/<decoder>/{generated,captured}/
    └── stage/<widget>/
```

Every protocol decoder directory is split into two tiers:

- **`generated/`** — deterministic traces emitted by WaveCrux's own fixture
  generators. 100% reproducible; the unit-test backbone. Each `.vcd` / `.fst`
  has a sibling `.expected_*.json` describing what the decoder must produce —
  usually `.expected_transactions.json`, but the RISC-V corpus also carries
  `.expected_retire_stream.json`, `.expected_pipeline.json` and
  `.expected_violations.json`, because a trace decoder answers more than one
  question about the same trace.
- **`captured/`** — traces acquired or rebuilt from **permissively-licensed
  open-source projects**, exercising the decoder against real-world bus traffic.
  Each `captured/` directory carries a **`PROVENANCE.md`** recording the source
  project, version/commit, license, and how the trace was produced, plus the
  same expectation companion.

### Fixtures that are meant to fail

Some `generated/` fixtures are deliberately broken. The RISC-V RVFI set is the
clearest case: `riscv_rvfi_retire.vcd` is a well-formed retirement stream, and
six siblings — `riscv_rvfi_bad_pc_wdata`, `_x0_write`, `_rd_addr`, `_mem_mask`,
`_order`, `_trap` — corrupt exactly one property of it each. Their
`.expected_violations.json` names the violations the consistency checker must
raise, and the clean sibling is half the test: it must raise **none**. A
checker that fires on everything passes the broken six and fails the corpus.

### Captured from real cores

`open-core/protocol/riscv/captured/riscv_ibex_rvfi_trap.fst` is the first trace
in this corpus taken from RTL nobody on the WaveCrux team wrote — lowRISC's
[Ibex](https://github.com/lowRISC/ibex) core (Apache-2.0), built from a pinned
upstream commit and run against a hand-assembled RV32I program that works
through arithmetic, byte/halfword/word loads and stores, a taken branch, a
counted loop, and finally an `ecall` into a trap handler. Its
`PROVENANCE.md` records the commit, the exact Verilator invocation, the
hand-verified anchor instructions, and — worth reading — two places where
upstream Ibex's RVFI output departs from the RVFI specification. Those
deviations are **not** suppressed: the consistency checker reports them, because
a fixture that hides what a real core actually does is not a fixture of a real
core.

### Stage fixtures

`open-core/stage/` and `pro/stage/<widget>/` hold the traces the Stage widgets
are driven from. A few carry a `.wavecrux` session alongside the trace —
`pro/stage/riscv/riscv_demo.wavecrux` is the fullest one — and those open the
same way any session does. If you only want something to open, start with
[`examples/`](../examples/) instead; these are corpus first and demo second.

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
