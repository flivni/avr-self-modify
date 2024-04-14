/* Connections

      PB5 ---> LED
*/

#ifndef __AVR_ATmega328P__
#define __AVR_ATmega328P__
#endif

// CPU main clock frequency in Hz
#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <avr/boot.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

// address need not be page aligned, only program_buffer_size worth of data will be written, the rest will
// be left untouched.
// program_buffer_size needs to be a multiple of 2
void insert_user_code(const uint32_t address, uint8_t *program_buffer, const uint32_t program_buffer_size) {
    // Disable interrupts.
    uint8_t  sreg_last_state = SREG;
    cli();

    eeprom_busy_wait();
    // iterate through the program_buffer one page at a time
    for (uint32_t current_page_address = (address / SPM_PAGESIZE) * SPM_PAGESIZE; 
         current_page_address < (address + program_buffer_size); 
         current_page_address += SPM_PAGESIZE) 
    {
        // iterate through the page, one word (two bytes) at a time
        for (uint16_t b = 0; b < SPM_PAGESIZE; b += 2)
        {
          uint16_t w;
          if ((current_page_address + b) < address)
          {
            w = pgm_read_word(current_page_address + b);
          } 
          else if ((current_page_address + b) < (address + program_buffer_size)) 
          {
          // Set up little-endian word
            w = *program_buffer++;
            w += (*program_buffer++) << 8;
          } 
          else 
          {
            w = pgm_read_word(current_page_address + b);
          }

          boot_page_fill(current_page_address + b, w);
        }

        boot_page_erase(current_page_address);
        boot_spm_busy_wait(); // Wait until the memory is erased.

        boot_page_write(current_page_address); // Store buffer in flash page.
        boot_spm_busy_wait();          // Wait until the memory is written.
    }

  // Re-enable RWW-section again. We need this if we want to jump back
  // to the application after bootloading.
  boot_rww_enable();

  // Re-enable interrupts (if they were previously enabled).
  SREG = sreg_last_state;
}
  uint8_t user_code[] = { 
      0x2d, 0x9a,  // sbi	0x05, 5 // PORTB |= 1 << PB5; 
      0x0c, 0x94, 0xe6, 0x3e // jmp 0x7dcc
  };


int main(void)
{
  // Configure LED pin as output
  DDRB |= (1 << PB5);

  // asm("jmp 0x7dcc");
  asm volatile("nop");
  asm volatile("nop");

  // Check if a user program exists in flash memory
  if (pgm_read_word(0) == 0xFFFF) {
    // Write the binary code of the blinky program to flash memory at address 0x0000
    insert_user_code(0x1000, user_code, sizeof(user_code));
  }

  // Jump to the start address of the user code
  asm("jmp 0x1000");
  
  // We want to jump back here - `jmp 0x7dcc` = 0e 94 4b 3e

  while(1) {
      // PORTB &= ~(1 << PB5); // Turn-off LED
      // _delay_ms(2000);
      // PORTB |= 1 << PB5; // Turn-on LED
      // _delay_ms(100);
  }
}