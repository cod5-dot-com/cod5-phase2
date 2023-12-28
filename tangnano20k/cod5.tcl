set_device GW2AR-LV18QN88C8/I7
add_file "../common/src/soc.v" -type verilog
add_file "../common/src/uart.v" -type verilog
add_file "../common/src/c5_alu.v" -type verilog
add_file "../common/src/c5_ram.v" -type verilog
add_file "../common/src/c5_cpu.v" -type verilog
add_file "../common/src/c5_inc.v" -type verilog
add_file "../common/src/sdcard.v" -type verilog
add_file "../common/src/c5_mult.v" -type verilog
add_file "../common/src/display.v" -type verilog
add_file "../common/src/c5_adder.v" -type verilog
add_file "../common/src/c5_negate.v" -type verilog
add_file "../common/src/c5_control.v" -type verilog
add_file "../common/src/c5_shifter.v" -type verilog
add_file "../common/src/c5_pc_next.v" -type verilog
add_file "../common/src/spi_master.v" -type verilog
add_file "../common/src/async_fifo.v" -type verilog
add_file "../common/src/c5_bus_mux.v" -type verilog
add_file "../common/src/c5_pipeline.v" -type verilog
add_file "../common/src/c5_reg_bank.v" -type verilog
add_file "../common/src/c5_mem_ctrl.v" -type verilog
add_file "../common/src/c5_increment.v" -type verilog
add_file "../common/src/tmds_encoder.v" -type verilog
add_file "src/gpdi.v" -type verilog
add_file "src/sdram.v" -type verilog
add_file "src/gowin_rpll/TMDS_rPLL.v" -type verilog
add_file "src/gowin_rpll/gowin_rpll.v" -type verilog
add_file "src/cod5_top.v" -type verilog
add_file "src/physical_constraint.cst" -type cst
add_file "src/timing_constraint.sdc" -type sdc
set_option -top_module cod5_top
set_option -print_all_synthesis_warning 1
set_option -place_option 1
set_option -route_option 1
set_option -rpt_auto_place_io_info 1
set_option -synthesis_onoff_pragma 1
#set_option -correct_hold_violation 0
set_option -gen_sdf 1
set_option -gen_posp 1
set_option -gen_io_cst 1
set_option -gen_ibis 1
set_option -gen_text_timing_rpt 1
set_option -gen_verilog_sim_netlist 1
set_option -show_init_in_vo 1
set_option -show_all_warn 1
set_option -use_jtag_as_gpio 0
set_option -use_sspi_as_gpio 0
set_option -use_mspi_as_gpio 0
saveto -all_options project.tcl
run all

