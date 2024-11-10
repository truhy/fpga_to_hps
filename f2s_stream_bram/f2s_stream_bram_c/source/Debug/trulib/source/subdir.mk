################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../trulib/source/tru_c5soc_hps_uart_ll.c \
../trulib/source/tru_cache.c \
../trulib/source/tru_etu.c \
../trulib/source/tru_irq.c \
../trulib/source/tru_newlib_ext.c \
../trulib/source/tru_startup.c \
../trulib/source/tru_util.c 

OBJS += \
./trulib/source/tru_c5soc_hps_uart_ll.o \
./trulib/source/tru_cache.o \
./trulib/source/tru_etu.o \
./trulib/source/tru_irq.o \
./trulib/source/tru_newlib_ext.o \
./trulib/source/tru_startup.o \
./trulib/source/tru_util.o 

C_DEPS += \
./trulib/source/tru_c5soc_hps_uart_ll.d \
./trulib/source/tru_cache.d \
./trulib/source/tru_etu.d \
./trulib/source/tru_irq.d \
./trulib/source/tru_newlib_ext.d \
./trulib/source/tru_startup.d \
./trulib/source/tru_util.d 


# Each subdirectory must supply rules for building sources it contributes
trulib/source/%.o: ../trulib/source/%.c trulib/source/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU Arm Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-a9 -marm -mfloat-abi=hard -mfpu=neon -mno-unaligned-access -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -DDEBUG -Dsoc_cv_av -DCYCLONEV -DALT_INT_PROVISION_VECTOR_SUPPORT=0 -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\bsp" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\hwlib\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\hwlib\include\soc_cv_av" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\trulib\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\streamer\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\FreeRTOS\Source\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\FreeRTOS\Source\portable\GCC\ARM_CA9" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\CMSIS\Core\Include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\CMSIS\Core\Include\a-profile" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\CMSIS\Device\c5soc\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


