//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
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
// Implements a register bank with 32 registers that are 32-bits wide.
// There are two read-ports and one write port.
//
// References:
// http://plasmacpu.no-ip.org
// https://opencores.org/projects/plasma
// https://booksite.elsevier.com/9780124077263/
//
// Executes all MIPS I(tm) opcodes but exceptions and non-aligned
// memory accesses.  Based on information found in:
//    "MIPS RISC Architecture" by Gerry Kane and Joe Heinrich
//    and "The Designer's Guide to VHDL" by Peter J. Ashenden
//
// The CPU is implemented as a two or three stage pipeline.
// An add instruction would take the following steps (see cpu.gif):
// Stage #0:
//    1.  The "pc_next" entity passes the program counter (PC) to the 
//        "mem_ctrl" entity which fetches the opcode from memory.
// Stage #1:
//    2.  The memory returns the opcode.
// Stage #2:
//    3.  "Mem_ctrl" passes the opcode to the "control" entity.
//    4.  "Control" converts the 32-bit opcode to a 60-bit VLWI opcode
//        and sends control signals to the other entities.
//    5.  Based on the rs_index and rt_index control signals, "reg_bank" 
//        sends the 32-bit reg_source and reg_target to "bus_mux".
//    6.  Based on the a_source and b_source control signals, "bus_mux"
//        multiplexes reg_source onto a_bus and reg_target onto b_bus.
// Stage #3 (part of stage #2 if using two stage pipeline):
//    7.  Based on the alu_func control signals, "alu" adds the values
//        from a_bus and b_bus and places the result on c_bus.
//    8.  Based on the c_source control signals, "bus_bux" multiplexes
//        c_bus onto reg_dest.
//    9.  Based on the rd_index control signal, "reg_bank" saves
//        reg_dest into the correct register.
// Stage #3b:
//   10.  Read or write memory if needed.
//
// All signals are active high. 
// Here are the signals for writing a character to O_address 0xffff
// when using a two stage pipeline:
//
// Program:
// addr     value  opcode 
// =============================
//   3c: 00000000  nop
//   40: 34040041  li $a0,0x41
//   44: 3405ffff  li $a1,0xffff
//   48: a0a40000  sb $a0,0($a1)
//   4c: 00000000  nop
//   50: 00000000  nop
//
//      I_intr_in                             I_mem_pause 
//  I_rst_n                               O_byte_we     Stages
//     ns         O_address     O_data_w     I_data_r        40 44 48 4c 50
//   3600  0  0  00000040   00000000   34040041  0  0   1  
//   3700  0  0  00000044   00000000   3405FFFF  0  0   2  1  
//   3800  0  0  00000048   00000000   A0A40000  0  0      2  1  
//   3900  0  0  0000004C   41414141   00000000  0  0         2  1
//   4000  0  0  0000FFFC   41414141   XXXXXX41  1  0         3  2  
//   4100  0  0  00000050   00000000   00000000  0  0               1
//////////////////////////////////////////////////////////////////////

module c5_cpu #(parameter 
	WIDTH = 32 
	) (
	input I_clk,
	input I_rst_n,

	input I_intr_in,

        output [31:2] O_address_next,
        output [3:0] O_byte_we_next,

        output [31:2] O_address,
        output [3:0] O_byte_we,
        output [31:0] O_data_w,
        output [7:0] O_debug,
        input [31:0] I_data_r,
        input I_mem_pause
);

`include "c5_parameters.v"

localparam memory_type = "XILINX_16X"; //ALTERA_LPM, or DUAL_PORT_
localparam mult_type = "DEFAULT"; //AREA_OPTIMIZED
localparam shifter_type = "DEFAULT"; //AREA_OPTIMIZED
localparam alu_type  = "DEFAULT"; //AREA_OPTIMIZED
localparam pipeline_stages = 2; //2 or 3


//When using a two stage pipeline "sigD <= sig".
//When using a three stage pipeline "sigD <= sig when rising_edge(I_clk)",
//  so sigD is delayed by one clock cycle.
wire [31:0] opcode;
wire [5:0] rs_index;
wire [5:0] rt_index;
wire [5:0] rd_index;
reg [5:0] rd_indexD;
wire [31:0] reg_source;
wire [31:0] reg_target;
wire [31:0] reg_dest;
reg [31:0] reg_destD;
wire[31:0] a_bus;
reg [31:0] a_busD;
wire [31:0] b_bus;
reg [31:0] b_busD;
reg [31:0] c_bus;
wire [31:0] c_alu;
wire [31:0] c_shift;
wire [31:0] c_mult;
wire [31:0] c_memory;
wire [15:0] imm;
wire [31:2] pc_future;
wire [31:2] pc_current;
wire [31:2] pc_plus4;
wire [3:0]  alu_func;
reg [3:0] alu_funcD;
wire [1:0] shift_func;
reg [1:0] shift_funcD;
wire [3:0] mult_func;
reg [3:0] mult_funcD;
wire [2:0] branch_func;
wire take_branch;
wire [1:0] a_source;
wire [1:0] b_source;
wire [2:0] c_source;
wire [1:0] pc_source;
wire [3:0] mem_source;
wire pause_mult;
wire pause_ctrl;
reg pause_pipeline;
reg pause_any;
reg pause_non_ctrl;
reg pause_bank;
reg nullify_op;
wire intr_enable;
reg intr_signal;
wire exception_sig;
reg [3:0] reset_reg;
reg reset_n;
reg [7:0] debug;

assign O_debug = debug;

c5_pc_next u1_pc_next (
        .I_clk(I_clk),
        .I_rst_n(reset_n),
        .I_take_branch(take_branch),
        .I_pause_in(pause_any),
        .I_pc_new(c_bus[31:2]),
        .I_opcode25_0(opcode[25:0]),
        .I_pc_source(pc_source),
        .O_pc_future(pc_future),
        .O_pc_current(pc_current),
        .O_pc_plus4(pc_plus4));

c5_mem_ctrl u2_mem_ctrl (
        .I_clk         (I_clk),
        .I_rst_n       (reset_n),
        .I_pause_in    (pause_non_ctrl),
        .I_nullify_op  (nullify_op),
        .I_address_pc  (pc_future),
        .O_opcode_out  (opcode),

        .I_address_in  (c_bus),
        .I_mem_source  (mem_source),
        .I_data_write  (reg_target),
        .O_data_read   (c_memory),
        .O_pause_out   (pause_ctrl),

        .O_address_next(O_address_next),
        .O_byte_we_next(O_byte_we_next),

        .O_address     (O_address),
        .O_byte_we     (O_byte_we),
        .O_data_w      (O_data_w),
        .I_data_r      (I_data_r));

   c5_control u3_control (
        .I_opcode      (opcode),
        .I_intr_signal (intr_signal),
        .O_rs_index    (rs_index),
        .O_rt_index    (rt_index),
        .O_rd_index    (rd_index),
        .O_imm_out     (imm),
        .O_alu_func    (alu_func),
        .O_shift_func  (shift_func),
        .O_mult_func   (mult_func),
        .O_branch_func (branch_func),
        .O_a_source_out(a_source),
        .O_b_source_out(b_source),
        .O_c_source_out(c_source),
        .O_pc_source_out(pc_source),
        .O_mem_source_out(mem_source),
        .O_exception_out(exception_sig));

   c5_reg_bank u4_reg_bank(
        .I_clk           (I_clk),
        .I_rst_n         (reset_n),
        .I_pause         (pause_bank),
        .I_rs_index      (rs_index),
        .I_rt_index      (rt_index),
        .I_rd_index      (rd_indexD),
        .O_reg_source_out(reg_source),
        .O_reg_target_out(reg_target),
        .I_reg_dest_new  (reg_destD),
        .O_intr_enable   (intr_enable));

   c5_bus_mux u5_bus_mux (
        .I_imm_in      (imm),
        .I_reg_source  (reg_source),
        .I_a_mux       (a_source),
        .O_a_out       (a_bus),

        .I_reg_target  (reg_target),
        .I_b_mux       (b_source),
        .O_b_out       (b_bus),

        .I_c_bus       (c_bus),
        .I_c_memory    (c_memory),
        .I_c_pc        (pc_current),
        .I_c_pc_plus4  (pc_plus4),
        .I_c_mux       (c_source),
        .O_reg_dest_out(reg_dest),

        .I_branch_func (branch_func),
        .O_take_branch (take_branch));

   c5_alu u6_alu  (
        .I_a_in        (a_busD),
        .I_b_in        (b_busD),
        .I_alu_function(alu_funcD),
        .O_c_alu       (c_alu));

   c5_shifter u7_shifter(
        .I_value       (b_busD),
        .I_shift_amount(a_busD[4:0]),
        .I_shift_func  (shift_funcD),
        .O_c_shift     (c_shift)) /* synthesis syn_preserve = 1 */;

   c5_mult u8_mult(
        .I_clk      (I_clk),
        .I_rst_n (reset_n),
        .I_a        (a_busD),
        .I_b        (b_busD),
        .I_mult_func(mult_funcD),
        .O_c_mult   (c_mult),
        .O_pause_out(pause_mult));

`ifndef TWO_STAGE_PIPELINE
	always @(*) begin
a_busD <= a_bus;
b_busD <= b_bus;
alu_funcD <= alu_func;
shift_funcD <= shift_func;
mult_funcD <= mult_func;
rd_indexD <= rd_index;
reg_destD <= reg_dest;
pause_pipeline <= 0;
	end
`else
      //When operating in three stage pipeline mode, the following signals
      //are delayed by one clock cycle:  a_bus, b_bus, alu/shift/mult_func,
      //c_source, and rd_index.
   c5_pipeline u9_pipeline (
        .I_clk           (I_clk),
        .I_rst_n         (reset_n),
        .I_a_bus         (a_bus),
        .O_a_busD        (a_busD),
        .I_b_bus         (b_bus),
        .O_b_busD        (b_busD),
        .I_alu_func      (alu_func),
        .O_alu_funcD     (alu_funcD),
        .I_shift_func    (shift_func),
        .O_shift_funcD   (shift_funcD),
        .I_mult_func     (mult_func),
        .O_mult_funcD    (mult_funcD),
        .I_reg_dest      (reg_dest),
        .O_reg_destD     (reg_destD),
        .I_rd_index      (rd_index),
        .O_rd_indexD     (rd_indexD),

        .I_rs_index      (rs_index),
        .I_rt_index      (rt_index),
        .I_pc_source     (pc_source),
        .I_mem_source    (mem_source),
        .I_a_source      (a_source),
        .I_b_source      (b_source),
        .I_c_source      (c_source),
        .I_c_bus         (c_bus),
        .I_pause_any     (pause_any),
        .O_pause_pipeline(pause_pipeline));
`endif



always @(*) begin
		pause_any <= (I_mem_pause || pause_ctrl) || 
			(pause_mult || pause_pipeline);
		pause_non_ctrl <= (I_mem_pause || pause_mult) || 
			pause_pipeline;
		pause_bank <= (I_mem_pause || pause_ctrl || pause_mult) && 
			!pause_pipeline;
		nullify_op <= ((pc_source == FROM_LBRANCH && 
			take_branch == 0) ||
			intr_signal == 1 || exception_sig == 1) ? 
			1'b1 : 1'b0;
		reset_n <= (reset_reg != 4'b1111) ? 1'b0 : 1'b1;
		c_bus[31:0] <= c_alu | c_shift | c_mult;
end

always @(posedge I_clk or negedge I_rst_n) begin
	if (!I_rst_n) begin
         	reset_reg <= 4'b0000;
         	intr_signal <= 0;
         	debug <= 13;
	end else begin
		if (reset_reg != 4'b1111) begin
            		reset_reg <= reset_reg + 1'b1;
         	end
			debug <= 65;
         	//don't try to interrupt a multi-cycle instruction
		if (pause_any == 0) begin
            		if (I_intr_in == 1'b1 && intr_enable == 1'b1  &&
                  		pc_source == FROM_INC4)
			begin 
               			//the epc will contain pc+4
               			intr_signal <= 1;
			end else begin
               			intr_signal <= 0;
            		end
		end else begin
		       	if (pause_ctrl) debug <= 71; 
			if (pause_mult) debug <= 72;
		       	if (pause_pipeline) debug <= 73;
			if (I_mem_pause) debug <= 70;
		end
	end
end

endmodule

