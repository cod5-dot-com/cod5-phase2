add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/async_fifo.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_adder.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_alu.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_bus_mux.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_control.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_cpu.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_inc.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_increment.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_mem_ctrl.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_mult.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_negate.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_pc_next.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_pipeline.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_ram.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_reg_bank.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/c5_shifter.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/display.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/sdcard.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/soc.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/spi_master.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/tmds_encoder.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/common/src/uart.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/tangnano20k/src/cod5_top.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/tangnano20k/src/gowin_rpll/TMDS_rPLL.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/tangnano20k/src/gowin_rpll/gowin_rpll.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/tangnano20k/src/gpdi.v"
add_file -type verilog "/home/jml/Documents/src/cod5-phase2/tangnano20k/src/sdram.v"
add_file -type cst "/home/jml/Documents/src/cod5-phase2/tangnano20k/src/physical_constraint.cst"
add_file -type sdc "/home/jml/Documents/src/cod5-phase2/tangnano20k/src/timing_constraint.sdc"
set_device GW2AR-LV18QN88C8/I7 -device_version C
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name project
set_option -top_module cod5_top
set_option -verilog_std v2001
set_option -vhdl_std vhd1993
set_option -print_all_synthesis_warning 1
set_option -allow_duplicate_modules 0
set_option -multi_file_compilation_unit 1
set_option -auto_constraint_io 0
set_option -default_enum_encoding default
set_option -compiler_compatible 1
set_option -disable_io_insertion 0
set_option -fix_gated_and_generated_clocks 1
set_option -frequency Auto
set_option -looplimit 2000
set_option -maxfan 10000
set_option -pipe 1
set_option -resolve_multiple_driver 0
set_option -resource_sharing 1
set_option -retiming 0
set_option -run_prop_extract 1
set_option -rw_check_on_ram 0
set_option -supporttypedflt 0
set_option -symbolic_fsm_compiler 1
set_option -synthesis_onoff_pragma 1
set_option -update_models_cp 0
set_option -write_apr_constraint 1
set_option -gen_sdf 1
set_option -gen_io_cst 1
set_option -vccaux 3.3
set_option -gen_ibis 1
set_option -gen_posp 1
set_option -gen_text_timing_rpt 1
set_option -gen_verilog_sim_netlist 1
set_option -gen_vhdl_sim_netlist 0
set_option -show_init_in_vo 1
set_option -show_all_warn 1
set_option -timing_driven 1
set_option -ireg_in_iob 1
set_option -oreg_in_iob 1
set_option -ioreg_in_iob 1
set_option -replicate_resources 0
set_option -cst_warn_to_error 1
set_option -rpt_auto_place_io_info 1
set_option -correct_hold_violation 1
set_option -place_option 1
set_option -route_option 1
set_option -clock_route_order 0
set_option -route_maxfan 23
set_option -use_jtag_as_gpio 0
set_option -use_sspi_as_gpio 0
set_option -use_mspi_as_gpio 0
set_option -use_ready_as_gpio 0
set_option -use_done_as_gpio 0
set_option -use_reconfign_as_gpio 0
set_option -use_mode_as_gpio 0
set_option -use_i2c_as_gpio 0
set_option -use_cpu_as_gpio 0
set_option -power_on_reset_monitor 1
set_option -bit_format bin
set_option -bit_crc_check 1
set_option -bit_compress 0
set_option -bit_encrypt 0
set_option -bit_encrypt_key 00000000000000000000000000000000
set_option -bit_security 1
set_option -bit_incl_bsram_init 1
set_option -bg_programming off
set_option -hotboot 0
set_option -i2c_slave_addr 00
set_option -secure_mode 0
set_option -loading_rate default
set_option -program_done_bypass 0
set_option -wakeup_mode 0
set_option -user_code default
set_option -unused_pin default
set_option -multi_boot 1
set_option -multiboot_address_width 24
set_option -multiboot_mode normal
set_option -multiboot_spi_flash_address 00000000
set_option -mspi_jump 0
set_option -turn_off_bg 0
set_option -vccx 3.3
set_option -ext_cclk false
set_option -ext_cclk_div 1