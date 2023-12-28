//              
//          MMXXIII September 29 PUBLIC DOMAIN by O'ksi'D
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


// References:
// https://github.com/nand2mario/sdram-tang-nano-20k
// https://github.com/zhelnio/ahb_lite_sdram/blob/master/src/ahb_lite_sdram/ahb_lite_sdram.v
// https://github.com/hdl-util/sdram-controller/blob/master/src/sdram_controller.sv
// http://cdn.gowinsemi.com.cn/IPUG279E.pdf
// https://media-www.micron.com/-/media/client/global/documents/products/data-sheet/dram/64mb_x32_sdram.pdf?rev=0af7f6403bf14075ab6b3984f549fc15
//

module sdram
#(
    parameter         FREQ = 60_000_000, // 60 MHz clock (should be 166MHz...)
    parameter         DATA_WIDTH = 32, // 32bit data width
    parameter         BANK_WIDTH = 2,  // 4 banks
    parameter         ROW_WIDTH = 11,  // 2K rows (512K words)
    parameter         COL_WIDTH = 8,   // 256 words per row

    parameter [4:0]   CL   = 5'd2,     // CAS
    parameter [4:0]   T_RP = 5'd2,     // precharge to active 
    parameter [4:0]   T_RFC= 5'd4,     // auto refresh period (normaly 9)
    parameter [4:0]   T_MRD= 5'd3,     // load mode register 
    parameter [4:0]   T_RCD= 5'd2,     // active to read/write 
    parameter [4:0]   T_WR = 5'd2      // write recovery
)
(
    // SDRAM chip
    inout [DATA_WIDTH-1:0]      IO_ram_DQ,
    output reg [ROW_WIDTH-1:0]  O_ram_A,
    output reg [BANK_WIDTH-1:0] O_ram_BA,
    output            O_ram_nCS,  
    output reg        O_ram_nWE,
    output reg        O_ram_nRAS,
    output reg        O_ram_nCAS,
    output            O_ram_CLK,
    output            O_ram_CKE, 
    output reg  [3:0] O_ram_DQM,
    
    // SoC bus
    input             I_clk,
    input             I_clk_sdram,     // phase shifted clock
    input             I_rst_n,
    input             I_cmd_read,      // command: read
    input             I_cmd_write,     // command: write
    input             I_cmd_refresh,   // command: auto refresh. one per 15us
    input      [22:0] I_address,       // byte address
    input      [31:0] I_data_in,       // data input
    output reg [31:0] O_data_out,      // data output
    output reg        O_data_ready,     
    output reg        O_busy           // 0: ready for next command
);

localparam CMD_SET_MODE = 3'b000;
localparam CMD_AUTO_REFRESH = 3'b001;
localparam CMD_PRECHARGE = 3'b010;
localparam CMD_BANK_ACTIVATE = 3'b011;
localparam CMD_WRITE = 3'b100;
localparam CMD_READ = 3'b101;
localparam CMD_NOP = 3'b111;

assign O_ram_CLK = I_clk_sdram;
assign O_ram_CKE = 1'b1;
assign O_ram_nCS = 1'b0;

reg dq_oen;         // 0 -> output
reg [DATA_WIDTH-1:0] dq_buf;
(*preserve*) reg [DATA_WIDTH-1:0] dq_out /* synthesis preserve */;
assign IO_ram_DQ = dq_oen ? 32'bzzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz : dq_out;
reg [DATA_WIDTH-1:0] dq_in;

always @(*) begin
	dq_in <= IO_ram_DQ;
end

localparam [2:0] BURST_LEN = 3'b0;
localparam BURST_MODE = 1'b0;     
localparam [10:0] MODE_REG = {4'b0, CL[2:0], BURST_MODE, BURST_LEN};

reg [22:0] addr_buf;

localparam STATE_UNINIT = 3'd0;
localparam STATE_IDLE = 3'd1;
localparam STATE_WRITING = 3'd2;
localparam STATE_READING = 3'd3;
localparam STATE_REFRESH = 3'd4;
localparam STATE_PRECHARGE = 3'd5;
reg [2:0] state_machine;
reg [4:0] step;
reg [31:0] countdown;
reg [2:0] cmd;

always @(posedge I_clk or negedge I_rst_n) begin
	if (!I_rst_n) begin
		O_busy <= 1'b1;
		state_machine <= STATE_UNINIT;
		step <= 5'd0;
        	O_ram_DQM <= 4'b0;
		dq_oen <= 1'b1;
		dq_buf <= 0;
	end else begin 
		step <= (step == 5'd31) ? 5'd31 : (step + 5'd1);
    		cmd = CMD_NOP; 
		case (state_machine)
		STATE_UNINIT: begin
			if (step == 5'd0) begin
				step <=  5'd1;
				countdown <=  FREQ/1000*200/1000; // 200 us
			end else if (step == 5'd1) begin
				countdown <= countdown - 1'd1;
				step <= 5'd1;
				if (countdown == 32'd0) begin
					step <= 5'd2;
				end
			end else if (step == 5'd2) begin
				state_machine <= STATE_PRECHARGE;
				step <= 5'd0;
			end
		end
		STATE_IDLE: begin
        		if (I_cmd_read || I_cmd_write) begin
				cmd = CMD_BANK_ACTIVATE;
            			O_ram_BA <= I_address[ROW_WIDTH+COL_WIDTH+
					BANK_WIDTH-1+2 : 
					ROW_WIDTH+COL_WIDTH+2];
            			O_ram_A <= I_address[ROW_WIDTH+COL_WIDTH-1+2:
					COL_WIDTH+2]; 
            			state_machine <= I_cmd_read ? STATE_READING : 
						STATE_WRITING;
            			addr_buf <= I_address;
				if (I_cmd_write) begin
            				dq_out <= I_data_in;
            				dq_buf <= I_data_in;
				end else begin
					dq_oen <= 1'b1;
				end
            			step <= 5'd1;
            			O_busy <= 1'b1;
			end else if (I_cmd_refresh) begin
            			cmd = CMD_AUTO_REFRESH;
            			state_machine <= STATE_REFRESH;
            			step <= 5'd1;
            			O_busy <= 1'b1;
        		end
		end
		STATE_REFRESH: begin
			if (step == T_RFC) begin
            			state_machine <= STATE_IDLE;
            			O_busy <= 1'b0;
        		end
		end
		STATE_WRITING: begin
			if (step == T_RCD) begin
          	  		cmd = CMD_WRITE;
            			O_ram_A[10] <= 1'b1; // auto precharge
            			O_ram_A[9:0] <= {1'b0, 
					addr_buf[COL_WIDTH-1+2:2]};
	    			O_ram_DQM <= 4'b0000;
            			dq_out <= dq_buf;
            			dq_oen <= 1'b0; 
        		end else if (step == T_RCD+4'd1) begin
            			dq_oen <= 1'b1;
        		end else if (step == T_RCD+T_WR+T_RP) begin 
            			O_busy <= 0;
            			state_machine <= STATE_IDLE;
        		end
		end
		STATE_READING: begin
        		if (step == T_RCD) begin
            			cmd = CMD_READ;
            			O_ram_A[10] <= 1'b1; // auto precharge
            			O_ram_A[9:0] <= {1'b0, 
					addr_buf[COL_WIDTH-1+2:2]};
            			O_ram_DQM <= 4'b0;
        		end else if (step == T_RCD+CL) begin
            			O_data_ready <= 1'b1;
            			O_data_out <= dq_in;
        		end else if (step == T_RCD+CL+5'd1) begin
            			O_data_ready <= 1'b0;
            			O_busy <= 0;
            			state_machine <= STATE_IDLE;
        		end
		end
		STATE_PRECHARGE: begin
			if (step == 5'd0) begin
            			cmd = CMD_PRECHARGE;
            			O_ram_A[10] <= 1'b1;
			end else if (step == T_RP) begin
            			cmd = CMD_AUTO_REFRESH;
			end else if (step == T_RP+T_RFC) begin
            			cmd = CMD_AUTO_REFRESH;
			end else if (step == T_RP+T_RFC+T_RFC) begin
            			cmd = CMD_SET_MODE;
            			O_ram_A[10:0] <= MODE_REG;
			end else if (step == T_RP+T_RFC+T_RFC+T_MRD) begin
            			state_machine <= STATE_IDLE;
            			O_busy <= 1'b0;              //  init done
			end
		end
		endcase
		{O_ram_nRAS, O_ram_nCAS, O_ram_nWE} <= cmd; 
	end
end
endmodule
