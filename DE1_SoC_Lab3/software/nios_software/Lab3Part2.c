/* Lab 3 Part 2: Timer + Pushbutton Interrupt Demo
 *
 * - KEY1 ISR: increments/decrements HEX0 depending on SW0
 * - Timer ISR: toggles LEDs every timeout (100 ms)
 */

#include "io.h"
#include <stdio.h>
#include "system.h"
#include "alt_types.h"
#include "sys/alt_irq.h"
#include "altera_avalon_timer_regs.h"
#include "altera_avalon_timer.h"

// ---------------- Type aliases ----------------
typedef   signed char   sint8;
typedef unsigned char   uint8;
typedef   signed short  sint16;
typedef unsigned short  uint16;
typedef   signed long   sint32;
typedef unsigned long   uint32;
typedef         float   real32;

// ---------------- Peripheral pointers ----------------
uint32* TimerPtr    = (uint32*)TIMER_0_BASE;
unsigned int* LedPtr   = (unsigned char*)LEDS_BASE;
unsigned int* Hex0Ptr   = (unsigned int*)HEX0_BASE;
unsigned int* SwitchPtr = (unsigned int*)SWITCHES_BASE;
unsigned int* KeyPtr    = (unsigned int*)PUSHBUTTONS_BASE;
unsigned int* KeyEdgePtr= (unsigned int*)(PUSHBUTTONS_BASE + 12); // edge cap reg
unsigned int* KeyMaskPtr= (unsigned int*)(PUSHBUTTONS_BASE + 8);  // irq mask reg

// ---------------- HEX0 lookup table ----------------
const unsigned char seven_seg_table[10] = {
    0x40, // 0
    0x79, // 1
    0x24, // 2
    0x30, // 3
    0x19, // 4
    0x12, // 5
    0x02, // 6
    0x78, // 7
    0x00, // 8
    0x10  // 9
};

volatile int count = 0;   // HEX0 display value

// ---------------- Pushbutton ISR ----------------
static void button_isr(void* context, alt_u32 id) {
    // Clear edge capture
    *KeyEdgePtr = 0xF;

    int sw0 = *SwitchPtr & 0x1;
    if (sw0) {
        if (count < 9) count++;
    } else {
        if (count > 0) count--;
    }

    // Update HEX0
    *Hex0Ptr = seven_seg_table[count];
}

// ---------------- Timer ISR ----------------
static void timer_isr(void* context, alt_u32 id) {
    // Clear timer interrupt
    *TimerPtr = 0;

    // Toggle LEDs
    *LedPtr = ~(*LedPtr);
}

// ---------------- Main ----------------
int main(void) {
    // Initialize HEX0
    *Hex0Ptr = seven_seg_table[count];

    // Clear edge capture
    *KeyEdgePtr = 0xF;

    // Enable KEY1 only (bit1 = KEY1)
    *KeyMaskPtr = 0x2;

    // Register button ISR
    alt_ic_isr_register(PUSHBUTTONS_IRQ_INTERRUPT_CONTROLLER_ID,
                        PUSHBUTTONS_IRQ,
                        button_isr,
                        NULL, 0);

    // Register timer ISR
    alt_ic_isr_register(TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID,
                        TIMER_0_IRQ,
                        timer_isr,
                        NULL, 0);

    // Enable timer: ITO + CONT + START
    IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE,
        ALTERA_AVALON_TIMER_CONTROL_ITO_MSK |
        ALTERA_AVALON_TIMER_CONTROL_CONT_MSK |
        ALTERA_AVALON_TIMER_CONTROL_START_MSK);

    while (1); // ISRs handle everything
    return 0;
}
