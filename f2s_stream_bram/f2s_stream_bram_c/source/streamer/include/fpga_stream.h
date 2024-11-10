/*
	MIT License

	Copyright (c) 2023 Truong Hy

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

	Version: 20230908
*/

#ifndef FPGA_STREAM_H
#define FPGA_STREAM_H

// My includes
#include "tru_intel_pio.h"
#include "tru_c5soc_hps_ll.h"

// FreeRTOS includes
#include "FreeRTOS.h"
#include "task.h"

// Standard includes
#include <stdbool.h>
#include <stdint.h>

// These sizes must match with the hardware design
#define STREAM_F2S_BIT_BUS_WIDTH  256U
#define STREAM_F2S_BYTE_BUS_WIDTH (STREAM_F2S_BIT_BUS_WIDTH / 8U)
#define STREAM_F2S_MAX_BURST      16U

// ============
// Test options
// ============

#define TEST_VARIATION    1U  // Test transfer size variation: 0 = Single, 1 = Variation
#define TEST_VERIFICATION 1U  // Test samples verification: 0 = Disable, 1 = Enable
#if TEST_VARIATION == 1U
	// Tests various transfer sizes
	#define TEST_NUM_ITERATIONS 2U
	#define TEST_NUM_VARIATIONS 20U
	#define TEST_XFER_SIZE      (STREAM_F2S_MAX_BURST * STREAM_F2S_BYTE_BUS_WIDTH)
#else
	// Test single transfer size
	#define TEST_NUM_ITERATIONS 300U
	#define TEST_NUM_VARIATIONS 1U
	#define TEST_XFER_SIZE      (256U * STREAM_F2S_MAX_BURST * STREAM_F2S_BYTE_BUS_WIDTH)
	//#define TEST_XFER_SIZE    (16U * 4096U * STREAM_F2S_MAX_BURST * STREAM_F2S_BYTE_BUS_WIDTH)
#endif

// Task priorities
#define	STREAM0_TASK_PRIORITY (tskIDLE_PRIORITY + 1U)

#define KB 1024U
#define MB 1048576UL

#define STREAM_TESTDATA_MAX_COUNT 65536UL

// ================
// PIO IP registers
// ================

// These PIO addresses must match with Platform Designer in the hardware design
#define PIO_S0_RDY_BASE  (TRU_HPS_L2F_BASE + 0x00000000UL)
#define PIO_S0_ADDR_BASE (TRU_HPS_L2F_BASE + 0x00000020UL)
#define PIO_S0_LEN_BASE  (TRU_HPS_L2F_BASE + 0x00000030UL)

// PIO IP instances as type representation
#define STREAM_S0_RDY_REG  ((tru_intel_pio_t *)PIO_S0_RDY_BASE)
#define STREAM_S0_ADDR_REG ((tru_intel_pio_t *)PIO_S0_ADDR_BASE)
#define STREAM_S0_LEN_REG  ((tru_intel_pio_t *)PIO_S0_LEN_BASE)

// Host ready flag
// Since the interrupt or process between the HPS and FPGA is asynchronous, we
// need a ready flag to indicate to the FPGA side when the host PC is ready
// to accept more data, i.e. when the FPGA can update and overwrite old data
// with new ones.  We only need to use the first 2 bits of the flag, whose
// values are:
//   00 = PC host is not ready
//   01 = PC host is ready 0
//   10 = PC host is ready 1
//   11 = XOR mask for toggling between ready 0 and 1
// Switching between 2 flags enables synchronisation without the need for a
// locking mechanism.  Functionally, this is a 2-bit circular buffer
typedef enum stream_host_ready_e{
	FPGA_STREAM_HOST_BUSY,
	FPGA_STREAM_HOST_RDY_0,
	FPGA_STREAM_HOST_RDY_1,
	FPGA_STREAM_HOST_RDY_XOR
}stream_host_ready_t;

typedef struct{
	uint32_t buf_size;
	uint32_t *buf_addr_actual;
	uint32_t buf_size_actual;
	void *xfer_addr;
	uint32_t xfer_size;
	uint32_t rdy_index;
	TaskHandle_t stream_task;
	uint32_t elapsed_tick_freq;
	uint64_t elapsed_ticks;
	uint16_t sample_ref;
	uint32_t num_iterations;
	uint32_t num_variations;
	uint32_t iter_index;
	uint32_t var_index;
	float rate;
	float *rateavg_results;
	uint32_t *dif_results;
}stream_t;

bool stream_init(void);
void stream_deinit(void);
void stream0_assert_rdy(void);
void stream0_wait_rdy(uint32_t mask, uint32_t val);
void stream0_set_addr(uint32_t addr, bool wait);
void stream0_set_len(uint32_t len, bool wait);

#endif
