//
// 
//            29 October MMXXIII PUBLIC DOMAIN by O'ksi'D
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
//
// References:
// https://stackoverflow.com/questions/36610527/how-to-initialize-contents-of-inferred-block-ram-bram-in-verilog
//
module c5_ram#(parameter 
	WIDTH = 32
	) (
		input I_clk,
		input I_rst_n,
		input I_enable,
		input [3:0] I_write_byte_enable,
		input [31:2] I_address,
		input [WIDTH-1:0] I_data_write,
		output reg [WIDTH-1:0] O_data_read
);

`include "c5_parameters.v"

reg [7:0] ram0[0:((BSRAM_SIZE)-1)];
reg [7:0] ram1[0:((BSRAM_SIZE)-1)];
reg [7:0] ram2[0:((BSRAM_SIZE)-1)];
reg [7:0] ram3[0:((BSRAM_SIZE)-1)];
reg initialized = 0;

always @(posedge I_clk) begin
	if (!I_rst_n) begin
	   O_data_read <= 0;
	   initialized <= 0;
	end else begin
		if (I_enable && I_write_byte_enable[0]) begin
			ram0[{I_address[BSRAM_DEPTH+1:2]}] <= 
			       	I_data_write[7:0];
	   		if (I_address[BSRAM_DEPTH+1:2] == 0) begin
				initialized <= 1;
			end
		end 
		if (I_enable && I_write_byte_enable[1]) begin
			ram1[{I_address[BSRAM_DEPTH+1:2]}] <=
				I_data_write[15:8];
		end
		if (I_enable && I_write_byte_enable[2]) begin
			ram2[{I_address[BSRAM_DEPTH+1:2]}] <=
				I_data_write[23:16];
		end
		if (I_enable && I_write_byte_enable[3]) begin
			ram3[{I_address[BSRAM_DEPTH+1:2]}] <= 
				I_data_write[31:24];
		end

		O_data_read <= {
			ram3[{I_address[BSRAM_DEPTH+1:2]}],
			ram2[{I_address[BSRAM_DEPTH+1:2]}],
			ram1[{I_address[BSRAM_DEPTH+1:2]}],
			ram0[{I_address[BSRAM_DEPTH+1:2]}]};

		if (!initialized) begin
			case ({I_address[BSRAM_DEPTH+1:2], 2'b00})
`include "rom.v"
			default: begin end
			endcase
		end
	end
end

endmodule

