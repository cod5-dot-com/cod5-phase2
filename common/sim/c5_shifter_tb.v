`timescale 1ns / 1ps

`define assert(a, b) \
	if (a !== b) begin \
		$display("assertion FAILED %h !== %h", a, b); \
		$finish; \
	end

module test_bench;

reg clk;
reg [31:0]  a;
reg [4:0]  n;
reg [1:0] f;
wire [31:0] r;

c5_shifter dut (
	.I_value(a),
	.I_shift_amount(n),
	.I_shift_func(f),
	.O_c_shift(r)
);

initial begin
	$monitor("%t: %h <<>> %d = %h", $time, a, n, r);
	a = 'h10;
	n = 4;
	f = c5.SHIFT_LEFT_UNSIGNED;
	#10 `assert(r, 'h100);
	f = c5.SHIFT_RIGHT_UNSIGNED;
	#10 `assert(r, 'h1);
	a = 'h80000000;
	f = c5.SHIFT_RIGHT_SIGNED;
	#10 `assert(r, 'hF8000000);
	$finish;
end;

initial begin
	clk = 0;
	forever clk = #1 ~clk;
end
endmodule;
