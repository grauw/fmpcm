;
; Application code.
;
Application: MACRO
	cli:
		CLI
	drivers:
		Drivers
	track:
		Track
	player:
		Player
	ENDM

Application_Main:
	ld ix,Heap_main
	call Heap_Construct
	ld bc,HEAP_SIZE
	ld de,HEAP
	call Heap_Free
	ld ix,Mapper_instance
	call Mapper_Construct
	ld ix,Application_instance
	call Application_Construct
	ld hl,Application_Run
	call System_TryCall
	call Application_Destruct
	ld ix,Mapper_instance
	call Mapper_Destruct
	ret

; ix = this
Application_Construct:
	push ix
	call Application_GetCLI
	call CLI_Construct
	pop ix
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
	call Application_GetCLI_IY
	ld a,(iy + CLI.quiet)
	cpl
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
; ix <- CLI
Application_GetCLI:
	ld de,Application.cli
	add ix,de
	ret

; ix = this
; iy <- CLI
Application_GetCLI_IY:
	ld e,ixl
	ld d,ixh
	ld iy,Application.cli
	add iy,de
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

; hl = string
; ix = this
Application_Print:
	push af
	call Application_GetCLI_IY
	bit 0,(iy + CLI.quiet)
	call z,System_Print
	pop af
	ret

; ix = this
Application_Run: PROC
	ld hl,Application_welcome
	call Application_Print
	push ix
	call Application_GetCLI
	call CLI_HasFileInfoBlock
	pop ix
	ld hl,Application_usageInstructions
	call z,System_ThrowExceptionWithMessage
Loop:
	call Application_Load
	call Application_Play
	call Application_Unload
	push ix
	call Application_GetCLI
	call CLI_NextPath
	pop ix
	jr nc,Loop
	ret
	ENDP

; ix = this
Application_Load:
	call Application_PrintLoading
	push ix
	push ix
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	ex (sp),ix
	call Application_GetTrack
	pop de
	call Track_Load
	pop ix
	ret

; ix = this
Application_PrintLoading:
	push ix
	ld hl,Application_loading
	call Application_Print
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	call FileInfoBlock_GetName
	pop ix
	call Application_Print
	ld hl,Application_dotDotDot
	call Application_Print
	ret

; ix = this
Application_Unload:
	push ix
	call Application_GetTrack
	call Track_Unload
	pop ix
	ret

; ix = this
Application_Play:
	ld hl,Application_playing
	call Application_Print
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

Application_welcome:
	db "FM PCM Player 1.0 by Grauw",13,10,10
	db "Plays 15.7 kHz 8-bit signed PCM on MSX-MUSIC (YM2413 OPLL).",13,10
	db "Press ESC to end playback.",13,10,10,0

Application_loading:
	db "Loading ",0

Application_dotDotDot:
	db "...",13,10,0

Application_playing:
	db "Playing...",13,10,0

Application_driverNotFound:
	db "MSX-MUSIC not found.",13,10,0

Application_usageInstructions:
	db "Usage: fmpcm [options] <file.raw>",13,10
	db 13,10
	db "Options:",13,10
	db "  /q  No messages and visualisation.",13,10,0
