# Rebuild the captured Wishbone fixture.
#
# Produces wishbone_picorv32_wb_ez.fst by simulating YosysHQ's
# picorv32_wb core (vendored verbatim from picorv32.v, ISC) wired to a
# tiny in-memory Wishbone slave preloaded with the same six-instruction
# loop as upstream testbench_ez.v (public domain). No RISC-V toolchain
# required — the program is embedded as hand-encoded RV32I words.
#
# Usage:
#   make            # compile + run, emit wishbone_picorv32_wb_ez.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/wishbone/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/wishbone/captured

FIXTURE := wishbone_picorv32_wb_ez.fst
SRCS    := tb_picorv32_wb_ez.v picorv32.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -o tb_picorv32_wb_ez.vvp $(SRCS)
	vvp tb_picorv32_wb_ez.vvp -fst

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb_picorv32_wb_ez.vvp $(FIXTURE)

.PHONY: all install clean
