
module cod5_top(
		input wire clk,
		inout reg [8:0] io_eb_b 
	);

	wire rst;
	assign rst = io_eb_b[0];

	reg [26:0] counter;
	
	wire clk270, clk180, clk90, clk0, usr_ref_out;
	wire usr_pll_lock_stdy, usr_pll_lock;

	CC_PLL #(
		.REF_CLK("10.0"),    // reference input in MHz
		.OUT_CLK("100.0"),   // pll output frequency in MHz
		.PERF_MD("ECONOMY"), // LOWPOWER, ECONOMY, SPEED
		.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
		.CI_FILTER_CONST(2), // optional CI filter constant
		.CP_FILTER_CONST(4)  // optional CP filter constant
	) pll_inst (
		.CLK_REF(clk), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
		.USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
		.CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clk0), .CLK_REF_OUT(usr_ref_out)
	);

	soc u0_soc(
		.I_clk(clk0),
		.I_rst_n(io_eb_b[1]),

		.I_uart_rx(io_eb_b[2]),
		.O_uart_tx(io_eb_b[3])
	);
/*
	always @(*)
	begin
	       	io_eb_b[8:1] <= counter[26:16];
	end

	always @(posedge clk0)
	begin
		if (!rst) begin
			counter <= 0;
		end else begin
			counter <= counter + 1'b1;
		end
	end
*/
endmodule
