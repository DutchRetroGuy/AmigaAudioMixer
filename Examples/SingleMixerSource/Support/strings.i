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
	EXREF	BUILD_STRINGS_SM,preptxt
	EXREF	BUILD_STRINGS_SM,titletxt
	EXREF	BUILD_STRINGS_SM,maintxt
	EXREF	BUILD_STRINGS_SM,palhtxt
	EXREF	BUILD_STRINGS_SM,ntschtxt
	EXREF	BUILD_STRINGS_SM,palpertxt
	EXREF	BUILD_STRINGS_SM,ntscpertxt	
	
	EXREF	BUILD_STRINGS_SM,subpreptxt
	EXREF	BUILD_STRINGS_SM,substarttxt
	EXREF	BUILD_STRINGS_SM,subtxt
	
	EXREF	BUILD_STRINGS_SM,chantxt_ptrs
	EXREF	BUILD_STRINGS_SM,acttxt_ptrs
	EXREF	BUILD_STRINGS_SM,modtxt_ptrs
; End of File
