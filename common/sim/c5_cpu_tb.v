`timescale 1ns / 1ns

`define assert(a, b) \
	if (a !== b) begin \
		$display("assertion FAILED %h !== %h", a, b); \
		$finish; \
	end

module test_bench;

reg clk;
reg I_rst_n;
reg I_intr_in;
reg [31:0] I_data_r;
reg I_mem_pause;
wire [31:2] O_address_next;
wire [3:0] O_byte_we_next;
wire [31:2] O_address;
wire [3:0] O_byte_we;
wire [31:0] O_data_w;
wire [7:0] O_debug;
wire [31:0] a;

c5_cpu dut (
	.I_clk(clk),
	.I_rst_n(I_rst_n),
	.I_intr_in(I_intr_in),
        .O_address_next(O_address_next),
        .O_byte_we_next(O_byte_we_next),
        .O_address(O_address),
        .O_byte_we(O_byte_we),
        .O_data_w(O_data_w),
        .O_debug(O_debug),
        .I_data_r(I_data_r),
        .I_mem_pause(I_mem_pause)
);


wire ram_enable;
wire mem_enable;
wire [31:0] ram_data_r;
c5_ram u2_bsram(
	.I_clk(clk),
	.I_rst_n(I_rst_n),
	.I_enable(O_address_next < 'h1000),
	.I_write_byte_enable(O_byte_we_next),
	.I_address(O_address_next),
	.I_data_write(O_data_w),
	.O_data_read(I_data_r)
);

assign a = {O_address_next, 2'b00};

initial begin
	$monitor("%c %t: [%h]=%h %h %h", O_debug,  $time, a, O_data_w, O_byte_we_next, I_data_r);
	I_rst_n = 0;
	I_intr_in = 0;
//	I_data_r = 32'h0;
	I_mem_pause = 0;
	#100 I_rst_n = 1;

	#100 `assert(I_rst_n, 'd1);

	#500

	$finish;
end;

initial begin
	clk = 0;
	#5
	forever clk = #5 ~clk;
end


endmodule;
