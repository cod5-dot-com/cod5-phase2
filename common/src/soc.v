module soc(
	input I_clk,
	input I_rst_n,

	output reg O_mem_select,
	output reg [31:2] O_mem_address,
	output reg [3:0]  O_mem_byte_we,
	output reg [31:0] O_mem_data_write,
	input  [31:0] I_mem_data_read,
	input I_mem_pause,
	input I_mem_data_ready,

	input I_uart_rx,
        output O_uart_tx,
    
	output O_spi_mosi,
        input I_spi_miso,
        output O_spi_sck,
        output O_spi_cs_sdcard,
        output O_spi_cs_ext1,
        output O_spi_cs_ext2,


	inout IO_usb_dp,
	inout IO_usb_dn,

	output O_tmds_clk_p,
	output O_tmds_clk_n,
	output [2:0]  O_tmds_data_p,
	output [2:0]  O_tmds_data_n, 
	input I_clk_pixel, 
	input I_clk_pixel_x5
);

`include "../../common/src/c5_parameters.v"

reg [31:2] beam_address;
reg display_fill;
wire display_sync;
wire display_read;
wire [31:0] display_data;
wire display_empty;

display u0_display (
	.I_clk(I_clk),
	.I_rst_n(I_rst_n),
        .I_clk_pixel(I_clk_pixel),
        .I_clk_pixel_x5(I_clk_pixel_x5),
    	.O_sync(display_sync),
        .O_read(display_read),
    	.I_data(display_data),
        .I_empty(display_empty),

    	.O_tmds_clk_p(O_tmds_clk_p),
    	.O_tmds_clk_n(O_tmds_clk_n),
    	.O_tmds_data_p(O_tmds_data_p),
	.O_tmds_data_n(O_tmds_data_n)
);

reg display_write;
reg [31:0] display_data_in;
wire display_full;
wire display_half_full;

async_fifo #(
	.DATA_WIDTH(32),
	.POINTER_WIDTH(5))
fifo_inst (
	.I_write_clk(I_clk),
    	.I_write_rst_n(I_rst_n & !display_sync),
    	.I_cmd_write(display_write),
    	//.I_write_data(display_data_in),
    	.I_write_data(32'h77777777),
    	.O_write_full(display_full),

    	.O_half_full(display_half_full),

	.I_read_clk(I_clk_pixel),
    	.I_read_rst_n(I_rst_n & !display_sync),
    	.I_cmd_read(display_read),
    	.O_read_data(display_data),
    	.O_read_empty(display_empty)
);

wire intr_in;
wire [31:2] address_next;
wire [3:0] byte_we_next;
wire [31:2] address;
wire [3:0] byte_we;
wire [31:0] data_w;
reg [31:0] data_r;
wire [7:0] debug;
wire cpu_pause;

c5_cpu u1_cpu(
	.I_clk(I_clk),
	.I_rst_n(I_rst_n),
	.I_intr_in(intr_in),
        .O_address_next(address_next),
        .O_byte_we_next(byte_we_next),
        .O_address(address),
        .O_byte_we(byte_we),
        .O_data_w(data_w),
        .O_debug(debug),
        .I_data_r(data_r),
        .I_mem_pause(cpu_pause)
); 

reg ram_enable;
wire [31:0] ram_data_r;
c5_ram u2_bsram(
	.I_clk(I_clk),
	.I_rst_n(I_rst_n),
	.I_enable(ram_enable),
	.I_write_byte_enable(byte_we_next),
	.I_address(address_next),
	.I_data_write(data_w),
	.O_data_read(ram_data_r)
);

wire [7:0] uart_data_r;
wire uart_busy_write;
wire uart_data_ready;
reg uart_read;
reg uart_write;

uart u3_uart(
	.I_clk(I_clk),
	.I_rst_n(I_rst_n),
	.I_cmd_read(uart_read),
	.I_cmd_write(uart_write),
//	.I_cmd_write(uart_data_ready && !uart_busy_write),
	.I_in_pin(I_uart_rx),
	.O_out_pin(O_uart_tx),
	.I_data_out(data_w[7:0]),
	//.I_data_out(8'd65),
	.O_data_in(uart_data_r),
	.O_busy_write(uart_busy_write),
	.O_data_ready(uart_data_ready)
);

/*
reg tmp;
assign O_uart_tx = tmp;
always @(posedge I_clk or negedge I_rst_n) begin
	if (!I_rst_n) begin
		tmp <= 0;
	end else begin
		tmp <= I_uart_rx;
	end
end
*/

always @(*) begin
	uart_read <= 0;
	uart_write <= 0;
	if (address[31] && address[30]) begin
		case ({address[29:2], 2'b00})
		'h0000: begin
			uart_read <= (byte_we == 4'd0) && uart_data_ready;
			uart_write <= (byte_we != 4'd0) && !uart_busy_write;
		end
		default: begin end
		endcase
	end
end

assign cpu_pause = I_mem_pause || !display_half_full || display_fill;
assign intr_in = 0;

always @(*) begin
	if (display_half_full && !display_fill && 
		address_next < BSRAM_SIZE) 
	begin
		ram_enable = 1;
	end else begin
		ram_enable = 0;
	end
end

always @(*) begin
	display_fill <= 0;
	// FIXME
	if (!display_sync && (!display_half_full || 
		(display_fill && !display_full))) 
	begin
		data_r <= 0;
		display_fill <= 1;
		display_data_in <= I_mem_data_read;
	end else if (address < BSRAM_SIZE) begin
		data_r <= ram_data_r;
	end else if (!(address[31] && address[30])) begin
		data_r <= I_mem_data_read;
	end else begin
		case ({address[30:2], 2'b00})
		'h0000: data_r <= {24'd0, uart_data_r};
		default: begin data_r <= 0; end
		endcase
	end
end

always @(*) begin
	O_mem_byte_we <= byte_we_next;
	O_mem_address <= address_next;
	O_mem_data_write <= data_w;
	O_mem_select <= 0;
	if (display_fill) begin
		O_mem_byte_we <= 0;
		O_mem_address <= beam_address;
		O_mem_select <= 1;
		display_write <= I_mem_data_ready;
	end else if (!(address_next[31] && address_next[30]) && 
		address_next >= BSRAM_SIZE) 
	begin
		O_mem_select <= 1;
	end
end

always @(posedge I_clk) begin
	if (display_sync) begin
		beam_address <= FRAMEBUFFER0[31:2];
	end else begin
		if (display_fill) begin
			if (I_mem_data_ready) begin
				beam_address = beam_address + 1'b1;
			end
		end
	end
end

endmodule

