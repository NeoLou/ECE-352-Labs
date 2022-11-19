.equ JTAG_UART_BASE, 0xFF201000
.equ JTAG_UART_RR, 0
.equ JTAG_UART_TR, 0
.equ JTAG_UART_CSR, 4

.global _start
_start:
movia sp, 0x17fff80 		# initiate sp
movia r8, JTAG_UART_BASE 	# UART IO addr
movi r2, 1
stwio r2, JTAG_UART_CSR(r8)		# enable read interrupt on UART
wrctl ctl0, r2 		# enable interrupts globally
movi r2, 0x100
wrctl ctl3, r2 		# enable IRQ8 for UART

fever:
movia r8, JTAG_UART_BASE 	# UART IO addr
ldwio r2, JTAG_UART_CSR(r8)   # read CSR
br fever

.section .exceptions, "ax"
handler:   
addi sp, sp, -12			# save r9/r10
stw r9, 0(sp)
stw r10, 4(sp)
stw r11, 8(sp)
movia r9, JTAG_UART_BASE
ldwio r10, JTAG_UART_RR(r9)   # read RR
#andi r10, r10, 0xff    		# character received, copy lower 8 bits
wait:
ldwio r11, JTAG_UART_CSR(r9)  # read CSR
srli r11, r11, 16             # keep only the upper 16 bits
beq r2, r0, wait         	# if upper 16 bits are zero keep trying    
stwio r10, JTAG_UART_TR(r9)   # place it in the output FIFO
ldw r9, 0(sp)			# recover r9/r10
ldw r10, 4(sp)
ldw r11, 8(sp)
addi sp, sp, 12
subi ea, ea, 4			# make sure we execute instruction interrupted
eret					# return from interrupt
