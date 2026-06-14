# Rebuild the captured JTAG fixture.
#
# Produces wavecrux_jtag_tap_exerciser.fst by simulating our own
# CC0-1.0 JTAG TAP exerciser (`tb_jtag_tap_exerciser.v`). Follows the
# public IEEE 1149.1 standard.
#
# Pipeline: pure iverilog + vvp + vcd2fst.
#
# Usage:
#   make            # compile + run + emit wavecrux_jtag_tap_exerciser.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/jtag/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/jtag/captured

FIXTURE := wavecrux_jtag_tap_exerciser.fst
SRCS    := tb_jtag_tap_exerciser.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -o tb.vvp $(SRCS)
	vvp tb.vvp
	vcd2fst -v tb_jtag_tap_exerciser.vcd -f $(FIXTURE) -Z -c
	rm -f tb.vvp tb_jtag_tap_exerciser.vcd

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb.vvp tb_jtag_tap_exerciser.vcd $(FIXTURE)

.PHONY: all install clean
