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
	EXREF	BUILD_STRINGS_PL,preptxt
	EXREF	BUILD_STRINGS_PL,titletxt
	EXREF	BUILD_STRINGS_PL,maintxt
	EXREF	BUILD_STRINGS_PL,palhtxt
	EXREF	BUILD_STRINGS_PL,ntschtxt
	
	EXREF	BUILD_STRINGS_PL,subpreptxt
	EXREF	BUILD_STRINGS_PL,substarttxt
	EXREF	BUILD_STRINGS_PL,subtxt
	
	EXREF	BUILD_STRINGS_PL,chantxt_ptrs
	EXREF	BUILD_STRINGS_PL,acttxt_ptrs
	EXREF	BUILD_STRINGS_PL,pltxt_ptrs
; End of File
