`timescale 1ns / 1ps

`define assert(a, b) \
	if (a !== b) begin \
		$display("assertion FAILED %h !== %h", a, b); \
		$finish; \
	end

module test_bench;

reg clk;
reg [31:2]  a;
wire [31:2] r;

c5_increment dut (
	.O_result(r),
	.I_a(a)
);

initial begin
	$monitor("%t: %h = %h", $time, a, r);
	a = 0;
	#10 a = 'h1;
	#10 `assert(r, 'h2);   a = 'h10;
	#10 `assert(r, 'h11);  a = 'h20;
	#10 `assert(r, 'h21)
	$finish;
end;

initial begin
	clk = 0;
	forever clk = #1 ~clk;
end
endmodule;
