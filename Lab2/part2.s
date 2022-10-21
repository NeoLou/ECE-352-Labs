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
    #   r4  A pointer to current place in input list
	#	r5  A pointer to current place in output negative list
	#	r6  A pointer to current place in output positive list
	#   r7  Number to be processed
    #   r16, r17 Short-lived temporary values.
    #   etc...

.global _start
_start:
    movia r4, IN_LIST
	movi r2, 0
	movi r3, 0
	movia r5, OUT_NEGATIVE
	movia r6, OUT_POSITIVE
    # Your program here. Pseudocode and some code done for you:
    BEGINLOOP:
    # Begin loop to process each number
    	ldh r7, 0(r4)
		addi r4, r4, 2 # increment array
		beq r7, r0, LOOP_FOREVER
		bge r7, r0, POS
		br NEG
        # Process a number here:
        #    if (number is negative) { 
        #        insert number in OUT_NEGATIVE list
        #        increment count of negative values (r2)
        #    } else if (number is positive) { 
        #        insert number in OUT_POSITIVE list
        #        increment count of positive values (r3)
        #    }
        # Done processing.
		
	NEG:
		sth r7, 0(r5)
		addi r5, r5, 2
		addi r2, r2, 1
		br BEGINLOOP
	POS:
		sth r7, 0(r6)
		addi r6, r6, 2
		addi r3, r3, 1
		br BEGINLOOP
        # (You'll learn more about I/O in Lab 4.)
        # movia  r16, RED_LEDS          # r16 and r17 are temporary values
        # ldwio  r17, 0(r16)
        # addi   r17, r17, 1
        # stwio  r17, 0(r16)
		# br BEGINLOOP
        # Finished output to LEDs.
    # End loop


LOOP_FOREVER:
    br LOOP_FOREVER                   # Loop forever.
    
	