
SYNTH=/tools/Xilinx/Vivado/2022.2/bin/setEnvAndRunCmd.sh vivado -mode batch -source 

TOP=cod5_top

all: cod5_top.bit
	echo done

monitor:
	../common/monitor /dev/ttyUSB1

cod5_top.bit:
	$(SYNTH) cod5.tcl

live:
	openFPGALoader -b arty_s7_50 vivado/vivado.runs/impl_1/cod5_top.bit

flash:
	openFPGALoader -b arty_s7_50 -f vivado/vivado.runs/impl_1/cod5_top.bit

clean:
	rm -f cod5.gprj.user
	rm -rf impl/temp impl/pnr impl/gwsynthesis
	rm -f sim/*.vcd
	rm -f *.jou *.prj *.log
