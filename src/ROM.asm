;
; PCM player using horizontal blank timer.
; For YM2413 OPLL (MSX-MUSIC) and turboR PCM.
;
DEBUG: equ 1

TPA_PAGE1: equ ROM_PAGE1
RAM_RESIDENT: equ RAM

ROM_BANK_8000_CHANGE: equ 7000H

	org 4000H

ROM_PAGE1: ds 4000H

	SECTION ROM_PAGE1

	db "AB"
	dw Application_Main
	dw Application_Call
	dw 0, 0, 0, 0, 0

	INCLUDE "Macros.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "Memory.asm"
	INCLUDE "VDP.asm"
	INCLUDE "VDPCommand.asm"
	INCLUDE "Application.asm"
	INCLUDE "Track.asm"
	INCLUDE "Player.asm"
	INCLUDE "drivers/Drivers.asm"
	INCLUDE "RAM.asm"

	ENDS

	org 4000H
ROM_wave:
	INCBIN "../res/sample.raw"
ROM_waveEnd:

	ALIGN 4000H
