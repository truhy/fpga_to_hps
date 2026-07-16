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

#include "fpga_irqh.h"

// Trulib includes
#include "tru_logger.h"
#include "tru_iom.h"
#include "tru_cache.h"
#include "arm/tru_cortex_a9.h"
#include "c5soc/tru_clkmgr_c5soc.h"

// Arm CMSIS includes
#include "RTE_Components.h"
#include CMSIS_device_header

// FreeRTOS includes
#include "FreeRTOS.h"
#include "task.h"

// Standard includes
#include <stdlib.h>
#include <string.h>

static stream_t stream0;

void print_stats(void){
	if(stream0.xfer_size < KB){
		printf("Xfer: %.2f B", (float)stream0.xfer_size);
	}else if(stream0.xfer_size < MB){
		printf("Xfer: %.2f KB", stream0.xfer_size / (float)KB);
	}else{
		printf("Xfer: %.2f MB", stream0.xfer_size / (float)MB);
	}

	if(stream0.rate < (float)KB){
		printf(", Rate: %.2f B/s", stream0.rateavg_results[stream0.var_index]);
	}else if(stream0.rate < (float)MB){
		printf(", Rate: %.2f KB/s", stream0.rateavg_results[stream0.var_index] / (float)KB);
	}else{
		printf(", Rate: %.2f MB/s", stream0.rateavg_results[stream0.var_index] / (float)MB);
	}

#if TEST_VERIFICATION == 1U
	printf(", Dif: %lu", stream0.dif_results[stream0.var_index]);
#endif

	printf("\n");
}

void process_samples(void){
	uint16_t *samples = (uint16_t *)stream0.xfer_addr;
	uint32_t num_samples = stream0.xfer_size / 2U;

	// Process samples
	for(uint32_t i = 0; i < num_samples; i++){
		// Display the sample (address, number, value).  Warning: enabling this will slow down the streaming to the serial to computer speed
		//printf("A: 0x%.8x, S%.10u: %u\n", samples + i, i, samples[i]);

		// Verify sample
		if(samples[i] != stream0.sample_ref){
			stream0.dif_results[stream0.var_index]++;
		}

		// Update reference sample
		stream0.sample_ref++;
		stream0.sample_ref %= STREAM_TESTDATA_MAX_COUNT;
	}
}

void process_stream0(void){
	// Calculate throughput
	stream0.rate = stream0.xfer_size * (float)stream0.elapsed_tick_freq / stream0.elapsed_ticks;
	stream0.rateavg_results[stream0.var_index] = (stream0.iter_index * stream0.rateavg_results[stream0.var_index] + stream0.rate) / (stream0.iter_index + 1);

#if TEST_VERIFICATION == 1U
	process_samples();
#endif

	stream0.iter_index++;

#if TEST_VARIATION == 1U
	if(stream0.iter_index == stream0.num_iterations){
		print_stats();

		// Prepare for next run
		stream0.iter_index = 0;
		stream0.var_index++;
		stream0.xfer_size <<= 1;
		stream0_set_addr((uint32_t)stream0.xfer_addr, true);  // Send new DDR-3 RAM start address to FPGA
		stream0_set_len(stream0.xfer_size, true);             // Send new transfer length to FPGA
	}
#else
	print_stats();
#endif
}

void wait(uint32_t millisec){
	TickType_t x_last_wakeup_time = xTaskGetTickCount();

	// Block task to create desired delay
	vTaskDelayUntil(&x_last_wakeup_time, millisec / portTICK_PERIOD_MS);
}

void stream0_task(void *parameters){
	// Suppress compiler unused parameter warning
	(void)parameters;

	uint32_t ulNotificationValue;
	const TickType_t xMaxBlockTime = pdMS_TO_TICKS(200);

	printf("Running transfer test\n");
	printf("Location    : FPGA embedded RAM to HPS SDRAM\n");
	printf("Interface   : F2S interface\n");
	printf("Iteration(s): %lu\n", stream0.num_iterations);
	printf("Units       : 1KB = %lu bytes & 1MB = %lu bytes\n", KB, MB);

	stream0_assert_rdy();  // Signal FPGA to start a stream
	while(1){
		// Wait for notification
		ulNotificationValue = ulTaskNotifyTake(pdTRUE, xMaxBlockTime);
		if(ulNotificationValue){
			process_stream0();

			//wait(2000U);  // Test simulate a busy CPU

			if(stream0.var_index < stream0.num_variations){
				stream0_assert_rdy();  // Signal FPGA to start another stream
			}else{
				printf("Finished\n");
			}
		}else{
			// Timed-out
		}
	}
}

bool stream0_setup_tasks(void){
	BaseType_t x_ret;

	// Create a FreeRTOS task
	x_ret = xTaskCreate(stream0_task, "0", configMINIMAL_STACK_SIZE, NULL, STREAM0_TASK_PRIORITY, &stream0.stream_task);
	if(x_ret != pdPASS) return false;

	return true;
}

// Change MMU table 1MB page section entries to non-cacheable for the given memory range
void stream_mmap_noncacheable(void){
	// Memory range
	uint32_t start_addr = (uint32_t)stream0.xfer_addr;
	uint32_t mem_size = stream0.buf_size;

	if(mem_size){
		mmu_region_attributes_Type region = {
			.rg_t = SECTION,
			.domain = 0x0,
			.e_t = ECC_DISABLED,
			.g_t = GLOBAL,
			.inner_norm_t = NON_CACHEABLE,  // L1 cache
			.outer_norm_t = NON_CACHEABLE,  // L2 cache
			.mem_t = NORMAL,
			.sec_t = SECURE,
			.xn_t = EXECUTE,
			.priv_t = RW,
			.user_t = RW,
			.sh_t = SHARED
		};
		uint32_t L1_Section_Attrib_NonCache_RWX;  // Section attribute variable
		uint32_t noncache_num_sections = (mem_size % 1048576UL) ? mem_size / 1048576UL + 1 : mem_size / 1048576UL;  // Calc number of 1MB MMU sections rounding up
		uint32_t *mmu_ttb_l1 = mmu_get_ttb_l1();

		MMU_GetSectionDescriptor(&L1_Section_Attrib_NonCache_RWX, region);  // Fill section attribute variable
		MMU_TTSection(mmu_ttb_l1, start_addr, noncache_num_sections, DESCRIPTOR_FAULT);  // Replace the old translation table entry with an invalid (faulting) entry
		// Clean of page entries is not required because Cortex-A9 has Multiprocessing Extensions
		//uint32_t offset = start_addr >> 20U;
		//tru_l1_data_clean_range(mmu_ttb_l1 + offset, 4U * noncache_num_sections);
		__DSB();  // Ensure faulting entry is visible
		MMU_InvalidateRange(mmu_ttb_l1, start_addr, noncache_num_sections);  // Invalidate TLB entries by MVA with Multiprocessing Extension support
		__set_BPIALL(0);  // Invalidate entire branch predictor array
		__DSB();  // Ensure completion of the invalidate branch predictor operation
		__ISB();  // Ensure changes visible to instruction fetch
		MMU_TTSection(mmu_ttb_l1, start_addr, noncache_num_sections, L1_Section_Attrib_NonCache_RWX);  // Write MMU table 1MB section entries that are non-cacheable
		__DSB();  // Ensure the new entry is visible
	}
}

bool stream_init(void){
	// Initialise stream object
	stream0.rdy_index = FPGA_STREAM_HOST_RDY_1;

	// F2S + F2H bridge buffer alignment requirement on burst transfers
	// ================================================================
	// We need to provide a starting DDR-3 RAM address to the FPGA so that it knows where to fill samples over
	// the bridge.  The bridge has two alignment bugs in burst mode, the starting buffer alignment depends on:
	//   1. If the burst is less than 16, then the starting buffer address must be aligned to 32-bits (4 bytes)
	//   2. If the burst is equal 16, then the starting buffer address must be aligned to burst_len * bus_width
	// We can apply these conditions by having an actual pointer and an aligned version of it.  Since condition 2
	// is already 32-bits aligned, we don't need to apply condition 1 and simply apply condition 2
	stream0.num_iterations = TEST_NUM_ITERATIONS;
	stream0.num_variations = TEST_NUM_VARIATIONS;
	stream0.xfer_size = TEST_XFER_SIZE;
	stream0.iter_index = 0;
	stream0.var_index = 0;
	stream0.rateavg_results = malloc(stream0.num_variations * sizeof(float));
	memset(stream0.rateavg_results, 0x0, stream0.num_variations * sizeof(float));
	stream0.dif_results = malloc(stream0.num_variations * sizeof(uint32_t));
	memset(stream0.dif_results, 0x0, stream0.num_variations * sizeof(uint32_t));
	stream0.buf_size = stream0.xfer_size << (stream0.num_variations - 1U);
#ifdef DEBUG
	stream0.buf_size_actual = stream0.buf_size + STREAM_F2S_MAX_BURST * STREAM_F2S_BYTE_BUS_WIDTH;  // Buffer size + extra for alignment
	stream0.buf_addr_actual = (uint32_t *)malloc(stream0.buf_size_actual);  // Actual buffer
	stream0.xfer_addr = (uint32_t *)INT_ALIGN_UP((uintptr_t)stream0.buf_addr_actual, STREAM_F2S_MAX_BURST * STREAM_F2S_BYTE_BUS_WIDTH);  // Align buffer to burst_len * bus_width
#else
	stream0.buf_size_actual = stream0.buf_size + 1048576UL;  // Buffer size + extra for alignment
	stream0.buf_addr_actual = (uint32_t *)malloc(stream0.buf_size_actual);  // Actual buffer
	stream0.xfer_addr = (uint32_t *)INT_ALIGN_UP((uintptr_t)stream0.buf_addr_actual, 1048576UL);  // Align buffer to 1MB
	stream_mmap_noncacheable();
#endif

	stream0.sample_ref = 0;

	printf("Buffer region: 0x%.8x - 0x%.8x\n", stream0.xfer_addr, stream0.xfer_addr + stream0.buf_size);

	// Note
	// The clock source of the private timer is set to the MPU peripheral clock
	// It is 1/4 of the processor clock.  On the DE10-Nano processor clock is normally 800MHz, in this case the MPU peripheral clock is 800/4 = 200MHz
	stream0.elapsed_tick_freq = get_mpu_peri_clk(TRU_HPS_INPUT_CLK_HZ).fout;  // Get MCU peripheral base clock

	iom_wr32(0xffc25080UL, 0x3fffU);  // Release the FPGA SDRAM controller ports from reset
	//tru_iom_wr32(0xffc2505cUL, 0xaU);  // Set appycfg bit (not needed)
	fpga_init(&stream0);  // Init FPGA to HPS IRQ
	return stream0_setup_tasks();
}

void stream_deinit(void){
	fpga_deinit();

	free(stream0.rateavg_results);
	stream0.rateavg_results = NULL;
	free(stream0.dif_results);
	stream0.dif_results = NULL;
	free(stream0.buf_addr_actual);
	stream0.buf_addr_actual = NULL;
	stream0.xfer_addr = NULL;
}

void stream0_assert_rdy(void){
	stream0.rdy_index = stream0.rdy_index ^ FPGA_STREAM_HOST_RDY_XOR;  // Switch flag
	gtim_zero_counter();  // Reset timer
	gtim_enable();  // Start timer
	STREAM_S0_RDY_REG->out_set = stream0.rdy_index;  // Assert ready flag
}

void stream0_wait_rdy(uint32_t mask, uint32_t val){
	STREAM_S0_RDY_REG->dir = TRU_ALTERA_PIO_DIR_INPUT;
	while(STREAM_S0_RDY_REG->data & mask != val);  // Wait for the FPGA to update to the new value, i.e. echo back the value
}

void stream0_set_addr(uint32_t addr, bool wait){
	STREAM_S0_ADDR_REG->dir = TRU_ALTERA_PIO_DIR_OUTPUT;  // Set PIO to output mode
	STREAM_S0_ADDR_REG->data = addr;  // Pass parameter to the FPGA

	if(wait){
		STREAM_S0_ADDR_REG->dir = TRU_ALTERA_PIO_DIR_INPUT;
		while(STREAM_S0_ADDR_REG->data != addr);  // Wait for the FPGA to update to the new value, i.e. echo back the value
	}
}

void stream0_set_len(uint32_t len, bool wait){
	STREAM_S0_LEN_REG->dir =  TRU_ALTERA_PIO_DIR_OUTPUT;  // Set PIO to output mode
	STREAM_S0_LEN_REG->data = len;  // Pass parameter to the FPGA

	if(wait){
		STREAM_S0_LEN_REG->dir = TRU_ALTERA_PIO_DIR_INPUT;
		while(STREAM_S0_LEN_REG->data != len);  // Wait for the FPGA to update to the new value, i.e. echo back the value
	}
}
