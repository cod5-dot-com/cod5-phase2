/*
 *                          cod5.com computer
 *
 *                    MMXXIII December 19 PUBLIC DOMAIN
 *           The author disclaims copyright to this source code.
 *
 *
 */

#ifndef JTAG_H_
#define JTAG_H_

#include "Arduino.h"
#include <stdio.h>

#define var long

#define FAKETHIS()

#define std__panic()

#define std__address_of(v) \
	((var)&v)

#define std__or(a,b) ((a) | (b))
#define std__and(a,b) ((a) & (b))
#define std__sll(a,b) ((a) << (b))
#define std__slr(a,b) ((var)((unsigned var)(a) >> (b)))

#define bytes__get_at(buf, at) \
	((uint8_t*)buf)[at]

#define bytes__set_at(buf, at, v) \
	((uint8_t*)buf)[at] = (v & 0xFF)

#define digital__write(p, d) \
	digitalWrite(p, d)

#define digital__LOW LOW

#define digital__HIGH HIGH

#define pin__mode(pin, v) \
	pinMode(pin, v)

#define pin__OUTPUT OUTPUT

#define jtag__VENDOR_ID                  0x6E
#define jtag__ID_VJTAG                   0x84
#define jtag__CHECK_STATUS               0x004
#define jtag__USER0_VDR                  0x00C
#define jtag__USER1_VIR                  0x00E

#define jtag__init_out(pin) PORT->Group[0].DIRSET.reg = (1<<pin)
#define jtag__set_out(pin) PORT->Group[0].OUTSET.reg = (1<<pin)
#define jtag__clear_out(pin) PORT->Group[0].OUTCLR.reg = (1<<pin)
#define jtag__init_in(pin) \
        PORT->Group[0].PINCFG[pin].reg=(uint8_t)(PORT_PINCFG_INEN); \
        PORT->Group[0].DIRCLR.reg = (1<<pin)
#define jtag__read_in(pin) ((PORT->Group[0].IN.reg & (1<<pin)) != 0)

/* ATSAMD21G18A port A connected to connector J11 and FPGA JTAG dedicated pins
 */
#define jtag__TDI             12 /* PA12 -> TDI_B1_H4  Test Data In */
#define jtag__TDO             15 /* PA15 <- TDO_B1_J4  Test Data Out */
#define jtag__TCK             13 /* PA13 -> TCK_B1_H3  Test ClocK */
#define jtag__TMS             14 /* PA14 -> TMS_B1_J5  Test Mode Select */
#define jtag__MB_INT_PIN      31
#define jtag__MB_BASE         0x00000000

#ifdef __cplusplus
extern "C" {
#endif
long jtag__init(void);
long jtag__mb_pin_set(void);
long jtag__mb_eve_send(long data, long len);
#ifdef __cplusplus
}
#endif
#endif
