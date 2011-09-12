# Makefile for compiling libArduino
.SUFFIXES: .o .a .c .s

CHIP=__SAM3U4E__
VARIANT=arduino_due
LIBNAME=libarduino_$(VARIANT)
TOOLCHAIN=gcc

#-------------------------------------------------------------------------------
# Path
#-------------------------------------------------------------------------------

# Output directories
#OUTPUT_BIN = ../lib
OUTPUT_BIN = ..

# Libraries
PROJECT_BASE_PATH = ..
SYSTEM_PATH = ../../../system
CMSIS_PATH = $(SYSTEM_PATH)/CMSIS/Include
VARIANT_PATH = ../../../variants/$(VARIANT)

#-------------------------------------------------------------------------------
# Files
#-------------------------------------------------------------------------------

vpath %.h $(PROJECT_BASE_PATH) $(SYSTEM_PATH) $(VARIANT_PATH)
vpath %.c $(PROJECT_BASE_PATH) $(VARIANT_PATH)
vpath %.cpp $(PROJECT_BASE_PATH) $(PROJECT_BASE_PATH)

VPATH+=$(PROJECT_BASE_PATH)

INCLUDES =
INCLUDES += -I$(PROJECT_BASE_PATH)
INCLUDES += -I$(SYSTEM_PATH)
INCLUDES += -I$(SYSTEM_PATH)/libsam
INCLUDES += -I$(VARIANT_PATH)
INCLUDES += -I$(CMSIS_PATH)

#-------------------------------------------------------------------------------
ifdef DEBUG
include debug.mk
else
include release.mk
endif

#-------------------------------------------------------------------------------
# Tools
#-------------------------------------------------------------------------------

include $(TOOLCHAIN).mk

#-------------------------------------------------------------------------------
ifdef DEBUG
OUTPUT_OBJ=debug
OUTPUT_LIB=$(LIBNAME)_$(TOOLCHAIN)_dbg.a
else
OUTPUT_OBJ=release
OUTPUT_LIB=$(LIBNAME)_$(TOOLCHAIN)_rel.a
endif

OUTPUT_PATH=$(OUTPUT_OBJ)_$(VARIANT)

#-------------------------------------------------------------------------------
# C source files and objects
#-------------------------------------------------------------------------------
C_SRC=$(wildcard $(PROJECT_BASE_PATH)/*.c)

C_OBJ_TEMP = $(patsubst %.c, %.o, $(notdir $(C_SRC)))

# during development, remove some files
C_OBJ_FILTER=wiring_analog.o wiring_pulse.o dlib_lowlevel_sam3.o

C_OBJ=$(filter-out $(C_OBJ_FILTER), $(C_OBJ_TEMP))

#-------------------------------------------------------------------------------
# CPP source files and objects
#-------------------------------------------------------------------------------
CPP_SRC=$(wildcard $(PROJECT_BASE_PATH)/*.cpp)

CPP_OBJ_TEMP = $(patsubst %.cpp, %.o, $(notdir $(CPP_SRC)))

# during development, remove some files
CPP_OBJ_FILTER=Tone.o

CPP_OBJ=$(filter-out $(CPP_OBJ_FILTER), $(CPP_OBJ_TEMP))

#-------------------------------------------------------------------------------
# Assembler source files and objects
#-------------------------------------------------------------------------------
A_SRC=$(wildcard $(PROJECT_BASE_PATH)/*.s)

A_OBJ_TEMP=$(patsubst %.s, %.o, $(notdir $(A_SRC)))

# during development, remove some files
A_OBJ_FILTER=

A_OBJ=$(filter-out $(A_OBJ_FILTER), $(A_OBJ_TEMP))

#-------------------------------------------------------------------------------
# Rules
#-------------------------------------------------------------------------------
all: $(VARIANT)

$(VARIANT): create_output $(OUTPUT_LIB)

.PHONY: create_output
create_output:
	@echo --- Preparing $(VARIANT) files in $(OUTPUT_PATH) $(OUTPUT_BIN) 
	@echo -------------------------
	@echo *$(INCLUDES)
	@echo -------------------------
	@echo *$(C_SRC)
	@echo -------------------------
	@echo *$(C_OBJ)
	@echo -------------------------
	@echo *$(addprefix $(OUTPUT_PATH)/, $(C_OBJ))
	@echo -------------------------
	@echo *$(CPP_SRC)
	@echo -------------------------
	@echo *$(CPP_OBJ)
	@echo -------------------------
	@echo *$(addprefix $(OUTPUT_PATH)/, $(CPP_OBJ))
	@echo -------------------------
	@echo *$(A_SRC)
	@echo -------------------------

#	-@mkdir $(subst /,$(SEP),$(OUTPUT_BIN)) 1>NUL 2>&1
	-mkdir $(subst /,$(SEP),$(OUTPUT_BIN))
	-@mkdir $(OUTPUT_PATH) 1>NUL 2>&1

$(addprefix $(OUTPUT_PATH)/,$(C_OBJ)): $(OUTPUT_PATH)/%.o: %.c
#	@$(CC) -v -c $(CFLAGS) $< -o $@
	@$(CC) -c $(CFLAGS) $< -o $@

$(addprefix $(OUTPUT_PATH)/,$(CPP_OBJ)): $(OUTPUT_PATH)/%.o: %.cpp
#	@$(CC) -c $(CPPFLAGS) $< -o $@
	@$(CC) -xc++ -c $(CPPFLAGS) $< -o $@

$(addprefix $(OUTPUT_PATH)/,$(A_OBJ)): $(OUTPUT_PATH)/%.o: %.s
	@$(AS) -c $(ASFLAGS) $< -o $@

$(OUTPUT_LIB): $(addprefix $(OUTPUT_PATH)/, $(C_OBJ)) $(addprefix $(OUTPUT_PATH)/, $(CPP_OBJ)) $(addprefix $(OUTPUT_PATH)/, $(A_OBJ))
	@$(AR) -v -r "$(OUTPUT_BIN)/$@" $^
	@$(NM) "$(OUTPUT_BIN)/$@" > "$(OUTPUT_BIN)/$@.txt"


.PHONY: clean
clean:
	@echo --- Cleaning $(VARIANT) files [$(OUTPUT_PATH)$(SEP)*.o]
	-@$(RM) $(OUTPUT_PATH) 1>NUL 2>&1
	-@$(RM) $(OUTPUT_BIN)/$(OUTPUT_LIB) 1>NUL 2>&1
