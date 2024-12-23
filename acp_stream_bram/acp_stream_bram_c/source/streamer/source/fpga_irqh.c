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
*/

// My includes
#include "fpga_irqh.h"
#include "tru_util_ll.h"
#include "tru_irq.h"
#include "tru_cortex_a9.h"

// FreeRTOS includes
#include "FreeRTOS.h"
#include "queue.h"

static stream_t *stream0_irq_context = NULL;

// User IRQ handler for interrupt triggered from FPGA
static void fpga_stream0_irqhandler(void){
	gtim_disable();  // Stop timer
	STREAM_S0_RDY_REG->out_clr = stream0_irq_context->rdy_index;  // De-assert ready flag and pass to FPGA

	stream0_irq_context->elapsed_ticks = gtim_get_counter();
	vTaskNotifyGiveFromISR(stream0_irq_context->stream_task, NULL);

	stream0_wait_rdy(stream0_irq_context->rdy_index, 0);  // This is optional the MCU is not fast enough to past this: Wait to ensure FPGA has disabled its IRQ trigger
}

void fpga_init(stream_t *stream0){
	stream0_irq_context = stream0;

	// Initialise Parallel Port IO IP memory mapped registers
	STREAM_S0_RDY_REG->out_clr = stream0_irq_context->rdy_index;  // De-assert ready flag and pass to FPGA
	stream0_set_addr((uint32_t)stream0->xfer_addr, true);  // Pass parameter to FPGA
	stream0_set_len(stream0->xfer_size, true);  // Pass parameter to FPGA

	// Register and enable the specified IRQ
	tru_irq_register(
		TRU_IRQ_SPI_F2H0,            // IRQ ID
		TRU_GIC_DIST_CPU0,           // CPU0
		TRU_GIC_PRIORITY_LEVEL29_7,  // Set lower priority than FreeRTOS tick interrupt handler
		fpga_stream0_irqhandler      // Register user interrupt handler
	);

	gtim_setup_basic_mode();  // Setup global timer in basic mode
}

void fpga_deinit(void){
	tru_irq_unregister(TRU_IRQ_SPI_F2H0);
	stream0_irq_context = NULL;
}
