//-------------------------------------------------------------------------
//-- Jaidon Rodriguez
//-- Embedded System Design 1
//-- Lab 5 C Code
//-- October 15th 2025
//-------------------------------------------------------------------------

#include "io.h"
#include <stdio.h>
#include "system.h"
#include "alt_types.h"
#include "sys/alt_irq.h"

/* -----------------------------------------------------------------------
 * Typedefs
 * -------------------------------------------------------------------- */
typedef unsigned char   uint8;   /* unsigned 8 bit values */
typedef unsigned short  uint16;  /* unsigned 16 bit values */
typedef unsigned long   uint32;  /* unsigned 32 bit values */

/* -----------------------------------------------------------------------
 * Forward declarations (prototypes)
 * -------------------------------------------------------------------- */
int  angle_to_pulse_count(int angle);
void pushbutton_ISR(void* context);
void servo_ISR(void* context);
void display_angle(void);

/* -----------------------------------------------------------------------
 * Globals (register pointers and state)
 * -------------------------------------------------------------------- */

/* Servo and display hardware pointers (memory-mapped addresses) */
uint32 *hex5 = (uint32 *) HEX5_BASE;
uint32 *hex4 = (uint32 *) HEX4_BASE;
uint32 *hex2 = (uint32 *) HEX2_BASE;
uint32 *hex1 = (uint32 *) HEX1_BASE;
uint32 *hex0 = (uint32 *) HEX0_BASE;
volatile uint32 *buttons = (uint32 *) PUSHBUTTONS_BASE;
volatile uint32 *switches = (uint32 *) SWITCHES_BASE;
uint32 *servo = (uint32 *) SERVO_CONTROLLER_0_BASE;

/* Configurable angle limits (volatile because modified in ISR) */
volatile uint32 min_angle = 46;
volatile uint32 max_angle = 134;

/* Flags / conversion results */
volatile uint8 update_display = 0;
uint32 conv_min;
uint32 conv_max;

/* -----------------------------------------------------------------------
 * 7-Segment display map (constant)
 * -------------------------------------------------------------------- */
const uint8 SEGMENT_MAP[10] = {
    0x40, 0x79, 0x24, 0x30, 0x19,    /* 0-4 */
    0x12, 0x02, 0x78, 0x00, 0x10     /* 5-9 */
};

/* -----------------------------------------------------------------------
 * Helper: convert angle to servo pulse count
 * -------------------------------------------------------------------- */
int angle_to_pulse_count(int angle) {
    int count = angle * (555.556) + 25000;
    return count;
}

/* -----------------------------------------------------------------------
 * Interrupt Service Routines
 * -------------------------------------------------------------------- */
void pushbutton_ISR(void* context) {
    uint32 button_edge = *(buttons + 3);

    if (button_edge & 0x8) {    /* KEY3: Set min angle */
        min_angle = *switches;
        /* if (min_angle >= 100) min_angle = 99; */
    }

    if (button_edge & 0x4) {    /* KEY2: Set max angle */
        max_angle = *switches;
    }

    update_display = 1;

    *(buttons + 3) &= 0xFF;  /* Clears Interrupts */

    button_edge = *(buttons + 3);
}

void servo_ISR(void* context) {
    conv_min = angle_to_pulse_count(min_angle);
    conv_max = angle_to_pulse_count(max_angle);

    printf("%lu\n", conv_min);
    printf("%lu\n", conv_max);

    *(servo + 0) = conv_min;   /* Write min angle */
    *(servo + 1) = conv_max;   /* Write max angle */
}

/* -----------------------------------------------------------------------
 * Display Handling
 * -------------------------------------------------------------------- */
void display_angle() {
    /* Write min angle to HEX5/HEX4 */
    *hex4 = SEGMENT_MAP[min_angle % 10];
    *hex5 = SEGMENT_MAP[(min_angle / 10) % 10];

    /* Write max angle to HEX0/HEX1/HEX2 */
    *hex0 = SEGMENT_MAP[max_angle % 10];
    *hex1 = SEGMENT_MAP[(max_angle / 10) % 10];
    *hex2 = SEGMENT_MAP[max_angle / 100];
}

/* -----------------------------------------------------------------------
 * main
 * -------------------------------------------------------------------- */
int main(void) {
    /* Configure pushbutton interrupts: enable KEY3 & KEY2 */
    *(buttons + 2) &= 0x00;
    *(buttons + 2) |= 0x0C;  /* Enables interrupts for KEY3 & KEY2 Pushbutton */
    *(buttons + 3) &= 0xFF;  /* Clears Interrupts */

    /* Register ISRs */
    alt_ic_isr_register(PUSHBUTTONS_IRQ_INTERRUPT_CONTROLLER_ID,
                        PUSHBUTTONS_IRQ,
                        pushbutton_ISR,
                        0,
                        0);

    alt_ic_isr_register(SERVO_CONTROLLER_0_IRQ_INTERRUPT_CONTROLLER_ID,
                        SERVO_CONTROLLER_0_IRQ,
                        servo_ISR,
                        0,
                        0);

    /* Initialize servo angles */
    conv_min = angle_to_pulse_count(min_angle);
    conv_max = angle_to_pulse_count(max_angle);

    *(servo + 0) = conv_min;
    *(servo + 1) = conv_max;

    /* Initialize display for angles */
    display_angle();

    /* Main loop */
    while (1) {
        if (update_display) {
            display_angle();
            update_display = 0;
        }
    }

    return 0;
}
