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

// General Purpose Digital Interface (It has nothing do with HDMI ;-)

// Reference : 
// https://lists.inf.ethz.ch/pipermail/oberon/2019/013413.html
// https://www.fpga4fun.com/HDMI.html
// https://github.com/sipeed/TangNano-20K-example/blob/main/nestang/src/nes2hdmi.sv
//

module gpdi (
	input I_rst_n,
    	input I_serial_clk,
    	input I_pix_clk, 
    	input I_rgb_vs, 
    	input I_rgb_hs,    
    	input I_rgb_de, 
    	input [7:0] I_rgb_r,
    	input [7:0] I_rgb_g,  
    	input [7:0] I_rgb_b,  

    	output O_tmds_clk_p,
    	output O_tmds_clk_n,
    	output [2:0] O_tmds_data_p,
    	output [2:0] O_tmds_data_n 
);


wire [9:0] red;
wire [9:0] green;
wire [9:0] blue;

TMDS_encoder encode_red(
	.I_clk(I_pix_clk), 
	.I_video_data(I_rgb_r), 
	.I_ctrl_data(2'b00), 
	.I_video_enable(I_rgb_de), 
	.O_tmds(red)
);

TMDS_encoder encode_green(
	.I_clk(I_pix_clk), 
	.I_video_data(I_rgb_g), 
	.I_ctrl_data(2'b00), 
	.I_video_enable(I_rgb_de), 
	.O_tmds(green)
);

TMDS_encoder encode_blue(
	.I_clk(I_pix_clk), 
	.I_video_data(I_rgb_b), 
	.I_ctrl_data({I_rgb_vs, I_rgb_hs}), 
	.I_video_enable(I_rgb_de), 
	.O_tmds(blue)
);

wire [2:0] tmds;
ELVDS_OBUF tmds_buf [3:0] (
	.I({I_pix_clk, tmds}),
	.O({O_tmds_clk_p, O_tmds_data_p}),
	.OB({O_tmds_clk_n, O_tmds_data_n})
);

OSER10 ser_r (
	.Q(tmds[2]),
	.D0(red[0]),
	.D1(red[1]),
	.D2(red[2]),
	.D3(red[3]),
	.D4(red[4]),
	.D5(red[5]),
	.D6(red[6]),
	.D7(red[7]),
	.D8(red[8]),
	.D9(red[9]),
	.FCLK(I_serial_clk),
	.PCLK(I_pix_clk),
	.RESET(!I_rst_n)
);

OSER10 ser_g (
	.Q(tmds[1]),
	.D0(green[0]),
	.D1(green[1]),
	.D2(green[2]),
	.D3(green[3]),
	.D4(green[4]),
	.D5(green[5]),
	.D6(green[6]),
	.D7(green[7]),
	.D8(green[8]),
	.D9(green[9]),
	.FCLK(I_serial_clk),
	.PCLK(I_pix_clk),
	.RESET(!I_rst_n)
);

OSER10 ser_b (
	.Q(tmds[0]),
	.D0(blue[0]),
	.D1(blue[1]),
	.D2(blue[2]),
	.D3(blue[3]),
	.D4(blue[4]),
	.D5(blue[5]),
	.D6(blue[6]),
	.D7(blue[7]),
	.D8(blue[8]),
	.D9(blue[9]),
	.FCLK(I_serial_clk),
	.PCLK(I_pix_clk),
	.RESET(!I_rst_n)
);

endmodule

