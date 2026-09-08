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
	EXREF	BUILD_STRINGS_SMHQ,preptxt
	EXREF	BUILD_STRINGS_SMHQ,titletxt
	EXREF	BUILD_STRINGS_SMHQ,maintxt
	EXREF	BUILD_STRINGS_SMHQ,palhtxt
	EXREF	BUILD_STRINGS_SMHQ,ntschtxt
	EXREF	BUILD_STRINGS_SMHQ,palpertxt
	EXREF	BUILD_STRINGS_SMHQ,ntscpertxt	
	
	EXREF	BUILD_STRINGS_SMHQ,subpreptxt
	EXREF	BUILD_STRINGS_SMHQ,substarttxt
	EXREF	BUILD_STRINGS_SMHQ,subtxt
	
	EXREF	BUILD_STRINGS_SMHQ,chantxt_ptrs
	EXREF	BUILD_STRINGS_SMHQ,acttxt_ptrs
	EXREF	BUILD_STRINGS_SMHQ,modtxt_ptrs
; End of File
