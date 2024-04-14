# uno-self-modify

Uno-self-modify is a bootloader than modifies injects code into user space and executes it, returning back to the bootloader afterwards.

## Background
The idea that prompted this project was a question asked at a local electronics meetup regarding how one might have a bootloader inject code instruction by instruction into user-space. This code doesn't accomplish that, just a single instruction. 

## Future work
In order to inject one instruction at a time, one would need to:
 * restore the user code state, i.e. registers, etc. prior to the jmp to user space
 * save the user code state after the jmp back to bootloader space
 * keep track of a "user code program counter" for the user space code so new code can be injected, and jumped to at that address.

## Code explanation
The injected instruction is `sbi 0x05, 5`, which sets Pin 13 to HIGH, turning on the LED on an Arduino Uno development board.

The jump point must be calculated by hand after inspecting the assembler code which can be generated with `make assemble`. Note, the address in assembler is a byte-address, but needs to be set in code as little-endian and as a word-address.

## Running the code
* Set your programmer in the Makefile
* run `make upload` to compile and upload
* you should see the LED on your Uno development board come on.

You can change `0x2d, 0x9a` to `0x00, 0x00` in main.c in order to change `sbi 0x05, 5` to `nop` and then the light will not turn on.

If you add / remove lines from the code, you'll likely have to recalculate the address for jumping back to bootloader space (see "Code explanation" section above).
