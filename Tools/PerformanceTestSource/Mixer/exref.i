; $VER: exref.i 1.0 (08.09.26)
;
; exref.i
; Include file containing the EXREF macro
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20260809
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

	IFND	EXREF_I
EXREF_I	SET	1

; References macro
EXREF	MACRO
		IFD \1
			XDEF \2
		ELSE
			XREF \2
		ENDIF
		ENDM

	ENDC
; End of File