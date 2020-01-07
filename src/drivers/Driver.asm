;
; Sound chip driver.
;
Driver: MACRO ?port, ?mapping
	found:
		db 1
	port:
		db ?port
	mapping:
		db ?mapping >> 8
	unsignedPCM:
		db 0
	ENDM

; ix = this
; f <- nz: found
Driver_IsFound:
	bit 0,(ix + Driver.found)
	ret

; ix = this
Driver_SetNotFound:
	ld (ix + Driver.found),0
	ret

; ix = this
; c <- port
Driver_GetPort:
	ld c,(ix + Driver.port)
	ret

; ix = this
; de <- mapping
Driver_GetMapping:
	ld e,0
	ld d,(ix + Driver.mapping)
	ret

; a = unsigned PCM
; ix = this
Driver_SetUnsignedPCM:
	cp (ix + Driver.unsignedPCM)
	ret z
	ld (ix + Driver.unsignedPCM),a
	call Driver_GetMapping
	ld b,80H
	ld hl,0080H
	add hl,de
Loop:
	ld a,(de)
	ld c,(hl)
	ex de,hl
	ld (de),a
	ld (hl),c
	inc de
	inc hl
	djnz Loop
	ret
