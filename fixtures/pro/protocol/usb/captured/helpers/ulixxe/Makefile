# Rebuild the captured USB 2.0 fixture.
#
# Produces ulixxe_usb_cdc_host_tx.fst by simulating a small 0BSD
# testbench (tb_usb_cdc_host_tx.v) that drives D+/D- via the vendored
# ulixxe/usb_cdc host-side packet emitters (MIT). The emitters generate
# NRZI-encoded, bit-stuffed, CRC-computed USB 2.0 Full-Speed packets
# byte-for-byte per the spec.
#
# Sequence emitted: SOF (frame 0x123) → SETUP token (addr=0, ep=0) →
# DATA0 (8-byte GET_DESCRIPTOR(DEVICE) setup packet) → ACK handshake.
#
# Pipeline: pure iverilog + vvp + vcd2fst.
#
# Usage:
#   make            # compile + run + emit ulixxe_usb_cdc_host_tx.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/usb/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/usb/captured

FIXTURE := ulixxe_usb_cdc_host_tx.fst
SRCS    := tb_usb_cdc_host_tx.v
INCLUDES:= -I .

all: $(FIXTURE)

$(FIXTURE): $(SRCS) usb_tasks.v usb_rx_tasks.v sim_tasks.v
	iverilog -g2005 $(INCLUDES) -o tb.vvp $(SRCS)
	vvp tb.vvp
	vcd2fst -v tb_usb_cdc_host_tx.vcd -f $(FIXTURE) -Z -c
	rm -f tb.vvp tb_usb_cdc_host_tx.vcd

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb.vvp tb_usb_cdc_host_tx.vcd $(FIXTURE)

.PHONY: all install clean
