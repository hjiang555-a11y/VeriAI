# GPIO Gold-Standard Simulation
# Requires: iverilog (Icarus Verilog)
# Usage:
#   make          – compile and run, print PASS/FAIL summary
#   make wave     – run and open GTKWave
#   make clean    – remove build artifacts

IV      ?= iverilog
VVP     ?= vvp
GTKWAVE ?= gtkwave

DUT_SRC  = gpio.v
TB_SRC   = tb_gpio.v
TOP      = tb_gpio
SIM_OUT  = tb_gpio.vvp
VCD_OUT  = tb_gpio.vcd

.PHONY: all sim compile wave clean

all: sim

sim: compile
	$(VVP) $(SIM_OUT)

compile: $(SIM_OUT)

$(SIM_OUT): $(TB_SRC) $(DUT_SRC)
	$(IV) -g2012 -Wall -o $(SIM_OUT) $(TB_SRC) $(DUT_SRC)

wave: compile
	$(VVP) $(SIM_OUT) && $(GTKWAVE) $(VCD_OUT) &

clean:
	rm -f $(SIM_OUT) $(VCD_OUT)
