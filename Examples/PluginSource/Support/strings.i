; $VER: strings.i 1.0 (10.03.23)
;
; strings.i
; 
; Include file for strings.asm. 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20230310
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; References macro
EXREF	MACRO
		IFD BUILD_STRINGS_PL
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM

; External references
	EXREF	preptxt
	EXREF	titletxt
	EXREF	maintxt
	EXREF	palhtxt
	EXREF	ntschtxt
	
	EXREF	subpreptxt
	EXREF	substarttxt
	EXREF	subtxt
	
	EXREF	chantxt_ptrs
	EXREF	acttxt_ptrs
	EXREF	pltxt_ptrs
; End of File
