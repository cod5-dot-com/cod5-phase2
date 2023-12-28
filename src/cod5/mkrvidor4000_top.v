//
//
module mkrvidor4000_top
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

wire echo;
wire dummy;
wire [7:0] bus;
wire [7:0] bus1;

uart #(.CLOCK_HZ(48000000), .BAUDRATE(115200)) uart(
	.clk(CLK_48MHZ),
	.reset(~RESETn),
	.cmd_read(1),
	.cmd_write(echo),
	.in_pin(MKR_D[14]),
	.out_pin(MKR_D[13]),
	.bus_in(bus1),
	.bus_out(bus),
	.busy_write(busy),
	.data_avail(dummy)
);

spi spi(
	.clk(CLK_48MHZ),
	.reset(~RESETn),
	.cmd_read(0),
	.cmd_write(dummy && ~busy),
	.mosi(FLASH_MOSI),
	.miso(FLASH_MISO),
	.sclk(FLASH_SCK),
	.cs_n(FLASH_CS),
	.hold_n(FLASH_HOLD),
	.wp_n(FLASH_WP),
	.bus_in(8'h90),
	.bus_out(bus1),
	.busy_write(busy1),
	.data_avail(echo)
);

endmodule

