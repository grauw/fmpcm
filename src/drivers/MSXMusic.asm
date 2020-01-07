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
	ld bc,01H << 8 | 2CH
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

	SECTION RAM

	ALIGN 100H
MSXMusic_amplitudeMap:
	db 0, 170, 1, 169, 2, 168, 3, 3, 167, 4, 166, 5, 165, 6, 6, 164
	db 7, 163, 8, 162, 9, 9, 161, 10, 160, 11, 159, 12, 12, 158, 13, 157
	db 14, 156, 15, 155, 16, 16, 154, 17, 153, 18, 152, 19, 151, 20, 20, 150
	db 21, 149, 22, 148, 23, 147, 24, 146, 25, 145, 26, 144, 27, 143, 28, 28
	db 142, 141, 30, 140, 31, 31, 139, 138, 33, 137, 34, 136, 35, 135, 36, 134
	db 37, 133, 38, 132, 131, 40, 130, 41, 129, 42, 128, 127, 44, 126, 125, 46
	db 124, 123, 48, 122, 121, 50, 120, 119, 52, 53, 117, 116, 55, 56, 57, 113
	db 58, 111, 110, 109, 62, 63, 64, 66, 67, 69, 70, 72, 73, 76, 78, 83
	db 254, 249, 246, 244, 242, 241, 239, 238, 237, 235, 234, 233, 232, 231, 230, 229
	db 228, 227, 227, 226, 225, 224, 223, 223, 222, 221, 221, 220, 219, 218, 218, 217
	db 217, 216, 215, 215, 214, 213, 213, 212, 212, 211, 210, 210, 209, 209, 208, 208
	db 207, 206, 206, 205, 205, 204, 204, 203, 203, 202, 202, 201, 201, 200, 200, 199
	db 199, 198, 198, 197, 197, 196, 196, 195, 195, 194, 194, 194, 193, 193, 192, 192
	db 191, 191, 190, 190, 189, 189, 189, 188, 188, 187, 187, 186, 186, 185, 185, 185
	db 184, 184, 183, 183, 182, 182, 181, 181, 181, 180, 180, 179, 179, 178, 178, 178
	db 177, 177, 176, 176, 175, 175, 175, 174, 174, 173, 173, 172, 172, 172, 171, 171

	ENDS
