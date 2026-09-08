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

	include exref.i

; External references
	EXREF	BUILD_TILES,sb_tiles
	
; Constants
sb_tsize	EQU 16*3*2	; 16 lines/3 planes/1 word
sb_tbsize	EQU (16*3)<<6|1

; End of File