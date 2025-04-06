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

	Version: 20250405
	Target : ARM Cortex-A9 on the DE10-Nano development board (Intel Cyclone V
	         SoC FPGA)
	Type   : Standalone C

	This is the software part of the FPGA to HPS data transfer test project.

	The software on the HPS has a master role and the hardware design on the
	FPGA has a slave role.  The FPGA waits for a signal before starting the
	transfer process.  The HPS controls the transfers, whenever a transfer is
	complete it measures the throughput, reads and verifies the data in the
	SDRAM buffer.  It is interrupt and preemptive task (FreeRTOS) driven.

	Transfer is made by the FPGA using the FPGA-to-HPS bridge (F2H bridge) and
	Accelerator Coherency Port (ACP).  We don't need to apply any cache
	maintenance with this method, i.e. disable or clean the L1/L2 cache.

	Parameters and flags are transmitted between the two sides over the
	Lightweight HPS-to-FPGA bridge (L2F bridge), accessed with the Parallel IO
	IP (PIO IP), which provides memory-mapped registers for the HPS.

	Process flow:
		1.  The compiled hardware design file is downloaded to the FPGA
		2.  The HPS application is executed
		3.  The FPGA fills the BRAM (M10K embedded memory) with test data
		4.  The FPGA is now in a waiting state; waiting for the HPS to send
		    parameters and the ready signal before it starts transferring
		5.  The HPS application send parameters to the FPGA, starts a
		    preemptive control task, starts a timer and asserts the ready signal
		6.  The FPGA transfers data from FPGA BRAM to HPS SDRAM buffer
		    defined by start address and size parameters received from HPS
		    earlier
		7.  When the transfer size is reached the FPGA asserts an interrupt
		    trigger to generate one on the HPS, and then enters into a waiting
		    state
		8.  The IRQ is raised on the HPS which jumps into the interrupt handler.
		    The handler stops the timer, deasserts the ready signal to indicate
		    the FPGA to deassert the interrupt trigger, and then signals the
		    preemptive control task to process the data
		9.  The FPGA switches to another ready flag
		10. The control task calculates the throughput of the transfer and
		    verifies the transferred data
		11. If the test is not yet complete, the task switches to another ready
		    flag, and asserts the ready signal for the FPGA to start another
		    transfer, repeating the process

	Transfer throughput is measured using the MPCore 64-bit global timer, which
	provides high resolution timer ticks (default 200MHz = 5ns).

	Two separate ready flags are used for acknowledgement between the two sides.
	They are organised as a 2 position cyclic buffer, where after a complete
	data transfer, each side (FPGA and HPS) switches to an opposite index.  This
	ensures that each side always use a different ready flag, which prevents the
	synchronisation problem of a flag being read and written at the same time.
	
	Limitations

	This design is not optimised because it uses only a single SDRAM buffer
	region.  Consider a continuous acquisition scenario, the interrupt and
	processing delay is deadtime which may create gaps in the acquisition.  A
	double-buffer may help to prevent this.
*/

// My includes
#include "fpga_stream.h"

// Arm CMSIS includes
#include "RTE_Components.h"   // CMSIS
#include CMSIS_device_header  // CMSIS

// FreeRTOS includes
#include "FreeRTOS.h"
#include "task.h"

#ifdef SEMIHOSTING
	extern void initialise_monitor_handles(void);  // Reference function header from the external Semihosting library
#endif

int main(int argc, char **argv){
	#ifdef SEMIHOSTING
		initialise_monitor_handles();  // Initialise Semihosting
	#endif

	if(stream_init()){
		vTaskStartScheduler();  // Start the FreeRTOS preemptive scheduler
	}
	stream_deinit();
	while(1);

	return 0;
}
