;
; TurboR PCM driver.
;
TurboRPCM_DATA: equ 0A4H
TurboRPCM_CONTROL: equ 0A5H

TurboRPCM: MACRO
	super:
		Driver TurboRPCM_DATA, TurboRPCM_amplitudeMap, TurboRPCM_name
	ENDM

; ix = this
TurboRPCM_Construct:
	call TurboRPCM_Detect
	jp nc,Driver_SetNotFound
	ld a,80H
	out (TurboRPCM_DATA),a
	ld a,00000011B
	out (TurboRPCM_CONTROL),a
	ret

; ix = this
TurboRPCM_Destruct:
	call Driver_IsFound
	ret z
	ld a,00000010B
	out (TurboRPCM_CONTROL),a
	ld a,80H
	out (TurboRPCM_DATA),a
	ret

; f <- c: found
TurboRPCM_Detect:
	ld hl,IDBYT2
	call System_ReadBIOS
	add a,-3
	ret

;
TurboRPCM_name:
	db "TurboR PCM",0

	SECTION RAM

	ALIGN 100H
TurboRPCM_amplitudeMap:
	db 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143
	db 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159
	db 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175
	db 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191
	db 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207
	db 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223
	db 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239
	db 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255
	db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
	db 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
	db 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47
	db 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63
	db 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79
	db 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95
	db 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111
	db 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127

	ENDS
