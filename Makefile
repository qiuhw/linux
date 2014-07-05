AS86 = as86 -0 -a
LD86 = ld86 -0
AS = as
LD = ld
CC = gcc

CPP = $(CC) -E -nostdinc -Iinclude
CFLAGS = -Wall -Wextra -O -fstrength-reduce -fomit-frame-pointer -m32
LDFLAGS = -s -x -M -Ttext 0 -e startup_32 -m elf_i386

ARCHIVES = kernel/kernel.o mm/mm.o fs/fs.o
LIBS = lib/lib.a

LOOP_DEV := $(shell losetup -f)

.c.s:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -S -o $*.s $<
.s.o:
	$(AS) -32 -o $*.o $<
.c.o:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -c -o $*.o $<

all: Image hda.img

hda.img:
	dd if=/dev/zero of=$@ bs=1M seek=40 count=0
	echo ";" | sfdisk -H 4 -S 20 -C 1024 -D $@
	sudo losetup -o 10240 $(LOOP_DEV) $@
	sudo mkfs.minix -n 14 $(LOOP_DEV)
	mkdir tmp
	sudo mount $(LOOP_DEV) tmp
	sudo mkdir tmp/{bin,usr}
	@sleep 1
	sudo umount tmp
	sudo losetup -d $(LOOP_DEV)
	rmdir tmp

Image: tools/build boot/boot tools/system
	objcopy  -O binary -R .note -R .comment tools/system tools/system.bin
	tools/build boot/boot tools/system.bin > $@
	rm tools/system.bin

tools/build: tools/build.c
	$(CC) -Werror $(CFLAGS) -o $@ $<

boot/boot: boot/boot.s tools/system
	(echo -n "SYSSIZE = "; ls -l tools/system | awk '{print int(($$5+15)/16)}') > tmp.s
	cat $< >> tmp.s
	$(AS86) -o $*.o tmp.s
	rm tmp.s
	$(LD86) -s -o $@ $*.o

tools/system: boot/head.o init/main.o $(ARCHIVES) $(LIBS)
	$(LD) $(LDFLAGS) $^ -o $@ > System.map

boot/head.o: boot/head.s

kernel/kernel.o:
	(cd kernel; make)

mm/mm.o:
	(cd mm; make)

fs/fs.o:
	(cd fs; make)

$(LIBS):
	(cd lib; make)

clean:
	rm -f Image hda.img System.map boot/boot core tmp_make
	rm -f init/*.o boot/*.o tools/system tools/build
	(cd mm; make clean)
	(cd fs; make clean)
	(cd kernel; make clean)
	(cd lib; make clean)

dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in init/*.c; do echo -n "init/"; $(CPP) -M $$i; done) >> tmp_make
	cp tmp_make Makefile
	(cd fs; make dep)
	(cd kernel; make dep)
	(cd mm; make dep)

### Dependencies:
init/main.o: init/main.c include/unistd.h include/sys/stat.h \
 include/sys/types.h include/sys/times.h include/sys/utsname.h \
 include/utime.h include/time.h include/linux/tty.h include/termios.h \
 include/linux/sched.h include/linux/head.h include/linux/fs.h \
 include/linux/mm.h include/asm/system.h include/asm/io.h \
 include/stddef.h include/stdarg.h include/fcntl.h
