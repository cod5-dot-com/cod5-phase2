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


module display #(
	parameter resolution = "640x480",
	parameter clock_frequency = 32'd27_000_000
)
(
    input             I_clk,
    input             I_rst_n,
    input	      I_clk_pixel,
    input	      I_clk_pixel_x5,
    output reg	      O_sync,
    output reg	      O_read,
 
    input 	[31:0] I_data,
    input 	      I_empty,
    output            O_tmds_clk_p,
    output            O_tmds_clk_n,
    output     [2:0]  O_tmds_data_p,
    output     [2:0]  O_tmds_data_n 
);


wire serial_clk;
wire pix_clk;
reg [31:0] data;

assign pix_clk = I_clk_pixel;
assign serial_clk = I_clk_pixel_x5;

reg [9:0] xpos;  // counts from 0 to 799
reg [9:0] ypos;  // counts from 0 to 524
reg [9:0] xpos_next;
reg [9:0] ypos_next;
reg h_sync;
reg v_sync;
reg draw_enable;
reg draw_enable_next;
reg [7:0] red;
reg [7:0] green;
reg [7:0] blue;
reg [3:0] pixel;
reg reading;
reg [15:0] count;
reg [31:0] color;
reg [9:0] x;

always @(posedge pix_clk)
begin
	if (!I_rst_n) begin
		h_sync <= 1'b0;
		v_sync <= 1'b0;
		O_sync <= 1'b0;
		draw_enable_next <= 1'b0;
		xpos_next <= 10'd0;
		ypos_next <= 10'd0;
		reading <= 0;
		data <= 0;
		count <= 0;
		color <= 0;
		x <= 0;
	end else begin
		xpos_next <= (xpos_next==799) ? 10'd0 : xpos_next+10'd1;
		if (xpos_next==799) begin
			ypos_next <= (ypos_next==524) ? 10'd0 : ypos_next+10'd1;
		end
		draw_enable_next <= (xpos_next<48+640) && (ypos_next<33+480) &&
				(xpos_next>=48) && (ypos_next>=33);
		draw_enable <= draw_enable_next;
		xpos <= xpos_next;
		ypos <= ypos_next;
		h_sync <= (xpos>=48+640+16) && (xpos<48+640+16+96);
		v_sync <= (ypos>=33+480+10) && (ypos<33+480+10+2);
		O_sync <= (ypos==0) && (xpos<128);
	
		O_read <= 1'b0;
		if (xpos_next[2:0] == 3'd5 && 
			(draw_enable_next || 
			(ypos_next==33 && xpos_next<48 && xpos_next >48-8))) 
		begin
			if (I_empty) begin
				data <= 0;
			end else begin
				O_read <= 1'b1; // 5
			end
		end else if (O_read) begin
			reading <= 1; // 6
		end else if (reading) begin
			reading <= 0;
			data <= I_data; // 7
		end
		
		case (xpos[2:0])
		3'd0: pixel = data[3:0];
		3'd1: pixel = data[7:4];
		3'd2: pixel = data[11:8];
		3'd3: pixel = data[15:12];
		3'd4: pixel = data[19:16];
		3'd5: pixel = data[23:20];
		3'd6: pixel = data[27:24];
		3'd7: pixel = data[31:28];
		endcase
	        if (xpos == ypos) begin
			red <= 8'd255;
			green <= 8'd0;
			blue <= 8'd255;
		end else begin
			case (pixel[3:0])
			4'd0: begin red<= 8'd0;green<= 8'd0;blue<= 8'd0;end
			4'd1: begin red<= 8'hFF;green<= 8'd0;blue<= 8'd0;end
			4'd2: begin red<= 8'd0;green<= 8'hFF;blue<= 8'd0;end
			4'd3: begin red<= 8'hFF;green<= 8'hFF;blue<= 8'd0;end
			4'd4: begin red<= 8'd0;green<= 8'd0;blue<= 8'hFF;end
			4'd5: begin red<= 8'hFF;green<= 8'd0;blue<= 8'hFF;end
			4'd6: begin red<= 8'd0;green<= 8'hFF;blue<= 8'hFF;end
			4'd7: begin red<= 8'hFF;green<= 8'hFF;blue<= 8'hFF;end
			4'd8: begin red<= 8'h11;green<= 8'h11;blue<= 8'h11;end
			4'd9: begin red<= 8'h22;green<= 8'h22;blue<= 8'h22;end
			4'd10: begin red<= 8'h44;green<= 8'h44;blue<= 8'h44;end
			4'd11: begin red<= 8'h66;green<= 8'h66;blue<= 8'h66;end
			4'd12: begin red<= 8'h88;green<= 8'h88;blue<= 8'h88;end
			4'd13: begin red<= 8'hAA;green<= 8'hAA;blue<= 8'hAA;end
			4'd14: begin red<= 8'hCC;green<= 8'hCC;blue<= 8'hCC;end
			4'd15: begin red<= 8'hDD;green<= 8'hDD;blue<= 8'hDD;end
			endcase
		end

	end
end

gpdi gpdi_inst
(

    .I_rst_n       (I_rst_n    ),  //asynchronous reset, low active
    .I_serial_clk  (serial_clk ),
    .I_pix_clk     (pix_clk    ),  //pixel clock
    .I_rgb_vs      (v_sync     ), 
    .I_rgb_hs      (h_sync     ),    
    .I_rgb_de      ( draw_enable ), 
    .I_rgb_r       (  red ),
    .I_rgb_g       (  green ),  
    .I_rgb_b       (  blue ),  

    .O_tmds_clk_p  (O_tmds_clk_p  ),
    .O_tmds_clk_n  (O_tmds_clk_n  ),
    .O_tmds_data_p (O_tmds_data_p ),  //{r,g,b}
    .O_tmds_data_n (O_tmds_data_n )
);

endmodule
