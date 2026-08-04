# RISC-V captured-fixture helpers (lowRISC Ibex, RVFI)

Rebuild recipe for `riscv_ibex_rvfi_trap.fst` — the corpus's real-core
RVFI capture.

Every other RVFI fixture in this repo comes out of
`tool/generate_riscv_fixtures.dart`: we pick the signal names, the
hierarchy, the widths and the retirement timing. Those are excellent
regression locks and no evidence at all that the RVFI substrate works
against RTL written by somebody else. This one is a Verilator capture of
lowRISC's [Ibex](https://github.com/lowRISC/ibex) (Apache-2.0) with
`+define+RVFI`, so every one of those properties is Ibex's choice rather
than ours.

## Why Ibex is not vendored

The sibling picorv32 helper vendors `picorv32.v` verbatim — one file. That
is not an option here: `ibex_top` pulls in ~30 RTL files plus lowRISC's
`prim` / `prim_generic` cell libraries. The `Makefile` fetches the pinned
commit instead:

```
IBEX_SHA := 3250d99482f1963891ef1cf19356eeaeeaa71d30
```

using a single-commit shallow fetch, so the build is exactly reproducible
without carrying Ibex's history or its source tree in this repo. `make
distclean` removes the clone.

## No RISC-V toolchain required

Same constraint as the picorv32 helper, same answer: `assemble.py`
hand-encodes the RV32I program and writes a `$readmemh` image. There is no
dependency on `riscv32-unknown-elf-gcc`.

Memory map (1 KiB, byte addresses 0x000–0x3FF):

| Region | Purpose |
|--------|---------|
| 0x000  | trap handler — Ibex's `mtvec` resets to `boot_addr_i`, vectored |
| 0x080  | reset vector — Ibex resets to `boot_addr_i + 0x80` |
| 0x200  | data scratch |

`boot_addr_i` is tied to 0, so both land in the same 1 KiB.

## Files committed here

- `tb_ibex_rvfi.sv` — our testbench. Clock, reset, a 1 KiB dual-port
  memory (separate instruction and data ports, one-cycle grant/rvalid),
  and the `ibex_top` tie-offs copied from upstream's own
  `examples/simple_system/rtl/ibex_simple_system.sv`. SPDX `0BSD`.
  Nothing in Ibex itself is modified.
- `assemble.py` — the RV32I encoder. Emits `prog.hex` and a `prog.lst`
  listing. SPDX `0BSD`.
- `trim.py` — the waveform filter, see below. SPDX `0BSD`.
- `Makefile` — `make` fetches, builds, runs and trims; `make install`
  copies the FST into both the `test/` and `verification/` trees.

## Why there is a trim step

Verilator **ignores the scope and level arguments to `$dumpvars`** — asking
for two signals dumps the entire design anyway. `--trace-depth` is not a
substitute either: Verilator inlines `ibex_top`'s children into it, so
depth 1 gives the testbench alone (17 signals) and depth 2 already gives
the whole core (2596 signals, 42530 bytes).

`trim.py` therefore does the selection after the fact, via gtkwave's
`fst2vcd` → filter → `vcd2fst`. It keeps `clk`, `rst_n`, and the 21 RVFI
channels WaveCrux binds, at their real hierarchical names
(`tb_ibex_rvfi.u_ibex_top.rvfi_*`). Result: **1841 bytes**, smaller than
the picorv32 capture, with the real core scope preserved. The script fails
loudly if any whitelisted signal is missing, so a rename upstream cannot
silently produce a thinner fixture.

## Rebuild

```
cd test/fixtures/protocol/riscv/captured/helpers/ibex
make && make install
```

Requires `verilator` (≥ 5.0, built with FST support), gtkwave's `fst2vcd`
and `vcd2fst`, `python3`, and `git`. On macOS the `Makefile` locates
Homebrew's `lz4` for you — Verilator's FST writer needs it and it is not on
the default search path.

Then regenerate the decoded snapshot in both trees:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/riscv_captured_fixtures_test.dart
cp test/fixtures/protocol/riscv/captured/riscv_ibex_rvfi_trap.expected_transactions.json \
   verification/fixtures/protocol/riscv/captured/riscv_ibex_rvfi_trap.expected_transactions.json
```

The waveform is deterministic — only the VCD `$date` header differs between
runs, so a rebuilt FST is not byte-identical to the committed one even
though the samples are.

## The program

| addr  | word         | assembly              | note |
|-------|--------------|-----------------------|------|
| 0x000 | `0x34202673` | `csrrs x12, mcause, x0` | trap handler entry |
| 0x004 | `0x341026f3` | `csrrs x13, mepc, x0`   | |
| 0x008 | `0x02a00713` | `addi x14, x0, 42`      | |
| 0x00c | `0x10500073` | `wfi`                   | core sleeps; capture ends |
| 0x080 | `0x12300093` | `addi x1, x0, 0x123`    | reset vector |
| 0x084 | `0x45600113` | `addi x2, x0, 0x456`    | |
| 0x088 | `0x002081b3` | `add x3, x1, x2`        | → 0x579 |
| 0x08c | `0x40110233` | `sub x4, x2, x1`        | → 0x333 |
| 0x090 | `0x20000293` | `addi x5, x0, 0x200`    | data base |
| 0x094 | `0x0032a023` | `sw x3, 0(x5)`          | word store |
| 0x098 | `0x0002a303` | `lw x6, 0(x5)`          | word load |
| 0x09c | `0x00618463` | `beq x3, x6, +8`        | taken |
| 0x0a0 | `0xfff00393` | `addi x7, x0, -1`       | **never retired** |
| 0x0a4 | `0x05a00413` | `addi x8, x0, 0x5a`     | |
| 0x0a8 | `0x00828223` | `sb x8, 4(x5)`          | byte store |
| 0x0ac | `0x0042c483` | `lbu x9, 4(x5)`         | byte load |
| 0x0b0 | `0x00329423` | `sh x3, 8(x5)`          | halfword store |
| 0x0b4 | `0x0082d503` | `lhu x10, 8(x5)`        | halfword load |
| 0x0b8 | `0x0041c5b3` | `xor x11, x3, x4`       | → 0x64a |
| 0x0bc | `0x00300793` | `addi x15, x0, 3`       | loop counter |
| 0x0c0 | `0xfff78793` | `addi x15, x15, -1`     | loop: — retired 3× |
| 0x0c4 | `0xfe079ee3` | `bne x15, x0, -4`       | backward branch |
| 0x0c8 | `0x00000073` | `ecall`                 | traps to 0x000 |

26 retirements in total. `rvfi_order` runs densely from 1 to 26.

The two `csrrs` and the `wfi` decode as `UNKNOWN INSN` in the committed
snapshot: `assets/decoders/isa/riscv/` carries RV32I/M/A/F/C and
RV64I/M/A/D/C, and no Zicsr or privileged-system TOML. That gap is real and
is recorded rather than designed around.

## Two RVFI deviations this capture found in upstream Ibex

The capture was expected to produce zero consistency violations. It
produces 21, and they are pinned rather than suppressed — see
`test/services/riscv/riscv_ibex_captured_rvfi_test.dart` for the full
write-up, and `PROVENANCE.md` for the short form. In brief:

1. **`rvfi_mem_rmask` is `4'b1111` on every non-store.** `ibex_core.sv:1653`
   derives it from `lsu_type` alone; for an instruction with no memory
   access `lsu_type` is `ibex_decoder.sv:227`'s unconditional default
   (the word encoding), and nothing gates the assignment on whether a
   request was issued. RVFI defines a zero mask as "no memory access", so a
   literal reading reports a four-byte read on every `addi`. 19 of the
   21 violations.
2. **`rvfi_pc_wdata` is PC+4, not the handler, on a trapping instruction.**
   `ibex_core.sv:1652` samples it when the ID stage completes, one cycle
   before the controller applies the exception redirect. The `ecall` at
   0x0c8 retires with `rvfi_trap=1` and `rvfi_pc_wdata=0x0cc`, while the
   next retirement's `rvfi_pc_rdata` is `0x000`. Trips `controlFlow` and
   `trapConsistency`, one violation each.

Both are properties of the RTL, readable from the source without running
anything, and neither field is checked by Ibex's own DV.

## Limits of this capture

- **Two-state only.** Verilator has no `x`/`z`, so there is no
  X-propagation anywhere in this trace, including at time zero. A
  four-state capture would exercise `hasUnknownBits`; this one cannot, and
  the test asserts their absence so the gap stays visible.
- **One retirement per cycle.** Ibex's RVFI *ports* are scalar, so this
  fixture says nothing about packed-NRET bundle detection.
