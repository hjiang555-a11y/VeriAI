# UART Gold-Standard Simulation
# Requires: iverilog (Icarus Verilog)
# Usage:
#   make          – compile and run, print PASS/FAIL summary
#   make wave     – run and open GTKWave
#   make clean    – remove build artifacts

OSS_CAD  ?= $(HOME)/.apio/packages/oss-cad-suite
IVERILOG := $(OSS_CAD)/bin/iverilog
VVP      := $(OSS_CAD)/bin/vvp
GTKWAVE  = gtkwave

TOP    = tb_uart
DUT_SRC ?= uart.v
SRC    = $(DUT_SRC) $(TOP).v
OUT    = build/$(TOP).out
VCD    = build/$(TOP).vcd
IVFLAGS = -g2012 -Wall

.PHONY: all wave clean

all: $(OUT)
	$(VVP) $(OUT)

$(OUT): $(SRC)
	@mkdir -p build
	$(IVERILOG) $(IVFLAGS) -o $@ $(SRC)

wave: $(VCD)
	$(GTKWAVE) $(VCD) &

$(VCD): $(OUT)
	$(VVP) -n $(OUT) -dumpfile=$(VCD)

clean:
	rm -rf build
