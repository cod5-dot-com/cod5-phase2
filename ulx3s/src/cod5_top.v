
module cod5_top(
		input wire clk_25mhz,
		input [6:0] btn,
		output [7:0] led,
		output [3:0] gpdi_dp,
		//output [3:0] gpdi_dn,
		
		input ftdi_txd,
		output ftdi_rxd,
		
		output wifi_gpio0 
	);

	reg [31:0] counter =0;
	
	assign led = counter[30:23];
	assign wifi_gpio0 = 1'b1;
`include "../../common/src/c5_parameters.v"

wire rst_n;
assign rst_n = 1;

wire clk;
wire plasma_interrupt;
wire mem_pause;
wire mem_ready;
wire mem_busy;
wire mem_select;
wire [31:2] address_next;
wire [3:0] byte_we_next;
wire [31:2] address;
wire [3:0] byte_we;
wire [31:0] data_write;
wire [31:0] data_read;

reg [31:0] data_bus;

wire enable_ram;
wire [31:0] data_read_ram;

wire clk_sdram;
wire clk_sdram_p;
wire startup_rst_n;
wire pll_lock;
wire serial_clk;
wire pix_clk;

assign startup_rst_n = 1; // rst_n && pll_lock;

assign pix_clk = clk_25mhz;

sys_pll U6_pll (.CLKI(clk_25mhz), .CLKOP(serial_clk), .CLKOS(clk), .CLKOS2(clk_sdram), .CLKOS3(clk_sdram_p), 
    .LOCK(pll_lock));
	

soc u0_soc (
	.I_clk(clk),
	.I_rst_n(startup_rst_n),

	.I_clk_pixel(pix_clk),
	.I_clk_pixel_x5(serial_clk),
    	.O_tmds_clk_p(gpdi_dp[3]),
    	.O_tmds_clk_n(),
    	.O_tmds_data_p({gpdi_dp[2], gpdi_dp[1], gpdi_dp[0]}),
    	.O_tmds_data_n(),

	
	.O_mem_select(mem_select),
	.O_mem_address(address),
	.O_mem_byte_we(byte_we),
	.O_mem_data_write(data_write),
	.I_mem_data_read(data_read),
	.I_mem_pause(mem_pause),
	.I_mem_data_ready(mem_ready),


	.I_uart_rx(ftdi_txd),
	.O_uart_tx(ftdi_rxd)
/*
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


wire mem_read;
reg mem_refresh;
wire mem_write;
wire mem_enable;
wire [22:0] mem_address;

assign mem_address = address[24:2];
assign mem_enable = !mem_pause && !mem_refresh && mem_select;
assign mem_write = mem_enable && byte_we != 0;
assign mem_read = mem_enable && byte_we == 0;

assign mem_pause = mem_busy; // FIXME
always @(posedge clk_25mhz) begin
	if (!startup_rst_n) begin
		mem_refresh <= 0;
		counter <= 32'd0;
	end else begin
		counter <= counter + 1'b1;
		mem_refresh <= 0;
		if (counter >= 48_000_000 * 15 / 1_000_000) begin
			//counter <= 32'd0; // 15us
			mem_refresh <= 1;
		end
	end

end
/*
sdram u3_sdram (
	.I_rst_n(startup_rst_n),
	.I_clk(clk),
	.I_clk_sdram(clk_sdram),
	.I_cmd_read(mem_read),
	.I_cmd_write(mem_write),
	.I_cmd_refresh(mem_refresh),
	.I_address(mem_address),
	.I_data_in(data_write),
	.O_data_out(data_read),
	.O_data_ready(mem_ready),
	.O_busy(mem_busy),


    .O_ram_CLK(O_sdram_clk),
    .O_ram_CKE(O_sdram_cke),
    .O_ram_nCS(O_sdram_cs_n),
    .O_ram_nCAS(O_sdram_cas_n),
    .O_ram_nRAS(O_sdram_ras_n),
    .O_ram_nWE(O_sdram_wen_n),
    .IO_ram_DQ(IO_sdram_dq),
    .O_ram_A(O_sdram_addr),
    .O_ram_BA(O_sdram_ba),
    .O_ram_DQM(O_sdram_dqm)
);

*/

endmodule
