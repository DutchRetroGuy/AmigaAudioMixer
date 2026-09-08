; $VER: support.i 1.0 (16.03.23)
;
; support.i
; Include file for support.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20230316
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

	IFND	SUPPORT_I
SUPPORT_I	SET	1

	include exref.i

; External references
	EXREF	BUILD_SUPPORT,WaitLeftMouse
	EXREF	BUILD_SUPPORT,ReadInput
	EXREF	BUILD_SUPPORT,CopyMem
	EXREF	BUILD_SUPPORT,SetFGPtrs
	EXREF	BUILD_SUPPORT,SetSBPtrs
	EXREF	BUILD_SUPPORT,SetFGPal
	EXREF	BUILD_SUPPORT,SetSBPal
	EXREF	BUILD_SUPPORT,PrintFG
	EXREF	BUILD_SUPPORT,PrintSubbuffer
	EXREF	BUILD_SUPPORT,AllocAll
	EXREF	BUILD_SUPPORT,FreeAll
	EXREF	BUILD_SUPPORT,PrepSamples
	EXREF	BUILD_SUPPORT,InitLFSR
	EXREF	BUILD_SUPPORT,GetRandom
	
; Constants
PolyMask_32	EQU	$b4bcd35c
PolyMask_31	EQU $7a5bc2e3
	
	ENDC
; End of File