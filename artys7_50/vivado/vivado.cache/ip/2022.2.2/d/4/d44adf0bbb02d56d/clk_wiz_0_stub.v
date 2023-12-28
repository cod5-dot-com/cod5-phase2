// Copyright 1986-2023 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2.2 (lin64) Build 3788238 Tue Feb 21 19:59:23 MST 2023
// Date        : Tue Nov  7 09:53:02 2023
// Host        : redhat running 64-bit Fedora release 38 (Thirty Eight)
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s50csga324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(clk_48mhz, clk_125mhz, clk_25mhz, clk_150mhz, 
  clk_150mhzp, clk_50mhz, resetn, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_48mhz,clk_125mhz,clk_25mhz,clk_150mhz,clk_150mhzp,clk_50mhz,resetn,locked,clk_in1" */;
  output clk_48mhz;
  output clk_125mhz;
  output clk_25mhz;
  output clk_150mhz;
  output clk_150mhzp;
  output clk_50mhz;
  input resetn;
  output locked;
  input clk_in1;
endmodule
