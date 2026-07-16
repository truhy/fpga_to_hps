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

	Version: 20260707
*/

// My includes
#include "fpga_irqh.h"
#include "arm/tru_cortex_a9.h"

// Arm CMSIS includes
#include "RTE_Components.h"   // CMSIS
#include CMSIS_device_header  // CMSIS

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

	stream0_wait_rdy(stream0_irq_context->rdy_index, 0);  // This is optional, this CPU is not fast enough to pass this: Wait to ensure FPGA has disabled its IRQ trigger
}

void fpga_init(stream_t *stream0){
	stream0_irq_context = stream0;

	// Initialise Parallel Port IO IP memory mapped registers
	STREAM_S0_RDY_REG->out_clr = stream0_irq_context->rdy_index;  // De-assert ready flag and pass to FPGA
	stream0_set_addr((uint32_t)stream0->xfer_addr, true);  // Pass parameter to FPGA
	stream0_set_len(stream0->xfer_size, true);  // Pass parameter to FPGA

	// Register and enable the specified IRQ
	IRQ_SetHandler(C5SOC_F2H0_IRQn, fpga_stream0_irqhandler);  // Register user interrupt handler
	IRQ_SetPriority(C5SOC_F2H0_IRQn, GIC_IRQ_PRIORITY_LEVEL29_7);  // Set low priority
	IRQ_SetMode(C5SOC_F2H0_IRQn, IRQ_MODE_TYPE_IRQ | IRQ_MODE_CPU_0 | IRQ_MODE_TRIG_LEVEL | IRQ_MODE_TRIG_LEVEL_HIGH);
	IRQ_Enable(C5SOC_F2H0_IRQn);  // Enable the interrupt

	gtim_setup_basic_mode();  // Setup global timer in basic mode
}

void fpga_deinit(void){
	IRQ_Disable(C5SOC_F2H0_IRQn);                      // Disable user interrupt handler
	IRQ_SetHandler(C5SOC_F2H0_IRQn, (IRQHandler_t)0);  // Unregister user interrupt handler
	stream0_irq_context = NULL;
}
