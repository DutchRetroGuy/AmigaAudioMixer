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
	EXREF	BUILD_STRINGS_MP,preptxt
	EXREF	BUILD_STRINGS_MP,titletxt
	EXREF	BUILD_STRINGS_MP,maintxt
	EXREF	BUILD_STRINGS_MP,palhtxt
	EXREF	BUILD_STRINGS_MP,ntschtxt
	EXREF	BUILD_STRINGS_MP,palpertxt
	EXREF	BUILD_STRINGS_MP,ntscpertxt	

	EXREF	BUILD_STRINGS_MP,subpreptxt
	EXREF	BUILD_STRINGS_MP,substarttxt
	EXREF	BUILD_STRINGS_MP,subtxt
	
	EXREF	BUILD_STRINGS_MP,hwchantxt_ptrs
	EXREF	BUILD_STRINGS_MP,chantxt_ptrs
	EXREF	BUILD_STRINGS_MP,acttxt_ptrs
; End of File
