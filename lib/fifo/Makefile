# Simulation Makefile for sync_fifo gold-standard
# Requires: Icarus Verilog (iverilog / vvp) – free, cross-platform
#
# Usage:
#   make          – compile and run simulation
#   make sim      – same as default
#   make compile  – compile only
#   make wave     – run + open waveform in GTKWave (requires gtkwave)
#   make clean    – remove build artifacts

# -----------------------------------------------------------------------
# Tool configuration
# -----------------------------------------------------------------------
IV      ?= iverilog
VVP     ?= vvp
GTKWAVE ?= gtkwave

# -----------------------------------------------------------------------
# Source files
# -----------------------------------------------------------------------
DUT_SRC  = sync_fifo.v
TB_SRC   = tb_sync_fifo.v
TOP      = tb_sync_fifo

# -----------------------------------------------------------------------
# Output artefacts
# -----------------------------------------------------------------------
SIM_OUT  = tb_sync_fifo.vvp
VCD_OUT  = tb_sync_fifo.vcd

# -----------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------
.PHONY: all sim compile wave clean

all: sim

sim: compile
	$(VVP) $(SIM_OUT)

compile: $(SIM_OUT)

$(SIM_OUT): $(TB_SRC) $(DUT_SRC)
	$(IV) -g2001 -Wall -o $(SIM_OUT) $(TB_SRC) $(DUT_SRC)

wave: compile
	$(VVP) $(SIM_OUT) && $(GTKWAVE) $(VCD_OUT) &

clean:
	rm -f $(SIM_OUT) $(VCD_OUT)
