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
#define jtag___DsizeD 0
#define jtag___DcidD 11
#define jtag__TEST_LOGIC_RESET 1
#define jtag__RUN_TEST_IDLE 2
#define jtag__SELECT_DR_SCAN 3
#define jtag__CAPTURE_DR 4
#define jtag__SHIFT_DR 5
#define jtag__EXIT_1_DR 6
#define jtag__PAUSE_DR 7
#define jtag__EXIT_2_DR 8
#define jtag__UPDATE_DR 9
#define jtag__SELECT_IR_SCAN 10
#define jtag__CAPTURE_IR 11
#define jtag__SHIFT_IR 12
#define jtag__EXIT_1_IR 13
#define jtag__PAUSE_IR 14
#define jtag__EXIT_2_IR 15
#define jtag__UPDATE_IR 16
var jtag__init();
var jtag__send(var signal, var data, var clk);
var jtag__tap_update(var tms);
var jtag__read_tdo(var bit_count, var data, var inst);
var jtag__read_tdo_buf(var bit_count, var txbuf, var rxbuf, var inst);
var jtag__update_dr();
var jtag__shift_dr();
var jtag__run_idle();
var jtag__load_ji(var action);
var jtag__setup_chain(var action);
var jtag__check_status();
var jtag__vir(var instruction);
var jtag__write_buffer(var address, var data, var len);
var jtag__mb_pin_set();
var jtag__mb_eve_send(var data, var len);
static void std__init_strings()
{
}
/* class jtag */
static var jtag__tap_state = 0;
static var jtag__jtag_id = 0;
static var jtag__jtag_n_slaves = 0;
static var jtag__jtag_slave_bits = 0;
static var jtag__jtag_vir_size = 0;
static var jtag__jtag_last_vir = 0;
var jtag__init()
{
	var i;
	var j;
	var rec;
	var r;
	FAKETHIS();

	jtag__tap_state=jtag__TEST_LOGIC_RESET;
	jtag__jtag_id=-(1);
	jtag__jtag_vir_size=0;
	jtag__init_in(jtag__TDO);
	jtag__init_out(jtag__TMS);
	jtag__init_out(jtag__TCK);
	jtag__init_out(jtag__TDI);
	jtag__set_out(jtag__TMS);
	jtag__set_out(jtag__TDI);
	jtag__clear_out(jtag__TCK);
	jtag__run_idle();
	if ((jtag__check_status())==0) {
		jtag__load_ji(jtag__USER1_VIR);
		jtag__shift_dr();
		jtag__read_tdo(64,0,0);
		jtag__update_dr();
		jtag__load_ji(jtag__USER0_VDR);
		rec=0;
		i=0;
		while (i<8) {
			jtag__shift_dr();
			rec=std__slr(rec,4);
			r=jtag__read_tdo(4,0,0);
			r=std__sll(r,28);
			rec=std__or(rec,r);
			jtag__update_dr();
			jtag__run_idle();
			i=i+1;
		}
		jtag__jtag_id=-(1);
		jtag__jtag_last_vir=-(1);
		j=0;
		if ((std__and(std__slr(rec,8),2047))==(jtag__VENDOR_ID)) {
			jtag__jtag_n_slaves=std__and(std__slr(rec,19),255);
			jtag__jtag_slave_bits=0;
			while ((std__sll(1,jtag__jtag_slave_bits))<((jtag__jtag_n_slaves+1))) {
				jtag__jtag_slave_bits=jtag__jtag_slave_bits+1;
			}
			jtag__jtag_vir_size=std__and(rec,255);
			j=0;
			while (j<jtag__jtag_n_slaves) {
				rec=0;
				i=0;
				while (i<8) {
					jtag__shift_dr();
					rec=std__slr(rec,4);
					r=jtag__read_tdo(4,0,0);
					r=std__sll(r,28);
					rec=std__or(rec,r);
					jtag__update_dr();
					jtag__run_idle();
					i=i+1;
				}
				if ((std__and(std__slr(rec,19),255))==(jtag__ID_VJTAG)) {
					if ((std__and(std__slr(rec,8),2047))==(jtag__VENDOR_ID)) {
						jtag__jtag_id=j;
						return 0;
					}
				}
				j=j+1;
			}
		}
	}
	return -(1);
}
var jtag__send(var signal, var data, var clk)
{
	FAKETHIS();

	if (data!=0) {
		jtag__set_out(signal);
	} else {
		jtag__clear_out(signal);
	}
	if (clk!=0) {
		jtag__set_out(jtag__TCK);
		jtag__clear_out(jtag__TCK);
	}
	return 0;
}
var jtag__tap_update(var tms)
{
	FAKETHIS();

	jtag__send(jtag__TMS,tms,1);
	
	switch (jtag__tap_state) {
	case jtag__TEST_LOGIC_RESET: 
		if (tms==0) {
			jtag__tap_state=jtag__RUN_TEST_IDLE;
		}
		break;
	case jtag__RUN_TEST_IDLE: 
		if (tms==1) {
			jtag__tap_state=jtag__SELECT_DR_SCAN;
		}
		break;
	case jtag__SELECT_DR_SCAN: 
		if (tms==1) {
			jtag__tap_state=jtag__SELECT_IR_SCAN;
		} else {
			jtag__tap_state=jtag__CAPTURE_DR;
		}
		break;
	case jtag__CAPTURE_DR: 
		if (tms==1) {
			jtag__tap_state=jtag__EXIT_1_DR;
		} else {
			jtag__tap_state=jtag__SHIFT_DR;
		}
		break;
	case jtag__SHIFT_DR: 
		if (tms==1) {
			jtag__tap_state=jtag__EXIT_1_DR;
		}
		break;
	case jtag__EXIT_1_DR: 
		if (tms==1) {
			jtag__tap_state=jtag__UPDATE_DR;
		} else {
			jtag__tap_state=jtag__PAUSE_DR;
		}
		break;
	case jtag__PAUSE_DR: 
		if (tms==1) {
			jtag__tap_state=jtag__EXIT_2_DR;
		}
		break;
	case jtag__EXIT_2_DR: 
		if (tms==1) {
			jtag__tap_state=jtag__UPDATE_DR;
		} else {
			jtag__tap_state=jtag__SHIFT_DR;
		}
		break;
	case jtag__UPDATE_DR: 
		if (tms==1) {
			jtag__tap_state=jtag__SELECT_DR_SCAN;
		} else {
			jtag__tap_state=jtag__RUN_TEST_IDLE;
		}
		break;
	case jtag__SELECT_IR_SCAN: 
		if (tms==1) {
			jtag__tap_state=jtag__TEST_LOGIC_RESET;
		} else {
			jtag__tap_state=jtag__CAPTURE_IR;
		}
		break;
	case jtag__CAPTURE_IR: 
		if (tms==1) {
			jtag__tap_state=jtag__EXIT_1_IR;
		} else {
			jtag__tap_state=jtag__SHIFT_IR;
		}
		break;
	case jtag__SHIFT_IR: 
		if (tms==1) {
			jtag__tap_state=jtag__EXIT_1_IR;
		}
		break;
	case jtag__EXIT_1_IR: 
		if (tms==1) {
			jtag__tap_state=jtag__UPDATE_IR;
		} else {
			jtag__tap_state=jtag__PAUSE_IR;
		}
		break;
	case jtag__PAUSE_IR: 
		if (tms==1) {
			jtag__tap_state=jtag__EXIT_2_IR;
		}
		break;
	case jtag__EXIT_2_IR: 
		if (tms==1) {
			jtag__tap_state=jtag__UPDATE_IR;
		} else {
			jtag__tap_state=jtag__SHIFT_IR;
		}
		break;
	case jtag__UPDATE_IR: 
		if (tms==1) {
			jtag__tap_state=jtag__SELECT_DR_SCAN;
		} else {
			jtag__tap_state=jtag__RUN_TEST_IDLE;
		}
		break;
	default:
		jtag__tap_state=jtag__TEST_LOGIC_RESET;
		break;
	} 
	return 0;
}
var jtag__read_tdo(var bit_count, var data, var inst)
{
	var rec;
	var i;
	var in;
	var clk;
	FAKETHIS();

	i=0;
	rec=0;
	while (i<bit_count) {
		in=jtag__read_in(jtag__TDO);
		rec=std__or(rec,std__sll(in,i));
		if (((i==((bit_count-1)))&&(inst!=0))) {
			clk=0;
		} else {
			clk=1;
		}
		jtag__send(jtag__TDI,std__and(data,1),clk);
		data=std__slr(data,1);
		i=i+1;
	}
	return rec;
}
var jtag__read_tdo_buf(var bit_count, var txbuf, var rxbuf, var inst)
{
	var rec;
	var tdi;
	var tdo;
	var i;
	var charbit;
	var indata;
	var outdata;
	var iin;
	var iout;
	var r;
	var clk;
	FAKETHIS();

	rec=0;
	tdi=0;
	tdo=0;
	charbit=0;
	indata=0;
	iin=0;
	iout=0;
	i=0;
	while (i<bit_count) {
		if (charbit==0) {
			if (txbuf!=0) {
				outdata=bytes__get_at(txbuf,iout);
				iout=iout+1;
			} else {
				outdata=-(1);
			}
		}
		r=jtag__read_in(jtag__TDO);
		indata=std__slr(indata,1);
		indata=std__or(indata,std__sll(r,7));
		if (((i==((bit_count-1)))&&(inst!=0))) {
			clk=0;
		} else {
			clk=1;
		}
		jtag__send(jtag__TDI,std__and(outdata,1),clk);
		outdata=std__slr(outdata,1);
		charbit=std__and((charbit+1),7);
		if (charbit==0) {
			if (rxbuf!=0) {
				bytes__set_at(rxbuf,iin,indata);
				iin=iin+1;
				indata=0;
			}
		}
		i=i+1;
	}
	return 0;
}
var jtag__update_dr()
{
	FAKETHIS();

	if (jtag__tap_state!=(jtag__SHIFT_DR)) {
		return 1;
	}
	jtag__tap_update(1);
	jtag__tap_update(1);
	return 0;
}
var jtag__shift_dr()
{
	FAKETHIS();

	if ((jtag__tap_state!=(jtag__UPDATE_DR))&&(jtag__tap_state!=(jtag__UPDATE_IR))) {
		if ((jtag__tap_state!=(jtag__TEST_LOGIC_RESET))&&(jtag__tap_state!=(jtag__RUN_TEST_IDLE))) {
			return 1;
		} else {
			jtag__tap_update(0);
			jtag__tap_update(0);
			jtag__tap_update(1);
			jtag__tap_update(0);
			jtag__tap_update(0);
			return 0;
		}
	}
	jtag__tap_update(1);
	jtag__tap_update(0);
	jtag__tap_update(0);
	return 0;
}
var jtag__run_idle()
{
	var i;
	FAKETHIS();

	if ((jtag__tap_state!=(jtag__UPDATE_IR))&&(jtag__tap_state!=(jtag__UPDATE_DR))) {
		i=0;
		while (i<5) {
			jtag__tap_update(1);
			i=i+1;
		}
	}
	jtag__tap_update(0);
	return 0;
}
var jtag__load_ji(var action)
{
	var i;
	var rec;
	FAKETHIS();

	if ((jtag__tap_state!=(jtag__TEST_LOGIC_RESET))&&(jtag__tap_state!=(jtag__RUN_TEST_IDLE))) {
		jtag__run_idle();
	}
	jtag__tap_update(0);
	jtag__tap_update(1);
	jtag__tap_update(1);
	jtag__tap_update(0);
	jtag__tap_update(0);
	rec=jtag__read_tdo(10,action,1);
	if (rec!=341) {
		return -(1);
	}
	jtag__tap_update(1);
	jtag__tap_update(1);
	return 0;
}
var jtag__setup_chain(var action)
{
	FAKETHIS();

	if ((jtag__tap_state!=(jtag__TEST_LOGIC_RESET))&&(jtag__tap_state!=(jtag__RUN_TEST_IDLE))) {
		jtag__run_idle();
	}
	jtag__tap_update(0);
	jtag__tap_update(1);
	jtag__tap_update(1);
	jtag__tap_update(0);
	jtag__tap_update(0);
	jtag__read_tdo(10,action,1);
	jtag__tap_update(1);
	jtag__tap_update(1);
	return 0;
}
var jtag__check_status()
{
	var bit;
	var data;
	var jseq_max;
	var jseq_conf_done;
	var conf_done_bit;
	var r;
	FAKETHIS();

	r=jtag__setup_chain(jtag__CHECK_STATUS);
	jtag__shift_dr();
	jseq_max=360;
	jseq_conf_done=224;
	conf_done_bit=((((jseq_max-jseq_conf_done))*3))+1;
	bit=0;
	while (bit<conf_done_bit) {
		jtag__send(jtag__TDI,0,1);
		bit=bit+1;
	}
	data=jtag__read_tdo(1,0,0);
	jtag__update_dr();
	jtag__run_idle();
	if (data==0) {
		return 1;
	}
	return 0;
}
var jtag__vir(var instruction)
{
	var ret;
	var code;
	FAKETHIS();

	ret=0;
	if (jtag__jtag_last_vir!=instruction) {
		code=std__or(std__sll((jtag__jtag_id+1),jtag__jtag_vir_size),instruction);
		ret=jtag__load_ji(jtag__USER1_VIR);
		if (ret<0) {
			return ret;
		}
		jtag__shift_dr();
		jtag__read_tdo(jtag__jtag_vir_size+jtag__jtag_slave_bits,code,1);
		jtag__update_dr();
		jtag__jtag_last_vir=instruction;
	}
	return ret;
}
var jtag__write_buffer(var address, var data, var len)
{
	var ret;
	var a;
	FAKETHIS();

	ret=jtag__vir(0);
	if (ret<0) {
		return ret;
	}
	jtag__load_ji(jtag__USER0_VDR);
	jtag__shift_dr();
	a=((address*4))+3;
	jtag__read_tdo_buf(32,std__address_of(a),0,0);
	jtag__read_tdo_buf(((32*len))+2,data,0,0);
	return len;
}
var jtag__mb_pin_set()
{
	var rpc;
	var ret;
	FAKETHIS();

	rpc=0;
	ret=jtag__write_buffer(jtag__MB_BASE,std__address_of(rpc),1);
	if (ret!=1) {
		return -(1);
	}
	pin__mode(jtag__MB_INT_PIN,pin__OUTPUT);
	digital__write(jtag__MB_INT_PIN,digital__LOW);
	return 0;
}
var jtag__mb_eve_send(var data, var len)
{
	var start;
	var ret;
	FAKETHIS();

	ret=jtag__write_buffer(jtag__MB_BASE,data,len);
	if (ret!=len) {
		return -(10);
	}
	digital__write(jtag__MB_INT_PIN,digital__HIGH);
	digital__write(jtag__MB_INT_PIN,digital__LOW);
	return 0;
}
