	include <p16f628a.inc>

	errorlevel -302 ; disable bank switch warning

;	__CONFIG	_LVP_OFF & _BODEN_OFF & _MCLRE_OFF & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_LVP_OFF & _BODEN_OFF & _MCLRE_OFF & _WDT_OFF & _FOSC_XT

PIN_DATA equ RB0
PIN_SHIFT equ RB1
PIN_STORE equ RB2
PIN_ALARM equ RB3
PIN_BTN1 equ RB4
PIN_BTN2 equ RB5
PIN_BTN3 equ RB6

; scratch space
temp1 equ 0x21
temp2 equ 0x22

; timing variables
bk_w equ 0x23
bk_status equ 0x24
ticks equ 0x25
last_btn equ 0x40

; kitchen clock state
state equ 0x26
minutes equ 0x28
seconds equ 0x29

READY_BIT equ 0
READY equ (1 << READY_BIT)

COUNTDOWN_BIT equ 1
COUNTDOWN equ (1 << COUNTDOWN_BIT)

BEEPING_BIT equ 2
BEEPING equ (1 << BEEPING_BIT)

; bcd converter arguments
bin equ 0x30 ; 8-bit binary number A1*16+A0
hundreds equ 0x31 ; the hundreds digit of the BCD conversion
tens_and_ones equ 0x32 ; the tens and ones digits of the BCD conversion

	org 0
boot:
	goto main		; boot entry point

	org 4
intvec:
	bcf INTCON, GIE 	; disable interrupt

	movwf bk_w		; w retten 
	swapf STATUS, w		; status retten 
	movwf bk_status
	
	movlw D'131'          ; 256-125=131 ((1MHz : 32 ): 125 = 250 Hz) 
	movwf TMR0

	; <---- executed at 250 Hz
	
	; read buttons, detect presses
	comf last_btn, f
	movfw PORTB
	andlw B'01110000'	; w <- current button state
	movwf temp1
	andwf last_btn, f	; last_btn <- ~last_btn & w
	btfsc last_btn, PIN_BTN1
	 call on_plus_10_btn
	btfsc last_btn, PIN_BTN2
	 call on_plus_1_btn
	btfsc last_btn, PIN_BTN3
	 call on_start_btn
	movfw temp1		; last_btn <- current button state
	movwf last_btn

	; 2. Display update

	; blink if state == COUNTDOWN && minutes == 1 && seconds < 30
	btfss state, COUNTDOWN_BIT
	 goto _display_minutes		; state != COUNTDOWN
	decf minutes, w
	btfss STATUS, Z
	 goto _display_minutes		; minutes != 1
	movlw D'30'
	subwf seconds, w
	btfsc STATUS, C
	 goto _display_minutes		; seconds >= 30
	movlw D'125'
	subwf ticks, w
	btfss STATUS, C
	 goto _display_minutes		; every half second
	call display_blank
	goto _display_done
_display_minutes:
	movfw minutes
	call display_number
_display_done:
	
	; enable alarm if state == BEEPING
	btfss state, BEEPING_BIT
	 call alarm_off
	btfsc state, BEEPING_BIT
	 call alarm_on

	decfsz ticks, f
	goto _cont
	movlw  D'250'
	movwf ticks

	; <---- executed at 1 Hz
	call on_1hz
 
_cont:
	swapf bk_status, w	; STATUS zurück 
	movwf STATUS  
	swapf bk_w, f		; w zurück mit flags 
	swapf bk_w, w

	bcf INTCON, T0IF	; Interrupt-Flag löschen 
	bsf INTCON, GIE		; enable Interrupt (macht RETFIE aber auch allein)

	retfie

main:
	; Initialize variables
	movlw D'250'
	movwf ticks
	clrf last_btn

	clrf seconds
	clrf minutes

	movlw READY
	movwf state

	; Initialize PORT B
	banksel TRISB
	movlw B'11110000'
	movwf TRISB

	banksel PORTB
	movlw B'00000000'
	movwf PORTB

	; Initialize Timer
	bsf     STATUS, RP0     ; auf Bank 1 umschalten 
	movlw   B'10000100'     ; internen Takt zählen, Vorteiler zum Timer0, 32:1 
	movwf   OPTION_REG 
	movlw   D'255'
	bcf     STATUS, RP0     ; auf Bank 0 zurückschalten 
	movwf   TMR0 
	bsf     INTCON, T0IE    ; Timer0 interrupt erlauben 
	bsf     INTCON, GIE     ; Interrupt erlauben

mainloop:
	goto mainloop

	include "sevenseg.asm"
	include "alarm.asm"

;;;;; STATE MACHINE ;;;;;

on_1hz:
	; do nothing if state != COUNTDOWN
	btfss state, COUNTDOWN_BIT
	 return

	; decrease time, go to BEEPING state if zero
	decfsz seconds, f
	 return
	movlw D'60'
	movwf seconds
	decfsz minutes, f
	 return

	movlw BEEPING
	movwf state
	return

on_plus_1_btn:
	; return if state != READY
	btfss state, READY_BIT
	 return
	; increase minutes by 1, but not above 99
	movlw D'99'
	subwf minutes, w
	btfss STATUS, C
	 incf minutes, f
	return

on_plus_10_btn:
	; return if state != READY
	btfss state, READY_BIT
	 return
	; increase minutes by 10
	movlw D'10'
	addwf minutes, f
	; return if minutes < 100
	movlw D'100'
	subwf minutes, w
	btfss STATUS, C
	 return
	; else, saturate at 99
	movlw D'99'
	movwf minutes
	return

on_start_btn:
	; when in READY state, go to COUNTDOWN state
	btfsc state, READY_BIT
	 goto on_start_btn_when_ready

	; reset to zero, go to READY state
	clrf minutes

	movlw READY
	movwf state
	return

on_start_btn_when_ready:
	; if state == READY, go to COUNTDOWN state (only if minutes > 0)
	movf minutes, f
	btfsc STATUS, Z
	 return
	movlw D'60'
	movwf seconds

	movlw COUNTDOWN
	movwf state
	return

	end

