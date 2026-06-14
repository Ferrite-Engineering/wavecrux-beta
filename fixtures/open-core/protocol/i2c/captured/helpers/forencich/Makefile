# Rebuild the captured I²C fixture.
#
# Produces i2c_forencich_master_slave.fst by simulating Alex Forencich's
# i2c_master + i2c_slave (vendored verbatim from `verilog-i2c`, MIT)
# wired together on a shared open-drain SDA/SCL bus with explicit
# pull-ups. The master is driven with a hand-written AXIS command
# program that performs two back-to-back writes (2 bytes then 1 byte)
# to the slave at 7-bit address 0x50.
#
# Pipeline matches the picorv32 captures: no cocotb, no Python — pure
# Verilog + iverilog + vvp.
#
# Usage:
#   make            # compile + run, emit i2c_forencich_master_slave.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/i2c/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/i2c/captured

FIXTURE := i2c_forencich_master_slave.fst
SRCS    := tb_i2c_master_slave.v i2c_master.v i2c_slave.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -o tb_i2c.vvp $(SRCS)
	vvp tb_i2c.vvp -fst

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb_i2c.vvp $(FIXTURE)

.PHONY: all install clean
