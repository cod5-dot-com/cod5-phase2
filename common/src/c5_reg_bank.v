//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
//
// 
//            18 October MMXXIII PUBLIC DOMAIN by O'ksi'D
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
// Implements a register bank with 32 registers that are 32-bits wide.
// There are two read-ports and one write port.
//
// References:
// http://plasmacpu.no-ip.org
// https://opencores.org/projects/plasma
// https://booksite.elsevier.com/9780124077263/

module c5_reg_bank#(parameter 
	WIDTH = 32 
	) (
	input I_clk,
	input I_rst_n,

	input I_pause,
	input [5:0] I_rs_index,
	input [5:0] I_rt_index,
	input [5:0] I_rd_index,
	output reg [31:0] O_reg_source_out,
	output reg [31:0] O_reg_target_out,
	input [31:0] I_reg_dest_new,
	output reg O_intr_enable
);

`include "c5_parameters.v"

wire [4:0] addr_read1;
wire [4:0] addr_read2;
wire [4:0] addr_write;
reg write_enable;
reg intr_enable_reg;
reg [31:0] data_out1;
reg [31:0] data_out2;

// two identical registers file so we can read two registers at the same time
reg [7:0] dual_port_ram1[0:127];
reg [7:0] dual_port_ram2[0:127];

assign addr_read1 = (I_rs_index == 6'b101110) ? 5'b00000 : I_rs_index[4:0];
assign addr_read2 = I_rt_index[4:0];
assign addr_write = (I_rd_index == 6'b101110) ? 5'b00000 : I_rd_index[4:0];

always @(posedge I_clk) begin
	if (!I_rst_n) begin
		intr_enable_reg <= 1'b0;
	end else begin
		if (I_rd_index == 6'b101110) begin // reg_epc CP0 14
			intr_enable_reg <= 1'b0; // disable interrupts
		end else if (I_rd_index == 6'b101100) begin
			intr_enable_reg <= I_reg_dest_new[0];
		end
	end
end

always @(*) begin
	O_intr_enable <= intr_enable_reg;
end

always @(*) begin
	data_out1 <= {dual_port_ram1[{addr_read1, 2'b11}],
				dual_port_ram1[{addr_read1, 2'b10}],
				dual_port_ram1[{addr_read1, 2'b01}],
				dual_port_ram1[{addr_read1,2'b00}]};
end

always @(*) begin
	data_out2 <= {dual_port_ram2[{addr_read2, 2'b11}],
				dual_port_ram2[{addr_read2, 2'b10}],
				dual_port_ram2[{addr_read2, 2'b01}],
				dual_port_ram2[{addr_read2,2'b00}]};
end
integer i;
always @(posedge I_clk) begin
	if (!I_rst_n) begin
		for (i = 0; i < 128; i = i + 1) begin
          dual_port_ram1[i] <= 0;
          dual_port_ram2[i] <= 0;
        end
	end else begin
		if (write_enable == 1'b1) begin
			{dual_port_ram1[{addr_write, 2'b11}],
				dual_port_ram1[{addr_write, 2'b10}],
				dual_port_ram1[{addr_write, 2'b01}],
				dual_port_ram1[{addr_write, 2'b00}]}
		       		<= I_reg_dest_new;
			{dual_port_ram2[{addr_write, 2'b11}],
				dual_port_ram2[{addr_write, 2'b10}],
				dual_port_ram2[{addr_write, 2'b01}],
				dual_port_ram2[{addr_write, 2'b00}]}
		       		<= I_reg_dest_new;
		end
	end
end

always @(*) begin
		case (I_rs_index)
		6'b000000: O_reg_source_out <= ZERO;
		6'b101100: O_reg_source_out <= {ZERO[31:1], intr_enable_reg};
		// interrupt vector address: 0x3c
		6'b111111: O_reg_source_out <= {ZERO[31:8], 8'b00111100}; 
		default: begin
			O_reg_source_out <= data_out1;
		end
		endcase

		case (I_rt_index)
		6'b000000: O_reg_target_out <= ZERO;
		default: begin
			O_reg_target_out <= data_out2;
		end
		endcase

end

always @(*) begin
		if (I_rd_index != 6'b000000 && I_rd_index != 6'b101100 && I_pause == 0)
		begin
			write_enable <= 1'b1;
		end else begin
			write_enable <= 1'b0;
		end
	if (!I_rst_n) begin
		write_enable <= 1'b0;
	end
end

endmodule

