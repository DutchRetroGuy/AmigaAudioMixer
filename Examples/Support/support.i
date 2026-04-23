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

; References macro
	IFND EXREF
EXREF	MACRO
		IFD BUILD_SUPPORT 
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; External references
	EXREF	WaitLeftMouse
	EXREF	ReadInput
	EXREF	CopyMem
	EXREF	SetFGPtrs
	EXREF	SetSBPtrs
	EXREF	SetFGPal
	EXREF	SetSBPal
	EXREF	PrintFG
	EXREF	PrintSubbuffer
	EXREF	AllocAll
	EXREF	FreeAll
	EXREF	PrepSamples
	EXREF	InitLFSR
	EXREF	GetRandom
	
; Constants
PolyMask_32	EQU	$b4bcd35c
PolyMask_31	EQU $7a5bc2e3
	
	ENDC
; End of File