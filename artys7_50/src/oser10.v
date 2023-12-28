
module OSER10 (
	output Q,
	input D0,
	input D1,
	input D2,
	input D3,
	input D4,
	input D5,
	input D6,
	input D7,
	input D8,
	input D9,
	input FCLK, // high speed clock
	input PCLK,
	input RESET
);

wire [1:0] slave_to_master;
reg	sync_ce, q_ce, qq_ce, resetd;

initial	resetd = 1'b1;
initial	{ sync_ce, qq_ce, q_ce } = 0;

always @(posedge PCLK) begin
		q_ce <= !RESET;
		qq_ce <= q_ce;
		sync_ce <= qq_ce;
		resetd <= !sync_ce;
end

OSERDESE2 #(
	.DATA_RATE_OQ("DDR"),
	.DATA_RATE_TQ("SDR"),
	.DATA_WIDTH(10),
	.SERDES_MODE("MASTER"),
	.TRISTATE_WIDTH(1)
) low (
	.OCE(sync_ce),
	.OFB(),
	.TCE(1'b0),
	.TFB(),
	.TQ(),
	.CLK(FCLK),
	.CLKDIV(PCLK),
	.OQ(Q),
	.D1(D0),
	.D2(D1),
	.D3(D2),
	.D4(D3),
	.D5(D4),
	.D6(D5),
	.D7(D6),
	.D8(D7),
	.RST(resetd),
	.TBYTEIN(1'b0),
	.TBYTEOUT(),
	.T1(1'b0),
	.T2(1'b0),
	.T3(1'b0),
	.T4(1'b0),
	.SHIFTIN1(slave_to_master[0]),
	.SHIFTIN2(slave_to_master[1]),
	.SHIFTOUT1(),
	.SHIFTOUT2()
);

OSERDESE2 #(
	.DATA_RATE_OQ("DDR"),
	.DATA_RATE_TQ("SDR"),
	.DATA_WIDTH(10),
	.SERDES_MODE("SLAVE"),
	.TRISTATE_WIDTH(1)
) high (
	.OCE(sync_ce),
	.OFB(),
	.TCE(1'b0),
	.TFB(),
	.TQ(),
	.CLK(FCLK),
	.CLKDIV(PCLK),
	.OQ(),
	.D1(1'b0),
	.D2(1'b0),
	.D3(D8),
	.D4(D9),
	.D5(1'b0),
	.D6(1'b0),
	.D7(1'b0),
	.D8(1'b0),
	.RST(resetd),
	.TBYTEIN(1'b0),
	.TBYTEOUT(),
	.T1(1'b0),
	.T2(1'b0),
	.T3(1'b0),
	.T4(1'b0),
	.SHIFTIN1(1'b0),
	.SHIFTIN2(1'b0),
	.SHIFTOUT1(slave_to_master[0]),
	.SHIFTOUT2(slave_to_master[1])
);


endmodule

