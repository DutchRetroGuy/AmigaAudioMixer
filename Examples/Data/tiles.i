; $VER: tiles.i 1.0 (07.03.19)
;
; tiles.i
; Include file for tiles.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; References macro
	IFND EXREF
EXREF	MACRO
		IFD BUILD_TILES
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; External references
	EXREF	sb_tiles
	
; Constants
sb_tsize		EQU 16*3*2	; 16 lines/3 planes/1 word
sb_tbsize	EQU (16*3)<<6|1

; End of File