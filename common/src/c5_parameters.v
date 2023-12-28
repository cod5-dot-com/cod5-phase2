//
// Translated from Steve Rhoads's Plasma VHDL to Verilog source code.
//
//

localparam [31:0] FRAMEBUFFER0 = 32'h00030000;
localparam [31:0] FRAMEBUFFER1 = 32'h00060000;

localparam [5:0]  BSRAM_DEPTH = 7;
localparam [31:0] BSRAM_SIZE = (1 << BSRAM_DEPTH);

localparam [31:0] ZERO = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
localparam [31:0] ONES = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
localparam [31:0] HIGH_Z = 32'bzzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz;
  
localparam [3:0] ALU_NOTHING    = 4'b0000;
localparam [3:0] ALU_ADD        = 4'b0001;
localparam [3:0] ALU_SUBTRACT   = 4'b0010;
localparam [3:0] ALU_LESS_THAN  = 4'b0011;
localparam [3:0] ALU_LESS_THAN_SIGNED  = 4'b0100;
localparam [3:0] ALU_OR         = 4'b0101;
localparam [3:0] ALU_AND        = 4'b0110;
localparam [3:0] ALU_XOR        = 4'b0111;
localparam [3:0] ALU_NOR        = 4'b1000;

localparam [1:0] SHIFT_NOTHING         = 2'b00;
localparam [1:0] SHIFT_LEFT_UNSIGNED   = 2'b01;
localparam [1:0] SHIFT_RIGHT_SIGNED    = 2'b11;
localparam [1:0] SHIFT_RIGHT_UNSIGNED  = 2'b10;

localparam [3:0] MULT_NOTHING        = 4'b0000;
localparam [3:0] MULT_READ_LO        = 4'b0001;
localparam [3:0] MULT_READ_HI        = 4'b0010;
localparam [3:0] MULT_WRITE_LO       = 4'b0011;
localparam [3:0] MULT_WRITE_HI       = 4'b0100;
localparam [3:0] MULT_MULT           = 4'b0101;
localparam [3:0] MULT_SIGNED_MULT    = 4'b0110;
localparam [3:0] MULT_DIVIDE         = 4'b0111;
localparam [3:0] MULT_SIGNED_DIVIDE  = 4'b1000;

localparam [1:0] A_FROM_REG_SOURCE  = 2'b00;
localparam [1:0] A_FROM_IMM10_6     = 2'b01;
localparam [1:0] A_FROM_PC          = 2'b10;

localparam [1:0] B_FROM_REG_TARGET  = 2'b00;
localparam [1:0] B_FROM_IMM         = 2'b01;
localparam [1:0] B_FROM_SIGNED_IMM  = 2'b10;
localparam [1:0] B_FROM_IMMX4       = 2'b11;

localparam [2:0] C_FROM_NULL        = 3'b000;
localparam [2:0] C_FROM_ALU         = 3'b001;
localparam [2:0] C_FROM_SHIFT       = 3'b001; //same as alu
localparam [2:0] C_FROM_MULT        = 3'b001; //same as alu
localparam [2:0] C_FROM_MEMORY      = 3'b010;
localparam [2:0] C_FROM_PC          = 3'b011;
localparam [2:0] C_FROM_PC_PLUS4    = 3'b100;
localparam [2:0] C_FROM_IMM_SHIFT16 = 3'b101;
localparam [2:0] C_FROM_REG_SOURCEN = 3'b110;

localparam [1:0] FROM_INC4        = 2'b00;
localparam [1:0] FROM_OPCODE25_0  = 2'b01;
localparam [1:0] FROM_BRANCH      = 2'b10;
localparam [1:0] FROM_LBRANCH     = 2'b11;

localparam [2:0] BRANCH_LTZ  = 3'b000;
localparam [2:0] BRANCH_LEZ  = 3'b001;
localparam [2:0] BRANCH_EQ   = 3'b010;
localparam [2:0] BRANCH_NE   = 3'b011;
localparam [2:0] BRANCH_GEZ  = 3'b100;
localparam [2:0] BRANCH_GTZ  = 3'b101;
localparam [2:0] BRANCH_YES  = 3'b110;
localparam [2:0] BRANCH_NO   = 3'b111;

   // mode(32=1,16=2,8=3), signed, write
localparam [3:0] MEM_FETCH    = 4'b0000;
localparam [3:0] MEM_READ32   = 4'b0100;
localparam [3:0] MEM_WRITE32  = 4'b0101;
localparam [3:0] MEM_READ16   = 4'b1000;
localparam [3:0] MEM_READ16S  = 4'b1010;
localparam [3:0] MEM_WRITE16  = 4'b1001;
localparam [3:0] MEM_READ8    = 4'b1100;
localparam [3:0] MEM_READ8S   = 4'b1110;
localparam [3:0] MEM_WRITE8   = 4'b1101;


