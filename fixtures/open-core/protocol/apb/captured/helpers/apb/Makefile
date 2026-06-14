# Rebuild the captured APB fixture.
#
# Produces apb_axil2apb.fst by simulating Gisselquist Technology's
# axil2apb + apbslave (both vendored verbatim from ZipCPU/wb2axip,
# Apache-2.0) driven by the in-tree tb_apb.v testbench. Toolchain:
# icarus-verilog only. No Python / cocotb dependencies.
#
# Usage:
#   make            # compile + run, emit apb_axil2apb.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/apb/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/apb/captured

FIXTURE := apb_axil2apb.fst
SRCS    := tb_apb.v axil2apb.v apbslave.v skidbuffer.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -o tb_apb.vvp $(SRCS)
	vvp tb_apb.vvp -fst

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb_apb.vvp $(FIXTURE)

.PHONY: all install clean
