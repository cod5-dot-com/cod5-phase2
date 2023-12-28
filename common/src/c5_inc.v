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

module c5_inc#(parameter 
	WIDTH = 32 
	) (
	output reg [WIDTH-1:0] O_result,
	input [WIDTH-1:0] I_a
);


reg carry_in;
integer i;

always @(*) begin
/*	carry_in = 1;
	for (i = 0; i < WIDTH; i = i + 1) begin
		O_result[i] = I_a[i] ^ carry_in;
		carry_in = carry_in & I_a[i];
	end
*/
    O_result <= I_a + 1'b1;
end

endmodule

