`timescale 1ns / 1ps

`define assert(a, b) \
	if (a !== b) begin \
		$display("assertion FAILED %h !== %h", a, b); \
		$finish; \
	end

module test_bench;

reg clk;
reg [31:0]  a;
reg [31:0]  b;
reg [3:0] f;
wire [31:0] r;

c5_alu dut (
	.I_a_in(a),
	.I_b_in(b),
	.I_alu_function(f),
	.O_c_alu(r)
);


initial begin
	$monitor("%t: %h = %h", $time, a, r);
	a = 1;
	b = 2;
	f = c5.ALU_ADD;
	#10 `assert(r, 'd3);
	f = c5.ALU_SUBTRACT;
	#10 `assert(r, -'d1);
	f = c5.ALU_LESS_THAN;
	#10 `assert(r, 'd1);
	f = c5.ALU_LESS_THAN_SIGNED;
	#10 `assert(r, 'd1);
	f = c5.ALU_OR;
	#10 `assert(r, 'd3);
	f = c5.ALU_AND;
	#10 `assert(r, 'd0);
	f = c5.ALU_XOR;
	#10 `assert(r, 'd3);
	f = c5.ALU_NOR;
	#10 `assert(r, ~'d3);
	$finish;
end;

initial begin
	clk = 0;
	forever clk = #1 ~clk;
end
endmodule;
