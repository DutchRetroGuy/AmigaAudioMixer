; $VER: font.i 1.0 (25.08.18)
;
; font.i
; 
; This is the include file for font.i
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20180825
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

	include exref.i

; External references
	EXREF	BUILD_FONT,PlotCharCPU
	EXREF	BUILD_FONT,PlotTextCPU
	EXREF	BUILD_FONT,PlotInvertedCharCPU
	EXREF	BUILD_FONT,PlotInvertedTextCPU
	EXREF	BUILD_FONT,PlotTextMultiCPU
	EXREF	BUILD_FONT,basicfont
; End of File