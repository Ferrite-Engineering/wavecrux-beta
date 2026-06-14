# RISC-V captured-fixture helpers (picorv32_wb)

The RISC-V captured fixture (`riscv_picorv32_wb_ez.fst`) reuses the
exact `picorv32_wb` + WB-slave testbench shape used for the sibling
Wishbone capture (see
`../../../wishbone/captured/helpers/picorv32/README.md`), with one
delta: the testbench connects `picorv32_wb`'s `mem_instr` output
(otherwise tied off) and derives an `ifetch_valid` strobe so the
WaveCrux RISC-V decoder consumes only completed instruction-fetch
transactions and ignores data load/store reads that share `wb_ack`.

Same no-cocotb + no-RISC-V-toolchain pipeline as Wishbone: vendor
`picorv32.v` (ISC) and preload the WB slave's memory with the same
six-instruction loop that upstream `testbench_ez.v` uses (public
domain). No `riscv32-unknown-elf-gcc` required.

Files committed here:

- `picorv32.v` — vendored from upstream commit
  `87c89acc18994c8cf9a2311e871818e87d304568`. ISC header preserved.
  Claire Xenia Wolf's RV32I core, including the `picorv32_wb`
  Wishbone-master wrapper.
- `tb_picorv32_riscv_ez.v` — our pure-Verilog testbench. Wires
  `picorv32_wb` to a 256-word in-memory WB slave preloaded with the
  same six-instruction loop as the sibling Wishbone capture, plus the
  `mem_instr` port wired through to a top-level wire and a derived
  `ifetch_valid = wb_ack & mem_instr` strobe. SPDX `0BSD` (public
  domain).
- `Makefile` — `make` builds + runs (produces
  `riscv_picorv32_wb_ez.fst` in this directory); `make install` copies
  the FST into both `test/` and `verification/` trees.

Rebuild: `cd helpers/picorv32 && make && make install`. Requires only
`iverilog` + `vvp` from icarus-verilog (already in PATH).

After rebuilding the FST, regenerate the decoded snapshot in both
trees with:

```
cd <repo_root>
REGENERATE=1 flutter test test/services/decoders/riscv_captured_fixtures_test.dart
cp test/fixtures/protocol/riscv/captured/riscv_picorv32_wb_ez.expected_transactions.json \
   verification/fixtures/protocol/riscv/captured/riscv_picorv32_wb_ez.expected_transactions.json
```

## Decoded stream

The capture exercises seven ifetch completions across one full pass
through the upstream loop body plus the first instruction of the
second iteration after the `j loop` backward jump:

| t (ns) | PC      | Instruction              | Disassembly             |
|--------|---------|--------------------------|-------------------------|
| 80     | 0x0000  | `0x3FC00093`             | `addi ra, zero, 1020`   |
| 140    | 0x0004  | `0x0000A023`             | `sw zero, 0(ra)`        |
| 200    | 0x0008  | `0x0000A103`             | `lw sp, 0(ra)`          |
| 310    | 0x000C  | `0x00110113`             | `addi sp, sp, 1`        |
| 420    | 0x0010  | `0x0020A023`             | `sw sp, 0(ra)`          |
| 480    | 0x0014  | `0xFF5FF06F`             | `jal zero, …` (-12B)    |
| 590    | 0x0008  | `0x0000A103`             | `lw sp, 0(ra)` (loop)   |

The PC trace confirms the `jal` at 0x14 takes a -12-byte backward
branch to 0x08 as expected. Data load/store transactions on the bus
(reads from 0x3FC, writes to 0x3FC) are correctly skipped because
their `mem_instr` is low, so they never raise `ifetch_valid`.

## Documented immediate-display behavior

The `jal` at PC=0x14 displays its immediate as `-2561` rather than
the architectural byte offset `-12`. This is **intentional**, not a
bug: per `VERIFICATION_GUIDE.md` §5.9.10, the JKU/Surfer TOML schema
reassembles J-type and B-type immediates by concatenating bit slices
in instruction-word MSB-first order, which produces a deterministic
"bit-shuffled" value for offsets where `imm[11]` (B-type) or
`imm[11]` / `imm[19:12]` (J-type) are non-zero. The PC chain is
correct (the next ifetch lands at PC=0x08, the true `loop:` target),
so the underlying branch-target arithmetic is right — only the
displayed immediate departs from architectural byte units, and it
does so identically across WaveCrux and Surfer.
