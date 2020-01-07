;
; PCM track.
;
Track_MAX_SEGMENTS: equ 400H
Track_LOAD_BUFFER_SIZE: equ 2000H

Track: MACRO
	length:
		dd 0
	halfRate:
		db 0
	unsignedPCM:
		db 0
	segmentCount:
		dw 0
	segments:
		dw 0
	loadBuffer:
		dw 0
	ENDM

; a = half rate (7850 Hz)
; b = unsigned PCM
; ix = this
Track_Construct:
	ld (ix + Track.halfRate),a
	ld (ix + Track.unsignedPCM),b
	push ix
	ld bc,Track_MAX_SEGMENTS * MapperSegment._size
	ld ix,Heap_main
	call Heap_Allocate
	pop ix
	ld (ix + Track.segments),e
	ld (ix + Track.segments + 1),d
	push ix
	ld bc,Track_LOAD_BUFFER_SIZE
	ld ix,Heap_main
	call Heap_Allocate
	pop ix
	ld (ix + Track.loadBuffer),e
	ld (ix + Track.loadBuffer + 1),d
	push iy
	call Track_GetSegments_IY
	ld h,80H
	push bc
	call Memory_GetSlot
	pop bc
	ld (iy + MapperSegment.slot),a
	call Mapper_instance.GetP2
	ld (iy + MapperSegment.segment),a
	pop iy
	ld (ix + Track.segmentCount),1
	ld (ix + Track.segmentCount + 1),0
	ret

; ix = this
Track_Destruct:
	call Track_Unload
	ld e,(ix + Track.loadBuffer)
	ld d,(ix + Track.loadBuffer + 1)
	push ix
	ld bc,Track_LOAD_BUFFER_SIZE
	ld ix,Heap_main
	call Heap_Free
	pop ix
	ld e,(ix + Track.segments)
	ld d,(ix + Track.segments + 1)
	push ix
	ld bc,Track_MAX_SEGMENTS * MapperSegment._size
	ld ix,Heap_main
	call Heap_Free
	pop ix
	ret

; ix = this
; iy <- segments
Track_GetSegments_IY:
	ld e,(ix + Track.segments)
	ld d,(ix + Track.segments + 1)
	ld iyl,e
	ld iyh,d
	ret

; iy = this
; hl <- segments
; bc <- segments count (excluding empty last)
Track_GetSegmentsAndLengthIY:
	ld l,(iy + Track.segments)
	ld h,(iy + Track.segments + 1)
	ld c,(iy + Track.segmentCount)
	ld b,(iy + Track.segmentCount + 1)
	ld a,(iy + Track.length)
	and a
	ret nz
	ld a,(iy + Track.length + 1)
	and 3FH
	ret nz
	dec bc
	ret

; iy = this
; f <- z: empty
Track_IsEmptyIY:
	ld a,(iy + Track.length)
	or (iy + Track.length + 1)
	or (iy + Track.length + 2)
	or (iy + Track.length + 3)
	ret

; ix = this
Track_SetInitialSegment:
	push iy
	call Track_GetSegments_IY
	ld a,(iy + MapperSegment.segment)
	call Mapper_instance.PutP2
	ld a,(iy + MapperSegment.slot)
	ld h,80H
	call Memory_SetSlot
	pop iy
	ret

; iy = this
Track_SetInitialSegmentIY:
	push iy
	ex (sp),ix
	call Track_SetInitialSegment
	ex (sp),ix
	pop iy
	ret

; ix = this
Track_Unload: PROC
	call Track_GetSegments_IY
	ld c,(ix + Track.segmentCount)
	ld b,(ix + Track.segmentCount + 1)
	jr SkipFirst
Loop:
	push bc
	ld a,(iy + MapperSegment.segment)
	ld b,(iy + MapperSegment.slot)
	call Mapper_instance.Free
	call c,System_ThrowException
	pop bc
SkipFirst:
	inc iy
	inc iy
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ld (ix + Track.segmentCount),1
	ld (ix + Track.segmentCount + 1),0
	ld (ix + Track.length),0
	ld (ix + Track.length + 1),0
	ld (ix + Track.length + 2),0
	ld (ix + Track.length + 3),0
	ret
	ENDP

; de = path / file info block
; ix = this
Track_Load: PROC
	ld a,00000001B  ; read-only
	call DOS_OpenFileHandle
	call DOS_TerminateIfError
	push bc
	ld hl,Track_ReadFile
	call System_TryCall
	pop bc
	call DOS_CloseFileHandle
	call DOS_TerminateIfError
	ret
	ENDP

; b = file handle
; ix = this
Track_ReadFile: PROC
	call Track_GetSegments_IY
Loop:
	call Track_GetDestinationAndSpace
	call Track_ReadFromFileHandle
	cp .EOF
	jr z,Done
	call DOS_TerminateIfError
	push bc
	call Track_AddLength
	pop bc
	jr c,OutOfMemory
	jr Loop
Done:
	call Track_Pad
OutOfMemory:
	call Track_SetInitialSegment
	ret
	ENDP

; ix = this
; hl <- remaining space
; de <- destination
Track_GetDestinationAndSpace:
	ld e,(ix + Track.length)
	ld d,(ix + Track.length + 1)
	res 6,d
	res 7,d
	ld hl,4000H
	and a
	sbc hl,de
	set 7,d
	ret

; hl = amount
; ix = this
; f <- c: max length reached
Track_AddLength: PROC
	call Add
	ld a,d
	xor h
	and 0C0H
	jp nz,Track_AddNewSegment
	and a
	ret
Add:
	ld e,(ix + Track.length)
	ld d,(ix + Track.length + 1)
	add hl,de
	ld (ix + Track.length),l
	ld (ix + Track.length + 1),h
	ret nc
	inc (ix + Track.length + 2)
	ret nz
	inc (ix + Track.length + 3)
	ret
	ENDP

; iy = segment
; ix = this
; f <- c: out of memory
Track_AddNewSegment:
	ld e,(ix + Track.segmentCount)
	ld d,(ix + Track.segmentCount + 1)
	ld hl,-Track_MAX_SEGMENTS
	add hl,de
	ret c
	ld a,(Mapper_instance.primaryMapperSlot)
	or 00100000B  ; allocate primary slot, or another
	ld b,a
	ld a,0
	call Mapper_instance.Allocate
	ret c
	inc de
	ld (ix + Track.segmentCount),e
	ld (ix + Track.segmentCount + 1),d
	inc iy
	inc iy
	ld (iy + MapperSegment.segment),a
	ld (iy + MapperSegment.slot),b
	ld a,(iy + MapperSegment.slot)
	ld h,80H
	call Memory_SetSlot
	ld a,(iy + MapperSegment.segment)
	call Mapper_instance.PutP2
	and a
	ret

; ix = this
Track_Pad:
	call Track_GetDestinationAndSpace
	ld c,l
	ld b,h
	ld l,e
	ld h,d
	ld (hl),0
	inc de
	dec bc
	ld a,b
	or c
	call nz,System_FastLDIR
	ret

; b = file handle
; de = destination buffer
; hl = number of bytes to read
; ix = this
; a <- error
; f <- nz: error
; b <- file handle
; hl <- number of bytes actually read
Track_ReadFromFileHandle: PROC
	ld a,(Mapper_instance.primaryMapperSlot)
	cp (iy + MapperSegment.slot)
	jr nz,SecondarySlot
	push bc
	call DOS_ReadFromFileHandle
	pop bc
	ret
SecondarySlot:
	push bc
	push de
	ld de,Track_LOAD_BUFFER_SIZE
	and a
	sbc hl,de
	ex de,hl
	jr nc,CapSize
	add hl,de
CapSize:
	ld e,(ix + Track.loadBuffer)
	ld d,(ix + Track.loadBuffer + 1)
	call DOS_ReadFromFileHandle
	pop de
	jr nz,Error
	push af
	push hl
	ld c,l
	ld b,h
	ld l,(ix + Track.loadBuffer)
	ld h,(ix + Track.loadBuffer + 1)
	ld a,b
	or c
	call nz,System_FastLDIR
	pop hl
	pop af
Error:
	pop bc
	ret
	ENDP
