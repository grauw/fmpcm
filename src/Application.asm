;
; Application code.
;
Application: MACRO
	drivers:
		Drivers
	track:
		Track ROM_wave, ROM_waveEnd
	player:
		Player
	ENDM

Application_Call: PROC
	ld a,(PROCNM)
	cp "F"
	jr nz,NotFound
	ld a,(PROCNM + 1)
	cp 0
	jr nz,NotFound
	push hl
	call Application_Main
	pop hl
	and a
	ret
NotFound:
	scf
	ret
	ENDP

Application_Main:
	ld h,80H
	call Memory_GetSlot
	push af
	ld h,40H
	call Memory_GetSlot
	ld h,80H
	call Memory_SetSlot
	call RAM_Init
	ld ix,Application_instance
	call Application_Construct
	ld hl,Application_Run
	call System_TryCall
	call Application_Destruct
	pop af
	ld h,80H
	call Memory_SetSlot
	ret

; ix = this
Application_Construct:
	push ix
	call Application_GetDrivers
	call Drivers_Construct
	pop ix
	push ix
	call Application_GetTrack
	call Track_Construct
	pop ix
	push ix
	push ix
	call Application_GetDrivers
	call Drivers_GetDriver
	ex (sp),ix
	call Application_GetPlayer
	pop de
	call Player_Construct
	pop ix
	ret

; ix = this
Application_Destruct:
	push ix
	call Application_GetPlayer
	call Player_Destruct
	pop ix
	push ix
	call Application_GetTrack
	call Track_Destruct
	pop ix
	push ix
	call Application_GetDrivers
	call Drivers_Destruct
	pop ix
	ret

; ix = this
; ix <- drivers
Application_GetDrivers:
	ld de,Application.drivers
	add ix,de
	ret

; ix = this
; ix <- track
Application_GetTrack:
	ld de,Application.track
	add ix,de
	ret

; ix = this
; ix <- player
Application_GetPlayer:
	ld de,Application.player
	add ix,de
	ret

; ix = this
Application_Run:
	call Application_Play
	ret

; ix = this
Application_Play:
	push ix
	call Application_GetTrack
	ex (sp),ix
	pop iy
	push ix
	call Application_GetPlayer
	call Player_Play
	pop ix
	ret

;
	SECTION RAM

Application_instance:
	Application

	ENDS
