;
; TurboR PCM driver.
;
Dummy_DATA: equ 7CH

Dummy: MACRO
	super:
		Driver Dummy_DATA, Dummy_amplitudeMap, Dummy_name
	ENDM

; ix = this
Dummy_Construct:
	ret

; ix = this
Dummy_Destruct:
	ret

;
Dummy_name:
	db "None",0

	ALIGN 100H
Dummy_amplitudeMap:
	ds 256
