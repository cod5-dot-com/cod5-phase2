

## target sources
VLOG_SRC = \
	src/cod5_top.v \
	../common/src/async_fifo.v \
	../common/src/c5_adder.v \
	../common/src/c5_alu.v \
	../common/src/c5_bus_mux.v \
	../common/src/c5_control.v \
	../common/src/c5_cpu.v \
	../common/src/c5_increment.v \
	../common/src/c5_inc.v \
	../common/src/c5_mem_ctrl.v \
	../common/src/c5_negate.v \
	../common/src/c5_pc_next.v \
	../common/src/c5_pipeline.v \
	../common/src/c5_ram.v \
	../common/src/c5_reg_bank.v \
	../common/src/c5_shifter.v \
	../common/src/display.v \
	../common/src/sdcard.v \
	../common/src/soc.v \
	../common/src/spi_master.v \
	../common/src/tmds_encoder.v \
	../common/src/uart.v \
	../common/src/c5_mult.v \


TOP = cod5_top
EXE =

PRFLAGS += -ccf src/$(TOP).ccf

## toolchain
YOSYS = ../../cc-toolchain-linux/bin/yosys/yosys$(EXE)
PR    = ../../cc-toolchain-linux/bin/p_r/p_r$(EXE)
OFL   = ../../cc-toolchain-linux/bin/openFPGALoader/openFPGALoader$(EXE)

GTKW = gtkwave
IVL = iverilog
VVP = vvp
IVLFLAGS = -Winfloop -g2012 -gspecify -Ttyp

## simulation libraries
CELLS_SYNTH = ../../cc-toolchain-linux/bin/yosys/share/gatemate/cells_sim.v
CELLS_IMPL = ../../cc-toolchain-linux/bin/p_r/cpelib.v


## misc tools
RM = rm -rf

## toolchain targets
all: synth impl jtag

synth: synth_vlog

synth_vlog: $(VLOG_SRC)
	$(YOSYS) -qql log/synth.log -p 'read -vlog2k $^; synth_gatemate -top $(TOP) -nomx8 -vlog net/$(TOP)_synth.v'

synth_vhdl: $(VHDL_SRC)
	$(YOSYS) -ql log/synth.log -p 'ghdl --warn-no-binding -C --ieee=synopsys $^ -e $(TOP); synth_gatemate -top $(TOP) -nomx8 -vlog net/$(TOP)_synth.v'

impl:
	$(PR) -i net/$(TOP)_synth.v -o $(TOP) $(PRFLAGS) > log/$(TOP)_impl.log

jtag:
	$(OFL) $(OFLFLAGS) -b gatemate_evb_jtag $(TOP)_00.cfg

jtag-flash:
	$(OFL) $(OFLFLAGS) -b gatemate_evb_jtag -f --verify $(TOP)_00.cfg

spi:
	$(OFL) $(OFLFLAGS) -b gatemate_evb_spi -m $(TOP)_00.cfg

spi-flash:
	$(OFL) $(OFLFLAGS) -b gatemate_evb_spi -f --verify $(TOP)_00.cfg

## verilog simulation targets
vlog_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ $(VLOG_SRC) sim/$(TOP)_tb.v

synth_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ net/$(TOP)_synth.v sim/$(TOP)_tb.v $(CELLS_SYNTH)

impl_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ $(TOP)_00.v sim/$(TOP)_tb.v $(CELLS_IMPL)

.PHONY: %sim %sim.vvp
%sim: %sim.vvp
	$(VVP) -N sim/$< -lx2
	@$(RM) sim/$^

wave:
	$(GTKW) sim/$(TOP)_tb.vcd sim/config.gtkw

clean:
	$(RM) log/*.log
	$(RM) net/*_synth.v
	$(RM) *.history
	$(RM) *.txt
	$(RM) *.refwire
	$(RM) *.refparam
	$(RM) *.refcomp
	$(RM) *.pos
	$(RM) *.pathes
	$(RM) *.path_struc
	$(RM) *.net
	$(RM) *.id
	$(RM) *.prn
	$(RM) *_00.v
	$(RM) *.used
	$(RM) *.sdf
	$(RM) *.place
	$(RM) *.pin
	$(RM) *.cfg*
	$(RM) *.cdf
	$(RM) sim/*.vcd
	$(RM) sim/*.vvp
	$(RM) sim/*.gtkw
