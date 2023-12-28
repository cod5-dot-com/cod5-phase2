// 00000000 <__start>:
	'h0000: O_data_read <= 32'h00002826; //	xor	a1,zero,zero
	'h0004: O_data_read <= 32'h3c05c000; //	lui	a1,0xc000
	'h0008: O_data_read <= 32'h24070044; //	li	a3,68
// 0000000c <l1>:
	'h000c: O_data_read <= 32'h24060043; //	li	a2,67
	'h0010: O_data_read <= 32'haca60000; //	sw	a2,0(a1)
	'h0014: O_data_read <= 32'h00000000; // nop
	'h0018: O_data_read <= 32'h00000000; // nop
	'h001c: O_data_read <= 32'h1000fffb; //	b	c <l1>
	'h0020: O_data_read <= 32'h00000000; //	nop
	'h0024: O_data_read <= 32'h00000000; // nop
	'h0028: O_data_read <= 32'h00000000; // nop
	'h002c: O_data_read <= 32'h08000000; //	j	0 <__start>
	'h0030: O_data_read <= 32'h00000000; //	nop
