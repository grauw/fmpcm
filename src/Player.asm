;
; Playback code.
;
Player: MACRO
	driver:
		dw 0
	ENDM

; de = driver
; ix = this
Player_Construct:
	ld (ix + Player.driver),e
	ld (ix + Player.driver + 1),d
	ret

; ix = this
Player_Destruct:
	ret

; ix = this
Player_GetDriver:
	ld e,(ix + Player.driver)
	ld d,(ix + Player.driver + 1)
	ld ixl,e
	ld ixh,d
	ret

; iy = track
; ix = this
Player_Play:
	call Track_IsEmptyIY
	ret z
	di
	ld a,2
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(0AAH)
	and 0F0H
	or 7  ; ESC row
	out (0AAH),a
	exx
	push ix
	call Player_GetDriver
	call Driver_GetPort
	call Driver_GetMapping
	pop ix
	ld l,0
	exx
	ld hl,ROM_BANK_8000_CHANGE
	ld c,(iy + Track.startBank)
	ld b,(iy + Track.bankCount)
	call Player_PlayBanks
	ld a,1
	ld (ROM_BANK_8000_CHANGE),a
	ld a,0
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	ei
	ret

; c = start bank
; b = bank count
; c' = port
; d' = mapping MSB
; l' = 0
Player_PlayBanks: PROC
BankLoop:
	ld (hl),c
	exx
	ld h,80H
Loop:
	in a,(0A9H)
	and 00000100B  ; ESC
	ret z
	ld e,(hl)
HREndLoop:
	in a,(VDP_PORT_1)
	and 00100000B
	jp nz,HREndLoop
HRStartLoop:
	in a,(VDP_PORT_1)
	and 00100000B
	jp z,HRStartLoop
	ld a,(de)
	out (c),a
	inc hl
	bit 6,h
	jr z,Loop
	exx
	inc c
	djnz BankLoop
	ret
	ENDP
