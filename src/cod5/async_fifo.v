/*
 *                          Asynchronous FIFO
 *
 *                      19 may MMXXI PUBLIC DOMAIN
 *           The author disclaims copyright to this source code.
 *
 *
 */


module cod5_async_fifo #(
    parameter  DATA_WIDTH = 16,
    parameter  POINTER_WIDTH = 5
) (
    input wire write_clk_i,
    input wire write_rst_ni,
    input wire write_inc_i,
    input wire [DATA_WIDTH-1:0] write_data_i,
    output reg write_full_o = 0,
    output reg [POINTER_WIDTH-1:0] nb_data_o = 0,

    input wire  read_clk_i,
    input wire  read_rst_ni,
    input wire  read_inc_i,
    output reg [DATA_WIDTH-1:0] read_data_o = 0, 
    output reg read_empty_o = 1 
);

localparam HALF = (1 << (POINTER_WIDTH-1));
localparam DEPTH = 1 << POINTER_WIDTH;

wire [POINTER_WIDTH-1:0] write_address;
wire [POINTER_WIDTH-1:0] read_address;
reg [POINTER_WIDTH:0] write_ptr;
reg [POINTER_WIDTH:0] read_ptr;


// synchronize read point
reg [POINTER_WIDTH:0] write_read_ptr;
reg [POINTER_WIDTH:0] write_read_ptr1;

always @(posedge write_clk_i or negedge write_rst_ni)
begin
	if (!write_rst_ni) 
		{write_read_ptr, write_read_ptr1} <= 0;
	else
		{write_read_ptr, write_read_ptr1} <= 
			{write_read_ptr1, read_ptr};
end

// synchronize write point
reg [POINTER_WIDTH:0] read_write_ptr;
reg [POINTER_WIDTH:0] read_write_ptr1;

always @(posedge read_clk_i or negedge read_rst_ni)
begin
	if (!read_rst_ni)
		{read_write_ptr, read_write_ptr1} <= 0;
	else
		{read_write_ptr, read_write_ptr1} <= 
			{read_write_ptr1, write_ptr};
end

// write requests
reg [POINTER_WIDTH:0] write_bin;
wire [POINTER_WIDTH:0] write_gray_next;
wire [POINTER_WIDTH:0] write_bin_next;
reg [POINTER_WIDTH:0] write_read_bin;
wire  write_full_val;
wire [POINTER_WIDTH-1:0] nb_data_val;

always @(posedge write_clk_i or negedge write_rst_ni)
begin
	if (!write_rst_ni)
		{write_bin, write_ptr} <= 0;
	else
		{write_bin, write_ptr} <= {write_bin_next, write_gray_next};
end

assign write_address = write_bin[POINTER_WIDTH-1:0];
assign write_bin_next = write_bin + (write_inc_i & ~write_full_o);
assign write_gray_next = (write_bin_next >> 1) ^ write_bin_next;
assign write_full_val = (write_gray_next == {
			~write_read_ptr[POINTER_WIDTH:POINTER_WIDTH-1],
			write_read_ptr[POINTER_WIDTH-2:0]});
assign nb_data_val = (write_bin[POINTER_WIDTH-1:0] - 
	write_read_bin[POINTER_WIDTH-1:0]); 

integer i;
always @(posedge write_clk_i or negedge write_rst_ni)
begin
	if (!write_rst_ni) begin
		write_full_o <= 1'b0;
		nb_data_o <= 0;
	end else begin
		write_read_bin = 0;
		for (i = 0; i <= POINTER_WIDTH; i = i + 1) begin
			write_read_bin = write_read_bin ^
			({write_read_ptr[POINTER_WIDTH:0]} >> i);
		end
		write_full_o <= write_full_val;
		nb_data_o <= nb_data_val;
	end
end

// dual port RAM
reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];
always @(posedge write_clk_i)
begin
	if (write_inc_i && !write_full_val)
		mem[write_address] <= write_data_i;
end

always @(posedge read_clk_i)
begin
	if (read_inc_i)
		read_data_o <= mem[read_address];
end

// read requests
reg [POINTER_WIDTH:0] read_bin;
wire [POINTER_WIDTH:0] read_gray_next;
wire [POINTER_WIDTH:0] read_bin_next;
wire read_empty_val;

always @(posedge read_clk_i or negedge read_rst_ni)
begin
	if (!read_rst_ni)
		{read_bin, read_ptr} <= 0;
	else
		{read_bin, read_ptr} <= {read_bin_next, read_gray_next};
end

assign read_address = read_bin[POINTER_WIDTH-1:0];
assign read_bin_next = read_bin + (read_inc_i & ~read_empty_o);
assign read_gray_next = (read_bin_next >> 1) ^ read_bin_next;

assign read_empty_val = (read_gray_next == read_write_ptr);

always @(posedge read_clk_i or negedge read_rst_ni)
begin
	if (!read_rst_ni) begin
		read_empty_o <= 1'b0;
	end else begin
		read_empty_o <= read_empty_val;
	end
end

endmodule

