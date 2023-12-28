//
//
module cod5_top
(
  	input CLK_48MHZ,
  	input RESETn,
  	input SAM_INT_IN,
  	output SAM_INT_OUT,
  
  	output wire SDRAM_CLK,
  	output [11:0] SDRAM_ADDR,
  	output [1:0] SDRAM_BA,
  	output SDRAM_CASn,
  	output SDRAM_CKE,
  	output SDRAM_CSn,
  	inout wire [15:0] SDRAM_DQ,
  	output [1:0] SDRAM_DQM,
  	output SDRAM_RASn,
  	output SDRAM_WEn,

  	output [2:0] HDMI_TX,
  	output HDMI_CLK,
  	inout  HDMI_SDA,
  	inout  HDMI_SCL,
  	input  HDMI_HPD,

        inout FLASH_MOSI,
        inout FLASH_MISO,
        inout FLASH_SCK,
        inout FLASH_CS,
        inout FLASH_HOLD,
        inout FLASH_WP,

        inout MKR_AREF,
        inout [6:0] MKR_A,
        inout [14:0] MKR_D
);

mem_pll mem_pll(
	.inclk0(CLK_48MHZ), 
	.c0(SDRAM_CLK)
);

wire clk_pixel_x5;
wire clk_pixel;
wire clk_audio;
hdmi_pll hdmi_pll(
	.inclk0(CLK_48MHZ), 
	.c0(clk_pixel), 
	.c1(clk_pixel_x5), 
	.c2(clk_audio)
);

wire clk;

wire plasma_interrupt;
wire plasma_mem_pause;
wire [31:2] plasma_address_next;
wire [3:0] plasma_byte_we_next;
wire [31:2] plasma_address;
wire [3:0] plasma_byte_we;
wire [31:0] plasma_data_w;
wire [31:0] plasma_data_r;

reg [31:0] data_bus;

wire enable_ram;
wire [31:0] data_read_ram;

//assign plasma_interrupt = O_leds[2];
//assign plasma_mem_pause = O_leds[1];


soc u0_soc (
	.I_clk(CLK_48MHZ), 
	.I_rst_n(RESETn),

	.I_uart_rx(MKR_D[14]),
	.O_uart_tx(MKR_D[13])
/*
	    input             I_clk_pixel     , //25MHz
    input             I_clk_pixel_x5  , //125MHz
    input             I_clk_audio     , //
    output            O_tmds_clk_p    ,
    output            O_tmds_clk_n    ,
    output     [2:0]  O_tmds_data_p   ,
    output     [2:0]  O_tmds_data_n   ,


    output [31:2] O_mem_address_next,
    output [3:0]  O_mem_byte_we_next,
    output [31:2] O_mem_address,
    output [3:0]  O_mem_byte_we,
    output [31:0] O_mem_data_write,
    input  [31:0] I_mem_data_read,
    input I_mem_pause,

    output O_sdcard_clk,
    output O_sdcard_mosi,
    inout I_sdcard_miso,
    output O_sdcard_cs_n,
    inout IO_sdcard_dat1,
    inout IO_sdcard_dat2,

    output [NB_LEDS-1:0] O_leds
*/
);

endmodule

