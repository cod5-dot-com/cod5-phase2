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
reg [31:0] data_r;
reg mem_pause;
wire [31:2] address;
wire [3:0] byte_we;
wire [31:0] data_w;
wire [7:0] debug;
wire [31:0] a;
wire [31:0] an;
wire tx;
reg rx;

soc dut (
	.I_clk(clk),
	.I_rst_n(I_rst_n),

	.I_uart_rx(rx),
	.O_uart_tx(tx),

        .O_mem_address(address),
        .O_mem_byte_we(byte_we),
        .O_mem_data_write(data_w),
        .I_mem_data_read(data_r),
        .I_mem_pause(mem_pause)
);


assign a = {address, 2'b00};

assign data_r = 'hDEADBEEF;

initial begin
	$monitor("%b %t: =%h %h CUR: %h %h", tx,  $time, data_w, data_r, byte_we, a);
	I_rst_n = 0;
//	I_data_r = 32'h0;
	mem_pause = 0;
	#100 I_rst_n = 1;

	#100 `assert(I_rst_n, 'd1);

	#150000

	$finish;
end

initial begin
	clk = 0;
	#5
	forever clk = #5 ~clk;
end


endmodule
