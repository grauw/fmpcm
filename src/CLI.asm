;
; Command-line interface parser
;
CLI_BUFFER_SIZE: equ 255

CLI: MACRO
	pathIndex:
		db 1
	fileInfoBlockReference:
		dw 0
	loops:
		db 1
	quiet:
		db 0
	disableVisualization:
		db 0
	preferTurboRPCM:
		db 0
	halfRate:
		db 0
	unsignedPCM:
		db 0
	fileInfoBlock:
		FileInfoBlock
	_size:
	ENDM

; ix = this
; ix <- this
CLI_Construct:
	ld (ix + CLI.pathIndex),1
	jr CLI_Parse

; ix = this
; ix <- this
CLI_Destruct: equ System_Return
;	ret

; ix = this
; ix <- file info block
CLI_GetFileInfoBlock:
	ld e,(ix + CLI.fileInfoBlockReference)
	ld d,(ix + CLI.fileInfoBlockReference + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; f <- nz: has file info block
CLI_HasFileInfoBlock:
	ld a,(ix + CLI.fileInfoBlockReference)
	or (ix + CLI.fileInfoBlockReference + 1)
	ret

; ix = this
CLI_Parse: PROC
	ld (ix + CLI.fileInfoBlockReference),0
	ld (ix + CLI.fileInfoBlockReference + 1),0
	push ix
	ld ix,Heap_main
	ld bc,CLI_BUFFER_SIZE
	call Heap_Allocate
	pop ix
	ld a,(ix + CLI.pathIndex)
	push af
	push bc
	push de
	ld hl,CLI_parametersEnvName
	ld b,CLI_BUFFER_SIZE
	call DOS_GetEnvironmentItem
	ld hl,Loop
	call System_TryCall
	pop de
	pop bc
	pop af
	ld (ix + CLI.pathIndex),a
	push ix
	ld ix,Heap_main
	call Heap_Free
	pop ix
	jp System_Rethrow
Loop:
	ld a,(de)
	and a
	ret z
	cp "/"
	jr z,Option
	cp " " + 1
	jr nc,Path
	inc de
	jr Loop
Option:
	call CLI_ParseOption
	jr Loop
Path:
	call CLI_ParsePath
	jr Loop
	ENDP

; de = buffer position
; ix = this
; de <- buffer position
CLI_ParseOption: PROC
	inc de
	ld a,(de)
	and 11011111B  ; upper-case
	cp "L"
	jr z,OptionLoops
	cp "Q"
	jr z,OptionQuiet
	cp "V"
	jr z,OptionDisableVisualization
	cp "R"
	jr z,OptionPreferTurboRPCM
	cp "H"
	jr z,OptionHalfRate
	cp "U"
	jr z,OptionUnsignedPCM
	ld hl,CLI_unknownOptionError
	call System_ThrowExceptionWithMessage
OptionLoops:
	inc de
	call CLI_ParseNumber
	ld (ix + CLI.loops),c
	jr Next
OptionQuiet:
	ld (ix + CLI.quiet),-1
	ld (ix + CLI.disableVisualization),-1
	inc de
	jr Next
OptionDisableVisualization:
	ld (ix + CLI.disableVisualization),-1
	inc de
	jr Next
OptionPreferTurboRPCM:
	ld (ix + CLI.preferTurboRPCM),-1
	inc de
	jr Next
OptionHalfRate:
	ld (ix + CLI.halfRate),-1
	inc de
	jr Next
OptionUnsignedPCM:
	ld (ix + CLI.unsignedPCM),-1
	inc de
	jr Next
Next:
	ld a,(de)
	cp " " + 1
	ret c
	ld hl,CLI_unknownOptionError
	call System_ThrowExceptionWithMessage
	ENDP

; de = buffer position
; ix = this
; de <- buffer position
CLI_ParsePath: PROC
	push de
Loop:
	ld a,(de)
	inc de
	cp " " + 1
	jr nc,Loop
	dec de
	and a
	jr z,FindFile
	xor a
	ld (de),a
	inc de
FindFile:
	pop hl
	call CLI_HasFileInfoBlock
	ret nz
	dec (ix + CLI.pathIndex)
	ret nz
	push de
	ex de,hl
	push ix
	ld bc,CLI.fileInfoBlock
	add ix,bc
	ld b,0
	call DOS_FindFirstEntry
	call DOS_TerminateIfError
	ld e,ixl
	ld d,ixh
	pop ix
	ld (ix + CLI.fileInfoBlockReference),e
	ld (ix + CLI.fileInfoBlockReference + 1),d
	pop de
	ret
	ENDP

; de = buffer position
; ix = this
; c <- value
; de <- buffer position
CLI_ParseNumber: PROC
	ld c,0
	ld hl,CLI_unknownOptionError
Loop:
	ld a,(de)
	cp " " + 1
	ret c
	sub "0"
	call c,System_ThrowExceptionWithMessage
	cp 10
	call nc,System_ThrowExceptionWithMessage
	call Multiply10AndAdd
	inc de
	jr Loop
Multiply10AndAdd:
	ld b,a
	ld a,c
	ld c,b
	add a,a
	call c,System_ThrowExceptionWithMessage
	ld b,a
	add a,a
	call c,System_ThrowExceptionWithMessage
	add a,a
	call c,System_ThrowExceptionWithMessage
	add a,b
	call c,System_ThrowExceptionWithMessage
	add a,c
	call c,System_ThrowExceptionWithMessage
	ld c,a
	ret
	ENDP

; ix = this
; f <- c: not found
CLI_NextPath: PROC
	call CLI_HasFileInfoBlock
	call z,System_ThrowException
	push ix
	call CLI_GetFileInfoBlock
	call DOS_FindNextEntry
	pop ix
	cp .NOFIL
	jr z,NotFound
	call DOS_TerminateIfError
	and a
	ret
NotFound:
	inc (ix + CLI.pathIndex)
	call z,System_ThrowException
	call CLI_Parse
	call CLI_HasFileInfoBlock
	ret nz
	scf
	ret
	ENDP

;
CLI_parametersEnvName:
	db "PARAMETERS",0

CLI_unknownOptionError:
	db "Unknown command line option.",13,10,0
