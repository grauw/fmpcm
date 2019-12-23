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
	ld bc,00H << 8 | 00H
	call MSXMusic_SetRegister
	ld bc,01H << 8 | 24H
	call MSXMusic_SetRegister
	ld bc,02H << 8 | 3FH
	call MSXMusic_SetRegister
	ld bc,03H << 8 | 00H
	call MSXMusic_SetRegister
	ld bc,04H << 8 | 0FFH
	call MSXMusic_SetRegister
	ld bc,05H << 8 | 0FFH
	call MSXMusic_SetRegister
	ld bc,06H << 8 | 0FH
	call MSXMusic_SetRegister
	ld bc,07H << 8 | 0FH
	call MSXMusic_SetRegister
	ld bc,30H << 8 | 00H
	call MSXMusic_SetRegister
	ld bc,10H << 8 | 00H
	call MSXMusic_SetRegister
	ld bc,20H << 8 | 1EH
	call MSXMusic_SetRegister
	ld bc,0FH << 8 | 04H
	call MSXMusic_SetRegister
	ld a,10H
	out (MSXMusic_ADDRESS),a
	ret

; ix = this
MSXMusic_Destruct:
	call Driver_IsFound
	ret z
	ld bc,20H << 8 | 0EH
	call MSXMusic_SetRegister
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
	db 85, 86, 87, 88, 88, 89, 90, 91, 91, 92, 93, 93, 94, 95, 96, 97
	db 97, 98, 99, 100, 100, 101, 102, 103, 104, 105, 105, 106, 107, 108, 108, 109
	db 110, 111, 112, 113, 113, 114, 115, 116, 117, 118, 118, 119, 120, 121, 122, 123
	db 124, 125, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138
	db 139, 140, 141, 142, 143, 143, 144, 145, 147, 148, 149, 150, 151, 152, 153, 154
	db 155, 156, 157, 158, 158, 160, 162, 163, 163, 165, 167, 168, 169, 170, 172, 173
	db 174, 176, 177, 178, 180, 181, 183, 184, 186, 188, 189, 191, 192, 194, 195, 197
	db 200, 201, 204, 205, 208, 209, 212, 214, 217, 219, 223, 226, 231, 234, 241, 248
	db 0, 0, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7, 7, 8, 9, 9
	db 10, 10, 11, 12, 12, 13, 14, 14, 15, 16, 16, 17, 18, 18, 19, 19
	db 20, 21, 21, 22, 23, 23, 24, 25, 25, 26, 27, 27, 28, 28, 29, 30
	db 30, 31, 32, 32, 33, 34, 34, 35, 36, 36, 37, 38, 38, 39, 40, 40
	db 41, 42, 42, 43, 44, 44, 45, 46, 46, 47, 48, 48, 49, 50, 50, 51
	db 52, 52, 53, 54, 54, 55, 56, 56, 57, 58, 58, 59, 60, 60, 61, 62
	db 63, 63, 64, 65, 65, 66, 67, 67, 68, 69, 69, 70, 71, 71, 72, 73
	db 74, 74, 75, 76, 77, 77, 78, 79, 80, 80, 81, 82, 82, 83, 84, 84
