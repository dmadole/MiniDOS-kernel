
kernel: kernel.asm bios.inc
	asm02 -L -b kernel.asm

fixed32k: kernel.asm bios.inc
	asm02 -L -b -DFIXED32K kernel.asm

clean:
	-rm kernel.bin


