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

module c5_alu#(parameter 
	WIDTH = 32 
	) (
	input [31:0] I_a_in,
	input [31:0] I_b_in,
	input [3:0] I_alu_function,
	output reg [31:0] O_c_alu
);

`include "c5_parameters.v"

wire do_add;
wire [32:0] sum;
wire less_than;

assign do_add = (I_alu_function == ALU_ADD) ? 1'b1 : 1'b0;
c5_adder u1_adder(sum, I_a_in, I_b_in, do_add);

assign less_than = (I_a_in[31] == I_b_in[31] || 
	I_alu_function == ALU_LESS_THAN)
		? sum[32] : I_a_in[31];

always @(*) begin
	case (I_alu_function)
	ALU_SUBTRACT, ALU_ADD: O_c_alu = sum[31:0];
	ALU_LESS_THAN: O_c_alu <= {ZERO[30:0], less_than};
	ALU_LESS_THAN_SIGNED: O_c_alu <= {ZERO[30:0], less_than};
	ALU_OR: O_c_alu <= I_a_in | I_b_in;
	ALU_AND: O_c_alu <= I_a_in & I_b_in;
	ALU_XOR: O_c_alu <= I_a_in ^ I_b_in;
	ALU_NOR: O_c_alu <= ~(I_a_in | I_b_in);
	default: O_c_alu <= ZERO;
	endcase
end

endmodule

