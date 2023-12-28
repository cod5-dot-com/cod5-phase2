//              
//          MMXXIII September 27 PUBLIC DOMAIN by O'ksi'D
//
//        The authors disclaim copyright to this software.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a
// compiled binary, for any purpose, commercial or non-commercial,
// and by any means.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT OF ANY PATENT, COPYRIGHT, TRADE SECRET OR OTHER
// PROPRIETARY RIGHT.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR 
// ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


module cod5_top #(
	parameter nb_leds = 6
)
(
    input             I_clk           , //27Mhz
    input             I_rst         ,
    output            O_tmds_clk_p    ,
    output            O_tmds_clk_n    ,
    output     [2:0]  O_tmds_data_p   ,//{r,g,b}
    output     [2:0]  O_tmds_data_n   ,

   
    // "Magic" port names that the gowin compiler connects to the on-chip SDRAM
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,            // chip select
    output O_sdram_cas_n,           // columns address select
    output O_sdram_ras_n,           // row address select
    output O_sdram_wen_n,           // write enable
    inout [31:0] IO_sdram_dq,       // 32 bit bidirectional data bus
    output [10:0] O_sdram_addr,     // 11 bit multiplexed address bus
    output [1:0] O_sdram_ba,        // two banks
    output [3:0] O_sdram_dqm,      // 32/4

    output O_sdcard_clk,
    output O_sdcard_mosi,
    inout I_sdcard_miso,
    output O_sdcard_cs_n,
    inout IO_sdcard_dat1,
    inout IO_sdcard_dat2,

    input I_uart_rx,
    output O_uart_tx,

    output [nb_leds-1:0] O_leds
);

`include "../../common/src/c5_parameters.v"

wire rst_n;
assign rst_n = !I_rst;

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
wire startup_rst_n;
wire pll_lock;
wire serial_clk;
wire pix_clk;

Gowin_rPLL pll(
    .clkout(clk),         // Main clock 48MHz
    .clkoutp(clk_sdram),  // Phase shifted clock for SDRAM
    .clkin(I_clk)         // 27Mhz system clock
);

TMDS_rPLL u_tmds_rpll
(.clkin     (I_clk     )     //input clk
,.clkout    (serial_clk)     //output clk
,.lock      (pll_lock  )     //output lock
);

assign startup_rst_n = rst_n & pll_lock;


CLKDIV u_clkdiv
(.RESETN(startup_rst_n)
,.HCLKIN(serial_clk) //clk  x5
,.CLKOUT(pix_clk)    //clk  x1
,.CALIB (1'b1)
);
defparam u_clkdiv.DIV_MODE="5";
defparam u_clkdiv.GSREN="false";


soc u0_soc (
	.I_clk(clk),
	.I_rst_n(startup_rst_n),

	.I_clk_pixel(pix_clk),
	.I_clk_pixel_x5(serial_clk),
    	.O_tmds_clk_p(O_tmds_clk_p),
    	.O_tmds_clk_n(O_tmds_clk_n),
    	.O_tmds_data_p(O_tmds_data_p),
    	.O_tmds_data_n(O_tmds_data_n),

	
	.O_mem_select(mem_select),
	.O_mem_address(address),
	.O_mem_byte_we(byte_we),
	.O_mem_data_write(data_write),
	.I_mem_data_read(data_read),
	.I_mem_pause(mem_pause),
	.I_mem_data_ready(mem_ready),


	.I_uart_rx(I_uart_rx),
	.O_uart_tx(O_uart_tx)
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
reg [31:0] counter;

assign O_leds = counter[27:22];

assign mem_address = address[24:2];
assign mem_enable = !mem_pause && !mem_refresh && mem_select;
assign mem_write = mem_enable && byte_we != 0;
assign mem_read = mem_enable && byte_we == 0;

assign mem_pause = mem_busy; // FIXME
always @(posedge I_clk or negedge rst_n) begin
	if (!rst_n) begin
		mem_refresh <= 0;
		counter <= 32'd0;
	end else begin
		counter <= counter + 1'b1;
		mem_refresh <= 0;
		if (counter >= 48_000_000 * 15 / 1_000_000) begin
			counter <= 32'd0; // 15us
			mem_refresh <= 1;
		end
	end

end

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

endmodule
