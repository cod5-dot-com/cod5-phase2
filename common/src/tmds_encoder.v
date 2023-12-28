//              
//           MMXXIII October 9 PUBLIC DOMAIN by O'ksi'D
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

// Reference : 
// https://www.fpga4fun.com/HDMI.html
// https://github.com/csus-senior-design/hdmi/blob/master/lib/tmds_encoder/tmds_encoder.v
// www.cs.unc.edu/Research/stc/FAQs/Video/dvi_spec-V1_0.pdf page 28-30
//

module TMDS_encoder(
	input I_clk,		 // pixel clock
	input [7:0] I_video_data,// (red, green or blue)
	input [1:0] I_ctrl_data, // control data
	input I_video_enable,    //  0 -> I_ctrl_data / 1 -> I_video_data 
	output [9:0] O_tmds
);

wire [7:0] D;
wire C0;
wire C1;
wire DE;
reg [3:0] cnt;
reg [9:0] q_out;
wire [3:0] N1_D;
wire [8:0] q_m;
wire xnor_op;
wire [3:0] N1_q_m;
wire [3:0] N0_q_m;

assign D = I_video_data;
assign C0 = I_ctrl_data[0];
assign C1 = I_ctrl_data[1];
assign DE = I_video_enable;
assign O_tmds = q_out;

assign N1_D = D[0] + D[1] + D[2] + D[3] + D[4] + D[5] + D[6] + D[7];

assign xnor_op = (N1_D > 4'd4) || (N1_D == 4'd4 && D[0] == 1'b0);

assign q_m = xnor_op ?
	{1'b0, q_m[6:0] ^~ D[7:1], D[0]} :
	{1'b1, q_m[6:0] ^ D[7:1], D[0]};

assign N1_q_m = q_m[0] + q_m[1] + q_m[2] + q_m[3] + 
	q_m[4] + q_m[5] + q_m[6] + q_m[7];

assign N0_q_m = 4'd8 - N1_q_m;

always @(posedge I_clk) begin
	if (DE) begin
		if (cnt == 0 || N1_q_m == 7'd4) begin
			q_out[9] <= ~q_m[8];
			q_out[8] <= q_m[8];
			q_out[7:0] <= (q_m[8]) ? q_m[7:0] : ~q_m[7:0];
			if (q_m[8]) begin
				if (N0_q_m > 4'd4) begin
					cnt <= cnt - (N0_q_m - N1_q_m); 
				end else begin
					cnt <= cnt + (N1_q_m - N0_q_m); 
				end
			end else begin
				if (N1_q_m > 4'd4) begin
					cnt <= cnt - (N1_q_m - N0_q_m); 
				end else begin
					cnt <= cnt + (N0_q_m - N1_q_m); 
				end
			end
		end else if ((cnt > 0 && N1_q_m > 4'd4) ||
				(cnt < 0 && N1_q_m < 4'd4)) 
		begin
			q_out[9] <= 1;
			q_out[8] <= q_m[8];
			q_out[7:0] <= ~q_m[7:0];
			if (N1_q_m > 4'd4) begin
				cnt <= cnt + q_m[8] + q_m[8] - 
					(N1_q_m - N0_q_m);
			end else begin
				cnt <= cnt + q_m[8] + q_m[8] + 
					(N0_q_m - N1_q_m);
			end
		end else begin
			q_out[9] <= 0;
			q_out[8] <= q_m[8];
			q_out[7:0] <= q_m[7:0];
			if (N0_q_m > 4'd4) begin
				cnt <= cnt + ~q_m[8] + ~q_m[8] -
					(N0_q_m - N1_q_m);
			end else begin
				cnt <= cnt + ~q_m[8] + ~q_m[8] +
					(N1_q_m - N0_q_m);
			end
		end

	end else begin
		case ({C1,C0})
		2'b00: q_out <= 10'b1101010100;
                2'b01: q_out <= 10'b0010101011;
                2'b10: q_out <= 10'b0101010100;
                default: q_out <= 10'b1010101011;
		endcase
		cnt <= 4'h0;
	end
end
endmodule

