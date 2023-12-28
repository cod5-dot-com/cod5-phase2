
GTKW = gtkwave
IVL = iverilog
VVP = vvp
IVLFLAGS = -Winfloop -g2012 -gspecify -Ttyp -Isrc

all: monitor rom.v soc_sim 
	@echo done

dump2v: tools/dump2v.c
	cc -Wall -o dump2v tools/dump2v.c

monitor: tools/monitor.c
	cc -Wall -o monitor tools/monitor.c

rom.v: dump2v src/rom.s
	mipsel-linux-gnu-as -mabi=32 -march=mips1 -msoft-float -EL  -o rom.o src/rom.s
	mipsel-linux-gnu-ld -O0 -nostdlib -Ttext=0 -mabi=32 -melf32ltsmip -EL  -o rom rom.o
	mipsel-linux-gnu-objdump -d rom > rom.txt
	./dump2v rom.txt rom.v
	cp rom.v ../common/src/

redhat-rom.v: dump2v src/rom.s
	mips64-linux-gnu-as -mabi=32 -march=mips1 -msoft-float -EL  -o rom.o src/rom.s
	mips64-linux-gnu-ld -O0 -nostdlib -Ttext=0 -mabi=32 -melf32ltsmip -EL  -o rom rom.o
	mips64-linux-gnu-objdump -d rom > rom.txt
	./dump2v rom.txt rom.v
	cp rom.v ../common/src/


c5_alu_sim.vvp: sim/c5_alu_tb.v
	$(IVL) $(IVLFLAGS) -o sim/$@ src/c5_adder.v src/c5.v src/c5_alu.v $<

c5_increment_sim.vvp: sim/c5_increment_tb.v
	$(IVL) $(IVLFLAGS) -o sim/$@ src/c5_increment.v $<

c5_negate_sim.vvp: sim/c5_negate_tb.v
	$(IVL) $(IVLFLAGS) -o sim/$@ src/c5_negate.v $<

c5_shifter_sim.vvp: sim/c5_shifter_tb.v
	$(IVL) $(IVLFLAGS) -o sim/$@ src/c5.v src/c5_shifter.v $<

c5_cpu_sim.vvp: sim/c5_cpu_tb.v
	$(IVL) $(IVLFLAGS) -o sim/$@ \
		src/c5_shifter.v \
		src/c5_cpu.v \
		src/c5_mult.v \
		src/c5_negate.v \
		src/c5_alu.v \
		src/c5_adder.v \
		src/c5_increment.v \
		src/c5_bus_mux.v \
		src/c5_control.v \
		src/c5_pc_next.v \
        	src/c5_reg_bank.v \
        	src/c5_pipeline.v \
        	src/c5_ram.v \
        	src/c5_mem_ctrl.v \
		$<

soc_sim.vvp: sim/soc_tb.v
	$(IVL) $(IVLFLAGS) -o sim/$@ \
		src/c5_shifter.v \
		src/display.v \
		sim/gpdi.v \
		src/c5_cpu.v \
		src/uart.v \
		src/c5_mult.v \
		src/c5_negate.v \
		src/c5_alu.v \
		src/c5_adder.v \
		src/c5_increment.v \
		src/c5_bus_mux.v \
		src/c5_control.v \
		src/c5_pc_next.v \
        	src/c5_reg_bank.v \
        	src/c5_pipeline.v \
        	src/c5_ram.v \
        	src/c5_mem_ctrl.v \
        	src/soc.v \
		$<


.PHONY: %sim %sim.vvp
%sim: %sim.vvp
	$(VVP) -N sim/$< -lx2
	$(RM) sim/$^

wave: vlog_sim
	$(GTKW) sim/$(TOP)_tb.vcd sim/config.gtkw

clean:
	rm -f monitor
	rm -f rom.v0 rom.v1 rom.v2 rom.v3 rom.v.data
	rm -f sim/*.vvp
	rm -f rom.v rom.txt rom.o dump2v a.out rom

