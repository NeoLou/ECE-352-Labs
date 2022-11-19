.section .reset, "ax"
movia sp, 0x17fff80 /* initialize stack */
movia ra, _start
ret

.section .exceptions, "ax"

handler:
addi sp, sp, -8			# save r9/r10
stw r9, 0(sp)
stw r10, 4(sp)
movia r9, 0xFF200000	# leds io addr
ldwio r10, 0(r9)		# read LEDs
xori r10, r10, 1		# blink LED0
stwio r10, 0(r9)		# store to LEDs
movia r9, 0xFF202000	# timer io addr
stwio r0, 0(r9)			# clear timer
subi ea, ea, 4
ldw r9, 0(sp)			# recover r9/r10
ldw r10, 4(sp)
addi sp, sp, 8
eret


.text
.global _start
_start:
	
init:
movia sp, 0x17fff80
movia r8, 0xFF202000 		# timer IO addr
movi r2, 1
stwio r2, 4(r8)				# enable read interrupt on timer1
wrctl ctl0, r2 				# enable interrupts globally
wrctl ctl3, r2 				# enable IRQ0 for timer1
movia r3, 100000000			# 1 second with 100MHz clock
srli r4, r3, 16				# upper 16-bits of r3 are in r4
stwio r4, 12(r8)			# store upper bits of period
stwio r3, 8(r8)				# store lower bits of period
ori r2, r2, 0b10
movia r5, 7
stwio r5, 4(r8)				# set timer to count mode, automatic restart

fever:						# filler code, waiting for interrupt
movia r11, 0xFF202000		# timer io addr
ldwio r13, 16(r11)			# read snapshot timer
br fever
.end

