.equ RED_LEDS, 0xFF200000 	   # (From DESL website > NIOS II > devices)


.data                              # "data" section for input and output lists


IN_LIST:                  	   # List of 10 signed halfwords starting at address IN_LIST
    .hword 1
    .hword -1
    .hword -2
    .hword 2
    .hword 0
    .hword -3
    .hword 100
    .hword 0xff9c
    .hword 0b1111
LAST:			 	    # These 2 bytes are the last halfword in IN_LIST
    .byte  0x01		  	    # address LAST
    .byte  0x02		  	    # address LAST+1
    
IN_LINKED_LIST:                     # Used only in Part 3
    A: .word 1
       .word B
    B: .word -1
       .word C
    C: .word -2
       .word E + 8
    D: .word 2
       .word C
    E: .word 0
       .word K
    F: .word -3
       .word G
    G: .word 100
       .word J
    H: .word 0xffffff9c
       .word E
    I: .word 0xff9c
       .word H
    J: .word 0b1111
       .word IN_LINKED_LIST + 0x40
    K: .byte 0x01		    # address K
       .byte 0x02		    # address K+1
       .byte 0x03		    # address K+2
       .byte 0x04		    # address K+3
       .word 0
    
OUT_NEGATIVE:
    .skip 40                         # Reserve space for 10 output words, 40 bytes
    
OUT_POSITIVE:
    .skip 40                         # Reserve space for 10 output words

#-----------------------------------------

.text                  # "text" section for code

    # Register allocation:
    #   r0 is zero, and r1 is "assembler temporary". Not used here.
    #   r2  Holds the number of negative numbers in the list
    #   r3  Holds the number of positive numbers in the list
    #   r4  A pointer to the current address of the linked list
	#	r5  A pointer to output negative list (current position)
	#	r6  A pointer to output positive list (current position)
	# 	R7,R8 USED FOR THE LINKED LIST
	#   r7  VAL
	#	r8 	NEXT



	# Control flow:
	# _start -> BEGINLOOP -> POS/NEG/SKIP -> INCREMENT -> BEGINLOOP
	#				|
	#				v
	#			LOOP_FOREVER
	
.global _start
_start:
    movia r4, IN_LINKED_LIST			# Set up the pointer to input
	movi r2, 0							# Counters = 0
	movi r3, 0
	movia r5, OUT_NEGATIVE				# Set up pointers to output
	movia r6, OUT_POSITIVE
	ldw r7, 0(r4)						# Load the first val
	ldw r8, 4(r4)						# Load the first next pointer
	
    BEGINLOOP:							# Begin loop to process each number
		beq r4, r0, LOOP_FOREVER 		# Current address is null, end program
		bgt r7, r0, POS					# If val > 0, add to positive list
		blt r7, r0, NEG					# Val < 0 so add to negative list
		br INCREMENT					# Val = 0 so just move on
		
	INCREMENT:
		add r4, r0, r8 					# Move current pointer to next
		ldw r7, 0(r4)					# Load new val
		ldw r8, 4(r4)					# Load new next pointer
		br BEGINLOOP					# Restart the loop
		
	NEG:
		stw r7, 0(r5)					# Store the value into the output list
		addi r5, r5, 4					# Output list pointer +1 word
		addi r2, r2, 1					# Negative count ++
		br INCREMENT					# Finished processing negative no
		
	POS:
		stw r7, 0(r6)					# Store the value into the output list
		addi r6, r6, 4					# Output list pointer +1 word
		addi r3, r3, 1					# Positive count ++
		br INCREMENT					# Finished processing positive no

LOOP_FOREVER:						 	# We done
    br LOOP_FOREVER                  	# Loop forever.
    
	