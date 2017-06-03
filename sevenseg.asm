
shift:
	bcf PORTB, PIN_DATA
	movwf temp1
	btfsc temp1, 0
	bsf PORTB, PIN_DATA
	rrf temp1, f
	bsf PORTB, PIN_SHIFT
	movfw temp1
	bcf PORTB, PIN_SHIFT
	return

store:
	bsf PORTB, PIN_STORE
	nop
	bcf PORTB, PIN_STORE
	nop
	return

segment_table:
	addwf PCL, f 
	retlw B'11101110' ; 0 
	retlw B'00100100' ; 1 
	retlw B'10111010' ; 2 
	retlw B'10110110' ; 3 
	retlw B'01110100' ; 4 
	retlw B'11010110' ; 5 
	retlw B'11011110' ; 6 
	retlw B'10100100' ; 7 
	retlw B'11111110' ; 8 
	retlw B'11110110' ; 9
	retlw B'00000000' ; 10

display_blank:
	movlw 0
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift

	movlw 0
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift

	call store

	return

display_number:
	movwf bin
	call bin2bcd

	movfw tens_and_ones
	andlw 0x0f
	call segment_table

	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift

	swapf tens_and_ones, w
	andlw 0x0f
	call segment_table

	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	call shift
	
	call store

	return

;******************************** 
;  bin2bcd - 8-bits
;  
;  Input
;    bin  - 8-bit binary number A1*16+A0
;  Outputs
;   hundreds - the hundreds digit of the BCD conversion
;   tens_and_ones - the tens and ones digits of the BCD conversion
;
; Routine written by Scott Dattalo, comments added by Alex Forencich,
; see http://www.piclist.com/techref/microchip/math/radix/b2bhp-8b3d.htm

bin2bcd:
	clrf    hundreds
	swapf   bin, W      ; swap the nibbles
	addwf   bin, W      ; so we can add the upper to the lower
	andlw   B'00001111' ; lose the upper nibble (W is in BCD from now on)
	skpndc              ; if we carried a one (upper + lower > 16)
	 addlw  0x16        ; add 16 (the place value) (1s + 16 * 10s)
	skpndc              ; did that cause a carry from the 1's place?
	 addlw  0x06        ; if so, add the missing 6 (carry is only worth 10)
	addlw   0x06        ; fix max digit value by adding 6
	skpdc               ; if was greater than 9, DC will be set
	 addlw  -0x06       ; if if it wasn't, get rid of that extra 6
	
	btfsc   bin,4       ; 16's place
	 addlw  0x16 - 1 + 0x6  ; add 16 - 1 and check for digit carry
	skpdc
	 addlw  -0x06       ; if nothing carried, get rid of that 6
	
	btfsc   bin, 5      ; 32nd's place
	 addlw  0x30        ; add 32 - 2
	
	btfsc   bin, 6      ; 64th's place
	 addlw  0x60        ; add 64 - 4
	
	btfsc   bin, 7      ; 128th's place
	 addlw  0x20        ; add 128 - 8 % 100
	
	addlw   0x60        ; has the 10's place overflowed?
	rlf     hundreds, F ; pop carry in hundreds' LSB
	btfss   hundreds, 0 ; if it hasn't
	 addlw  -0x60       ; get rid of that extra 60
	
	movwf   tens_and_ones   ; save result
	btfsc   bin,7       ; remeber adding 28 - 8 for 128?
	 incf   hundreds, F ; add the missing 100 if bit 7 is set
	
	return              ; all done!

