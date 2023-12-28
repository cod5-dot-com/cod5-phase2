// SPI master 
//            4 May MMXXIII PUBLIC DOMAIN by Jean-Marc Lienher
//             The authors disclaim copyright to this software.
//
module spi #(parameter 
	CLOCK_HZ = 48000000 
	) (
	input clk,
	input reset,
	input cmd_read,
	input cmd_write,
	output mosi,
	input miso,
	output sclk,
	output cs_n,
	output hold_n,
	output wp_n,
	input [7:0] bus_in,
	output [7:0] bus_out,
	output busy_write,
	output data_avail
);

reg unsigned [3:0] state;
reg [7:0] mo_shift;
reg [7:0] mo_buf;
reg mo_full;
reg [7:0] mi_shift;
reg [7:0] mi_buf;
reg mi_full;
reg clock;
reg in_read_buf;
assign mosi = mo_shift[7];
assign busy_write = mo_full;
assign hold_n = 1;
assign wp_n = 1;
assign cs_n = state == 0;
assign sclk = (state != 0) ? clock : 0;
assign data_avail = mi_full;
assign bus_out = in_read_buf ? mi_buf : 8'b01;

always @(posedge clk) begin
	if (reset) begin
		mo_shift <= 8'b11111111;
		mi_shift <= 8'b11111111;
		state <= 0;
		mo_full <= 0;
		mi_full <= 0;
		mi_buf <= 127;
		clock <= 0;
		in_read_buf <= 0;
	end else begin
		clock <= ~clock;
		if (cmd_write) begin
			if (~mo_full) begin
				if (state == 0) begin
					clock <= 0;
					state <= 10;
					mo_shift <= {bus_in[7:0]};
				end else begin
					mo_full <= 1;
					mo_buf <= {bus_in[7:0]};
				end
			end
		end
		if (in_read_buf) begin
			in_read_buf <= 0;
		end
		if (cmd_read && mi_full) begin
			in_read_buf <= 1;
			mi_full <= 0;
		end
		if (state != 0) begin
			if (~clock) begin
				if (state == 8) begin
					mi_buf <= {mi_shift[6:0], miso};
					mi_full <= 1;
					state <= 0;
				end else if (state == 9) begin
					mi_buf <= {mi_shift[6:0], miso};
					mi_full <= 1;
					state <= 1;
				end else if (state == 10) begin
					state <= 1;
				end else begin
					mi_shift <= {mi_shift[6:0], miso};
					state <= state + 1;
				end
			end else begin
				if (state == 8) begin
					if (mo_full) begin
						mo_full <= 0;
						mo_shift <= mo_buf;
						state <= 9;
					end
				end else begin
					mo_shift <= {mo_shift[6:0], 1'b0};
				end
			end
		end	
	end
end

endmodule
