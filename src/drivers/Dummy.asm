;
; TurboR PCM driver.
;
Dummy_DATA: equ 7CH

Dummy: MACRO
	super:
		Driver Dummy_DATA, Dummy_amplitudeMap
	ENDM

; ix = this
Dummy_Construct:
	ret

; ix = this
Dummy_Destruct:
	ret

;
	ALIGN 100H
Dummy_amplitudeMap:
	ds 256
