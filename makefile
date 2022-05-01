# Copyright 2016 The Fuchsia Authors
#
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT


include macros.mk

NOECHO ?= @

#GET_LOCAL_DIR    = $(patsubst %/,%,$(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))

LOCAL_DIR := $(GET_LOCAL_DIR)

BUILDDIR := $(LOCAL_DIR)/build

EFI_ARCH ?= x86_64

TOOLCHAIN_PREFIX:=x86_64-linux-gnu-

EFI_CC := $(TOOLCHAIN_PREFIX)gcc
EFI_LD := $(TOOLCHAIN_PREFIX)ld
OBJCOPY := $(TOOLCHAIN_PREFIX)objcopy
READELF := $(TOOLCHAIN_PREFIX)readelf
NM := $(TOOLCHAIN_PREFIX)nm

ifeq ($(EFI_ARCH),x86_64)
ARCH_CFLAGS :=
EFI_LINKSCRIPT := $(LOCAL_DIR)/build/efi-x86-64.lds
else ifeq ($(EFI_ARCH),x86)
ARCH_CFLAGS += -m32 -march=i686
ARCH_LDFLAGS += -melf_i386
EFI_LINKSCRIPT := $(LOCAL_DIR)/build/efi-x86.lds
endif

LIBGCC := $(shell $(TOOLCHAIN_PREFIX)gcc $ $(ARCH_CFLAGS) -print-libgcc-file-name)
$(info LIBGCC $(LIBGCC))
$(info LOCAL_DIR $(LOCAL_DIR))

#EFI_LIBDIRS := system/ulib/tftp

EFI_CFLAGS += $(ARCH_CFLAGS) -g -O2 \
			  -fPIE -fno-stack-protector \
			   -nostdinc -Wall -fshort-wchar \
			   -std=c99 -ffreestanding \
			   -mno-red-zone

EFI_CFLAGS += -I$(LOCAL_DIR)/src \
			  -I$(LOCAL_DIR)/include \
			  -I$(LOCAL_DIR)/include/efi \
			  -I$(LOCAL_DIR)/lib/include

#EFI_CFLAGS += $(foreach LIBDIR,$(EFI_LIBDIRS),-I$(LIBDIR)/include)

EFI_CFLAGS += -DTFTP_EFILIB

EFI_LDFLAGS += $(ARCH_LDFLAGS)
EFI_LDFLAGS += -nostdlib -T $(EFI_LINKSCRIPT) -pie

EFI_SECTIONS := .text .data .reloc
EFI_SECTIONS := $(patsubst %,-j %,$(EFI_SECTIONS))

ifeq ($(EFI_ARCH),x86_64)
EFI_SO          := $(BUILDDIR)/bootx64.so
EFI_BOOTLOADER  := $(BUILDDIR)/bootx64.efi
else ifeq ($(EFI_ARCH),x86)
EFI_SO          := $(BUILDDIR)/bootia32.so
EFI_BOOTLOADER  := $(BUILDDIR)/bootia32.efi
else ifeq ($(EFI_ARCH),aarch64)
EFI_SO          := $(BUILDDIR)/bootaa64.so
EFI_BOOTLOADER  := $(BUILDDIR)/bootaa64.efi
endif

# Bootloader sources
#EFI_SOURCES := \
#    $(LOCAL_DIR)/src/osboot.c \
#    $(LOCAL_DIR)/src/cmdline.c \
#    $(LOCAL_DIR)/src/zircon.c \
#    $(LOCAL_DIR)/src/misc.c \
#    $(LOCAL_DIR)/src/netboot.c \
#    $(LOCAL_DIR)/src/netifc.c \
#    $(LOCAL_DIR)/src/inet6.c \
#    $(LOCAL_DIR)/src/pci.c \
#    $(LOCAL_DIR)/src/framebuffer.c \
#    $(LOCAL_DIR)/src/device_id.c \

EFI_SOURCES := \
    $(LOCAL_DIR)/src/osboot.c \
    $(LOCAL_DIR)/src/cmdline.c \
    $(LOCAL_DIR)/src/zircon.c \
    $(LOCAL_DIR)/src/misc.c \
    $(LOCAL_DIR)/src/netboot.c \
    $(LOCAL_DIR)/src/netifc.c \
    $(LOCAL_DIR)/src/inet6.c \
    $(LOCAL_DIR)/src/pci.c \
    $(LOCAL_DIR)/src/framebuffer.c \
    $(LOCAL_DIR)/src/device_id.c \


# libxefi sources
EFI_SOURCES += \
    $(LOCAL_DIR)/lib/efi/guids.c \
    $(LOCAL_DIR)/lib/inet.c \
    $(LOCAL_DIR)/lib/xefi.c \
    $(LOCAL_DIR)/lib/loadfile.c \
    $(LOCAL_DIR)/lib/console-printf.c \
    $(LOCAL_DIR)/lib/ctype.c \
    $(LOCAL_DIR)/lib/printf.c \
    $(LOCAL_DIR)/lib/stdlib.c \
    $(LOCAL_DIR)/lib/string.c \
	$(LOCAL_DIR)/lib/tftp/tftp.c \
    $(LOCAL_DIR)/lib/strings.c



ASM_SOURCES += $(LOCAL_DIR)/src/asm.S

ASM_OBJS := $(patsubst $(LOCAL_DIR)/%.S,$(BUILDDIR)/%.S.o,$(ASM_SOURCES))
EFI_OBJS := $(patsubst $(LOCAL_DIR)/%.c,$(BUILDDIR)/%.c.o,$(EFI_SOURCES))
#$(info EFI_OBJS $(EFI_OBJS))
EFI_DEPS := $(patsubst %.c.o,%.c.d,$(EFI_OBJS))
#$(info EFI_DEPS $(EFI_DEPS))
#EFI_LIBS := $(foreach LIBDIR,$(EFI_LIBDIRS), \
#                 $(BUILDDIR)/EFI_libs/lib$(notdir $(LIBDIR)).a)

$(shell mkdir -p $(dir $(EFI_DEPS)))

$(BUILDDIR)/%.S.o : $(LOCAL_DIR)/%.S
	$(EFI_CC) -o $@ -c $(EFI_OPTFLAGS) $(EFI_COMPILEFLAGS) $(EFI_CFLAGS) $<

.PHONY: gigaboot clean

gigaboot: $(EFI_BOOTLOADER)

$(BUILDDIR)/%.c.o : $(LOCAL_DIR)/%.c
	@$(MKDIR)
	$(call BUILDECHO,compiling $<)
	$(EFI_CC) $(EFI_OPTFLAGS) $(EFI_COMPILEFLAGS) $(EFI_CFLAGS) -c $< -MMD -MP -MT $@ -MF $(@:%o=%d) -o $@

# -c $< -MMD -MP -MT $@ -MF $(@:%o=%d) -o $@

#$(EFI_SO): $(EFI_OBJS) $(EFI_LIBS)
$(EFI_SO): $(EFI_OBJS) $(ASM_OBJS)
	@$(MKDIR)
	$(call BUILDECHO,linking $@)
	$(EFI_LD) $(EFI_LDFLAGS) -o $@ $^ $(LIBGCC)
	$(NOECHO)if ! $(READELF) -r $@ | grep -q 'no relocations'; then \
	    echo "error: $@ has relocations"; \
	    $(READELF) -r $@; \
	    exit 1;\
	fi

# TODO: update this to build other ARCHes
$(EFI_BOOTLOADER): $(EFI_SO)
	@$(MKDIR)
	$(call BUILDECHO,building $@)
	$(NOECHO)$(OBJCOPY) --target=pei-x86-64 --subsystem 10 $(EFI_SECTIONS) $< $@
	$(NOECHO)if [ "`$(NM) $< | grep ' U '`" != "" ]; then echo "error: $<: undefined symbols"; $(NM) $< | grep ' U '; rm $<; exit 1; fi


GENERATED += $(EFI_BOOTLOADER)


clean:
	rm -rf $(EFI_BOOTLOADER) $(EFI_SO) $(EFI_OBJS) $(EFI_DEPS) $(ASM_OBJS)

ifeq ($(call TOBOOL,$(ENABLE_ULIB_ONLY)),false)
# x86 only by default for now
ifeq ($(ARCH),x86)
bootloader: gigaboot
all:: bootloader
endif
endif

-include $(EFI_DEPS)

