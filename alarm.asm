alarm:
	xorlw 0
	btfss STATUS, Z
	 goto alarm_on
alarm_off:
	bcf PORTB, PIN_ALARM
	return
alarm_on:
	bsf PORTB, PIN_ALARM
	return

