//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
//
// 
//         22 October MMXXIII PUBLIC DOMAIN by O'ksi'D
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
//    Implements the Program Counter logic.
// ---------------------------------------------------------------------

module c5_pc_next#(parameter 
	WIDTH = 32 
	) (
   	input I_clk,
        input I_rst_n,

        input [31:2] I_pc_new,
        input I_take_branch,
        input I_pause_in,
        input [25:0] I_opcode25_0,
        input [1:0] I_pc_source,
        output reg [31:2] O_pc_future,
        output reg [31:2] O_pc_current,
        output reg [31:2] O_pc_plus4
);

`include "c5_parameters.v"

reg [31:2] pc_reg;
wire [31:2] pc_inc;
reg [31:2] pc_next;
reg [31:0] pcn;
reg [31:0] pci;

c5_increment u1_pc_increm(.I_a(pc_reg), .O_result(pc_inc)) /* synthesis syn_keep = 1 */;

always @(*) begin
		pcn = {I_pc_new, 2'b00};
		pci = {pc_inc, 2'b00};
		case (I_pc_source)
   		FROM_INC4: pc_next = pc_inc;
		FROM_OPCODE25_0: begin
			pc_next = {pc_reg[31:28], I_opcode25_0};
		end
   		FROM_BRANCH, FROM_LBRANCH: begin 
			if (I_take_branch == 1'b1) begin
       				pc_next = I_pc_new;
			end else begin
       				pc_next = pc_inc;
      			end
		end
		default: begin 
			pc_next = pc_inc;
		end
		endcase
		if (I_pause_in == 1'b1) begin
      			pc_next = pc_reg;
		end
	if (!I_rst_n) begin
      		pc_next = ZERO[31:2];
	end
end

always @(posedge I_clk) begin
	if (!I_rst_n) begin
      		pc_reg <= ZERO[31:2];
   		O_pc_future <= ZERO[31:2];
   		O_pc_current <= ZERO[31:2];
   		O_pc_plus4 <= {ZERO[31:3], 1'b1};
	end else begin
   		pc_reg <= pc_next;
   		O_pc_future <= pc_next;
   		O_pc_current <= pc_reg;
   		O_pc_plus4 <= pc_inc;
   	end 
end

endmodule

