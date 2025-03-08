; $VER: module.i 1.0 (24.03.19)
;
; module.i
; Include file for module.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190324
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; References macro
	IFND EXREF
EXREF	MACRO
		IFD BUILD_MOD
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; External references
	EXREF	module
	EXREF	lspsam
	EXREF	lspdat

; End of File