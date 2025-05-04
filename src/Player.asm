;
; Playback code.
;
Player_MAX_SEQUENCE_SIZE: equ Track_MAX_SEGMENTS + 16 * 2 + 1
Player_PAGE_BASE: equ 8000H

Player: MACRO
	driver:
		dw 0
	loops:
		db 1
	enableVisualization:
		db 0
	sequence:
		dw 0
	visualization:
		Visualization
	ENDM

PlayerSequence: MACRO
	slot:
		db 0
	count:
		db 0
	segments:
	ENDM

; a = enable visualisation
; b = loops (0: infinite)
; de = driver
; ix = this
Player_Construct:
	ld (ix + Player.driver),e
	ld (ix + Player.driver + 1),d
	ld (ix + Player.enableVisualization),a
	ld (ix + Player.loops),b
	push ix
	ld bc,Player_MAX_SEQUENCE_SIZE
	ld ix,Heap_main
	call Heap_Allocate
	pop ix
	ld (ix + Player.sequence),e
	ld (ix + Player.sequence + 1),d
	ret

; ix = this
Player_Destruct:
	ld e,(ix + Player.sequence)
	ld d,(ix + Player.sequence + 1)
	push ix
	ld bc,Player_MAX_SEQUENCE_SIZE
	ld ix,Heap_main
	call Heap_Free
	pop ix
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

; iy = track
; ix = this
; a <- indirect VDP register
Player_StartVisualization:
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
Player_StopVisualization:
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
	push ix
	call Player_GetDriver
	ld a,(iy + Track.unsignedPCM)
	call Driver_SetUnsignedPCM
	pop ix
	call Player_BuildSequence
	call Player_UpdateHalfRate
	call Player_StartVisualization
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
	ld a,15
	out (0A0H),a
	ld a,10001111B  ; joystick port 1
	out (0A1H),a
	ld a,14
	out (0A0H),a
	call Player_PlaySequenceLoops
	ld a,0
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	ei
	call Player_StopVisualization
	ld h,Player_PAGE_BASE >> 8
	call Track_SetInitialSegmentIY
	ret

; ix = this
Player_PlaySequenceLoops: PROC
	ld b,(ix + Player.loops)
Loop:
	push bc
	call Player_PlaySequence
	pop bc
	ret c
	ld a,b
	add a,-1
	jr nc,Loop
	ld b,a
	jr nz,Loop
	ret
	ENDP

; ix = this
; f <- c: playback aborted
Player_PlaySequence: PROC
	exx
	push ix
	call Player_GetDriver
	call Driver_GetPort
	call Driver_GetMapping
	pop ix
	ld hl,Player_PAGE_BASE
	exx
	ld l,(ix + Player.sequence)
	ld h,(ix + Player.sequence + 1)
Loop:
	ld a,(hl)
	and a
	ret z
	inc hl
	push hl
	ld h,Player_PAGE_BASE >> 8
	call Memory_SetSlot
	pop hl
	ld b,(hl)
	inc hl
	ld c,0FEH
	call Player_PlayBanks
	jr nc,Loop
	ret
	ENDP

	SECTION RAM

; b = bank count
; c = mapper port
; hl = bank sequence start
; c' = port
; d' = mapping MSB
; hl' = data start
; f <- c: playback aborted
; hl <- bank sequence end
Player_PlayBanks: PROC
	outi
	inc b
	exx
	call Loop
	exx
	ccf
	dec hl
	ret
Loop:
	call Player_PlaySample
halfRate:
	inc hl
	in a,(0A9H)
	and 00000100B  ; ESC
	ret z
	in a,(0A2H)
	and 00010000B  ; trigger A
	ret z
	call Player_PlaySample
	inc hl
	bit 6,h
	jr (Player_PAGE_BASE >> 14 & 1 ? nz : z),Loop
	ld h,Player_PAGE_BASE >> 8
	exx
	outi
	exx
	jp nz,Loop
	scf
	ret
	ENDP

	ENDS

; b = line counter
; c = port
; d = mapping MSB
; hl = sample pointer
; hl <- incremented sample pointer
Player_PlaySample: PROC
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
	ret
	ENDP

; iy = track
; ix = this
Player_UpdateHalfRate: PROC
	bit 0,(iy + Track.halfRate)
	ld a,23H  ; inc hl
	jr z,FullRate
	ld a,00H  ; nop
FullRate:
	ld (Player_PlayBanks.halfRate),a
	ret
	ENDP

; iy = track
; ix = this
Player_BuildSequence: PROC
	push ix
	push iy
	call Track_GetSegmentsAndLengthIY
	ld e,(ix + Player.sequence)
	ld d,(ix + Player.sequence + 1)
	push hl
	pop ix
	ld hl,Player_MAX_SEQUENCE_SIZE - 2
	ld a,(ix + MapperSegment.slot)
	jr NewSlot
Loop:
	ld a,(ix + MapperSegment.slot)
	cp (iy + PlayerSequence.slot)
	jr z,Continue
NewSlot:
	dec hl
	dec hl
	bit 7,h
	jr nz,Done
	ld iyl,e
	ld iyh,d
	ld (iy + PlayerSequence.slot),a
	ld (iy + PlayerSequence.count),0
	inc de
	inc de
Continue:
	ld a,(ix + MapperSegment.segment)
	ld (de),a
	inc de
	inc (iy + PlayerSequence.count)
	inc ix
	inc ix
	dec hl
	bit 7,h
	jr nz,Done
	dec bc
	ld a,b
	or c
	jr nz,Loop
Done:
	ld a,0
	ld (de),a
	pop iy
	pop ix
	ret
	ENDP
