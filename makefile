
kernel: kernel.asm include/bios.inc
	asm02 -L -b kernel.asm

clean:
	-rm kernel.bin
	-rm kernel.lst


