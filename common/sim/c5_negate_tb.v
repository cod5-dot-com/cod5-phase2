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

c5_negate dut (
	.I_a(a),
	.O_result(r)
);


initial begin
	$monitor("%t: %h = %h", $time, a, r);
	a = 3;
	#10 `assert(r, -'d3);
	a = 2;
	#10 `assert(r, -'d2);
	$finish;
end;

initial begin
	clk = 0;
	forever clk = #1 ~clk;
end
endmodule;
