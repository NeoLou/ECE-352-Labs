.global _start
_start:

/*
Register allocation:
r2 - used to help get sensor reading in r3
r3 - sensor reading
r4 - parameter into ACC_CONTROL, sets acceleration to that value
r5 - parameter into STEER_CONTROL, sets steering to that value
r7 - used to store the UART address
r8 - used to request a sensor reading by writing 0x2 to UART
r9 - used to request a sensor reading by writing 0x2 to UART
r10 - used for comparing steering values
r11 - error register (if there is a weird sensor reading)
r16 - callee saved registers used in helper functions
r17 - callee saved registers used in helper functions
r18 - callee saved registers used in helper functions
*/

movia sp, 0x17fff80		# initialise stack pointer
movia r2, 0x0			# reset all regs
movia r3, 0x0	
movia r4, 0x0
movia r5, 0x0
movia r7, 0x10001020
movia r8, 0x0
movia r9, 0x0
movia r10, 0x0
movia r11, 0x0	
movia r16, 0x0	
movia r17, 0x0			
movia r18, 0x0			

movi r5, 0x00
call STEER
call WORLDRESET			# reset UART

movi r4, 0x7F			# high initial acceleration
call ACC_CONTROL 			# set an initial acceleration until car encounters first corner

# Main Function Loop
ReadSensorsAndSpeed:

# Request a reading
MAIN_WRITE_POLL:
ldwio r8, 4(r7) /* Load from the JTAG */
srli  r8, r8, 16 /* Check only the write available bits */
beq   r8, r0, MAIN_WRITE_POLL /* If this is 0 (branch true), data cannot be sent */
movui r9, 0x2 /* packet type is 2 (sensor)*/
stwio r9, 0(r7) /* Write the byte to the JTAG */

# Parse the reading
MAIN_READ_POLL:
ldwio r2, 0(r7) /* Load from the JTAG */
andi  r3, r2, 0x8000 /* Mask other bits */
beq   r3, r0, MAIN_READ_POLL /* If this is 0 (branch true), data is not valid */
andi  r3, r2, 0x00FF /* Data read is now in r3 */

MAIN_READ_POLL2:
ldwio r2, 0(r7) /* Load from the JTAG */
andi  r6, r2, 0x8000 /* Mask other bits */
beq   r6, r0, MAIN_READ_POLL2 /* If this is 0 (branch true), data is not valid */
andi  r6, r2, 0x00FF /* Data read is now in r6 */

# Compare scenarios
movi r10, 0x1f				# if sen = 0x1f, br all on track
beq r3, r10, AllOnTrack

movi r10, 0x1e				# if sen = 0x1e, br left on track
beq r3, r10, LeftOffTrack

movi r10, 0x1c				# if sen = 0x1c, br two left off track
beq r3, r10, TwoLeftOffTrack

movi r10, 0x0f				# if sen = 0x0f, br right off track
beq r3, r10, RightOffTrack

movi r10, 0x07				# if sen = 0x07, br two right off track
beq r3, r10, TwoRightOffTrack

br ReadSensorsAndSpeed

# Scenarios
AllOnTrack:	#  sensors are 0x1f = all sensors on track, steer straight
movi r5, 0x00
call STEER
movi r20, 30
bgt r6, r20, OVER
movi r20, 20
blt r6, r20, BELOW
movi r4, 100 # decelerate to keep constant speed after first corner
call ACC_CONTROL
br ReadSensorsAndSpeed

LeftOffTrack: # sensors are 0x1e = leftmost sensor off track, turn right by sending 0x32 = 50 to steering
movi r5, 50
call STEER
movi r20, 30
bgt r6, r20, OVER
movi r20, 20
blt r6, r20, BELOW
movi r4, -60 # decelerate to keep constant speed after first corner
call ACC_CONTROL
br ReadSensorsAndSpeed

TwoLeftOffTrack:# sensors are 0x1c = 2 leftmost sensors off track, turn hard right by sending 0x64 = 100 to steering
movi r5, 127
call STEER
movi r20, 30
bgt r6, r20, OVER
movi r20, 20
blt r6, r20, BELOW
movi r4, -127 # decelerate to keep constant speed after first corner
call ACC_CONTROL
br ReadSensorsAndSpeed

RightOffTrack:# sensors are 0x0f = rightmost sensor off track, turn left by sending 0xCE = -50 to steering
movi r5, -50
call STEER
movi r20, 30
bgt r6, r20, OVER
movi r20, 20
blt r6, r20, BELOW
movi r4, -60 # decelerate to keep constant speed after first corner
call ACC_CONTROL
br ReadSensorsAndSpeed

TwoRightOffTrack:# sensors are 0x07 = 2 rightmost sensors off track, turn hard left by sending 0x9C = -100 to steering
movi r5, -127
call STEER
movi r20, 30
bgt r6, r20, OVER
movi r20, 20
blt r6, r20, BELOW
movi r4, -127 # decelerate to keep constant speed after first corner
call ACC_CONTROL
br ReadSensorsAndSpeed    

BELOW:
movi r4, 127 # decelerate to keep constant speed after first corner
call ACC_CONTROL
br ReadSensorsAndSpeed  

OVER:
movi r4, -80 # decelerate to keep constant speed after first corner
call ACC_CONTROL
br ReadSensorsAndSpeed    
# Helper functions

WORLDRESET:	# writes 0x00 (op-stop) and drains reads. Uses callee saved registers r16-r18 
movia r16, 0x10001020 /* r16 now contains the base address of UART*/
RESET_WRITE_POLL:
ldwio r17, 4(r16) /* Load from the JTAG */
srli  r17, r17, 16 /* Check only the write available bits */
beq   r17, r0, RESET_WRITE_POLL /* If this is 0 (branch true), data cannot be sent */
stwio r0, 0(r16) /* Write the byte 0x00 to the JTAG canceling the wait for new packet*/
RESET_READ_POLL:
ldwio r17, 0(r16) /* Load from the JTAG */
andi  r18, r17, 0x8000 /* Mask other bits */
bne   r18, r0, RESET_READ_POLL /* If this is 1, data is valid, so continue draining */
ret

STEER: # write r5 into packet type 5, uses callee saved registers r16-r19
addi sp, sp, -12
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
movia r16, 0x10001020 /* r16 now contains the base address of UART*/
STEER_WRITE_POLL:
ldwio r17, 4(r16) /* Load from the JTAG */
srli  r17, r17, 16 /* Check only the write available bits */
beq   r17, r0, STEER_WRITE_POLL /* If this is 0 (branch true), data cannot be sent */
movui r18, 0x5 /* packet type is 5 (steering)*/
stwio r18, 0(r16) /* Write the byte to the JTAG */
STEER_WRITE_POLL2:
ldwio r17, 4(r16) /* Load from the JTAG */
srli  r17, r17, 16 /* Check only the write available bits */
beq   r17, r0, STEER_WRITE_POLL2 /* If this is 0 (branch true), data cannot be sent */
stwio r5, 0(r16) /* Write the steering value in r5 to the JTAG */
ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
addi sp, sp, 12
ret

ACC_CONTROL: # write r4 into packet type 4 uses callee saved registers r16-r18
addi sp, sp, -12
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
movia r16, 0x10001020 /* r16 now contains the base address */
ACC_WRITE_POLL:
ldwio r17, 4(r16) /* Load from the JTAG */
srli  r17, r17, 16 /* Check only the write available bits */
beq   r17, r0, ACC_WRITE_POLL /* If this is 0 (branch true), data cannot be sent */
movui r18, 0x4 /* packet type is 4 (acceleration)*/
stwio r18, 0(r16) /* Write the byte to the JTAG */
ACC_WRITE_POLL2:
ldwio r17, 4(r16) /* Load from the JTAG */
srli  r17, r17, 16 /* Check only the write available bits */
beq   r17, r0, ACC_WRITE_POLL2 /* If this is 0 (branch true), data cannot be sent */
stwio r4, 0(r16) /* Write the acceleration value to the JTAG */
ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
addi sp, sp, 12
ret
