;
; Copy RAM initialisation data from ROM to RAM.
; These values are defined in the RAM section and copied on boot.
;
RAM_Init:
	and a
	ld hl,(HIMEM)
	ld bc,RAM_endAddress
	sbc hl,bc
	ld hl,RAM_insufficientTPA
	call c,System_ThrowExceptionWithMessage
	ld hl,RAM_sourceAddress
	ld de,RAM_startAddress
	ld bc,RAM_endAddress - RAM_startAddress
	ldir
	ret

RAM_insufficientTPA:
	db "Insufficient TPA memory.",0

RAM_sourceAddress:
	org 0C000H
RAM_startAddress:
RAM: ds 1800H
RAM_endAddress:
	org RAM_sourceAddress + (RAM_endAddress - RAM_startAddress)
