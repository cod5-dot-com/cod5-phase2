RM = rm -rf

all: live 

diamond/impl1/diam_impl1.bit:
	/usr/local/diamond/3.13/bin/lin64/diamondc cod5.tcl

monitor:
	 ../common/monitor /dev/ttyUSB0

live: diamond/impl1/diam_impl1.bit
	openFPGALoader -b ulx3s diamond/impl1/diam_impl1.bit

flash: diamond/impl1/diam_impl1.bit
	openFPGALoader -b ulx3s -f diamond/impl1/diam_impl1.bit

clean:
	$(RM) diamond/.setting.ini diamond/.run_manager.ini
	$(RM) diamond/*.xml diamond/impl1 diamond/*.html diamond/*.dir
