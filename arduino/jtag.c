/*
 *                          cod5.com computer
 *
 *                      17 may MMXXI PUBLIC DOMAIN
 *           The author disclaims copyright to this source code.
 *
 *
 */

// That code served as documentation for the JTAG protocol:
// https://www.intel.com/content/dam/altera-www/global/en_US/others/literature/an/wpjrunner.zip
//

#include "jtag.h"

#define JTAG_VENDOR_ID   		0x6E
#define JTAG_ID_VJTAG    		0x84
#define JTAG_CHECK_STATUS		0x004
#define JTAG_USER0_VDR			0x00C
#define JTAG_USER1_VIR			0x00E

#define jtagInitOut(pin) PORT->Group[0].DIRSET.reg = (1<<pin)
#define jtagSetOut(pin) PORT->Group[0].OUTSET.reg = (1<<pin)
#define jtagClearOut(pin) PORT->Group[0].OUTCLR.reg = (1<<pin)
#define jtagInitIn(pin) \
	PORT->Group[0].PINCFG[pin].reg=(uint8_t)(PORT_PINCFG_INEN); \
	PORT->Group[0].DIRCLR.reg = (1<<pin)
#define jtagReadIn(pin) ((PORT->Group[0].IN.reg & (1<<pin)) != 0)

enum {
	RESET,
	RUNIDLE,
	SELECT_IR,
	CAPTURE_IR,
	SHIFT_IR,
	EXIT1_IR,
	PAUSE_IR,
	EXIT2_IR,
	UPDATE_IR,
	SELECT_DR,
	CAPTURE_DR,
	SHIFT_DR,
	EXIT1_DR,
	PAUSE_DR,
	EXIT2_DR,
	UPDATE_DR,
	UNDEFINE
};

static int jtag_state = 0;
static unsigned char jtag_id = (unsigned char)-1;
static unsigned char jtag_n_slaves;
static unsigned char jtag_slave_bits;
static unsigned char jtag_vir_size;
static unsigned char jtag_last_vir;

static void jtagDriveSignal(int signal, int data, int clk)
{
  	if (data) {
		jtagSetOut(signal);
	} else {
		jtagClearOut(signal);
	}
	if (clk) {
		jtagSetOut(TCK);
		jtagClearOut(TCK);
  	}
}

static int jtagReadTDO(int bit_count, int data, int inst)
{
	unsigned int rec = 0;
	unsigned int i;

	for (i = 0; i < bit_count; i++) {
		rec = rec | (jtagReadIn(TDO) << i);
    		jtagDriveSignal(TDI, data & 1, !(i==(bit_count-1) && inst));
		data >>= 1;
  	}
	return rec;
}

static void jtagReadTDOBuf(int bit_count, char *txbuf, char *rxbuf, int inst)
{
	unsigned int tdi = 0;
  	unsigned int tdo = 0;
  	unsigned int rec = 0;
  	unsigned int i;
  	unsigned int charbit = 0;
  	unsigned char indata = 0;
  	unsigned char outdata;
    	unsigned int mask;
  	for (i = 0; i < bit_count; i++) {
    		mask = 1;
    		if (charbit == 0) {
      			if (txbuf) {
        			outdata = *txbuf;
        			txbuf++;
      			} else {
        			outdata = -1;
      			}
		}

    		indata = (indata >> 1) | (jtagReadIn(TDO)<<7);
		jtagDriveSignal(TDI, outdata & 1, !(i==(bit_count-1) && inst));
		outdata = outdata >> 1;
		charbit = (charbit + 1) & 7;
		if (charbit == 0 && rxbuf) {
      			*rxbuf = indata;
      			rxbuf++;
      			indata = 0;
    		}
	}
}

static int jtagAdvance0()
{
	jtagDriveSignal(TMS, 0, 1);

	switch (jtag_state) {
	case RESET:     jtag_state = RUNIDLE; break;
  	case RUNIDLE:	jtag_state = RUNIDLE; break;
  	case SELECT_IR:	jtag_state = CAPTURE_IR; break;
	case CAPTURE_IR:jtag_state = SHIFT_IR; break;
  	case SHIFT_IR:	jtag_state = SHIFT_IR; break;
        case EXIT1_IR:	jtag_state = PAUSE_IR; break;
	case PAUSE_IR:  jtag_state = PAUSE_IR; break;
	case EXIT2_IR:  jtag_state = SHIFT_IR; break;
	case UPDATE_IR: jtag_state = RUNIDLE; break;
	case SELECT_DR: jtag_state = CAPTURE_DR; break;
  	case CAPTURE_DR:jtag_state = SHIFT_DR; break;
 	case SHIFT_DR:  jtag_state = SHIFT_DR; break;
	case EXIT1_DR:  jtag_state = PAUSE_DR; break;
	case PAUSE_DR:  jtag_state = PAUSE_DR; break;
	case EXIT2_DR:  jtag_state = SHIFT_DR; break;
	case UPDATE_DR: jtag_state = RUNIDLE; break;
	}
	return jtag_state;
}

static int jtagAdvance1()
{
	jtagDriveSignal(TMS, 1, 1);

	switch (jtag_state) {
	case RESET:     jtag_state = RESET; break;
  	case RUNIDLE:	jtag_state = SELECT_DR; break;
  	case SELECT_IR:	jtag_state = RESET; break;
	case CAPTURE_IR:jtag_state = EXIT1_IR; break;
  	case SHIFT_IR:	jtag_state = EXIT1_IR; break;
        case EXIT1_IR:	jtag_state = UPDATE_IR; break;
	case PAUSE_IR:  jtag_state = EXIT2_IR; break;
	case EXIT2_IR:  jtag_state = UPDATE_IR; break;
	case UPDATE_IR: jtag_state = SELECT_DR; break;
	case SELECT_DR: jtag_state = SELECT_IR; break;
  	case CAPTURE_DR:jtag_state = EXIT1_DR; break;
 	case SHIFT_DR:  jtag_state = EXIT1_DR; break;
	case EXIT1_DR:  jtag_state = UPDATE_DR; break;
	case PAUSE_DR:  jtag_state = EXIT2_DR; break;
	case EXIT2_DR:  jtag_state = UPDATE_DR; break;
	case UPDATE_DR: jtag_state = SELECT_DR; break;
	}
	return jtag_state;
}

static int jtagUpdateDr()
{
	if (jtag_state != SHIFT_DR) return 1;
	jtagAdvance1();
	jtagAdvance1();
	return 0;
}

static int jtagShiftDr()
{
	if (jtag_state != UPDATE_DR && jtag_state != UPDATE_IR) {
    		if (jtag_state != RESET && jtag_state != RUNIDLE) {
      			return 1;
    		} else {
			jtagAdvance0();
			jtagAdvance0();
			jtagAdvance1();
			jtagAdvance0();
			jtagAdvance0();
			return 0;
		}
	}
	jtagAdvance1();
	jtagAdvance0();
	jtagAdvance0();
	return 0;
}

static void jtagRunidle()
{
	int i = 0;
	if (jtag_state != UPDATE_IR && jtag_state != UPDATE_DR) {
    		for (i = 0; i < 5; i++) {
      			jtagAdvance1();
      		}
	}
	jtagAdvance0();
}

static int jtagLoadJI(int action)
{
	int i;
	int rec = 0;
	if (jtag_state != RUNIDLE && jtag_state != RESET) {
		jtagRunidle();
    	}
	jtagAdvance0();
  	jtagAdvance1();
  	jtagAdvance1();
  	jtagAdvance0();
  	jtagAdvance0();
	rec = jtagReadTDO(10, action, 1);
	if (rec != 0x155) {
		return -1;
	}
	jtagAdvance1();
	jtagAdvance1();
	return 0;
}

static void jtagSetupChain(int action)
{
	int i;
	int rec = 0;

	if (jtag_state != RUNIDLE && jtag_state != RESET) {
	       	jtagRunidle();
	}
	jtagAdvance0();
	jtagAdvance1();
	jtagAdvance1();
	jtagAdvance0();
	jtagAdvance0();
	rec = jtagReadTDO(10, action, 1);
	jtagAdvance1();
	jtagAdvance1();
}


int jtagCheckStatus()
{
	int bit;
	int data = 0;
	int jseq_max = 0;
	int jseq_conf_done = 0;
	int conf_done_bit = 0;

	jtagSetupChain(JTAG_CHECK_STATUS);
	jtagShiftDr();
	jseq_max = 360;
	jseq_conf_done = 224;
	conf_done_bit = ((jseq_max-jseq_conf_done) * 3) + 1;
	conf_done_bit += 0;
	for (bit = 0; bit < conf_done_bit; bit++) {
		jtagDriveSignal(TDI, 0, 1);
	}
	data = jtagReadTDO(1, 0, 0);
	jtagUpdateDr();
	jtagRunidle();
	if (!data) {
		return 1;
	}
	return 0;
}

static int jtagVIR(int instruction)
{
	int ret = 0;
	int code;

	if (jtag_last_vir != instruction) {
    		code = ((jtag_id + 1) << jtag_vir_size) | instruction;
    		ret = jtagLoadJI(JTAG_USER1_VIR);
    		if (ret < 0) {
			return ret;
		}
    		jtagShiftDr();
    		jtagReadTDO(jtag_vir_size + jtag_slave_bits, code, 1);
    		jtagUpdateDr();
    		jtag_last_vir = instruction;
  	}
	return ret;
}

int jtagInit()
{
	int i;
	int j;
	unsigned int rec;

	jtagInitIn(TDO);
  	jtagInitOut(TMS);
  	jtagInitOut(TCK);
  	jtagInitOut(TDI);

  	jtagSetOut(TMS);
  	jtagSetOut(TDI);
  	jtagClearOut(TCK);

	jtagRunidle();
	if (jtagCheckStatus() == 0) {
		jtagLoadJI(JTAG_USER1_VIR);
    		jtagShiftDr();
    		jtagReadTDO(64, 0, 0);
    		jtagUpdateDr();
    		jtagLoadJI(JTAG_USER0_VDR);
    		rec = 0;
    		for (i = 0; i < 8; i++) {
      			jtagShiftDr();
      			rec = (rec >> 4) | (jtagReadTDO(4, 0, 0) << 28);
      			jtagUpdateDr();
      			jtagRunidle();
    		}
    		jtag_id = -1;
    		jtag_last_vir = -1;
    		if (((rec >> 8) & 0x7ff) == JTAG_VENDOR_ID) {
			jtag_n_slaves = (rec >> 19) & 0xff; 
      			for (jtag_slave_bits = 0; 
				(1 << jtag_slave_bits) < (jtag_n_slaves + 1); 
				jtag_slave_bits++)
			{
			}
      			jtag_vir_size = rec & 0xff;
      			for (j = 0; j < jtag_n_slaves; j++) {
        			rec = 0;
        			for (i = 0; i < 8; i++) {
          				jtagShiftDr();
          				rec = (rec >> 4) | 
						(jtagReadTDO(4, 0, 0) << 28);
          				jtagUpdateDr();
          				jtagRunidle();
        			}
        			if (((rec >> 19) & 0xff) == JTAG_ID_VJTAG 
					&& ((rec >> 8) & 0x7ff) == 
					JTAG_VENDOR_ID)
				{
          				jtag_id = j;
          				return 0;
        			}
			}
		}
	}
	return -1;
}

int jtagWriteBuffer(unsigned int address, const uint8_t *data, size_t len)
{
	int ret = 0;
  	ret = jtagVIR(0);
  	if (ret < 0) {
		return ret;
  	}
  	jtagLoadJI(JTAG_USER0_VDR);
  	jtagShiftDr();
  	address = (address << 2) | 0x00000003;
  	jtagReadTDOBuf(32, &address, 0, 0);
  	jtagReadTDOBuf(32 * len+2, data, 0, 0);
  	return len;
}

int jtagMbPinSet(void)
{
	uint32_t rpc;
  	rpc = 0;
  	jtagWriteBuffer(MB_BASE, (const uint8_t *)&rpc, 1);
  	pinMode(MB_INT_PIN, OUTPUT);
  	digitalWrite(MB_INT_PIN, LOW);
}

int jtagMbEveSend(uint32_t* data, int len)
{
	long start;
	int ret;
 	ret = jtagWriteBuffer(MB_BASE, (const uint8_t *)data, len);
	if (ret != len) {
   		return -10;
 	}
	digitalWrite(MB_INT_PIN, HIGH);
	digitalWrite(MB_INT_PIN, LOW);
	return 0;
}

