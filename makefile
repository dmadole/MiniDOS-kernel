
kernel.bin: kernel.asm bios.inc
	asm02 -L -b kernel.asm

clean:
	-rm kernel.bin


