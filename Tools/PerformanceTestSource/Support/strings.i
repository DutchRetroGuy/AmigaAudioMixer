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
	IFND EXREF
EXREF	MACRO
		IFD BUILD_STRINGS_PMIX
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; External references
	EXREF	titletxt
	EXREF	resscrtxt
	EXREF	resscrtxt_2
	EXREF	palhtxt
	EXREF	ntschtxt
	EXREF	singhtxt
	EXREF	multhtxt
	EXREF	perstxt
	EXREF	permtxt
	EXREF	subtxt
	EXREF	ressbtxt
	
	EXREF	res_offset
	EXREF	res_line_offset
	EXREF	res_offset_2
	EXREF	res_line_offset_2
	
	EXREF	cntxt1
	EXREF	cntxt_ptrs
; End of File