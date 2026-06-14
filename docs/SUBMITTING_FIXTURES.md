# Submitting a Test Fixture

A **fixture** is a small waveform file plus the result WaveCrux *should* produce
from it. Fixtures are how WaveCrux proves its decoders and parsers stay correct:
every fixture in [`fixtures/`](../fixtures/) runs in the test suite, so once a
trace is in, the behavior it captures can never silently regress.

If you found a trace that a decoder gets wrong — or a protocol variant we don't
cover yet — **that trace is the most valuable thing you can give us.** This guide
explains how to submit one and the rules it has to follow.

## The fastest path

1. Open the
   **[fixture submission form](../../issues/new?template=fixture_submission.yml)**.
2. Attach (or link) the waveform file — `.vcd`, `.fst`, or a `.vcd.zst`.
3. Tell us: which decoder/protocol it exercises, what WaveCrux currently does,
   and what it *should* do (the correct transactions or values).
4. Confirm the licensing (below).

We take it from there: trim it, snapshot the expected result, document its
provenance, and fold it into the suite. You'll be credited on the resulting
change.

## What makes a great fixture

- **Small and focused.** One protocol, the fewest cycles that still reproduce the
  behavior. We can trim, but a tight trace is gold. Aim for under ~5 MB.
- **A known-correct answer.** The bug isn't "it looks wrong" — it's "transaction
  3 should be a write to `0x40`, but WaveCrux shows a read." The more precisely
  you can state the expected result, the faster it becomes a test.
- **Real or hand-crafted, both welcome.** A capture from real silicon/simulation
  that breaks a decoder, or a minimal hand-built trace that isolates an edge
  case — either is great.

## Licensing — please read

Fixtures we publish must be redistributable, because [`fixtures/`](../fixtures/)
is public. We can only accept fixtures under a permissive license:

> **MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, ISC, CC0, or public domain.**

- **Your own hand-crafted trace?** Easiest case — by submitting it you agree to
  contribute it under CC0 / public domain so it can live in the test suite.
- **Derived from an open-source project?** Only if that project is under one of
  the licenses above. Tell us the project, the commit/version, and how you
  generated the trace (e.g. "ran the project's testbench under Icarus Verilog").
  We record this as provenance.
- **From proprietary, GPL, or AGPL sources, or anything you can't relicense?**
  We can't accept it — please don't attach it. A *hand-rebuilt* minimal trace
  that reproduces the same behavior without copying the original is fine.

Submissions without clear, permissive provenance can't be published, and our
tooling refuses to publish a captured fixture that lacks a provenance record.

## How fixtures are organized

See [`fixtures/README.md`](../fixtures/README.md) for the full layout. In short:

- `generated/` — deterministic traces from our own generators.
- `captured/` — real-world traces from permissively-licensed open-source
  projects, each with a `PROVENANCE.md` describing its origin and license.

Your submission typically becomes a new `captured/` entry (with provenance) or a
new `generated/` case if we can reproduce it with a generator.

Thank you — every fixture you contribute makes WaveCrux's decoders more correct
for everyone.
