# Rebuild the captured AHB-Lite fixture.
#
# Produces ahb_lite_shalan_dmac.fst by simulating Mohamed Shalan's
# MS_DMAC_AHBL DMA controller (vendored verbatim from shalan/MS_DMAC_AHBL,
# Apache-2.0) wrapped in a pure-Verilog testbench. The testbench
# configures the DMAC's slave AHB-Lite port (CTRL/SADDR/DADDR/SIZE +
# software trigger) and captures the master AHB-Lite port (where the
# DMAC drives the actual word reads from 0x4000_0000 and writes to
# 0x5000_0000). HBURST and HRESP are tied to constants on the master
# side (SINGLE / OKAY) since the DMAC implements neither — they are
# exposed as named wires for the decoder to bind.
#
# Pipeline matches the picorv32 / forencich captures: no cocotb, no
# Python — pure Verilog + iverilog + vvp.
#
# Usage:
#   make            # compile + run, emit ahb_lite_shalan_dmac.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/ahb_lite/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/ahb_lite/captured

FIXTURE := ahb_lite_shalan_dmac.fst
SRCS    := tb_ms_dmac_ahbl.v MS_DMAC_AHBL.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -I. -o tb_ahb.vvp $(SRCS)
	vvp tb_ahb.vvp -fst

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb_ahb.vvp $(FIXTURE)

.PHONY: all install clean
