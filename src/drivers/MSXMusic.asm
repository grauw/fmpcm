;
; YM2413 OPLL MSX-MUSIC driver.
;
MSXMusic_ADDRESS: equ 7CH
MSXMusic_DATA: equ 7DH
MSXMusic_ID_ADDRESS: equ 4018H
MSXMusic_ENABLE_ADDRESS: equ 7FF6H

MSXMusic: MACRO
	super:
		Driver MSXMusic_DATA, MSXMusic_amplitudeMap
	slot:
		db 0
	internal:
		db 0
	ENDM

; ix = this
MSXMusic_Construct:
	call MSXMusic_Detect
	jp nc,Driver_SetNotFound
	ld (ix + MSXMusic.slot),a
	ld (ix + MSXMusic.internal),b
	call MSXMusic_Enable
	ld bc,0FH << 8 | 0
	call MSXMusic_SetRegister
	ld bc,30H << 8 | 0F0H
	call MSXMusic_SetRegister
	ld bc,20H << 8 | 1FH
	call MSXMusic_SetRegister
	ld bc,0FH << 8 | 00001111B
	call MSXMusic_SetRegister
	ld a,19H  ; access through alias to avoid modulator delay
	out (MSXMusic_ADDRESS),a
	ret

; ix = this
MSXMusic_Destruct:
	call Driver_IsFound
	ret z
	ld bc,0FH << 8 | 00H
	call MSXMusic_SetRegister
	call MSXMusic_Disable
	ret

; ix = this
MSXMusic_Enable:
	bit 0,(ix + MSXMusic.internal)
	ret nz
	ld a,(ix + MSXMusic.slot)
	ld hl,MSXMusic_ENABLE_ADDRESS
	call Memory_ReadSlot
	set 0,a
	ld e,a
	ld a,(ix + MSXMusic.slot)
	ld hl,MSXMusic_ENABLE_ADDRESS
	jp Memory_WriteSlot

; ix = this
MSXMusic_Disable:
	bit 0,(ix + MSXMusic.internal)
	ret nz
	ld a,(ix + MSXMusic.slot)
	ld hl,MSXMusic_ENABLE_ADDRESS
	call Memory_ReadSlot
	res 0,a
	ld e,a
	ld a,(ix + MSXMusic.slot)
	ld hl,MSXMusic_ENABLE_ADDRESS
	jp Memory_WriteSlot

; b = address
; c = data
MSXMusic_SetRegister:
	ld a,b
	out (MSXMusic_ADDRESS),a
	in a,(VDP_PORT_1)
	in a,(VDP_PORT_1)
	ld a,c
	out (MSXMusic_DATA),a
	in a,(VDP_PORT_1)
	in a,(VDP_PORT_1)
	in a,(VDP_PORT_1)
	in a,(VDP_PORT_1)
	in a,(VDP_PORT_1)
	in a,(VDP_PORT_1)
	in a,(VDP_PORT_1)
	in a,(VDP_PORT_1)
	ret

; f <- c: found
; a <- slot
; b <- 0: external, -1: internal
MSXMusic_Detect:
	ld hl,MSXMusic_MatchInternalID
	call Memory_SearchSlots
	ld b,-1
	ret c
	ld hl,MSXMusic_MatchExternalID
	call Memory_SearchSlots
	ld b,0
	ret

; a = slot id
; f <- c: found
MSXMusic_MatchInternalID:
	ld de,MSXMusic_internalId
	ld hl,MSXMusic_ID_ADDRESS
	ld bc,8
	jp Memory_MatchSlotString

; a = slot id
; ix = this
; f <- c: found
MSXMusic_MatchExternalID:
	ld de,MSXMusic_externalId
	ld hl,MSXMusic_ID_ADDRESS + 4
	ld bc,4
	jp Memory_MatchSlotString

;
MSXMusic_internalId:
	db "APRLOPLL"

MSXMusic_externalId:
	db "OPLL"

	ALIGN 100H
MSXMusic_amplitudeMap:
	db 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128
	db 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144
	db 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160
	db 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176
	db 192, 192, 192, 192, 192, 192, 192, 192, 192, 192, 192, 192, 192, 192, 192, 192
	db 208, 208, 208, 208, 208, 208, 208, 208, 208, 208, 208, 208, 208, 208, 208, 208
	db 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224
	db 240, 240, 240, 240, 240, 240, 240, 240, 240, 240, 240, 240, 240, 240, 240, 240
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	db 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
	db 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48
	db 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
	db 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80
	db 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96
	db 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112
