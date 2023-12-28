
SYNTH=../../IDE/bin/gw_sh
TOP=cod5

GTKW = gtkwave
IVL = iverilog
VVP = vvp
IVLFLAGS = -Winfloop -g2012 -gspecify -Ttyp -Isrc

VLOG_SRC = $(shell find ./src/ -type f \( -iname c5\*.v  \))

all: impl/pnr/project.fs
	echo done

monitor:
	../common/monitor /dev/ttyUSB1

impl/pnr/project.fs:
	$(SYNTH) cod5.tcl

flash: impl/pnr/project.fs
	openFPGALoader -b tangnano20k -f impl/pnr/project.fs

## verilog simulation targets
vlog_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ $(VLOG_SRC) sim/$(TOP)_tb.v

.PHONY: %sim %sim.vvp
%sim: %sim.vvp
	$(VVP) -N sim/$< -lx2
	$(RM) sim/$^

wave: vlog_sim
	$(GTKW) sim/$(TOP)_tb.vcd sim/config.gtkw


clean:
	rm -f cod5.gprj.user
	rm -rf impl/temp impl/pnr impl/gwsynthesis
	rm -f sim/*.vcd

