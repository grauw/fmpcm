;
; Sample wave visualisation effect.
;
Visualization: MACRO
	foregroundColor:
		db 0
	backgroundColor:
		db 0
	borderColor:
		db 0
	clearCommand:
		VDPCommand 0, 0, 0, 212, 512, 44, 0, 0, VDPCommand_HMMV
	lmmvCommand:
		VDPCommand 0, 0, 0, 0, 1, 1, 3, 0, VDPCommand_LMMV
	ENDM

; iy = track
; ix = this
Visualization_Construct:
	ld a,(FORCLR)
	ld (ix + Visualization.foregroundColor),a
	ld a,0
	ld (FORCLR),a
	ld a,(BAKCLR)
	ld (ix + Visualization.backgroundColor),a
	ld a,0
	ld (BAKCLR),a
	ld a,(BDRCLR)
	ld (ix + Visualization.borderColor),a
	ld a,0
	ld (BDRCLR),a
	push ix
	ld a,6
	ld ix,CHGMOD
	call System_CallBIOS
	pop ix
	call VDP_EnableBlank
	call VDP_DisableSprites
	ld hl,Visualization_palette
	call VDP_SetPalette
	call Visualization_Draw
	call Visualization_WaitVBlank
	call VDP_DisableBlank
	ret

; ix = this
Visualization_Destruct:
	call VDP_EnableBlank
	ld a,(ix + Visualization.foregroundColor)
	ld (FORCLR),a
	ld a,(ix + Visualization.backgroundColor)
	ld (BAKCLR),a
	ld a,(ix + Visualization.borderColor)
	ld (BDRCLR),a
	call VDP_EnableSprites
	push ix
	ld ix,TOTEXT
	call System_CallBIOS
	pop ix
	call VDP_DisableBlank
	ret

; iy = track
; ix = this
Visualization_Draw: PROC
	push ix
	ld de,Visualization.clearCommand
	add ix,de
	call VDPCommand_Execute
	pop ix
	ld bc,0
	bit 0,(iy + Track.unsignedPCM)
	jr z,Loop
	ld c,80H
Loop:
	ld a,c  ; signed / unsigned
	sub b
	jp m,Negative
Positive:
	ld (ix + Visualization.lmmvCommand.dx),0
	ld (ix + Visualization.lmmvCommand.dx + 1),1
	inc a
	jr Continue
Negative:
	ld (ix + Visualization.lmmvCommand.dx),a
	ld (ix + Visualization.lmmvCommand.dx + 1),0
	neg
Continue:
	ld (ix + Visualization.lmmvCommand.nx),a
	push af
	push bc
	push ix
	ld de,Visualization.lmmvCommand
	add ix,de
	call VDPCommand_Execute
	pop ix
	pop bc
	pop af
	inc (ix + Visualization.lmmvCommand.dy)
	djnz Loop
	ret
	ENDP

; ix = this
Visualization_WaitVBlank: PROC
	di
	ld a,2
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
VREndLoop:
	in a,(VDP_PORT_1)
	bit 6,a
	jr nz,VREndLoop
VRStartLoop:
	in a,(VDP_PORT_1)
	bit 6,a
	jr z,VRStartLoop
	ld a,0
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	ei
	ret
	ENDP

;
Visualization_palette:
	dw 000H, 000H, 000H, 070H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
