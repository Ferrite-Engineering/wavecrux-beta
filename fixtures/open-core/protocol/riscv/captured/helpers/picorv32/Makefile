# Rebuild the captured RISC-V instruction-fetch fixture.
#
# Produces riscv_picorv32_wb_ez.fst by simulating YosysHQ's picorv32_wb
# core (vendored verbatim from picorv32.v, ISC) wired to a tiny in-memory
# Wishbone slave preloaded with the same six-instruction loop as upstream
# testbench_ez.v (public domain). No RISC-V toolchain required — the
# program is embedded as hand-encoded RV32I words.
#
# Compared to the sibling wishbone capture, this variant connects
# picorv32_wb's `mem_instr` output (tied off there) and derives an
# `ifetch_valid` strobe so the WaveCrux RISC-V decoder consumes only
# completed ifetch transactions and skips data load/store reads that
# share wb_ack.
#
# Usage:
#   make            # compile + run, emit riscv_picorv32_wb_ez.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/riscv/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/riscv/captured

FIXTURE := riscv_picorv32_wb_ez.fst
SRCS    := tb_picorv32_riscv_ez.v picorv32.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -o tb_picorv32_riscv_ez.vvp $(SRCS)
	vvp tb_picorv32_riscv_ez.vvp -fst

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb_picorv32_riscv_ez.vvp $(FIXTURE)

.PHONY: all install clean
