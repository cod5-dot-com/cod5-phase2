//              
//          MMXXIII October 3 PUBLIC DOMAIN by O'ksi'D
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
// https://alchitry.com/serial-peripheral-interface-spi-verilog
// https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
// http://www.dejazzer.com/ee379/lecture_notes/lec12_sd_card.pdf
// http://www.rjhcoding.com/avrc-sd-interface-1.php
//

module spi_master #(parameter 
		FREQ = 48_000_000,
		CPHA = 0, // SPI mode 0
		CPOL = 0
	) (
	input I_clk,
	input I_rst_n,
	output reg O_mosi,
	input I_miso,
	output reg O_sck,

	input I_cmd_read,
	input I_cmd_write,
	input [3:0] I_speed,

	input [7:0] I_data_out,
	output reg [7:0] O_data_in,
	output reg O_busy_write,
	output reg O_data_ready
);

localparam [31:0] period  = FREQ / (200_000 * 2);

reg [7:0] buf_in;
reg [7:0] buf_out;
wire [31:0] speed;
reg [31:0] speed_value;
reg [31:0] counter;

localparam STATE_IDLE = 4'd0;
localparam STATE_START = 4'd1;
localparam STATE_WRITE = 4'd2;
localparam STATE_PRE_START = 4'd3;
reg [3:0] state;
reg [4:0] step;

assign speed = period >> I_speed;

always @(posedge I_clk or negedge I_rst_n) begin
	if (!I_rst_n) begin
		state <= STATE_IDLE;
		O_data_ready <= 0;
		O_busy_write <= 1;
		O_sck <= CPOL[0];
		O_mosi <= 1;
	end else begin
		if (O_data_ready && I_cmd_read) begin
			O_data_ready <= 0;
		end
		case (state)
		STATE_IDLE: begin
			O_sck <= CPOL[0];
			O_busy_write <= 0;
			if (I_cmd_write && !O_busy_write) begin
				state <= STATE_START;
				O_busy_write <= 1;
				O_data_ready <= 0;
				buf_out <= I_data_out;
				buf_in <= 8'd0;
				if (CPHA == 0) begin
					O_mosi <= I_data_out[7];
					state <= STATE_PRE_START;
					counter <= speed[31:0];		
				end
				speed_value <= speed[31:0];
			end
		end
		STATE_PRE_START: begin
			counter <= counter - 1'b1;
			if (counter == 0) begin
				state <= STATE_START;
			end
		end
		STATE_START: begin
			state <= STATE_WRITE;
			O_sck <= ~CPOL[0];
			step = 1;
			counter <= speed_value;		
			if (CPHA == 0) begin
				buf_out <= {buf_out[6:0], buf_out[0]};
				buf_in <= {buf_in[6:0], I_miso};
			end
		end
		STATE_WRITE: begin
			counter <= counter - 1'b1;
			if (counter == 0) begin
				counter <= speed_value;		
				O_sck <= ~O_sck;
				step <= step + 1'b1;
				if (CPHA[0] == step[0]) begin
					buf_out <= {buf_out[6:0],1'b0};
					buf_in <= {buf_in[6:0], I_miso};
				        //buf_in <= buf_in + 1'b1;
				end else begin
					O_mosi <= buf_out[7];
				end
				if (step == 5'd15) begin
					state <= STATE_IDLE;
					O_data_ready <= 1;
					O_data_in <= buf_in;
				end
			end
		end
		endcase
	end
end
endmodule
