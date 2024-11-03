; $VER: tiles.asm 1.0 (07.03.19)
;
; tiles.asm
; Foreground, background and subbuffer tiles
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include tiles.i
		
		section	gfxdata,data_c
		cnop	0,2

sb_tiles INCBIN "Examples/Data/sb_tiles_raw"	
; End of File