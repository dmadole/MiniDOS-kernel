# Elf/OS Classic

This is a branch of Mike Riley's fantastic disk operating system for the 1802
processor to carry on with enhancements to the 4.0 version series.  

The current version is 4.2.0 which is a development version which will become
a 4.2.1 release version when ready.

The current changes in this branch from the 4.1.0 release are:

1. Changed to build using asm02 instead of rcasm
2. No longer overwrites memory from $0000-000F
3. Removes variable-sized AU support from kernel
4. Integrates turbo filesystem speed improvements

Besides adding enhancements, the Elf/OS Classic branch seeks to maintain
maximum compatibility with existing software, BIOS, and hardware.

