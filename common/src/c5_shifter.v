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
// References:
// http://plasmacpu.no-ip.org
// https://opencores.org/projects/plasma
// https://booksite.elsevier.com/9780124077263/

module c5_shifter#(parameter 
	WIDTH = 32 
	) (
	input [31:0] I_value,
	input [4:0] I_shift_amount,
	input [1:0] I_shift_func,
	output reg [31:0] O_c_shift
);

`include "c5_parameters.v"

wire [31:0] shift1L;
wire [31:0] shift2L;
wire [31:0] shift4L;
wire [31:0] shift8L;
wire [31:0] shift16L;
wire [31:0] shift1R;
wire [31:0] shift2R;
wire [31:0] shift4R;
wire [31:0] shift8R;
wire [31:0] shift16R;
wire [15:0] fills;

assign shift1L = (I_shift_amount[0] == 1) ? {I_value[30:0],1'b0} : I_value;
assign shift2L = (I_shift_amount[1] == 1) ? {shift1L[29:0],2'b00} : shift1L;
assign shift4L = (I_shift_amount[2] == 1) ? {shift2L[27:0],4'b0000} : shift2L;
assign shift8L = (I_shift_amount[3] == 1) ? {shift4L[23:0],8'h00} : shift4L;
assign shift16L = (I_shift_amount[4] == 1) ? {shift8L[15:0],16'h0000} : shift8L;

assign fills = (I_shift_func == SHIFT_RIGHT_SIGNED && I_value[31] == 1'b1)
	? 16'b1111_1111_1111_1111 : 16'b0000_0000_0000_0000;

assign shift1R = (I_shift_amount[0] == 1) ? 
	{fills[0],I_value[31:1]} : I_value;
assign shift2R = (I_shift_amount[1] == 1) ? 
	{fills[1:0],shift1R[31:2]} : shift1R;
assign shift4R = (I_shift_amount[2] == 1) ? 
	{fills[3:0],shift2R[31:4]} : shift2R;
assign shift8R = (I_shift_amount[3] == 1) ? 
	{fills[7:0],shift4R[31:8]} : shift4R;
assign shift16R = (I_shift_amount[4] == 1) ? 
	{fills[15:0],shift8R[31:16]} : shift8R;

always @(*) begin
	case (I_shift_func)
	SHIFT_LEFT_UNSIGNED: O_c_shift <= shift16L;
	SHIFT_RIGHT_SIGNED: O_c_shift <= shift16R;
	SHIFT_RIGHT_UNSIGNED: O_c_shift <= shift16R;
	default: O_c_shift <= ZERO;
	endcase
end

endmodule

