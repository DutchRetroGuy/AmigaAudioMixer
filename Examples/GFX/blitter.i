; $VER: blitter.i 1.0 (07.03.18)
;
; blitter.i
; 
; Include file for blitter.asm
;
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; References macro
EXREF	MACRO
		IFD BUILD_BLITTER
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM

; External references
	EXREF	BlitPattern
	EXREF	BlitCopy
	EXREF	BlitBob
	EXREF	BlitClearScreen
	
	EXREF	DrawSubBuffer
	
; Macro's
		; Blitwait macro
		; Waits on the blitter, using blitter nasty mode
		; to reduce CPU usage of chipmemory during wait.
		; \1: adress register containing pointer to custombase
BlitWait	MACRO
			move.w	#$8400,dmacon(\1)
.bltwait_\@	btst	#6,dmaconr(\1)
			bne		.bltwait_\@
			move.w	#$0400,dmacon(\1)
			ENDM
; End of File