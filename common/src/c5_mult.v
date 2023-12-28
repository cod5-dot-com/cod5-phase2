//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
//
// 
//          22 October MMXXIII PUBLIC DOMAIN by O'ksi'D
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

module c5_mult#(parameter 
	WIDTH = 32 
	) (
	input I_clk,
	input I_rst_n,

	input [31:0] I_a,
	input [31:0] I_b,
	input [3:0] I_mult_func,
	output reg [31:0] O_c_mult,
	output reg O_pause_out
);

`include "c5_parameters.v"

localparam MODE_MULT = 1'b1;
localparam MODE_DIV = 1'b0;

reg mode_reg;
reg negate_reg;
reg sign_reg;
reg sign2_reg;
reg [5:0] count_reg;
reg [31:0] aa_reg;
reg [31:0] bb_reg;
reg [31:0] upper_reg;
reg [31:0] lower_reg;
//wire [31:0] upper_reg_neg;
//wire [31:0] lower_reg_neg;
//wire [31:0] a_neg;
wire [31:0] b_neg;
wire [32:0] sum;
   
// ABS and remainder signals
//c5_negate u1_abs_a(.I_a(I_a), .O_result(a_neg));
//c5_negate u2_abs_b(.I_a(I_b), .O_result(b_neg));
c5_adder u3_add(.I_a(upper_reg), .I_b(aa_reg), 
	.I_do_add(mode_reg), .O_result(sum));
assign b_neg = -I_b;
//c5_negate u4_neg(.I_a(upper_reg), .O_result(upper_reg_neg));
//c5_negate u5_neg(.I_a(lower_reg), .O_result(lower_reg_neg));

always @(*) begin
   	// Result
	if (I_mult_func == MULT_READ_LO && negate_reg == 0) begin	
		O_c_mult = lower_reg;
	end else if (I_mult_func == MULT_READ_LO && negate_reg == 1) begin	
		O_c_mult = -lower_reg;
	end else if (I_mult_func == MULT_READ_HI && negate_reg == 0) begin	
		O_c_mult = upper_reg;
	end else if (I_mult_func == MULT_READ_HI && negate_reg == 1) begin	
		O_c_mult = -upper_reg;
	end else begin
		O_c_mult = ZERO;
	end

	if (count_reg != 6'b000000 && (I_mult_func == MULT_READ_LO || 
			I_mult_func == MULT_READ_HI))
	begin
		O_pause_out = 1;
	end else begin
		O_pause_out = 0;
	end
end
   


reg [2:0] count;

always @(posedge I_clk) begin
	if (!I_rst_n) begin
        	mode_reg <= 0;
         	negate_reg <= 0;
         	sign_reg <= 0;
         	sign2_reg <= 0;
         	count_reg <= 6'b000000;
         	aa_reg <= ZERO;
         	bb_reg <= ZERO;
         	upper_reg <= ZERO;
         	lower_reg <= ZERO;
		count <= 3'b001;
	end else begin
		count = 3'b001;
        	case (I_mult_func)
            	MULT_WRITE_HI: begin
               		upper_reg <= I_a;
               		negate_reg <= 0;
		end
		MULT_WRITE_LO: begin
               		lower_reg <= I_a;
               		negate_reg <= 0;
		end
            	MULT_MULT: begin
               		mode_reg <= MODE_MULT;
               		aa_reg <= I_a;
               		bb_reg <= I_b;
               		upper_reg <= ZERO;
               		count_reg <= 6'b100000;
               		negate_reg <= 0;
               		sign_reg <= 0;
               		sign2_reg <= 0;
		end
            	MULT_SIGNED_MULT: begin
               		mode_reg <= MODE_MULT;
			if (I_b[31] == 0) begin
                  		aa_reg <= I_a;
                  		bb_reg <= I_b;
			end else begin
                  		aa_reg <= -I_a;
                  		bb_reg <= -I_b;
               		end
			if (I_a != ZERO) begin
                  		sign_reg <= I_a[31] ^ I_b[31];
			end else begin
                  		sign_reg <= 0;
               		end 
               		sign2_reg <= 0;
               		upper_reg <= ZERO;
               		count_reg <= 6'b100000;
               		negate_reg <= 0;
		end
            	MULT_DIVIDE: begin
               		mode_reg <= MODE_DIV;
               		aa_reg <= {I_b[0], ZERO[30:0]};
               		bb_reg <= I_b;
               		upper_reg <= I_a;
               		count_reg <= 6'b100000;
               		negate_reg <= 0;
		end
            	MULT_SIGNED_DIVIDE: begin
               		mode_reg <= MODE_DIV;
			if (I_b[31] == 0) begin
                  		aa_reg[31] <= I_b[0];
                  		bb_reg <= I_b;
			end else begin
                  		aa_reg[31] <= b_neg[0];
                  		bb_reg <= b_neg;
               		end
			if (I_a[31] == 0) begin
                  		upper_reg <= I_a;
			end else begin
                  		upper_reg <= -I_a;
               		end
               		aa_reg[30:0] <= ZERO[30:0];
               		count_reg <= 6'b100000;
               		negate_reg <= I_a[31] ^ I_b[31];
		end
            	default: begin
			if (count_reg != 6'b000000) begin
				if (mode_reg == MODE_MULT) begin
                     			// Multiplication
					if (bb_reg[0] == 1) begin
                        			upper_reg <= {(sign_reg ^ 
							sum[32]), sum[31:1]};
                        			lower_reg <= {sum[0], 
							lower_reg[31:1]};
                        			sign2_reg <= sign2_reg || 
							sign_reg;
                        			sign_reg <= 0;
                        			bb_reg <= {1'b0, bb_reg[31:1]};
                     // The following six lines are optional for speedup
                     //elsif bb_reg(3:0) <= "0000" and sign2_reg <= '0' and 
                     //      count_reg(5:2) /= "0000" then
                     //   upper_reg <= "0000" & upper_reg(31:4);
                     //   lower_reg <=  upper_reg(3:0) & lower_reg(31:4);
                     //   count := "100";
                     //   bb_reg <= "0000" & bb_reg(31:4);
	     				end else begin
                        			upper_reg <= {sign2_reg, 
							upper_reg[31:1]};
                        			lower_reg <= {upper_reg[0], 
							lower_reg[31:1]};
                        			bb_reg <= {1'b0, bb_reg[31:1]};
                     			end
				end else begin
                     			// Division
                     			if (sum[32] == 0 && 
						aa_reg != ZERO && 
                           			bb_reg[31:1] == ZERO[31:1])
					begin
                        			upper_reg <= sum[31:0];
                        			lower_reg[0] <= 1;
					end else begin
                        			lower_reg[0] <= 0;
                     			end
                     			aa_reg <= {bb_reg[1], aa_reg[31:1]};
                     			lower_reg[31:1] <= lower_reg[30:0];
                     			bb_reg <= {1'b0, bb_reg[31:1]};
                  		end
                  		count_reg <= count_reg - count;
               		end //count
		end
         	endcase
	end
end

endmodule

