################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../freertos_c5soc.c \
../main.c 

OBJS += \
./freertos_c5soc.o \
./main.o 

C_DEPS += \
./freertos_c5soc.d \
./main.d 


# Each subdirectory must supply rules for building sources it contributes
%.o: ../%.c subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU Arm Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-a9 -marm -mfloat-abi=hard -mfpu=neon -mno-unaligned-access -O2 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g -Dsoc_cv_av -DCYCLONEV -DALT_INT_PROVISION_VECTOR_SUPPORT=0 -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\bsp" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\hwlib\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\hwlib\include\soc_cv_av" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\trulib\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\streamer\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\FreeRTOS\Source\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\FreeRTOS\Source\portable\GCC\ARM_CA9" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\CMSIS\Core\Include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\CMSIS\Core\Include\a-profile" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\f2s_stream_bram_20250421\f2s_stream_bram_c\source\CMSIS\Device\c5soc\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


