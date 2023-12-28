
#include "jtag.h"

extern "C" int pinPeripheral(uint32_t, EPioType);

#define NODATA \
	0xFF, 0xFF, 0xFF, 0xFF, \
        0xFF, 0xFF, 0xFF, 0xFF, \
          	0xFF, 0xFF, 0xFF, 0xFF, 0xFF,\
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF,\
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF,\
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF,\
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF,\
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF,\
		0xFF, 0xFF, \
	0xFF, 0xFF, 0xFF, 0xFF, \
        0x00, 0x00, 0x00, 0x00 

// original data from :
// https://systemes-embarques.fr/wp/wp-content/uploads/2018/09/EmptySketch.zip
__attribute__ ((used, section(".fpga_bitstream_signature")))
const unsigned char signatures[4096] = {
	NODATA,
  	0x00, 0x00, 0x08, 0x00,
  	0xA9, 0x6F, 0x1F, 0x00,   
  		0x20, 0x77, 0x77, 0x77, 
		0x2e, 0x73, 0x79, 0x73, 
		0x74, 0x65, 0x6d, 0x65, 
		0x73, 0x2d, 0x65, 0x6d, 
		0x62, 0x61, 0x72, 0x71, 
		0x75, 0x65, 0x73, 0x2e, 
		0x66, 0x72, 0x20, 0x00,
		0x00, 0xff, 0xf0, 0x0f,
	0x01, 0x00, 0x00, 0x00,   
 	0x01, 0x00, 0x00, 0x00, 
 	NODATA
};

__attribute__ ((used, section(".fpga_bitstream")))
const unsigned char bitstream[] = {
#include "app.h"
};

/*  (Serial) PB23 RX <- IO_B7_C11 MKR_D[13] 
 *  (Serial) PB22 TX -> IO_B7_A13 MKR_D[14]
 *  PA20 -> IO_B6_G16/INIT_DONE open drain MKR_D[6]
 *  PA21 -> IO_B6_G15/CRC_ERROR MKR_D[7]
 *  PA16 -> IO_B6_F16/NCEO MKR_D[8]
 *  PA17 -> IO_B6_F15/CLKUSR MKR_D[9]
 *  PA27 GCLK ->  CLK0_B1_E2/DIFFCLK_0P CLK_48MHZ
 *  RESETN -> CLK1_B1_E1/DIFFCLK_0N RESETn
 *  PA26 -> IO_B5_L16 SAM_INT_IN
 *  PB9 -> IO_B2_N2 SAM_INT_OUT
 */
void setup() {
  uint32_t conf;
  long r;

  pinPeripheral(30, PIO_AC_CLK);
  clockout(0, 1);
  delay(1000);
  
  jtag__init();
  jtag__mb_pin_set();

  // Load FPGA user configuration
  conf = 0 | 3;
  r = jtag__mb_eve_send((long)&conf, 1);

  delay(1000);

  pinMode(jtag__TDO, INPUT);
  pinMode(jtag__TMS, INPUT);
  pinMode(jtag__TDI, INPUT);
  pinMode(jtag__TCK, INPUT);

  Serial.begin(115200);
  while (!Serial) {
    ; 
  }
  Serial1.begin(115200);
  while (!Serial1) { ; }
  PORT->Group[0].OUTCLR.reg = (1<<21);            
  PORT->Group[0].DIRSET.reg = (1<<21);
  PORT->Group[0].PINCFG[20].reg=(uint8_t)(PORT_PINCFG_INEN);
  PORT->Group[0].DIRCLR.reg = (1<<20);
}

void loop() {
  if (Serial.available()) {
    int c = Serial.read();
    Serial1.write(c);
    if (c == '\n' || c == '\r') return;
    if (c == 'a') { 
      PORT->Group[0].OUTSET.reg = (1<< 21);      
    } else {
      PORT->Group[0].OUTCLR.reg = (1<< 21);            
    }
    Serial.write(c);
    Serial.write(' ');
    Serial.print(PORT->Group[0].IN.reg, HEX);
    Serial.write(' ');
    if ((PORT->Group[0].IN.reg & (1<<20)) != 0) {
      Serial.write('1');
    } else {
      Serial.write('0');
    }
    Serial.write('\n');
  }
  if (Serial1.available()) {
    Serial.write("@");
    Serial.write(Serial1.read());
  }
   
}
