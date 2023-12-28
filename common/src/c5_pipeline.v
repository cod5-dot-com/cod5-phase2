//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
//
// 
//          22 October MMXXIII PUBLIC DOMAIN by O'ksi'D
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
//
// References:
// http://plasmacpu.no-ip.org
// https://opencores.org/projects/plasma
// https://booksite.elsevier.com/9780124077263/
//
//    Controls the three stage pipeline by delaying the signals:
//      I_a_bus, I_b_bus, alu/shift/I_mult_func, I_c_source, and I_rs_index.
////////////////////////////////////////////////////////////////////-

// Note: sigD <= sig after rising_edge(I_clk)

module c5_pipeline#(parameter 
	WIDTH = 32 
	) (
   	input I_clk,
        input I_rst_n,

        input [31:0] I_a_bus,
        output reg [31:0] O_a_busD,
        input [31:0] I_b_bus,
        output reg [31:0] O_b_busD,
        input [3:0] I_alu_func,
        output reg [3:0] O_alu_funcD,
        input [1:0] I_shift_func,
        output reg [1:0] O_shift_funcD,
        input [3:0] I_mult_func,
        output reg [3:0] O_mult_funcD,
        input [31:0] I_reg_dest,
        output reg [31:0] O_reg_destD,
        input [5:0] I_rd_index,
        output reg [5:0] O_rd_indexD,

        input [5:0] I_rs_index,
        input [5:0] I_rt_index,
        input [1:0] I_pc_source,
        input [3:0] I_mem_source,
        input [1:0] I_a_source,
        input [1:0] I_b_source,
        input [2:0] I_c_source,
        input [31:0] I_c_bus,
        input I_pause_any,
        output reg O_pause_pipeline 
);

`include "c5_parameters.v"

reg [5:0] rd_index_reg;
reg [31:0] reg_dest_reg;
reg [31:0] reg_dest_delay;
reg [2:0] c_source_reg;
reg pause_enable_reg;
reg  pause_mult_clock;
reg freeze_pipeline;

always @(*) begin
	if ((I_pc_source != FROM_INC4 && 
			I_pc_source != FROM_OPCODE25_0) || 
        	 I_mem_source != MEM_FETCH || 
        	 (I_mult_func == MULT_READ_LO || 
		 	I_mult_func == MULT_READ_HI))
	begin
      		pause_mult_clock = 1;
	end else begin
      		pause_mult_clock = 0;
   	end

   	freeze_pipeline = !(pause_mult_clock && pause_enable_reg) 
		&& I_pause_any;

   	O_pause_pipeline = (pause_mult_clock && pause_enable_reg);
   	O_rd_indexD = rd_index_reg;

// The value written back into the register bank, signal I_reg_dest is tricky.
//If I_reg_dest comes from the ALU via the signal I_c_bus, it is already delayed
// into stage #3, because O_a_busD and O_b_busD are delayed.  If I_reg_dest comes from
// c_memory, pc_current, or pc_plus4 then I_reg_dest hasn't yet been delayed into
// stage #3.
// Instead of delaying c_memory, pc_current, and pc_plus4, these signals
// are multiplexed into I_reg_dest which is then delayed.  The decision to use
// the already delayed I_c_bus or the delayed value of I_reg_dest (reg_dest_reg) is
// based on a delayed value of I_c_source (c_source_reg).

	if (c_source_reg == C_FROM_ALU) begin
	 	//delayed by 1 clock cycle via O_a_busD & O_b_busD
      		reg_dest_delay = I_c_bus; 
	end else begin
		//need to delay 1 clock cycle from I_reg_dest
      		reg_dest_delay = reg_dest_reg; 
	end
   	O_reg_destD = reg_dest_delay;


end

always @(posedge I_clk or negedge I_rst_n) begin
	if (!I_rst_n) begin
      		O_a_busD <= ZERO;
      		O_b_busD <= ZERO;
      		O_alu_funcD <= ALU_NOTHING;
      		O_shift_funcD <= SHIFT_NOTHING;
      		O_mult_funcD <= MULT_NOTHING;
      		reg_dest_reg <= ZERO;
      		c_source_reg <= 3'b000;
      		rd_index_reg <= 6'b000000;
      		pause_enable_reg <= 0;
	end else begin
		if (freeze_pipeline == 0) begin
         		if ((I_rs_index == 6'b000000 || 
				I_rs_index != rd_index_reg) || 
            			(I_a_source != A_FROM_REG_SOURCE  ||
			       		pause_enable_reg == 0))
			begin
            			O_a_busD <= I_a_bus;
			end else begin
			//rs from previous operation (bypass stage)
            			O_a_busD <= reg_dest_delay;  
         		end

         		if ((I_rt_index == 6'b000000 ||
			       	I_rt_index != rd_index_reg)  ||
               			(I_b_source != B_FROM_REG_TARGET 
					|| pause_enable_reg == 0))
			begin
            			O_b_busD <= I_b_bus;
			end else begin
			       	//rt from previous operation
            			O_b_busD <= reg_dest_delay; 
         		end

         		O_alu_funcD <= I_alu_func;
         		O_shift_funcD <= I_shift_func;
         		O_mult_funcD <= I_mult_func;
         		reg_dest_reg <= I_reg_dest;
         		c_source_reg <= I_c_source;
         		rd_index_reg <= I_rd_index;
      		end

		if (pause_enable_reg == 0 && I_pause_any == 0) begin
         		pause_enable_reg <= 1;   //enable O_pause_pipeline
		end else if  (pause_mult_clock == 1) begin
         		pause_enable_reg <= 0;   //disable O_pause_pipeline
      		end
   	end

end

endmodule

