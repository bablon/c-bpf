
CC = gcc
CFLAGS = -g -Wall -O2
LDFLAGS = -lelf -lbpf

CLANG ?= clang
LLC ?= llc

progs = cpustat offwaketime
bpf_objs = $(progs:=_kern.o)

all : $(progs) $(bpf_objs)

cpustat: cpustat_user.o bpf_load.o
	$(CC) -o $@ $^ $(LDFLAGS)
offwaketime: offwaketime_user.o bpf_load.o trace_helpers.o
	$(CC) -o $@ $^ $(LDFLAGS)

SRCARCH ?= x86
KBUILD = /lib/modules/$(shell uname -r)/build
KSRC = /lib/modules/$(shell uname -r)/source

KUSERINCLUDE    := \
                -I$(KSRC)/arch/$(SRCARCH)/include/uapi \
                -I$(KBUILD)/arch/$(SRCARCH)/include/generated/uapi \
                -I$(KSRC)/include/uapi \
                -I$(KBUILD)/include/generated/uapi \
                -include $(KSRC)/include/linux/kconfig.h

KLINUXINCLUDE := \
                -I$(KSRC)/arch/$(SRCARCH)/include \
                -I$(KBUILD)/arch/$(SRCARCH)/include/generated \
                -I$(KSRC)/include \
                -I$(KBUILD)/include \
                $(KUSERINCLUDE)

NOSTDINC_FLAGS := -nostdinc -isystem $(shell $(CC) -print-file-name=include)
BPF_EXTRA_CFLAGS := -g
LLC_FLAGS =

ifdef CROSS_COMPILE
CLANG_ARCH_ARGS = --target=$(notdir $(CROSS_COMPILE:%-=%))
endif

kernver=$(shell uname -r | cut -f 1-2 -d '.')

bpf_helper_defs.h: $(KSRC)/include/uapi/linux/bpf.h
	scripts/bpf_doc-$(kernver).py --header --file $< > $@

%_kern.o : %_kern.c bpf_helper_defs.h
	clang $(NOSTDINC_FLAGS) $(KLINUXINCLUDE) $(BPF_EXTRA_CFLAGS) -I. \
		-D__KERNEL__ -D__BPF_TRACING__ -Wno-unused-value -Wno-pointer-sign \
		-D__TARGET_ARCH_$(SRCARCH) -Wno-compare-distinct-pointer-types \
		-Wno-gnu-variable-sized-type-not-at-end \
		-Wno-address-of-packed-member -Wno-tautological-compare \
		-Wno-unknown-warning-option $(CLANG_ARCH_ARGS) \
		-include asm_goto_workaround.h \
		-O2 -emit-llvm -c $< -o -| $(LLC) -march=bpf $(LLC_FLAGS) -filetype=obj -o $@

.PHONY: clean

clean:
	$(RM) -f *.o $(progs) bpf_helper_defs.h
