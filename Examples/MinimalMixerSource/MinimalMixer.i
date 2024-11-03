; $VER: Audio_Mixing.i 1.0 (03.04.19)
;
; Audio_Mixing.i
; 
; Include file for main file. 
; Based on earlier code.
;
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190403
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; External references
	XDEF	_main
	
; Constants
; Volume levels determined experimentally. Best sounding volume levels will
; depend on module to play and samples to mix.
mod_volume_std	EQU	16
mod_volume_cmp	EQU	20
mod_volume_hq8	EQU	48
mod_volume_hq7	EQU	32

; End of File