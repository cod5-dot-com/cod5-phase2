`timescale 1ns / 1ps

module tb;

	reg I_clk;
	reg I_rst_n;
	reg I_intr_in;

        wire [31:2] O_address_next;
        wire [3:0] O_byte_we_next;

        wire [31:2] O_address;
        wire [3:0] O_byte_we;
        wire [31:0] O_data_w;
        reg [31:0] I_data_r;
        reg I_mem_pause;

        reg [31:0] I_a;
        reg [31:0] I_b;
        wire [31:0] O_r;
        reg I_f;
        reg [3:0] I_func;

	initial begin
`ifdef CCSDF
	//	$sdf_annotate("cod5_00.sdf", dut);
`endif
		$dumpfile("sim/cod5_tb.vcd");
		$dumpvars(0, tb);
		I_rst_n = 0;
	end

	initial begin
		I_clk = 0;
		forever begin
			I_clk = #1 ~I_clk;
		end
	end

`ifndef BOB
	initial begin
		$monitor("a: %b + b: %b = %b", I_a, I_b, O_r);
		I_a = 2; I_b = 3; I_func = 1; // add
		#10
		I_b = 1;
		#5
		I_b = 2;

		#5 
		I_func = 2; // sub
		#5 I_func = 3; // less than
		#5 I_func = 4; // less than signed 
		#5 I_func = 5; // or
		#5 I_func = 6; // and
		#5 I_func = 7; // xor
		#5 I_func = 8; // nor
		#5 I_func = 0; // nothing
		#5
		$finish;

	end
	c5_alu dut(
    		.I_a_in(I_a),
    		.I_b_in(I_b),
        	.O_c_alu(O_r),
		.I_alu_function(I_func)
	);
`else
	initial begin
		$monitor("a: %b + b: %b = %b", I_a, I_b, O_r);
		I_a = 2; I_b = 3; I_f = 1;
		#10
		I_b = 1;
		#5
		$finish;

	end
	c5_adder dut(
    		.I_a(I_a),
    		.I_b(I_b),
        	.O_result(O_r),
		.I_do_add(I_f)
	);
	c5_cpu dut(
    		.I_clk(I_clk),
    		.I_rst_n(I_rst_n),
		.I_intr_in(I_intr_in),
		.O_address_next(O_address_next),
        	.O_byte_we_next(O_byte_we_next),
        	.O_address(O_address),
        	.O_byte_we(O_byte_we),
        	.O_data_w(O_data_w),
        	.I_data_r(I_data_r),
        	.I_mem_pause(I_mem_pause)
	);
`endif

endmodule
