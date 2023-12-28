
TOP=cod5

all: cod5.ttf 
	@echo done.

cod5.ttf: 
	$(QSYS_ROOTDIR)/../../bin/quartus_sh -t $(TOP).tcl -project $(TOP) -revision 1.0.0 

jack:
	../../djak/dj303.run arduino/jtag arduino/jtag.jack arduino/jtag.h


flash: jack all build/arduino.ino.hex 
	arduino-cli upload -p /dev/ttyACM0 \
		--fqbn arduino:samd:mkrvidor4000 \
		--input-dir ./build arduino

monitor:
	arduino-cli monitor -p /dev/ttyACM0


build/arduino.ino.hex: arduino/app.h arduino/arduino.ino arduino/jtag.jack.c
	mkdir -p build
	arduino-cli compile --fqbn arduino:samd:mkrvidor4000 \
		--output-dir ./build arduino


arduino/app.h: ttf2h cod5.ttf
	./ttf2h cod5.ttf arduino/app.h

ttf2h: tools/ttf2h.c
	cc -Wall -o ttf2h tools/ttf2h.c

dump2v: tools/dump2v.c
	cc -Wall -o dump2v tools/dump2v.c

clean:
	rm -f *.summary *.qsf *.qpf *.rpt *.smsg *.ttf
	rm -f ttf2h *.pin *.sld *.pof *.done *.jdi *.sof
	rm -rf incremental_db
	rm -rf db/
	rm -rf build/
