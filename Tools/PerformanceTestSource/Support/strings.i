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
	EXREF	BUILD_STRINGS_PMIX,titletxt
	EXREF	BUILD_STRINGS_PMIX,resscrtxt
	EXREF	BUILD_STRINGS_PMIX,resscrtxt_2
	EXREF	BUILD_STRINGS_PMIX,resscrtxt_3
	EXREF	BUILD_STRINGS_PMIX,palhtxt
	EXREF	BUILD_STRINGS_PMIX,ntschtxt
	EXREF	BUILD_STRINGS_PMIX,singhtxt
	EXREF	BUILD_STRINGS_PMIX,multhtxt
	EXREF	BUILD_STRINGS_PMIX,perstxt
	EXREF	BUILD_STRINGS_PMIX,permtxt
	EXREF	BUILD_STRINGS_PMIX,subtxt
	EXREF	BUILD_STRINGS_PMIX,ressbtxt
	
	EXREF	BUILD_STRINGS_PMIX,res_offset
	EXREF	BUILD_STRINGS_PMIX,res_line_offset
	EXREF	BUILD_STRINGS_PMIX,res_offset_2
	EXREF	BUILD_STRINGS_PMIX,res_line_offset_2
	
	EXREF	BUILD_STRINGS_PMIX,cntxt1
	EXREF	BUILD_STRINGS_PMIX,cntxt_ptrs
	
	EXREF	BUILD_STRINGS_PMIX,restxt_ptrs
; End of File