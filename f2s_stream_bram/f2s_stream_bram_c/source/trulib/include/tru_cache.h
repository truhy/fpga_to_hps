/*
	MIT License

	Copyright (c) 2024 Truong Hy

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

	Version: 20241122
*/

#ifndef TRU_CACHE_H
#define TRU_CACHE_H

#include "tru_config.h"
#if(TRU_CMSIS == 1U)
	#include "RTE_Components.h"   // CMSIS
	#include CMSIS_device_header  // CMSIS
#else
	#include "alt_cache.h"
	#include "tru_cortex_a9.h"
	#include "tru_util_ll.h"
#endif
#include "tru_cache_l2c310.h"
#include <stdbool.h>

#define CACHELINE_SIZE L2C310_CACHELINE_SIZE

// ===========
// MMU related
// ===========

#if(TRU_CMSIS == 1U)
// Multiprocessing Extensions: Invalidate unified TLB by MVA, all ASID
__STATIC_FORCEINLINE void __set_TLBIMVAA(uint32_t value){
	__set_CP(15, 0, value, 8, 7, 3);
}

// Multiprocessing Extensions: Invalidate unified TLB by MVA, all ASID
__STATIC_INLINE void MMU_InvalidateTLBIMVAA(uint32_t value){
	__set_TLBIMVAA(value);
	__DSB();  // Ensure completion of the invalidation
	__ISB();  // Ensure instruction fetch path sees new state
}
#else
// Multiprocessing Extensions: Invalidate unified TLB by MVA, all ASID
static inline void MMU_InvalidateTLBIMVAA(uint32_t value){
	__write_tlbimvaa(value);
	__dsb();  // Ensure completion of the invalidation
	__isb();  // Ensure instruction fetch path sees new state
}
#endif

static inline void tru_mmu_inv_range(uint32_t *ttb, uint32_t base_address, uint32_t count){
	uint32_t offset = base_address >> 20U;
	uint32_t *entry_addr = ttb;

	// 4 bytes aligned
	entry_addr = entry_addr + offset;

	for(uint32_t i = 0; i < count; i++){
		MMU_InvalidateTLBIMVAA((uint32_t)entry_addr);
		entry_addr++;
	}
}

// ================
// L1 cache related
// ================

static inline bool tru_l1_is_dcache_enabled(void){
#if(TRU_CMSIS == 1U)
	return __get_SCTLR() & SCTLR_C_Msk;
#else
	uint32_t sctlr;
	__read_sctlr(sctlr);
	return sctlr & (1U << 2U);
#endif
}

static inline bool tru_l2_is_enabled(void){
#if(TRU_CMSIS == 1U)
	return L2C_310->CONTROL & 0x1U;
#else
	return tru_iom_rd32((uint32_t *)(L2C310_BASE + L2C310_CTRL_OFFSET)) & 0x1U;
#endif
}

static inline void tru_l1_data_clean_range(void *buf, uint32_t len){
#if(TRU_CMSIS == 1U)
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		L1C_CleanDCacheMVA((void *)addr);
		addr += CACHELINE_SIZE;  // Increment index
	}
	__DSB();  // Ensure completion of the clean
#else
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		__write_dccmvac((void *)addr);
		addr += CACHELINE_SIZE;  // Increment index
	}
	__dsb();  // Ensure completion of the clean
#endif
}

static inline void tru_l1_data_inv_range(void *buf, uint32_t len){
#if(TRU_CMSIS == 1U)
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		L1C_InvalidateDCacheMVA((void *)addr);
		addr += CACHELINE_SIZE;  // Increment index
	}
	__DSB();  // Ensure completion of the invalidate
#else
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		__write_dcimvac((void *)addr);
		addr += CACHELINE_SIZE;  // Increment index
	}
	__dsb();  // Ensure completion of the invalidate
#endif
}

static inline void tru_l1_data_cleaninv_range(void *buf, uint32_t len){
#if(TRU_CMSIS == 1U)
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		L1C_CleanInvalidateDCacheMVA((void *)addr);
		addr += CACHELINE_SIZE;  // Increment index
	}
	__DSB();  // Ensure completion
#else
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		__write_dccimvac((void *)addr);
		addr += CACHELINE_SIZE;  // Increment index
	}
	__dsb();  // Ensure completion
#endif
}

// ================
// L2 cache related
// ================

static inline void tru_l2_data_clean_range(void *buf, uint32_t len){
#if(TRU_CMSIS == 1U)
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		L2C_CleanPa((void *)addr);  // Note, this also issues the L2 sync instruction, which will stall the slave port until completion, that is unless there is a L2 background operation in in progress
		addr += CACHELINE_SIZE;  // Increment index
	}
	__DSB();
#else
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		tru_iom_wr32((uint32_t *)(L2C310_BASE + L2C310_CLEAN_PA_OFFSET), addr);
		tru_iom_wr32((uint32_t *)(L2C310_BASE + L2C310_CACHE_SYNC_OFFSET), 0U);
		addr += CACHELINE_SIZE;  // Increment index
	}
	alt_cache_l2_sync();
	__dsb();
#endif
}

static inline void tru_l2_data_inv_range(void *buf, uint32_t len){
#if(TRU_CMSIS == 1U)
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		L2C_InvPa((void *)addr);  // Note, this also issues the L2 sync instruction, which will stall the slave port until completion, that is unless there is a L2 background operation in in progress
		addr += CACHELINE_SIZE;  // Increment index
	}
	__DSB();
#else
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		tru_iom_wr32((uint32_t *)(L2C310_BASE + L2C310_INV_PA_OFFSET), addr);
		tru_iom_wr32((uint32_t *)(L2C310_BASE + L2C310_CACHE_SYNC_OFFSET), 0U);
		addr += CACHELINE_SIZE;  // Increment index
	}
	alt_cache_l2_sync();
	__dsb();
#endif
}

static inline void tru_l2_data_cleaninv_range(void *buf, uint32_t len){
#if(TRU_CMSIS == 1U)
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		L2C_CleanInvPa((void *)addr);  // Note, this also issues the L2 sync instruction, which will stall the slave port until completion, that is unless there is a L2 background operation in in progress
		addr += CACHELINE_SIZE;  // Increment index
	}
	__DSB();
#else
	uint32_t limit = (uint32_t)buf + len;
	uint32_t addr = (uint32_t)buf & ~(CACHELINE_SIZE - 1U);

	while(addr < limit){
		tru_iom_wr32((uint32_t *)(L2C310_BASE + L2C310_CLEANINV_PA_OFFSET), addr);
		tru_iom_wr32((uint32_t *)(L2C310_BASE + L2C310_CACHE_SYNC_OFFSET), 0U);
		addr += CACHELINE_SIZE;  // Increment index
	}
	alt_cache_l2_sync();
	__dsb();
#endif
}

#endif
