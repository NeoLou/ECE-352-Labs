/*********
 * 
 * Write the assembly function:
 *     printn ( char * , ... ) ;
 * Use the following C functions:
 *     printHex ( int ) ;
 *     printOct ( int ) ;
 *     printDec ( int ) ;
 * 
 * Note that 'a' is a valid integer, so movi r2, 'a' is valid, and you don't need to look up ASCII values.
 *********/

.global	printn

# printn:
	# ADDI sp, sp, -12
	# stw r7, 8(sp)
	# stw r6, 4(sp)
	# stw r5, 0(sp)
	# MOV r8, r4 # address of input string

# LOOP:
	# MOVI r11, 'O' # value of char 'O'
	# MOVI r12, 'H' # value of char 'H'
	# MOVI r13, 'D' # value of char 'D'
	# ldb r10, 0(r8)
	# ldw r4, 0(sp)
	# ADDI r8, r8, 1
	# stw r8, 0(sp)
	# BEQ r10, r11, PRINTOCT
	# BEQ r10, r12, PRINTHEX
	# BEQ r10, r13, PRINTDEC
	# ADDI sp, sp, 4
	# ret

# PRINTOCT:
	# call printOct
	# ldw r8, 0(sp)
	# ADDI sp, sp, 4
	# br LOOP

# PRINTHEX:
	# call printHex
	# ldw r8, 0(sp)
	# ADDI sp, sp, 4
	# br LOOP

# PRINTDEC:
	# call printDec
	# ldw r8, 0(sp)
	# ADDI sp, sp, 4
	# br LOOP
	

printn:
	addi sp, sp, -24
	stw ra, 8(sp)
	stw r5, 12(sp)
	stw r6, 16(sp)
	stw r7, 20(sp)
	addi r15, sp, 12	# save intial sp + 12 in r15 (first number) (note: might need to change r15 to another reg)
	mov r11, r4			# r4 contains string pointer
next_ch:
	movi r8, 'H'
	movi r9, 'O'
	movi r10, 'D'
	ldb r12, 0(r11)		# read char in r11 = first arg of printn = char *
	ldw r4, 0(r15)
	addi r11, r11, 1		# increment r11 = string pointer
	addi r15, r15, 4		# increment saved sp
	stw r11, 0(sp)
	stw r15, 4(sp)
	beq r12, r8, print_hex
	beq r12, r9, print_oct
	beq r12, r10, print_dec
	br end
print_hex:
	call printHex
	ldw r11, 0(sp)
	ldw r15, 4(sp)
	br next_ch
print_oct:
	call printOct
	ldw r11, 0(sp)
	ldw r15, 4(sp)
	br next_ch
print_dec:
	call printDec
	ldw r11, 0(sp)
	ldw r15, 4(sp)
	br next_ch
end:
    ldw ra, 8(sp)
	addi sp, sp, 24
	ret
	



