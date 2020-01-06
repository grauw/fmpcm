;
; Sound chip drivers.
;
	INCLUDE "Driver.asm"
	INCLUDE "MSXMusic.asm"
	INCLUDE "TurboRPCM.asm"
	INCLUDE "Dummy.asm"

Drivers: MACRO
	preferTurboRPCM:
		db 0
	msxMusic:
		MSXMusic
	turboRPCM:
		TurboRPCM
	dummy:
		Dummy
	ENDM

; a = prefer turboR PCM
; ix = this
Drivers_Construct:
	ld (ix + Drivers.preferTurboRPCM),a
	push ix
	call Drivers_GetMSXMusic
	call MSXMusic_Construct
	pop ix
	push ix
	call Drivers_GetTurboRPCM
	call TurboRPCM_Construct
	pop ix
	push ix
	call Drivers_GetDummy
	call Dummy_Construct
	pop ix
	ret

; ix = this
Drivers_Destruct:
	push ix
	call Drivers_GetMSXMusic
	call MSXMusic_Destruct
	pop ix
	push ix
	call Drivers_GetTurboRPCM
	call TurboRPCM_Destruct
	pop ix
	push ix
	call Drivers_GetDummy
	call Dummy_Destruct
	pop ix
	ret

; ix = this
; ix <- MSX-MUSIC
Drivers_GetMSXMusic:
	ld de,Drivers.msxMusic
	add ix,de
	ret

; ix = this
; ix <- TurboR PCM
Drivers_GetTurboRPCM:
	ld de,Drivers.turboRPCM
	add ix,de
	ret

; ix = this
; ix <- dummy
Drivers_GetDummy:
	ld de,Drivers.msxMusic
	add ix,de
	ret

; ix = this
; ix <- driver
; f <- nz: found
Drivers_GetDriver:
	bit 0,(ix + Drivers.preferTurboRPCM)
	jr nz,Drivers_GetDriverPreferTurboRPCM
	ld de,Drivers.msxMusic
	add ix,de
	call Driver_IsFound
	ret nz
	ld de,Drivers.turboRPCM - Drivers.msxMusic
	add ix,de
	call Driver_IsFound
	ret nz
	ld de,Drivers.dummy - Drivers.turboRPCM
	add ix,de
	call Driver_IsFound
	ret

; ix = this
; ix <- driver
; f <- nz: found
Drivers_GetDriverPreferTurboRPCM:
	ld de,Drivers.turboRPCM
	add ix,de
	call Driver_IsFound
	ret nz
	ld de,Drivers.msxMusic - Drivers.turboRPCM
	add ix,de
	call Driver_IsFound
	ret nz
	ld de,Drivers.dummy - Drivers.msxMusic
	add ix,de
	call Driver_IsFound
	ret
