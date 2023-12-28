
export PATH := $(HOME)/.local/bin:$(HOME)/intelFPGA_lite/20.1/quartus/bin:$(PATH)


all: build/arduino.ino.hex
	@echo build done.

install: all
	arduino-cli upload -p /dev/ttyACM0 \
		--fqbn arduino:samd:mkrvidor4000 \
		--input-dir ./build arduino

monitor: 
	arduino-cli monitor -p /dev/ttyACM0 


build/arduino.ino.hex: arduino/app.h arduino/arduino.ino
	mkdir -p build
	arduino-cli compile --fqbn arduino:samd:mkrvidor4000 \
		--output-dir ./build arduino

src/cod5.ttf: src/cod5/mkrvidor4000_top.v
	(\
	       	cd src; \
	       	hdlmake fetch; \
		hdlmake; \
		make; \
	)

arduino/app.h: ttf2h src/cod5.ttf 
	./ttf2h src/cod5.ttf arduino/app.h 

ttf2h: src/ttf2h.c
	cc -Wall -o ttf2h src/ttf2h.c

clean:
	rm -f ttf2h
	(\
	       	cd ./sim/spi/; \
		make clean; \
		make mrproper; \
		rm -f Makefile; \
	) 
	(\
	       	cd ./src/; \
		make clean; \
		make mrproper; \
		rm -f *.ttf *.sdc *.sld Makefile; \
	)
	rm -f arduino/app.h bin/arduino-cli
	rm -rf build

distclean: clean
	rm -rf ip_cores/*

