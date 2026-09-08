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

	include exref.i

; External references
	EXREF	BUILD_BLITTER,BlitPattern
	EXREF	BUILD_BLITTER,BlitCopy
	EXREF	BUILD_BLITTER,BlitBob
	EXREF	BUILD_BLITTER,BlitClearScreen
	
	EXREF	BUILD_BLITTER,DrawSubBuffer
	
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