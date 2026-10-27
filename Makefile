# Target board to build for, dynamic based on board selection
FORKNAME	?=	MAGISV2
TARGET ?= 
FW_Version ?= 
PROJECT ?=
FLASH_SIZE ?= 
API_Version ?=
RAM_SIZE 	?=
# Debugger options, must be empty or GDB
DEBUG ?= 

# Compile-time options
OPTIONS ?= '__FORKNAME__="$(FORKNAME)"' \
		   			'__TARGET__="$(TARGET)"' \
			 			'__FW_VER__="$(FW_Version)"' \
		   			'__API_VER__="$(API_Version)"' \
		   			'__PROJECT__="$(PROJECT)"' \
        		'__BUILD_DATE__="$(shell date +%d-%m-%Y)"' \
        		'__BUILD_TIME__="$(shell date +%H:%M:%S)"' \

VALID_TARGETS = PLUTOX PRIMUSX PRIMUSX2 PRIMUS_V5 PRIMUS_X2_v1

ifeq ($(FLASH_SIZE),)
ifeq ($(TARGET),$(filter $(TARGET),PLUTOX PRIMUSX PRIMUSX2 PRIMUS_V5 PRIMUS_X2_v1))
FLASH_SIZE = 256
RAM_SIZE 	= 40
else
$(error FLASH_SIZE not configured for target)
endif
endif

# Define the root directory for source and object files
ROOT = $(Prj_Dir)
# Conditional assignment based on the TARGET board

SRC_DIR = $(ROOT)
BUILD_DIR = $(ROOT)/Build
PLATFORM_DIR = $(ROOT)/API
CMSIS_DIR = $(ROOT)/lib/main/CMSIS
INCLUDE_DIRS	 = $(SRC_DIR)
LINKER_DIR	 = $(Linker_LD)
LIB_DIR = $(LIB_DIR_C)
VERSION_DIR = $(LIB_DIR)/version
$(shell mkdir -p /tmp >/dev/null 2>&1 || true)

# Function to find all source files
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# ROOT sources (kept relative to ROOT)
ROOT_SOURCES := $(subst $(ROOT)/,, $(call rwildcard,$(SRC_DIR)/,*.cpp))


ifeq ($(TARGET),$(filter $(TARGET),PRIMUSX2 PRIMUS_V5 PRIMUS_X2_v1))
# External LIB sources (kept as full paths for now)
LIB_SOURCES  := $(call rwildcard,$(LIB_DIR)/,*.cpp)
else
LIB_SOURCES  := $(subst $(ROOT)/,, $(call rwildcard, $(LIB_DIR)/,*.cpp))
endif
# If you still want a combined list for printing/debug:
CSOURCES := $(ROOT_SOURCES) \
						$(LIB_SOURCES)

# Include directories for the platform headers
DIRECTORY = $(sort $(dir $(call rwildcard, $(PLATFORM_DIR)/,*.*)))
INCLUDE_DIRS := $(DIRECTORY)

# Include directories for source headers
DIRECTORY = $(sort $(dir $(call rwildcard, $(SRC_DIR)/,*.*)))
INCLUDE_DIRS := $(INCLUDE_DIRS) \
                $(DIRECTORY)

ifeq ($(TARGET),$(filter $(TARGET),PRIMUSX2 PRIMUS_V5 PRIMUS_X2_v1))
# Include directories for library headers too
LIB_INCLUDE_DIRS = $(sort $(dir $(call rwildcard, $(LIB_DIR)/,*.*)))
INCLUDE_DIRS := $(INCLUDE_DIRS) $(LIB_INCLUDE_DIRS)
endif

# Linker script path
LD_SCRIPT = $(LINKER_DIR)/stm32_flash_f303_$(FLASH_SIZE)k.ld

# Architecture flags for the STM32
ARCH_FLAGS = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 -fsingle-precision-constant -Wdouble-promotion
DEVICE_FLAGS = -DSTM32F303xC -DSTM32F303
TARGET_FLAGS = -D$(TARGET)

# Define flags for GCC
ifneq ($(FLASH_SIZE),)
  DEVICE_FLAGS := $(DEVICE_FLAGS) -DFLASH_SIZE=$(FLASH_SIZE)
endif

# Set the compilers based on the platform
CC = arm-none-eabi-g++
C = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
SIZE = arm-none-eabi-size
MKDIR = mkdir
ECHO = echo


# Optimization flags for debugging and release
ifeq ($(DEBUG),GDB)
  OPTIMIZE = -O0
  LTO_FLAGS = $(OPTIMIZE)
else
  OPTIMIZE = -Os
  LTO_FLAGS = $(OPTIMIZE)
endif

DEBUG_FLAGS = -ggdb3 -DDEBUG

# Compiler flags
CFLAGS = $(ARCH_FLAGS) \
         $(LTO_FLAGS) \
         $(addprefix -D,$(OPTIONS)) \
         $(addprefix -I,$(INCLUDE_DIRS)) \
         $(DEBUG_FLAGS) \
         -std=gnu17 \
         -Wall -Wextra -Wunsafe-loop-optimizations -Wdouble-promotion \
         -ffunction-sections \
         -fdata-sections \
         -fno-lto \
         $(DEVICE_FLAGS) \
         -DUSE_STDPERIPH_DRIVER \
         $(TARGET_FLAGS) \
         -D'__TARGET__="$(TARGET)"' \
         -MMD -MP

# C++ Compiler flags
CCFLAGS = $(ARCH_FLAGS) \
          $(LTO_FLAGS) \
          $(addprefix -D,$(OPTIONS)) \
          $(addprefix -I,$(INCLUDE_DIRS)) \
          $(DEBUG_FLAGS) \
          -std=gnu++17 \
          -Wall -Wextra -Wunsafe-loop-optimizations -Wdouble-promotion \
          -ffunction-sections \
          -fdata-sections \
          -fno-lto \
          $(DEVICE_FLAGS) \
          -DUSE_STDPERIPH_DRIVER \
          $(TARGET_FLAGS) \
          -D'__TARGET__="$(TARGET)"' \
          -MMD -MP

# Assembler flags
ASFLAGS = $(ARCH_FLAGS) \
          -x assembler-with-cpp \
          $(addprefix -I,$(INCLUDE_DIRS)) \
          -MMD -MP

# Linker flags
LDFLAGS = -lm \
          -nostartfiles \
          --specs=nosys.specs \
          -lc \
          -lnosys \
          $(ARCH_FLAGS) \
          $(LTO_FLAGS) \
          $(DEBUG_FLAGS) \
          -static \
          -L$(LIB_DIR) -l$(TARGET)_$(FW_Version) \
          -Wl,-gc-sections,-Map,$(TARGET_MAP) \
          -Wl,-L$(LINKER_DIR) \
          -T$(LD_SCRIPT)

# Check if the target is valid
ifeq ($(filter $(TARGET),$(VALID_TARGETS)),)
  $(error Target '$(TARGET)' is not valid, must be one of $(VALID_TARGETS))
endif

# Binary output paths
TARGET_BIN = $(BUILD_DIR)/$(TARGET)/$(TARGET).bin
TARGET_HEX = $(BUILD_DIR)/$(TARGET)/$(PROJECT)_$(TARGET)_$(FW_Version).hex
TARGET_ELF = $(BUILD_DIR)/$(TARGET)/$(TARGET).elf
TARGET_MAP = $(BUILD_DIR)/$(TARGET)/$(TARGET).map
# TARGET_OBJS = $(addsuffix .o,$(addprefix $(BUILD_DIR)/$(TARGET)/bin/,$(basename $(CSOURCES))))
# Objects for ROOT sources
ROOT_OBJS := $(addsuffix .o,$(addprefix $(BUILD_DIR)/$(TARGET)/bin/,$(basename $(ROOT_SOURCES))))

# Objects for LIB sources go into a safe folder (no drive letters in names)
LIB_REL_SOURCES := $(patsubst $(LIB_DIR)/%,%,$(LIB_SOURCES))
LIB_OBJS := $(addsuffix .o,$(addprefix $(BUILD_DIR)/$(TARGET)/bin/,$(basename $(LIB_REL_SOURCES))))

ifeq ($(TARGET),$(filter $(TARGET),PRIMUSX2 PRIMUS_V5 PRIMUS_X2_v1))
TARGET_OBJS := $(ROOT_OBJS) $(LIB_OBJS)
else
TARGET_OBJS := $(ROOT_OBJS)
endif
TARGET_DEPS = $(addsuffix .d,$(addprefix $(BUILD_DIR)/$(TARGET)/bin/,$(basename $(TARGET)_SRC)))
TOTAL_FILES := $(shell echo $$(($(words $(TARGET_OBJS)) + 2)))
COMPILED_COUNT = 0

define progress_echo
  $(eval COMPILED_COUNT=$(shell echo $$(($(COMPILED_COUNT)+1))))
  @printf "\033[1;32m[%3d %%]\033[0m %s\n" \
    $$(($(COMPILED_COUNT) * 100 / $(TOTAL_FILES))) \
    "$(notdir $<)"
endef

define progress_step
  $(eval COMPILED_COUNT=$(shell echo $$(($(COMPILED_COUNT)+1))))
  @printf "\033[1;32m[%3d %%]\033[0m %s\n" \
    $$(($(COMPILED_COUNT) * 100 / $(TOTAL_FILES))) \
    "$1"
endef

# Final output
# $(info $(TARGET_OBJS))

# Target Hex
$(TARGET_HEX): $(TARGET_ELF)
	$(call progress_step,Generating HEX file...)
	$(OBJCOPY) -O ihex --set-start 0x8000000 $< $@

# Target Binary
$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) -O binary $< $@

# Target ELF
$(TARGET_ELF): $(TARGET_OBJS)
	$(call progress_step,Linking firmware...)
	$(CC) -o $@ $^ $(LDFLAGS)
	$(SIZE) $(TARGET_ELF)
	@{ \
	echo "=========== MEMORY SUMMARY ===========" ; \
	set -- $$($(SIZE) --format=berkeley $(abspath $(TARGET_ELF)) | sed -n '2p'); \
	TEXT=$$1; DATA=$$2; BSS=$$3; \
	FLASH_USED_B=$$((TEXT + DATA)); \
	RAM_USED_B=$$((DATA + BSS)); \
	FLASH_TOTAL_B=$$(( $(FLASH_SIZE) * 1024 )); \
	RAM_TOTAL_B=$$(( $(RAM_SIZE) * 1024 )); \
	BAR_WIDTH=30; \
	FLASH_PCT=$$((FLASH_USED_B * 100 / FLASH_TOTAL_B)); \
	RAM_PCT=$$((RAM_USED_B * 100 / RAM_TOTAL_B)); \
	FLASH_FILL=$$((FLASH_PCT * BAR_WIDTH / 100)); \
	RAM_FILL=$$((RAM_PCT * BAR_WIDTH / 100)); \
	FLASH_EMPTY=$$((BAR_WIDTH - FLASH_FILL)); \
	RAM_EMPTY=$$((BAR_WIDTH - RAM_FILL)); \
	FLASH_KB_INT=$$((FLASH_USED_B / 1024)); \
	FLASH_KB_DEC=$$(( (FLASH_USED_B % 1024) * 10 / 1024 )); \
	RAM_KB_INT=$$((RAM_USED_B / 1024)); \
	RAM_KB_DEC=$$(( (RAM_USED_B % 1024) * 10 / 1024 )); \
	printf "Flash [%.*s%.*s] %d%%  (%d.%d KB / %d KB)\n" \
		$$FLASH_FILL "##############################" \
		$$FLASH_EMPTY "                              " \
		$$FLASH_PCT $$FLASH_KB_INT $$FLASH_KB_DEC $(FLASH_SIZE); \
	printf "RAM   [%.*s%.*s] %d%%  (%d.%d KB / %d KB)\n" \
		$$RAM_FILL "##############################" \
		$$RAM_EMPTY "                              " \
		$$RAM_PCT $$RAM_KB_INT $$RAM_KB_DEC $(RAM_SIZE); \
	echo "===================================="; \
	}

# Compile C++ source files
$(BUILD_DIR)/$(TARGET)/bin/%.o: %.cpp
	@$(MKDIR) -p $(dir $@)
	$(call progress_echo)
	@$(CC) -c -o $@ $(CCFLAGS) $<

ifeq ($(TARGET),$(filter $(TARGET),PRIMUSX2 PRIMUS_V5 PRIMUS_X2_v1))
$(BUILD_DIR)/$(TARGET)/bin/%.o: $(LIB_DIR)/%.cpp
	@$(MKDIR) -p $(dir $@)
	$(call progress_echo)
	@$(CC) -c -o $@ $(CCFLAGS) $<
endif
# Compile C source files
$(BUILD_DIR)/$(TARGET)/bin/%.o: %.c
	@$(MKDIR) -p $(dir $@)
	$(call progress_echo)
	@$(C) -c -o $@ $(CFLAGS) $<

# Assemble source files
$(BUILD_DIR)/$(TARGET)/bin/%.o: %.s
	@$(MKDIR) -p $(dir $@)
	$(call progress_echo)
	@$(CC) -c -o $@ $(ASFLAGS) $<

$(BUILD_DIR)/$(TARGET)/bin/%.o: %.S
	@$(MKDIR) -p $(dir $@)
	$(call progress_echo)
	@$(CC) -c -o $@ $(ASFLAGS) $<

# All task

all: binary

# Clean all build files
clean:
	rm -f $(TARGET_BIN) $(TARGET_HEX) $(TARGET_ELF)  $(TARGET_MAP)
	rm -rf $(BUILD_DIR)/$(TARGET)
	cd src/test && $(MAKE) clean || true

# Binary creation task
binary: $(TARGET_HEX)

# Include dependencies
-include $(TARGET_DEPS)
