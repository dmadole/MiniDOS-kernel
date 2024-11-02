# Mini/DOS

Mini/DOS is a disk operating system for CDP1802-based computers that provides basic file system and memory manager services. It requires a compatible BIOS and a minimum of 16K of RAM, although 32K would be considered the baseline.

### History

Mini/DOS is based on the Elf/OS operating system written by Mike Riley, and was forked from his branch at version 4.1 after he announced he would be pausing his development efforts indefinitely. [^1]

On July 20, 2022, the new branch was named Elf/OS Classic and a snapshot release 4.2.0 was packaged with some initial changes including incorporation of previously-developed code to improve filesytem performance. [^2]

Development progressed, including cleaning up of existing code, removal of code that was never executed, and addition of some notable new features and performance improvements.

The first major feature added was support for multiple disk drives, first available in a test release 4.2.1.166 on January 12, 2023. [^3]

Support for volume labels and addressing drives by name was added in a test release 4.3.1.254 on December 30, 2023. [^4]

Further development focused on improving performance through re-write of code to remove unnecessary drive accesses, and addition of metadata caching and by other methods.

In October 24, 2024, Mike Riley asked that the Elf/OS Classic project be renamed to no longer use the Elf/OS name. [^5] As of November 1, 2024, the project has been renamed Mini/DOS (or MDOS for short).

### Objectives

Continued development of Mini/DOS has been under a few high-level guidelines:

1. **Continued Development and Improvement:** Mini/DOS strives for continued development and addition of new features and bug fixes, and incorporation of code from others who are interested in contributing.

2. **Maximum Backward Compatibility:** The Elf/OS 4 API addressed most of a major deficiencies in prior versions, and so Mini/DOS aims to standardize on this version of the API and maintain backward compatibility with applications to the fullest extent possible.

3. **Highest Possible Performance:** The 1802 is a capable but not fast processor. It's simple architecture and limited instruction set serve it well, but require well-tuned software with thoughtful algorithms to achieve performance on-par with it's contemporaries.

4. **Completeness of Functionality:** While Mini/DOS is a simple and limited operating system supporting only filesystem operations and basic memory management, there are certain features that are standard expencations of any operating system that need to be addressed, such as multiple disk support.

### Current Status

Mini/DOS 4.3 is a stable and compatible replacement for Elf/OS offering improved performance and additional features. Multiple drive support is complemented by utilities to create and copy filesystems and provides the ability to backup and maintain a system as would be expected of a disk operating system.

Further development will focus on further removal of legacy code, reduction in size of the code base, and general cleanup. Error detection and handling will also be improved.

As system utilities have been rewritten, they too have had additional features and improved performance added. Replacement of legacy utilities will continue along this strategy.

As of November 2024, a re-packaging of the kernel and utilities is being formed to create a complete distribution.

### Footnotes

[^1]: https://groups.io/g/cosmacelf/message/38759  
[^2]: https://groups.io/g/cosmacelf/message/38820  
[^3]: https://groups.io/g/cosmacelf/message/39872  
[^4]: https://groups.io/g/cosmacelf/message/43342  
[^5]: https://groups.io/g/cosmacelf/message/45869  

