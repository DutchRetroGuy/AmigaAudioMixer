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
	
; Constants
; Volume levels determined experimentally. Best sounding volume levels will
; depend on module to play and samples to mix.
mod_volume_std	EQU	40

; End of File