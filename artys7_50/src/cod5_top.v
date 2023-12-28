

module cod5_top(
	input [3:0] SW,
	input [3:0] BTN,
	input CLK,
	output [2:0] O_tmds_data_p,
	output [2:0] O_tmds_data_n,
	output O_tmds_clk_p,
	output O_tmds_clk_n,
	
	output [3:0] LED,
	output UART_TXD,
	input UART_RXD,
	output led0_r,
	output led0_g,
	output led0_b,
	output led1_r,
	output led1_g,
	output led1_b
    );


wire resetn;
wire clk_144mhz;
wire clk_48mhz;
wire clk_125mhz;
wire clk_25mhz;
wire clk_144mhzp;
wire locked;
wire intr_in;
wire [31:2] address;
wire [3:0] byte_we;
wire [31:0] data_w;
reg [31:0] data_r;
wire mem_pause;
wire mem_select;
reg [31:0] counter;

assign resetn = !BTN[0];
assign mem_pause = 0;
assign LED = counter[31:27];


always @(posedge clk_48mhz or negedge resetn) begin
	if (!resetn) begin
	   counter <= 0;
    end else begin
        counter <= counter + 1'b1;
    end
end

always @(posedge clk_48mhz or negedge resetn) begin
	if (!resetn) begin
		data_r <= 0;
	end else begin
	end
end

soc u0_soc(
	.I_clk(clk_48mhz),
	.I_rst_n(resetn),

    .O_mem_select(mem_select),
    .O_mem_address(address),
    .O_mem_byte_we(byte_we),
    .O_mem_data_write(data_w),
    .I_mem_data_read(data_r),
    .I_mem_pause(mem_pause),
	
	.I_clk_pixel(clk_25mhz),
	.I_clk_pixel_x5(clk_125mhz),

    .O_tmds_clk_p(O_tmds_clk_p),
    .O_tmds_clk_n(O_tmds_clk_n),
    .O_tmds_data_p(O_tmds_data_p),
	.O_tmds_data_n(O_tmds_data_n),
	
	.I_uart_rx(UART_RXD),
	.O_uart_tx(UART_TXD)
);


clk_wiz_0_clk_wiz u1_clk (
	.clk_in1(CLK),
	.resetn(resetn),
	.clk_144mhz(clk_144mhz),
	.clk_48mhz(clk_48mhz),
	.clk_125mhz(clk_125mhz),
	.clk_25mhz(clk_25mhz),
	.clk_144mhzp(clk_144mhzp),
	.locked(locked)
);

endmodule
