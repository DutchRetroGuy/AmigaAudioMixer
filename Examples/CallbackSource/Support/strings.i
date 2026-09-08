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

	include exref.i

; External references
	EXREF	BUILD_STRINGS_CB,preptxt
	EXREF	BUILD_STRINGS_CB,titletxt
	EXREF	BUILD_STRINGS_CB,maintxt
	EXREF	BUILD_STRINGS_CB,palhtxt
	EXREF	BUILD_STRINGS_CB,ntschtxt
	
	EXREF	BUILD_STRINGS_CB,subpreptxt
	EXREF	BUILD_STRINGS_CB,substarttxt
	EXREF	BUILD_STRINGS_CB,subtxt
	
	EXREF	BUILD_STRINGS_CB,chantxt_ptrs
	EXREF	BUILD_STRINGS_CB,acttxt_ptrs
	EXREF	BUILD_STRINGS_CB,cbtxt_ptrs
; End of File
