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

; References macro
	IFND EXREF
EXREF	MACRO
		IFD BUILD_FONT
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; External references
	EXREF	PlotCharCPU
	EXREF	PlotTextCPU
	EXREF	PlotInvertedCharCPU
	EXREF	PlotInvertedTextCPU
	EXREF	PlotTextMultiCPU
	EXREF	basicfont
; End of File