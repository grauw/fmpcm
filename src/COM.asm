;
; PCM player using horizontal blank timer.
; For YM2413 OPLL (MSX-MUSIC) and turboR PCM.
;
DEBUG: equ 1

TPA: equ RAM_PAGE0
TPA_PAGE0: equ RAM_PAGE0
TPA_PAGE1: equ RAM_PAGE1
RAM_RESIDENT: equ RAM_PAGE0
RAM: equ RAM_PAGE0

	org 100H

RAM_PAGE0: ds 3F00H
RAM_PAGE1: ds 4000H

	SECTION TPA

	DOS2Runtime Application_Main

	INCLUDE "Macros.asm"
	INCLUDE "DOS.asm"
	INCLUDE "DOS2Runtime.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "Memory.asm"
	INCLUDE "Mapper.asm"
	INCLUDE "Heap.asm"
	INCLUDE "VDP.asm"
	INCLUDE "VDPCommand.asm"
	INCLUDE "Application.asm"
	INCLUDE "CLI.asm"
	INCLUDE "Track.asm"
	INCLUDE "Player.asm"
	INCLUDE "Visualization.asm"
	INCLUDE "drivers/Drivers.asm"

	ENDS

	SECTION RAM

Heap_main:
	Heap

	ENDS

	SECTION RAM_PAGE1

	ALIGN 4
HEAP: equ $
HEAP_SIZE: equ 8000H - HEAP

	ENDS
