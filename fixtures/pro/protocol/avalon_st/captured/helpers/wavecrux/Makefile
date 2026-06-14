# Rebuild the captured Avalon-ST fixture.
#
# Produces wavecrux_avalon_st_exerciser.fst by simulating our own
# CC0-1.0 Avalon-ST source+sink exerciser (`tb_avalon_st_exerciser.v`).
# Follows the public Intel "Avalon Interface Specifications" (MNL-AVABUSREF).
#
# Pipeline: pure iverilog + vvp + vcd2fst.
#
# Usage:
#   make            # compile + run + emit wavecrux_avalon_st_exerciser.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/avalon_st/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/avalon_st/captured

FIXTURE := wavecrux_avalon_st_exerciser.fst
SRCS    := tb_avalon_st_exerciser.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -o tb.vvp $(SRCS)
	vvp tb.vvp
	vcd2fst -v tb_avalon_st_exerciser.vcd -f $(FIXTURE) -Z -c
	rm -f tb.vvp tb_avalon_st_exerciser.vcd

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb.vvp tb_avalon_st_exerciser.vcd $(FIXTURE)

.PHONY: all install clean
