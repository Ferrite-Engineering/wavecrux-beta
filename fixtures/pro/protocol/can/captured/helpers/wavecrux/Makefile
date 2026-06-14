# Rebuild the captured CAN fixture.
#
# Produces wavecrux_can_exerciser.fst by simulating our own CC0-1.0
# CAN 2.0A Standard Data Frame exerciser (`tb_can_exerciser.v`).
# Follows ISO 11898-1 packet format + the wavecrux CAN decoder's
# de-stuffed application-layer signal convention.
#
# Pipeline: pure iverilog + vvp + vcd2fst.

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/can/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/can/captured

FIXTURE := wavecrux_can_exerciser.fst
SRCS    := tb_can_exerciser.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2005 -o tb.vvp $(SRCS)
	vvp tb.vvp
	vcd2fst -v tb_can_exerciser.vcd -f $(FIXTURE) -Z -c
	rm -f tb.vvp tb_can_exerciser.vcd

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb.vvp tb_can_exerciser.vcd $(FIXTURE)

.PHONY: all install clean
