.equ ADDR_JP1, 0xFF200070   	# Address GPIO JP1
.equ STACK_BEGIN, 0x17fff80		# Address of initial stack
.equ THRESHOLD, 1	 			# minimum difference between the sensors for the motor to turn on
.equ NEG_THRESHOLD, -1	 		# minimum difference between the sensors for the motor to turn on
.equ DUTY_CYCLE_TOT, 5243		# total number of duty cycles/100, on+off at 100MHz, 524300 in example
.equ DUTY_CYCLE, 30		# % out of 100
.equ DUTY_CYCLE_C, 70			# 1-DUTY_CYCLE

.global _start
_start:
/*	Important register usage:
	R4 passing argument N into delay subroutine
	R8 address of GPIO, unchanged throughout
	R9 varying use, sensor 1 value, then direction of motor rotation
	R10 varying use, sensor 2 value
	R11 varying use, written to DR register to turn on motor and set direction
	R12 ON duty cycles number
	R13 OFF duty cycles number
	R14 varying use, for calculating duty cycles, then stores negative threshold 
	R15 stores threshold
*/
movia sp, STACK_BEGIN			# Initialise stack pointer
LOOP:
movia r8, ADDR_JP1				# Initialise GPIO address at r8
movia r9, 0x07f557ff        	# set direction registers to motor output sensor input
stwio  r9, 4(r8)				# put in DIR
movia r14,	DUTY_CYCLE_TOT		# total duty cycle
movia r15, DUTY_CYCLE
mul r12, r14, r15				# number of cycles on
movia r15, DUTY_CYCLE_C
mul r13, r14, r15				# number of cycles off
movia r14,	NEG_THRESHOLD		# -threshold
movia r15,	THRESHOLD			# threshold
# done initialising
SENSOR1:						# read sensor 1 and put in r9
movia  r9, 0xffffefff     		# enable sensor 1, disable all motors
stwio  r9, 0(r8)
ldwio  r9,  0(r8)          		# checking for valid data sensor 1
srli   r10,  r9, 13          	# is valid if bit 13 == 0 for sensor 1          
andi   r10,  r10, 0x1
bne    r0,  r10, SENSOR1        # wait for valid bit to be low: sensor 3 needs to be valid
srli   r9, r9, 27          		# shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits 
andi   r9, r9, 0x0f				# mask
SENSOR2:						# read sensor 2 and put in r10
movia  r10, 0xffffbfff     		# enable sensor 1, disable all motors
stwio  r10, 0(r8)
ldwio  r10,  0(r8)          	# checking for valid data sensor 2
srli   r11,  r10, 15         	# bit 15 is valid bit for sensor 2           
andi   r11,  r11,0x1
bne    r0,  r11, SENSOR2       	# wait for valid bit to be low: sensor 2 needs to be valid
srli   r10, r10, 27          	# shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits 
andi   r10, r10, 0x0f			# mask
CALCULATE:						# Calculate direction of motor rotation, store ‘10’ in r9 if cw, ‘00’ if ccw.
sub r9, r9, r10 				# r9-r10
bgt r9 , r15, ABOVETHRESHOLD
blt r9, r14, ABOVETHRESHOLD 	# difference < -threshold
BELOWTHRESHOLD:
Movia r9, 0x1					# motor off
br MOTORON
ABOVETHRESHOLD:
Blt r9, r0, RIGHT 				# r9-r10<0, r10>r9
LEFT:
Movia r9, 0x2					# r9<=r10
br MOTORON
RIGHT:							# r9<r10
Movia r9, 0x00
MOTORON:
movia r11, 0xfffffffc       	# motor0 enabled (bit0=0), direction set to forward (bit1=0) 
or r11, r11, r9			    # make use of calculation
stwio r11, 0(r8)			    # turn motor on
add r4, r0, r12					# ON duty cycles into parameter N
PRE:							# duty cycles need to be saved in pre and recovered in post
addi sp, sp, -4
stw ra, 0(sp)					# store ra
stw r13, 4(sp)					# store number of off duty cycles
call DELAY
POST:
ldw ra, 0(sp)					# recover regs
ldw r13, 4(sp)					# store number of off duty cycles
addi sp, sp, 4
MOTOROFF:
add r4, r0, r13					# number of off duty cycles
PRE2:
stw ra, 0(sp)					# store ra
call DELAY
POST2:
ldw ra, 0(sp)				    # recover regs
movia	 r12, 0xffffffff        # motor0 disabled (bit0=1)
stwio	 r12, 0(r8)				# turn motor off
br LOOP							# go again

# DELAY Subroutine
#	counts down a period of N on a 100MHz clock speed. Returns when done.
# 	Takes in arguments: r4 = N
DELAY: 							# lets use caller saved registers since its only a callee. r8-r15 
movia r8, 0xFF202000    		# r7 contains the base address for the timer 
stwio r0, 0(r8)					# clear timer
stwio r4, 8(r8)         		# set the period to be N clock cycles lower half 
srli r4, r4, 16
stwio r4, 12(r8))       		# set the period to be N clock cycles upper half
movui r11, 4
stwio r11, 4(r8)        		# start the timer without continuing or interrupts
POLL:
ldwio r10, 0(r8)				# load potential time out bit
andi r10, r10, 0x1				# isolate bit 1
movia r12, 0x1			
beq r12, r10, TIMEOUT   		# is timer == 1? if it is then we have timed out
br POLL
TIMEOUT:
ret
