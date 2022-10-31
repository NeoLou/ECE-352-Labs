.equ ADDR_JP1, 0xFF200070   	# Address GPIO JP1
.equ STACK_BEGIN, 0x17fff80		# Address of initial stack
.equ THRESHOLD, 1	 			# minimum difference between the sensors for the motor to turn on
.equ NEG_THRESHOLD, -1	 		# minimum difference between the sensors for the motor to turn on

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
movia r9, 0x07f557ff        	# set direction registers to motor output sensor input
stwio  r9, 4(r8)				# put in DIR
movia r12, 0x00
LOOP:
movia r8, ADDR_JP1				# Initialise GPIO address at r8
movia r14,	NEG_THRESHOLD		# -threshold
movia r15,	THRESHOLD			# threshold
# done initialising
SENSOR1:						# read sensor 1 and put in r9
movia  r9, 0xffffeffc     		# enable sensor 1, disable all motors
or r9, r9, r12			    # make use of calculation
stwio  r9, 0(r8)
ldwio  r9,  0(r8)          		# checking for valid data sensor 1
srli   r10,  r9, 13          	# is valid if bit 13 == 0 for sensor 1          
andi   r10,  r10, 0x1
bne    r0,  r10, SENSOR1        # wait for valid bit to be low: sensor 3 needs to be valid
srli   r9, r9, 27          		# shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits 
andi   r9, r9, 0x0f				# mask
SENSOR2:						# read sensor 2 and put in r10
movia  r10, 0xffffbffc     		# enable sensor 1, disable all motors
or r10, r10, r12			    # make use of calculation
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
Movia r12, 0x1					# motor off
br MOTORON
ABOVETHRESHOLD:
Blt r9, r0, RIGHT 				# r9-r10<0, r10>r9
LEFT:
Movia r12, 0x2					# r9<=r10
br MOTORON
RIGHT:							# r9<r10
Movia r12, 0x00
MOTORON:
movia r11, 0xfffffffc       	# motor0 enabled (bit0=0), direction set to forward (bit1=0) 
or r11, r11, r12			    # make use of calculation
stwio r11, 0(r8)			    # turn motor on
br LOOP							# go again

