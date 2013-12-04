AS = as
LD = ld
CC = gcc
TARGET_MACH := -32
TARGET_ARCH := -m32
CPPFLAGS := -MMD -MP -nostdinc -I../include
CFLAGS := -Wall -Wextra -O -fstrength-reduce -fomit-frame-pointer -finline-functions

OBJS := console.o \
		exit.o \
		fork.o \
		hd.o \
		mktime.o \
		panic.o \
		printk.o \
		sched.o \
		serial.o \
		sys.o \
		traps.o \
		tty_io.o \
		vsprintf.o
DEPS := $(OBJS:.o=.d)
OBJS += asm.o \
		keyboard.o \
		rs_io.o \
		system_call.o

kernel.o: $(OBJS)
	$(LD) -m elf_i386 -r -o $@ $^

-include $(DEPS)

asm.o: asm.s

keyboard.o: keyboard.s

rs_io.o: rs_io.s

system_call.o: system_call.s

clean:
	$(RM) core *.o

distclean: clean
	$(RM) *.d

.PHONY: clean distclean
