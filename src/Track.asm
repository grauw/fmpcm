;
; PCM track.
;
Track: MACRO ?start, ?end
	length:
		dd ?end - ?start
	startBank:
		db ?start >> 14
	bankCount:
		db (?end + 3FFFH >> 14) - (?start >> 14)
	ENDM

; ix = this
Track_Construct:
	ret

; ix = this
Track_Destruct:
	ret

; iy = this
; f <- z: empty
Track_IsEmptyIY:
	ld a,(iy + Track.length)
	or (iy + Track.length + 1)
	or (iy + Track.length + 2)
	or (iy + Track.length + 3)
	ret
