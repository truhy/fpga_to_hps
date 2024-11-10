################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include trulib/source/subdir.mk
-include streamer/source/subdir.mk
-include hwlib/src/hwmgr/soc_cv_av/subdir.mk
-include hwlib/src/hwmgr/subdir.mk
-include FreeRTOS/Source/portable/MemMang/subdir.mk
-include FreeRTOS/Source/portable/GCC/ARM_CA9/subdir.mk
-include FreeRTOS/Source/portable/Common/subdir.mk
-include FreeRTOS/Source/subdir.mk
-include CMSIS/Device/c5soc/source/subdir.mk
-include CMSIS/Core/Source/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(SX_DEPS)),)
-include $(SX_DEPS)
endif
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

OPTIONAL_TOOL_DEPS := \
$(wildcard ../makefile.defs) \
$(wildcard ../makefile.init) \
$(wildcard ../makefile.targets) \


BUILD_ARTIFACT_NAME := f2s_stream_bram
BUILD_ARTIFACT_EXTENSION := elf
BUILD_ARTIFACT_PREFIX :=
BUILD_ARTIFACT := $(BUILD_ARTIFACT_PREFIX)$(BUILD_ARTIFACT_NAME)$(if $(BUILD_ARTIFACT_EXTENSION),.$(BUILD_ARTIFACT_EXTENSION),)

# Add inputs and outputs from these tool invocations to the build variables 
SECONDARY_FLASH += \
f2s_stream_bram.bin \

SECONDARY_SIZE += \
f2s_stream_bram.siz \


# All Target
all: main-build

# Main-build Target
main-build: f2s_stream_bram.elf secondary-outputs

# Tool invocations
f2s_stream_bram.elf: $(OBJS) $(USER_OBJS) makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Building target: $@'
	@echo 'Invoking: GNU Arm Cross C Linker'
	arm-none-eabi-gcc -mcpu=cortex-a9 -marm -mfloat-abi=hard -mfpu=neon -mno-unaligned-access -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -T "D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\ldscript\tru_c5_ddr.ld" -Xlinker --gc-sections -Wl,-Map,"f2s_stream_bram.map" --specs=nosys.specs -o "f2s_stream_bram.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

f2s_stream_bram.bin: f2s_stream_bram.elf makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Invoking: GNU Arm Cross Create Flash Image'
	arm-none-eabi-objcopy -O binary "f2s_stream_bram.elf"  "f2s_stream_bram.bin"
	@echo 'Finished building: $@'
	@echo ' '

f2s_stream_bram.siz: f2s_stream_bram.elf makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Invoking: GNU Arm Cross Print Size'
	arm-none-eabi-size --format=berkeley "f2s_stream_bram.elf"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(SX_DEPS)$(OBJS)$(SECONDARY_FLASH)$(SECONDARY_SIZE)$(ASM_DEPS)$(S_UPPER_DEPS)$(C_DEPS) f2s_stream_bram.elf
	-@echo ' '

secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_SIZE)

.PHONY: all clean dependents main-build

-include ../makefile.targets
