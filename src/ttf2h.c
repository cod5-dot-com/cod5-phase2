/*
 *                          cod5.com computer
 *
 *                      17 may MMXXI PUBLIC DOMAIN
 *           The author disclaims copyright to this source code.
 *
 *
 */

#include <stdio.h>

int writeOut(FILE *out, unsigned char b)
{
	unsigned char c;
	int i;
	char hex[] = "0123456789ABCDEF";
	c = 0;
	for (i = 0; i < 8; i++) {
		c = (c << 1) | (b & 1);
		b = b >> 1;
	}
	fwrite("0x", 1, 2, out); 
	fwrite(hex + ((c >> 4) & 0xF), 1, 1, out); 
	fwrite(hex + (c & 0xF), 1, 1, out); 
	return 0;
}

int main (int argc, char *argv[])
{
	FILE *in;
	FILE *out;
	unsigned char b;
	unsigned char c;
	int n;

	in = fopen(argv[1], "rb");
	out = fopen(argv[2], "w+b");
	b = 0;
	n = 0;
	while (fread(&c, 1, 1, in) == 1) {
		if (c >= '0' && c <= '9') {
			b = b * 10;
			b += c - '0';
		}
		if (c == ',') {
			writeOut(out, b);
			fwrite(", ", 1, 2, out); 
			b = 0;
			n++;
			if ((n & 0x7) == 0) {
				fwrite("\n", 1, 1, out); 
			}
		}
	}	
	writeOut(out, b);
	fwrite("\n", 1, 1, out); 
	fclose(in);
	fclose(out);
	return 0;
}


