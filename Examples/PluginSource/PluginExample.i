; $VER: SingleMixer.i 1.0 (30.03.23)
;
; SingleMixer.i
; 
; Include file for main file. 
; Based on earlier code.
;
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20230330
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; External references
	XDEF	_main

; Structures
 STRUCTURE EXPluginData,0
	APTR	exp_SineData
	UWORD	exp_SineLength
	UWORD	exp_CurrentPos
	LABEL	exp_SIZEOF

; End of File