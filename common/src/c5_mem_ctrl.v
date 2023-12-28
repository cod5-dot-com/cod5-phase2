//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
//
// 
//          20 October MMXXIII PUBLIC DOMAIN by O'ksi'D
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
// http://plasmacpu.no-ip.org
// https://opencores.org/projects/plasma
// https://booksite.elsevier.com/9780124077263/
//
//    Memory controller for the Plasma CPU.
//    Supports Big or Little Endian mode.

module c5_mem_ctrl#(parameter 
	WIDTH = 32 
	) (
	input I_clk,
	input I_rst_n,

        input I_pause_in,
        input I_nullify_op,
        input [31:2] I_address_pc,
        output reg [31:0] O_opcode_out,

        input [31:0] I_address_in,
        input [3:0] I_mem_source,
        input [31:0] I_data_write,
        output reg [31:0] O_data_read,
        output reg O_pause_out,

        output reg [31:2] O_address_next,
        output reg [3:0] O_byte_we_next,

        output reg [31:2] O_address,
        output reg [3:0] O_byte_we,
        output reg [31:0] O_data_w,
        input [31:0] I_data_r 
);

`include "c5_parameters.v"

//"00" <= big_endian; "11" <= little_endian
localparam [1:0] ENDIAN_MODE = 2'b11;
localparam STATE_ADDR = 1'b0;
localparam STATE_ACCESS = 1'b1;

reg [31:2] address_var;
reg [31:2] address_reg;
reg [31:0] data_read_var;
reg [31:0] data_write_var;
reg [31:0] opcode_next;
reg [31:0] next_opcode_reg;
reg [31:0] opcode_reg;
reg [3:0] byte_we_var;
reg [3:0] byte_we_reg;
reg mem_state_next;
reg mem_state_reg;
reg pause_var;
wire [1:0] bits;

assign bits = I_address_in[1:0] ^ ENDIAN_MODE;

always @(*) begin
   	byte_we_var = 4'b0000;
   	pause_var = 0;
   	data_read_var = ZERO;
   	data_write_var = ZERO;
   	mem_state_next = mem_state_reg;
   	opcode_next = opcode_reg;

   	case (I_mem_source) 
   	MEM_READ32: begin
      		data_read_var = I_data_r;
	end
   	MEM_READ16, MEM_READ16S: begin
      		if (I_address_in[1] == ENDIAN_MODE[1]) begin
         		data_read_var[15:0] = I_data_r[31:16];
      		end else begin
         		data_read_var[15:0] = I_data_r[15:0];
      		end
		if (I_mem_source == MEM_READ16 || data_read_var[15] == 0) 
		begin
         		data_read_var[31:16] = ZERO[31:16];
      		end else begin
         		data_read_var[31:16] = ONES[31:16];
      		end
	end
   	MEM_READ8, MEM_READ8S: begin
      		case (bits)
      		2'b00: data_read_var[7:0] = I_data_r[31:24];
      		2'b01: data_read_var[7:0] = I_data_r[23:16];
      		2'b10: data_read_var[7:0] = I_data_r[15:8];
      		default: data_read_var[7:0] = I_data_r[7:0];
      		endcase
      		if (I_mem_source == MEM_READ8 || data_read_var[7] == 0)
		begin
         		data_read_var[31:8] = ZERO[31:8];
		end else begin
         		data_read_var[31:8] = ONES[31:8];
      		end
	end
   	MEM_WRITE32: begin
      		data_write_var = I_data_write;
      		byte_we_var = 4'b1111;
	end
   	MEM_WRITE16: begin
      		data_write_var = {I_data_write[15:0], I_data_write[15:0]};
		if (I_address_in[1] == ENDIAN_MODE[1]) begin
         		byte_we_var = 4'b1100;
		end else begin
         		byte_we_var = 4'b0011;
      		end
	end
   	MEM_WRITE8: begin
      		data_write_var = {I_data_write[7:0], I_data_write[7:0],
			I_data_write[7:0], I_data_write[7:0]};
      		case (bits)
      		2'b00: byte_we_var = 4'b1000; 
      		2'b01: byte_we_var = 4'b0100; 
      		2'b10: byte_we_var = 4'b0010; 
      		default: byte_we_var = 4'b0001; 
      		endcase
	end
   	default: begin
	end
   	endcase

	if (I_mem_source == MEM_FETCH) begin //opcode fetch
      		address_var = I_address_pc;
      		opcode_next = I_data_r;
      		mem_state_next = STATE_ADDR;
	end else begin
		if (mem_state_reg == STATE_ADDR) begin
			if (I_pause_in == 0) begin
            			address_var = I_address_in[31:2];
            			mem_state_next = STATE_ACCESS;
            			pause_var = 1;
         		end else begin
            			address_var = I_address_pc;
            			byte_we_var = 4'b0000;
         		end
		end else begin  // STATE_ACCESS
			if (I_pause_in == 0) begin
            			address_var = I_address_pc;
            			opcode_next = next_opcode_reg;
            			mem_state_next = STATE_ADDR;
            			byte_we_var = 4'b0000;
         		end else begin
            			address_var = I_address_in[31:2];
            			byte_we_var = 4'b0000;
         		end
      		end
   	end

	if (I_nullify_op == 1'b1 &&  I_pause_in == 0) begin
      		opcode_next = ZERO;  //NOP after beql
	end

end


always @(posedge I_clk) begin
	if (!I_rst_n) begin
      		mem_state_reg <= STATE_ADDR;
      		opcode_reg <= ZERO;
      		next_opcode_reg <= ZERO;
      		address_reg <= ZERO[31:2];
      		byte_we_reg <= 4'b0000;
	end else begin
		if (I_pause_in == 0) begin
         		address_reg <= address_var;
         		byte_we_reg <= byte_we_var;
         		mem_state_reg <= mem_state_next;
         		opcode_reg <= opcode_next;
			if (mem_state_reg == STATE_ADDR) begin
            			next_opcode_reg <= I_data_r;
         		end
      		end
	end
end

always @(*) begin
   	O_pause_out <= pause_var;
	O_opcode_out <= opcode_reg;
   	O_data_read <= data_read_var;

   	O_address_next <= address_var;
   	O_byte_we_next <= byte_we_var;

   	O_address <= address_reg;
   	O_byte_we <= byte_we_reg;
   	O_data_w <= data_write_var;

end


endmodule

