/*
 *                          cod5.com computer
 *
 *                      17 may MMXXI PUBLIC DOMAIN
 *           The author disclaims copyright to this source code.
 *
 *
 */

#ifndef JTAG_H_
#define JTAG_H_

#include "Arduino.h"

/* ATSAMD21G18A port A connected to 
connector J11 and FPGA JTAG dedicated pins
*/
#define TDI             12 /* PA12 -> TDI_B1_H4 */
#define TDO             15 /* PA15 <- TDO_B1_J4 */
#define TCK             13 /* PA13 -> TCK_B1_H3 */
#define TMS             14 /* PA14 -> TMS_B1_J5 */
#define MB_INT_PIN	31
#define MB_BASE 	0x00000000

#ifdef __cplusplus
extern "C" {
#endif
int jtagInit(void);
int jtagMbPinSet(void);
int jtagMbEveSend(uint32_t* data, int len);
#ifdef __cplusplus
}
#endif
#endif
