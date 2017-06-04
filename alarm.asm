
alarm_beep_time equ 0x50
alarm_beep_interval equ 0x51

alarm_initialize:
	; initialize PWM sound
	clrf CCP1CON		; ccp1 mode off 
	bcf T2CON, TMR2ON	; timer 2 off

	; set f_PWM = 440 Hz tone (at T2CKPS=16 and f_osc = 4 MHz / T_osc = 0.25us)
	movlw D'142'/2		; PR2 = 1 / ( f_PWM * 4 * T_osc * T2CKPS)
	banksel PR2		; bank 1
	movwf PR2

	banksel T2CON		; bank 0
	clrf T2CON
	bsf T2CON, T2CKPS1	; set T2CKPS to 16

	; set PWM duty cycle to 50% of PR2
	movlw D'71'/2
	banksel CCPR1L		; bank 0
	movwf CCPR1L
	banksel CCP1CON		; bank 0
	bcf CCP1CON, 4
	bcf CCP1CON, 5

	return

alarm_beep_on:
	movlw D'31'
	movwf alarm_beep_interval
	movlw 1
	movwf alarm_beep_time

	clrf TMR2
	bsf CCP1CON, CCP1M3	; ccp1 mode pwm-mode 
	bsf CCP1CON, CCP1M2
	bsf T2CON, TMR2ON	; timer 2 on

	return

alarm_beep_off:
	clrf TMR2
	clrf CCP1CON		; ccp1 mode off 
	bcf T2CON, TMR2ON	; timer 2 off
	bcf PORTB, PIN_ALARM

	return

alarm_beep_update:
	decfsz alarm_beep_time, f
	 return
	movfw alarm_beep_interval
	movwf alarm_beep_time
	
	movfw T2CON
	xorlw 1 << TMR2ON
	movwf T2CON

	return

