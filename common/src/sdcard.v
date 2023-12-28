//              
//          MMXXIII October 2 PUBLIC DOMAIN by O'ksi'D
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
// https://electronics.stackexchange.com/questions/602105/how-can-i-initialize-use-sd-cards-with-spi
// https://en.wikipedia.org/wiki/SD_card
// https://www.sdcard.org/downloads/pls/pdf/?p=PartE1_SDIO_Simplified_Specification_Ver3.00.jpg&f=PartE1_SDIO_Simplified_Specification_Ver3.00.pdf&e=EN_SSE1

module sdcard #(
	parameter FREQ = 48_000_000
)
(
	input I_clk, 
	input I_rst_n,

	output O_sck,
	output O_mosi,
	input I_miso,
	output reg O_cs_n,

	input I_cmd_write,
	input I_cmd_read,
	input I_cmd_init,

	input [31:0] I_data_out,
	output reg [31:0] O_data_in,
	output O_busy_write,
	output reg O_data_ready

);

//////////////////////////////////

reg spi_write;
reg spi_read;
reg [3:0] spi_speed;
reg [7:0] spi_send;
wire [7:0] spi_receive;
wire spi_busy;
wire spi_data_ready;

spi_master #(.FREQ(FREQ)) sdcard (
	.I_clk(I_clk),
	.I_rst_n(I_rst_n),
    	.O_sck(O_sck),
    	.O_mosi(O_mosi),
        .I_miso(I_miso),

	.I_cmd_write(spi_write),
	.I_cmd_read(spi_read),
	.I_speed(spi_speed),

	.I_data_out(spi_send),
	.O_data_in(spi_receive),
	.O_busy_write(spi_busy),
	.O_data_ready(spi_data_ready)
);

localparam CMD0 = 48'b01_000000_00000000_00000000_00000000_00000000_1001010_1;
localparam CMD8 = 48'h4800_0001_AA87;

localparam STATE_IDLE = 5'd0;
localparam STATE_INIT_CARD = 5'd1;
localparam STATE_SEND_CMD = 5'd2;
localparam STATE_CMD0_SENT = 5'd3;
localparam STATE_UNINIT = 5'd4;
localparam STATE_RETRY_INIT = 5'd6;
localparam STATE_CMD0_DUMMY = 5'd7;

reg [4:0] state;
reg [4:0] next_state;
reg [4:0] step;
reg [47:0] cmd;
reg [4:0] retry_count;
reg [4:0] dummy_send;

assign O_busy_write = (state != STATE_UNINIT) && (state != STATE_IDLE);

always @(posedge I_clk or negedge I_rst_n) 
begin
	if (!I_rst_n) begin
		O_cs_n <= 1;
		O_data_in <= 0;
		state <= STATE_UNINIT;
		spi_write <= 0;
		spi_read <= 0;
		spi_speed <= 0;
		spi_send <= 0;
		retry_count <= 0;
	end else if (I_cmd_init) begin
		spi_write <= 0;
		spi_read <= 0;
		O_cs_n <= 1;
		retry_count <= 0;
		state <= STATE_INIT_CARD;
		step <= 5'd11; // minimal 74 clock cycles
	end else begin
		spi_write <= 0;
		spi_read <= 0;
		if (I_cmd_read && O_data_ready) begin
			O_data_ready <= 0;
		end
		case (state) 
		STATE_UNINIT: begin
			O_cs_n <= 1;
		end
		STATE_IDLE: begin
			O_cs_n <= 0;
			if (!spi_busy) begin
				if (I_cmd_write) begin
				end else if (I_cmd_read) begin
				end
			end
		end
		STATE_RETRY_INIT: begin
			O_cs_n <= 1;
			retry_count <= retry_count + 1'b1;
			if (retry_count == 5'd15) begin
				state <= STATE_UNINIT;
			end else begin
				state <= STATE_INIT_CARD;
				step <= 5'd2; // 
			end
		end
		STATE_INIT_CARD: begin
			if (!spi_write && !spi_busy) begin
				step <= step - 1'b1;
				if (step == 5'd1) begin
					O_cs_n <= 0;
					//spi_send <= 8'b1111_1111;
					//spi_write <= 1;
				end else if (step == 0) begin
		//			O_cs_n <= 0;
					state <= STATE_SEND_CMD;
					next_state <= STATE_CMD0_SENT;
					cmd <= CMD0;
					step <= 0;
				end else begin
					O_cs_n <= 1;
					spi_send <= 8'b1111_1111;
					spi_write <= 1;
				end
			end
		end
		STATE_CMD0_SENT: begin
			if (!spi_write && !spi_busy) begin
				spi_send <= 8'b1111_1111;
				spi_write <= 1;
				state <= STATE_CMD0_DUMMY;
				dummy_send <= 5'd9;
			end
		end
		STATE_CMD0_DUMMY: begin
			if (!spi_write && !spi_busy && !spi_read) begin
				if (spi_data_ready) begin
					dummy_send <= dummy_send - 1'b1;
					spi_read <= 1;
					if (spi_receive == 8'd1) begin
						state <= STATE_IDLE;
						O_data_in[7:0] <= spi_receive;
						O_data_ready <= 1;
					end else if (dummy_send == 5'd0) begin
						O_data_in[7:0] <= spi_receive;
						O_data_ready <= 1;
						state <= STATE_RETRY_INIT;
					end else begin
						spi_send <= 8'b1111_1111;
						spi_write <= 1;
					end	
				end
			end
		end
		STATE_SEND_CMD: begin
			if (!spi_write && !spi_busy) begin
				step <= step + 1'b1;
				case (step)
				5'd0: begin
		//			O_cs_n <= 0;
					spi_send <= cmd[47:40];
					spi_write <= 1;
				end
				5'd1: begin
					spi_send <= cmd[39:32];
					spi_write <= 1;
				end
				5'd2: begin
					spi_send <= cmd[31:24];
					spi_write <= 1;
				end
				5'd3: begin
					spi_send <= cmd[23:16];
					spi_write <= 1;
				end
				5'd4: begin
					spi_send <= cmd[15:8];
					spi_write <= 1;
				end
				5'd5: begin
					spi_send <= cmd[7:0];
					spi_write <= 1;
				end
				5'd6: begin
					state <= next_state;
					step <= 0;
				end
				endcase
			end
		end
		endcase
	end
end

endmodule
