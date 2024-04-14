PROGRAM_NAME = bootloader
SRC_DIR = src
BUILD_DIR = build
PROGRAMMER = usbasp # alternatives: arduino
CC = avr-gcc

CFLAGS = -Wall -Os -mmcu=atmega328p -std=gnu99

# Set program start address to start address of boot section configured by fuse bits
LDFLAGS = -Wl,-section-start=.text=0x7C00 # 1024

MK_DIR = mkdir -pv

all: $(PROGRAM_NAME)

# create the build directory
$(BUILD_DIR):
	$(MK_DIR) $(BUILD_DIR)

# create the object file for main.c
main.o: $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $(BUILD_DIR)/main.o -c $(SRC_DIR)/main.c

# link and build the program in ELF format for Atmega328P
$(PROGRAM_NAME).elf: $(BUILD_DIR) main.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILD_DIR)/$(PROGRAM_NAME).elf $(BUILD_DIR)/main.o

# convert ELF file to HEX and BIN files to be programmed on Atmega328P
$(PROGRAM_NAME): $(BUILD_DIR) $(PROGRAM_NAME).elf
	avr-objcopy -j .text -j .data -O ihex $(BUILD_DIR)/$(PROGRAM_NAME).elf $(BUILD_DIR)/$(PROGRAM_NAME).hex
	avr-objcopy -j .text -j .data -O binary $(BUILD_DIR)/$(PROGRAM_NAME).elf $(BUILD_DIR)/$(PROGRAM_NAME).bin
	avr-size --format=avr --mcu=atmega328p $(BUILD_DIR)/$(PROGRAM_NAME).elf

# for debugging
assemble: $(BUILD_DIR) $(PROGRAM_NAME).elf
	avr-objdump -d -S $(BUILD_DIR)/$(PROGRAM_NAME).elf > $(BUILD_DIR)/assembled.s

# for debugging
disassemble: $(BUILD_DIR) $(PROGRAM_NAME)
	avr-objcopy -I ihex -O elf32-avr $(BUILD_DIR)/$(PROGRAM_NAME).hex $(BUILD_DIR)/disassembled.elf
	avr-objdump -D -m avr $(BUILD_DIR)/disassembled.elf > $(BUILD_DIR)/disassembled.s

read_fusebits:
	avrdude -v -p m328p -c $(PROGRAMMER) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h

# hfuse 0xDE = 512 bytes, 0xDC = 1024 bytes for the bootloader
write_fusebits:
	avrdude -c $(PROGRAMMER) -p m328p -U lfuse:w:0xFF:m -U hfuse:w:0xDC:m -U efuse:w:0xFD:m  -U lock:w:0xFF:m

read_flash: $(PROGRAM_NAME)
	avrdude -c $(PROGRAMMER) -p m328p -U flash:r:flash_contents.hex:i

upload: $(PROGRAM_NAME)
	avrdude -c $(PROGRAMMER) -p m328p -U flash:w:$(BUILD_DIR)/$(PROGRAM_NAME).hex

clean:
	rm -rf $(BUILD_DIR) 