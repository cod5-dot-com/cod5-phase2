//              
//           MMXXIII October 9 PUBLIC DOMAIN by O'ksi'D
//
//        The authors disclaim copyright to this software.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a
// compiled binary, for any purpose, commercial or non-commercial,
// and by any means.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT OF ANY PATENT, COPYRIGHT, TRADE SECRET OR OTHER
// PROPRIETARY RIGHT.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR 
// ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// References :
// https://zipcpu.com/blog/2018/07/06/afifo.html
//

module async_fifo #(
    parameter  DATA_WIDTH = 16,
    parameter  POINTER_WIDTH = 5 // 32 words of data
) (
    input wire I_write_clk,
    input wire I_write_rst_n,
    input wire I_cmd_write,
    input wire [DATA_WIDTH-1:0] I_write_data,
    output reg O_write_full,

    output reg O_half_full,

    input wire  I_read_clk,
    input wire  I_read_rst_n,
    input wire  I_cmd_read,
    output reg [DATA_WIDTH-1:0] O_read_data, 
    output reg O_read_empty 
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

// synchronize write point
reg [POINTER_WIDTH:0] read_write_ptr;
reg [POINTER_WIDTH:0] read_write_ptr1;

// dual port RAM
reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];

// write requests
reg [POINTER_WIDTH:0] write_bin;
wire [POINTER_WIDTH:0] write_gray_next;
wire [POINTER_WIDTH:0] write_bin_next;
reg [POINTER_WIDTH:0] write_read_bin;
wire  write_full_val;
reg  write_full;
wire [POINTER_WIDTH-1:0] nb_data_val;

assign write_address = write_bin[POINTER_WIDTH-1:0];
assign write_bin_next = write_bin + (I_cmd_write & ~write_full);
assign write_gray_next = (write_bin_next >> 1) ^ write_bin_next;
assign write_full_val = (write_gray_next == {
			~write_read_ptr[POINTER_WIDTH:POINTER_WIDTH-1],
			write_read_ptr[POINTER_WIDTH-2:0]});
assign nb_data_val = (write_bin[POINTER_WIDTH-1:0] - 
	write_read_bin[POINTER_WIDTH-1:0]); 

integer i;

always @(posedge I_write_clk or negedge I_write_rst_n)
begin
	if (!I_write_rst_n) begin
		O_write_full <= 1'b0;
		write_full <= 1'b0;
		{write_bin, write_ptr} <= 0;
		{write_read_ptr, write_read_ptr1} <= 0;
	end else begin
		write_read_bin = 0;
		for (i = 0; i <= POINTER_WIDTH; i = i + 1) begin
			write_read_bin = write_read_bin ^
			({write_read_ptr[POINTER_WIDTH:0]} >> i);
		end
		{write_bin, write_ptr} <= {write_bin_next, write_gray_next};
		{write_read_ptr, write_read_ptr1} <= 
			{write_read_ptr1, read_ptr};
		write_full <= write_full_val;
		O_write_full <= (nb_data_val >= DEPTH-2);
		O_half_full <= (nb_data_val >= DEPTH/2);
		if (I_cmd_write && !write_full_val) begin
			mem[write_address] <= I_write_data;
		end
	end
end

// read requests
reg [POINTER_WIDTH:0] read_bin;
wire [POINTER_WIDTH:0] read_gray_next;
wire [POINTER_WIDTH:0] read_bin_next;
wire read_empty_val;

assign read_address = read_bin[POINTER_WIDTH-1:0];
assign read_bin_next = read_bin + (I_cmd_read & ~O_read_empty);
assign read_gray_next = (read_bin_next >> 1) ^ read_bin_next;

assign read_empty_val = (read_gray_next == read_write_ptr);

always @(posedge I_read_clk or negedge I_read_rst_n)
begin
	if (!I_read_rst_n) begin
		O_read_empty <= 1'b0;
		{read_bin, read_ptr} <= 0;
		{read_write_ptr, read_write_ptr1} <= 0;
	end else begin
		{read_bin, read_ptr} <= {read_bin_next, read_gray_next};
		{read_write_ptr, read_write_ptr1} <= 
			{read_write_ptr1, write_ptr};
		O_read_empty <= read_empty_val;
		if (I_cmd_read) begin
			O_read_data <= mem[read_address];
		end
	end

end

endmodule

