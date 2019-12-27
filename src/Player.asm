;
; Playback code.
;
Player: MACRO
	driver:
		dw 0
	enableVisualization:
		db 0
	visualization:
		Visualization
	ENDM

; a = enable visualisation
; de = driver
; ix = this
Player_Construct:
	ld (ix + Player.driver),e
	ld (ix + Player.driver + 1),d
	ld (ix + Player.enableVisualization),a
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

; ix = this
; ix <- visualization
Player_GetVisualization:
	ld de,Player.visualization
	add ix,de
	ret

; ix = this
; a <- indirect VDP register
Player_StartVisualisation:
	ld a,32 | 128
	bit 0,(ix + Player.enableVisualization)
	ret z
 	push ix
	call Player_GetVisualization
	call Visualization_Construct
	pop ix
	ld a,23 | 128
	ret

; ix = this
Player_StopVisualisation:
	bit 0,(ix + Player.enableVisualization)
	ret z
	push ix
	call Player_GetVisualization
	call Visualization_Destruct
	pop ix
	ret

; iy = track
; ix = this
Player_Play:
	call Track_IsEmptyIY
	ret z
	call Player_StartVisualisation
	ld b,17
	call VDP_SetRegister
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
	call Player_StopVisualisation
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
HREndLoop:
	in a,(VDP_PORT_1)
	add a,a
	add a,a
	jp m,HREndLoop
	jr nc,NoVBlank
	ld b,1
NoVBlank:
	ld e,(hl)
HRStartLoop:
	in a,(VDP_PORT_1)
	and 00100000B
	jp z,HRStartLoop
	ld a,e
	add a,b
	out (VDP_PORT_3),a
	ld a,(de)
	out (c),a
	dec b
	inc hl
	bit 6,h
	jr z,Loop
	exx
	inc c
	djnz BankLoop
	ret
	ENDP
