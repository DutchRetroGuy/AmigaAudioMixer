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
	EXREF	BUILD_STRINGS_MM,preptxt
	EXREF	BUILD_STRINGS_MM,titletxt
	EXREF	BUILD_STRINGS_MM,maintxt
	EXREF	BUILD_STRINGS_MM,palhtxt
	EXREF	BUILD_STRINGS_MM,ntschtxt
	EXREF	BUILD_STRINGS_MM,palpertxt
	EXREF	BUILD_STRINGS_MM,ntscpertxt	
	
	EXREF	BUILD_STRINGS_MM,subpreptxt
	EXREF	BUILD_STRINGS_MM,substarttxt
	EXREF	BUILD_STRINGS_MM,subtxt
	
	EXREF	BUILD_STRINGS_MM,hwchantxt_ptrs
	EXREF	BUILD_STRINGS_MM,chantxt_ptrs
	EXREF	BUILD_STRINGS_MM,acttxt_ptrs
; End of File
