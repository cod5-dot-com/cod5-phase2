//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
//
// 
//            19 October MMXXIII PUBLIC DOMAIN by O'ksi'D
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

module c5_bus_mux#(parameter 
	WIDTH = 32 
	) (
	input [15:0] I_imm_in,
	input [31:0] I_reg_source,
	input [1:0] I_a_mux,        
	output reg [31:0] O_a_out,

	input [31:0] I_reg_target,
	input [1:0] I_b_mux,          
	output reg [31:0] O_b_out,

	input [31:0] I_c_bus,
	input [31:0] I_c_memory,
	input [31:2] I_c_pc,
	input [31:2] I_c_pc_plus4,
	input [2:0] I_c_mux,           
	output reg [31:0] O_reg_dest_out,

	input [2:0] I_branch_func,
	output reg O_take_branch
);

`include "c5_parameters.v"

always @(*) begin
	case (I_a_mux)
	A_FROM_REG_SOURCE: begin
		O_a_out <= I_reg_source;
	end
	A_FROM_IMM10_6: O_a_out <= {ZERO[31:5], I_imm_in[10:6]};
	A_FROM_PC: begin
		O_a_out <= {I_c_pc, 2'b00};
	end
	default: O_a_out <= {I_c_pc, 2'b00};
	endcase
end

always @(*) begin
	case (I_b_mux)
	B_FROM_REG_TARGET: O_b_out <= I_reg_target;
	B_FROM_IMM: O_b_out <= {ZERO[31:16], I_imm_in};
	B_FROM_SIGNED_IMM: begin
		if (I_imm_in[15] == 0) begin
			O_b_out[31:16] <= ZERO[31:16];
		end else begin
			O_b_out[31:16] <= ONES[31:16];
		end
		O_b_out[15:0] <= I_imm_in;
	end
	B_FROM_IMMX4: begin
		if (I_imm_in[15] == 0) begin
			O_b_out[31:18] <= ZERO[31:18];
		end else begin
			O_b_out[31:18] <= ONES[31:18];
		end
		O_b_out[17:0] <= {I_imm_in, 2'b00};
	end
	default: O_b_out <= I_reg_target;
	endcase
end

always @(*) begin
	case (I_c_mux)
	C_FROM_ALU: O_reg_dest_out <= I_c_bus;
	C_FROM_MEMORY: O_reg_dest_out <= I_c_memory;
	C_FROM_PC: begin
		O_reg_dest_out <= {I_c_pc[31:2], 2'b00};
	end
	C_FROM_PC_PLUS4: begin
		O_reg_dest_out <= {I_c_pc_plus4, 2'b00};
	end
	C_FROM_IMM_SHIFT16: O_reg_dest_out <= {I_imm_in, ZERO[15:0]};
	default: O_reg_dest_out <= I_c_bus;
	endcase
end

wire is_equal;
assign is_equal = (I_reg_source == I_reg_target);

always @(*) begin
	case (I_branch_func)
	BRANCH_LTZ: O_take_branch <= I_reg_source[31];
	BRANCH_LEZ: O_take_branch <= I_reg_source[31] | is_equal;
	BRANCH_EQ: O_take_branch <= is_equal;
	BRANCH_NE: O_take_branch <= !is_equal;
	BRANCH_GEZ: O_take_branch <= !I_reg_source[31];
	BRANCH_GTZ: O_take_branch <= !I_reg_source[31] & !is_equal;
	BRANCH_YES: O_take_branch <= 1;
	default: O_take_branch <= 0;
	endcase
end

endmodule

