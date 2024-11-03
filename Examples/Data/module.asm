; $VER: module.asm 1.0 (31.03.19)
;
; module.asm
; Source module data
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190331
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include module.i
		
		section	gfxdata,data_c
		cnop	0,2

module		INCBIN	"Examples/Data/SneakyChick.mod"
lspsam		INCBIN	"Examples/Data/SneakyChick.lsbank"

		section	data,data
lspdat		INCBIN	"Examples/Data/SneakyChick.lsmusic"
; End of File