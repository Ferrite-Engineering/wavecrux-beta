# Rebuild the captured PCIe TLP fixture.
#
# Produces wavecrux_pcie_tlp_exerciser.fst by simulating our own
# CC0-1.0 PCIe TLP exerciser (`tb_pcie_tlp_exerciser.v`). Emits four
# canonical TLP packets back-to-back on the 32-bit DW AXIS-style
# interface — formats from the public PCIe Base Specification (PCI-SIG).
#
# Pipeline: pure iverilog + vvp + vcd2fst.

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/pcie_tlp/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/pcie_tlp/captured

FIXTURE := wavecrux_pcie_tlp_exerciser.fst
SRCS    := tb_pcie_tlp_exerciser.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2005 -o tb.vvp $(SRCS)
	vvp tb.vvp
	vcd2fst -v tb_pcie_tlp_exerciser.vcd -f $(FIXTURE) -Z -c
	rm -f tb.vvp tb_pcie_tlp_exerciser.vcd

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb.vvp tb_pcie_tlp_exerciser.vcd $(FIXTURE)

.PHONY: all install clean
