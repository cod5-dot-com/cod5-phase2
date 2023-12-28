// RS232 UART
//            4 May MMXXIII PUBLIC DOMAIN by Jean-Marc Lienher
//             The authors disclaim copyright to this software.
//
module uart #(parameter 
	CLOCK_HZ = 48000000, 
	BAUDRATE = 115200
	) (
	input clk,
	input reset,
	input cmd_read,
	input cmd_write,
	input in_pin,
	output out_pin,
	input [7:0] bus_in,
	output [7:0] bus_out,
	output busy_write,
	output data_avail
);

wire [31:0] period;
assign period = CLOCK_HZ / BAUDRATE;

// TX
reg unsigned [3:0] out_state;
reg unsigned [31:0] out_cnt;
reg [8:0] out_shift;
assign out_pin = out_shift[0];
assign busy_write = out_state != 0;

always @(posedge clk) begin
	if (reset) begin
		out_shift <= 9'b000000001;
		out_state <= 0;
		out_cnt <= 0;
	end else if (out_state != 0) begin
		out_cnt <= out_cnt + 1;
		if (out_cnt == period) begin
			if (out_state == 12) begin
				out_state <= 0;
			end else if (out_state == 11) begin
				out_cnt <= 0;
				out_state <= out_state + 1;
			end else begin
				out_cnt <= 0;
				out_shift <= {1'b1, out_shift[8:1]};
				out_state <= out_state + 1;
			end
		end
	end else if (cmd_write) begin
		out_state <= 1;
		out_cnt <= 0;
		out_shift <= {bus_in[7:0], 1'b0};
	end else begin
		out_shift <= 9'b000000001;
	end
end

// RX 
wire [31:0] half;
assign half = {1'b0, period[31:1]};

reg [7:0] in_buffer;
reg [7:0] in_shift;
reg in_available;
reg in_read_buf;
reg in_p0;
reg in_p1;
reg unsigned [3:0] in_state;
reg unsigned [31:0] in_cnt;

assign bus_out = in_read_buf ? in_buffer : 8'bZ;
assign data_avail = in_available;

always @(posedge clk) begin
	if (reset) begin
		in_state <= 0;
		in_cnt <= 0;
		in_available <= 0;
		in_read_buf <= 0;
		in_shift <= 0;
	end else begin
		in_p0 <= in_pin;
		in_p1 <= in_p0;
		in_cnt <= in_cnt + 1;
		if (in_state == 1) begin
			if (in_cnt == half) begin
				if (~in_pin) begin
					in_cnt <= 0;
					in_state <= 2;
				end else begin
					in_state <= 0;
				end
			end else begin
				if (in_pin) begin
					in_state <= 0;
				end
			end
		end else if (in_state == 10) begin 
			if (in_cnt == period) begin
				if (in_pin) begin
					in_available <= 1;
					in_buffer <= in_shift;
				end
				in_state <= 0;
			end
		end else if (in_state != 0) begin
			if (in_cnt == period) begin
				in_cnt <= 0;
				in_state <= in_state + 1;
				in_shift = {in_pin, in_shift[7:1]};
			end
		end else begin
			if (~in_p0 & in_p1) begin
				in_state <= 1;
				in_cnt <= 0;
			end
		end
		if (in_read_buf) begin
			in_read_buf <= 0;
		end
		if (cmd_read && in_available) begin
			in_read_buf <= 1;
			in_available <= 0;
		end
	end
end

endmodule

