//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
//
// 
//           20 October MMXXIII PUBLIC DOMAIN by O'ksi'D
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

//   Controls the CPU by decoding the opcode and generating control
//    signals to the rest of the CPU.
//    This entity decodes the MIPS(tm) opcode into a
//    Very-Long-Word-Instruction.
//    The 32-bit I_opcode is converted to a
//       6+6+6+16+4+2+4+3+2+2+3+2+4 <= 60 bit VLWI opcode.
//    Based on information found in:
//       "MIPS RISC Architecture: by Gerry Kane and Joe Heinrich
//       and "The Designer's Guide to VHDL: by Peter J. Ashenden
////////////////////////////////////////////////////////////////////-
module c5_control#(parameter 
	WIDTH = 32 
	) (
   	input [31:0] I_opcode,
        input I_intr_signal,
        output reg [5:0] O_rs_index,
        output reg [5:0] O_rt_index,
        output reg [5:0] O_rd_index,
        output reg [15:0] O_imm_out,
        output reg [3:0] O_alu_func,
        output reg [1:0] O_shift_func,
        output reg [3:0] O_mult_func,
        output reg [2:0] O_branch_func,
        output reg [1:0] O_a_source_out,
        output reg [1:0] O_b_source_out,
        output reg [2:0] O_c_source_out,
        output reg [1:0] O_pc_source_out,
        output reg [3:0] O_mem_source_out,
	output reg O_exception_out
);

`include "c5_parameters.v"

reg [5:0] op;
reg [5:0] func;
reg [5:0] rs; 
reg [5:0] rt; 
reg [5:0] rd; 
reg [4:0] rtx;
reg [15:0] imm;
reg [3:0] alu_function;
reg [1:0] shift_function;
reg [3:0] mult_function;
reg [1:0] a_source;
reg [1:0] b_source;
reg [2:0] c_source;
reg [1:0] pc_source;
reg [2:0] branch_function;
reg [3:0] mem_source;
reg is_syscall;

always @(*) begin
   	alu_function = ALU_NOTHING;
   	shift_function = SHIFT_NOTHING;
   	mult_function = MULT_NOTHING;
   	a_source = A_FROM_REG_SOURCE;
   	b_source = B_FROM_REG_TARGET;
   	c_source = C_FROM_NULL;
   	pc_source = FROM_INC4;
   	branch_function = BRANCH_EQ;
   	mem_source = MEM_FETCH;
   	op = I_opcode[31:26];
   	rs = {1'b0, I_opcode[25:21]};
   	rt = {1'b0, I_opcode[20:16]};
   	rtx = I_opcode[20:16];
   	rd = {1'b0, I_opcode[15:11]};
   	func = I_opcode[5:0];
   	imm = I_opcode[15:0];
   	is_syscall = 0;

	case (op)
      	6'b000000: begin   //SPECIAL
      		case (func)
		6'b000000: begin    //SLL   r[rd]=r[rt]<<re;
         		a_source = A_FROM_IMM10_6;
         		c_source = C_FROM_SHIFT;
         		shift_function = SHIFT_LEFT_UNSIGNED;
		end
      		6'b000010: begin   //SRL   r[rd]=u[rt]>>re;
         		a_source = A_FROM_IMM10_6;
         		c_source = C_FROM_SHIFT;
         		shift_function = SHIFT_RIGHT_UNSIGNED;
		end
      		6'b000011: begin   //SRA   r[rd]=r[rt]>>re;
         		a_source = A_FROM_IMM10_6;
         		c_source = C_FROM_SHIFT;
         		shift_function = SHIFT_RIGHT_SIGNED;
		end
      		6'b000100: begin   //SLLV  r[rd]=r[rt]<<r[rs];
         		c_source = C_FROM_SHIFT;
         		shift_function = SHIFT_LEFT_UNSIGNED;
		end
      		6'b000110: begin   //SRLV  r[rd]=u[rt]>>r[rs];
         		c_source = C_FROM_SHIFT;
         		shift_function = SHIFT_RIGHT_UNSIGNED;
		end
      		6'b000111: begin   //SRAV  r[rd]=r[rt]>>r[rs];
         		c_source = C_FROM_SHIFT;
         		shift_function = SHIFT_RIGHT_SIGNED;
		end
      		6'b001000: begin   //JR    s->pc_next=r[rs];
         		pc_source = FROM_BRANCH;
         		alu_function = ALU_ADD;
         		branch_function = BRANCH_YES;
		end
      		6'b001001: begin   //JALR  r[rd]=s->pc_next; s->pc_next=r[rs];
         		c_source = C_FROM_PC_PLUS4;
         		pc_source = FROM_BRANCH;
         		alu_function = ALU_ADD;
         		branch_function = BRANCH_YES;
		end
      //6'b001010: begin   //MOVZ  if(!r[rt]) r[rd]=r[rs]; /*IV*/
      //6'b001011: begin   //MOVN  if(r[rt]) r[rd]=r[rs];  /*IV*/

      		6'b001100: begin   //SYSCALL
         		is_syscall = 1;
		end
      		6'b001101: begin   //BREAK s->wakeup=1;
         		is_syscall = 1;
		end
      //6'b001111: begin   //SYNC  s->wakeup=1;

      		6'b010000: begin   //MFHI  r[rd]=s->hi;
         		c_source = C_FROM_MULT;
         		mult_function = MULT_READ_HI;
		end
      		6'b010001: begin   //MTHI  s->hi=r[rs];
         		mult_function = MULT_WRITE_HI;
		end
      		6'b010010: begin   //MFLO  r[rd]=s->lo;
         		c_source = C_FROM_MULT;
         		mult_function = MULT_READ_LO;
		end
      		6'b010011: begin   //MTLO  s->lo=r[rs];
         		mult_function = MULT_WRITE_LO;
		end
      		6'b011000: begin   //MULT  s->lo=r[rs]*r[rt]; s->hi=0;
         		mult_function = MULT_SIGNED_MULT;
		end
      		6'b011001: begin   //MULTU s->lo=r[rs]*r[rt]; s->hi=0;
         		mult_function = MULT_MULT;
		end
      		6'b011010: begin   //DIV   s->lo=r[rs]/r[rt]; s->hi=r[rs]%r[rt];
         		mult_function = MULT_SIGNED_DIVIDE;
		end
      		6'b011011: begin   //DIVU  s->lo=r[rs]/r[rt]; s->hi=r[rs]%r[rt];
         		mult_function = MULT_DIVIDE;
		end
      		6'b100000: begin   //ADD   r[rd]=r[rs]+r[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_ADD;
		end
      		6'b100001: begin   //ADDU  r[rd]=r[rs]+r[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_ADD;
		end
      		6'b100010: begin   //SUB   r[rd]=r[rs]-r[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_SUBTRACT;
		end
      		6'b100011: begin   //SUBU  r[rd]=r[rs]-r[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_SUBTRACT;
		end
      		6'b100100: begin   //AND   r[rd]=r[rs]&r[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_AND;
		end
      		6'b100101: begin   //OR    r[rd]=r[rs]|r[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_OR;
		end
      		6'b100110: begin   //XOR   r[rd]=r[rs]^r[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_XOR;
		end
      		6'b100111: begin   //NOR   r[rd]=~(r[rs]|r[rt]);
         		c_source = C_FROM_ALU;
         		alu_function = ALU_NOR;
		end
      		6'b101010: begin   //SLT   r[rd]=r[rs]<r[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_LESS_THAN_SIGNED;
		end
      		6'b101011: begin   //SLTU  r[rd]=u[rs]<u[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_LESS_THAN;
		end
      		6'b101101: begin   //DADDU r[rd]=r[rs]+u[rt];
         		c_source = C_FROM_ALU;
         		alu_function = ALU_ADD;
		end
      //6'b110001: begin   //TGEU
      //6'b110010: begin   //TLT
      //6'b110011: begin   //TLTU
      //6'b110100: begin   //TEQ 
      //6'b110110: begin   //TNE 
      		default begin
		end
		endcase
	end
   	6'b000001: begin   //REGIMM
      		rt = 6'b000000;
      		rd = 6'b011111;
      		a_source = A_FROM_PC;
      		b_source = B_FROM_IMMX4;
      		alu_function = ALU_ADD;
      		pc_source = FROM_BRANCH;
      		branch_function = BRANCH_GTZ;
      		//if(test) pc=pc+imm*4
      		case (rtx) 
      		6'b10000: begin   //BLTZAL  r[31]=s->pc_next; branch=r[rs]<0;
         		c_source = C_FROM_PC_PLUS4;
         		branch_function = BRANCH_LTZ;
		end
      		6'b00000: begin   //BLTZ    branch=r[rs]<0;
         		branch_function = BRANCH_LTZ;
		end
      		6'b10001: begin   //BGEZAL  r[31]=s->pc_next; branch=r[rs]>=0;
         		c_source = C_FROM_PC_PLUS4;
         		branch_function = BRANCH_GEZ;
		end
      		6'b00001: begin   //BGEZ    branch=r[rs]>=0;
         		branch_function = BRANCH_GEZ;
		end
      //6'b10010: begin   //BLTZALL r[31]=s->pc_next; lbranch=r[rs]<0;
      //6'b00010: begin   //BLTZL   lbranch=r[rs]<0;
      //6'b10011: begin   //BGEZALL r[31]=s->pc_next; lbranch=r[rs]>=0;
      //6'b00011: begin   //BGEZL   lbranch=r[rs]>=0;

     		default: begin
		end
      		endcase
	end
   	6'b000011: begin   //JAL    r[31]=s->pc_next; s->pc_next=(s->pc&0xf0000000)|target;
      		c_source = C_FROM_PC_PLUS4;
      		rd = 6'b011111;
      		pc_source = FROM_OPCODE25_0;
	end
   	6'b000010: begin   //J      s->pc_next=(s->pc&0xf0000000)|target; 
      		pc_source = FROM_OPCODE25_0;
	end
   	6'b000100: begin   //BEQ    branch=r[rs]==r[rt];
      		a_source = A_FROM_PC;
      		b_source = B_FROM_IMMX4;
      		alu_function = ALU_ADD;
      		pc_source = FROM_BRANCH;
      		branch_function = BRANCH_EQ;
	end
   	6'b000101: begin   //BNE    branch=r[rs]!=r[rt];
      		a_source = A_FROM_PC;
      		b_source = B_FROM_IMMX4;
      		alu_function = ALU_ADD;
      		pc_source = FROM_BRANCH;
      		branch_function = BRANCH_NE;
	end
   	6'b000110: begin   //BLEZ   branch=r[rs]=0;
      		a_source = A_FROM_PC;
      		b_source = B_FROM_IMMX4;
      		alu_function = ALU_ADD;
      		pc_source = FROM_BRANCH;
      		branch_function = BRANCH_LEZ;
	end
   	6'b000111: begin   //BGTZ   branch=r[rs]>0;
      		a_source = A_FROM_PC;
      		b_source = B_FROM_IMMX4;
      		alu_function = ALU_ADD;
      		pc_source = FROM_BRANCH;
      		branch_function = BRANCH_GTZ;
	end
   	6'b001000: begin   //ADDI   r[rt]=r[rs]+(short)imm;
      		b_source = B_FROM_SIGNED_IMM;
      		c_source = C_FROM_ALU;
      		rd = rt;
      		alu_function = ALU_ADD;
	end
   	6'b001001: begin   //ADDIU  u[rt]=u[rs]+(short)imm;
      		b_source = B_FROM_SIGNED_IMM;
      		c_source = C_FROM_ALU;
      		rd = rt;
      		alu_function = ALU_ADD;
	end
   	6'b001010: begin   //SLTI   r[rt]=r[rs]<(short)imm;
      		b_source = B_FROM_SIGNED_IMM;
      		c_source = C_FROM_ALU;
      		rd = rt;
      		alu_function = ALU_LESS_THAN_SIGNED;
	end
   	6'b001011: begin   //SLTIU  u[rt]=u[rs]<(unsigned long)(short)imm;
      		b_source = B_FROM_SIGNED_IMM;
      		c_source = C_FROM_ALU;
      		rd = rt;
      		alu_function = ALU_LESS_THAN;
	end
   	6'b001100: begin   //ANDI   r[rt]=r[rs]&imm;
      		b_source = B_FROM_IMM;
      		c_source = C_FROM_ALU;
      		rd = rt;
      		alu_function = ALU_AND;
	end
   	6'b001101: begin   //ORI    r[rt]=r[rs]|imm;
      		b_source = B_FROM_IMM;
      		c_source = C_FROM_ALU;
      		rd = rt;
      		alu_function = ALU_OR;
	end
   	6'b001110: begin   //XORI   r[rt]=r[rs]^imm;
      		b_source = B_FROM_IMM;
      		c_source = C_FROM_ALU;
      		rd = rt;
      		alu_function = ALU_XOR;
	end
   	6'b001111: begin   //LUI    r[rt]=(imm<<16);
      		c_source = C_FROM_IMM_SHIFT16;
      		rd = rt;
	end
   	6'b010000: begin   //COP0
      		alu_function = ALU_OR;
      		c_source = C_FROM_ALU;
		if (I_opcode[23] == 0) begin  //move from CP0
         		rs = {1'b1, I_opcode[15:11]};
         		rt = 6'b000000;
         		rd = {1'b0, I_opcode[20:16]};
		end else begin                //move to CP0
         		rs = 6'b000000;
         		rd[5] = 1'b1;
         		pc_source = FROM_BRANCH; //delay possible interrupt
         		branch_function = BRANCH_NO;
      		end
	end
   //6'b010001: begin   //COP1
   //6'b010010: begin   //COP2
   //6'b010011: begin   //COP3
   //6'b010100: begin   //BEQL   lbranch=r[rs]==r[rt];
   //6'b010101: begin   //BNEL   lbranch=r[rs]!=r[rt];
   //6'b010110: begin   //BLEZL  lbranch=r[rs]=0;
   //6'b010111: begin   //BGTZL  lbranch=r[rs]>0;

   	6'b100000: begin   //LB     r[rt]=*(signed char*)ptr;
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		rd = rt;
      		c_source = C_FROM_MEMORY;
      		mem_source = MEM_READ8S;    //address=(short)imm+r[rs];
	end
   	6'b100001: begin   //LH     r[rt]=*(signed short*)ptr;
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		rd = rt;
      		c_source = C_FROM_MEMORY;
      		mem_source = MEM_READ16S;   //address=(short)imm+r[rs];
	end
   	6'b100010: begin   //LWL    //Not Implemented
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		rd = rt;
      		c_source = C_FROM_MEMORY;
      		mem_source = MEM_READ32;
	end
   	6'b100011: begin   //LW     r[rt]=*(long*)ptr;
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		rd = rt;
      		c_source = C_FROM_MEMORY;
      		mem_source = MEM_READ32;
	end
   	6'b100100: begin   //LBU    r[rt]=*(unsigned char*)ptr;
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		rd = rt;
      		c_source = C_FROM_MEMORY;
      		mem_source = MEM_READ8;    //address=(short)imm+r[rs];
	end
   	6'b100101: begin   //LHU    r[rt]=*(unsigned short*)ptr;
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		rd = rt;
      		c_source = C_FROM_MEMORY;
      		mem_source = MEM_READ16;    //address=(short)imm+r[rs];
	end
   //6'b100110: begin   //LWR    //Not Implemented

   	6'b101000: begin   //SB     *(char*)ptr=(char)r[rt];
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		mem_source = MEM_WRITE8;   //address=(short)imm+r[rs];
	end
   	6'b101001: begin   //SH     *(short*)ptr=(short)r[rt];
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		mem_source = MEM_WRITE16;
	end
   	6'b101010: begin   //SWL    //Not Implemented
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		mem_source = MEM_WRITE32;  //address=(short)imm+r[rs];
	end
   	6'b101011: begin   //SW     *(long*)ptr=r[rt];
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_SIGNED_IMM;
      		alu_function = ALU_ADD;
      		mem_source = MEM_WRITE32;  //address=(short)imm+r[rs];
	end
   //6'b101110: begin   //SWR    //Not Implemented
   //6'b101111: begin   //CACHE
   //6'b110000: begin   //LL     r[rt]=*(long*)ptr;
   //6'b110001: begin   //LWC1 
   //6'b110010: begin   //LWC2 
   //6'b110011: begin   //LWC3 
   //6'b110101: begin   //LDC1 
   //6'b110110: begin   //LDC2 
   //6'b110111: begin   //LDC3 
   //6'b111000: begin   //SC     *(long*)ptr=r[rt]; r[rt]=1;
   //6'b111001: begin   //SWC1 
   //6'b111010: begin   //SWC2 
   //6'b111011: begin   //SWC3 
   //6'b111101: begin   //SDC1 
   //6'b111110: begin   //SDC2 
   //6'b111111: begin   //SDC3 
   	default: begin
	end
   	endcase

	if (c_source == C_FROM_NULL) begin
      		rd = 6'b000000;
   	end

   	if (I_intr_signal == 1 || is_syscall == 1) begin 
      		rs = 6'b111111;  //interrupt vector
      		rt = 6'b000000;
      		rd = 6'b101110;  //save PC in EPC
      		alu_function = ALU_OR;
      		shift_function = SHIFT_NOTHING;
      		mult_function = MULT_NOTHING;
      		branch_function = BRANCH_YES;
      		a_source = A_FROM_REG_SOURCE;
      		b_source = B_FROM_REG_TARGET;
      		c_source = C_FROM_PC;
      		pc_source = FROM_LBRANCH;
      		mem_source = MEM_FETCH;
   	end

end

always @(*) begin

   	if (I_intr_signal == 1 || is_syscall == 1) begin 
      		O_exception_out <= 1'b1;
   	end else begin
      		O_exception_out <= 1'b0;
	end
   	O_rs_index <= rs;
   	O_rt_index <= rt;
   	O_rd_index <= rd;
   	O_imm_out <= imm;
   	O_alu_func <= alu_function;
   	O_shift_func <= shift_function;
   	O_mult_func <= mult_function;
   	O_branch_func <= branch_function;
   	O_a_source_out <= a_source;
   	O_b_source_out <= b_source;
   	O_c_source_out <= c_source;
   	O_pc_source_out <= pc_source;
   	O_mem_source_out <= mem_source;
end

endmodule

