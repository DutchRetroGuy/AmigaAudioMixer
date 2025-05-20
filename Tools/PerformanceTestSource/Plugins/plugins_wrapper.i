; $VER: plugins_wrapper.i 3.7 (04.02.24)
;
; plugins_wrapper.i
; Include file for plugins_wrapper.asm
;
;
; Author: Jeroen Knoester
; Version: 3.7
; Revision: 20250130
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes

; References macro
	IFND EXREF
EXREF	MACRO
		IFD BUILD_PLUGINS_WRAPPER
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; References
	EXREF	PLPerfTest_init_routines
	EXREF	PLPerfTest_routines
	
	EXREF	plrepeat
	EXREF	plsync
	EXREF	plvolume
	EXREF	plpitch
; End of File