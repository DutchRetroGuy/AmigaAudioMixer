; $VER: samples.i 1.0 (24.06.25)
;
; samples_e8x.i
; Include file for samples_e8x.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20250624
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; References macro
	IFND EXREF
EXREF	MACRO
		IFD BUILD_SAMPLES_E8X
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF
		
; External references
	EXREF	sample1_e8x
	EXREF	sample2_e8x

	EXREF	sample1_e8x_size
	EXREF	sample2_e8x_size
	
	EXREF	sample_e8x_total_size
	
	EXREF	sample1_e8x_mix
	EXREF	sample2_e8x_mix
	
	EXREF	sample_e8x_info
	EXREF	si_e8x_STRT_o
	EXREF	si_e8x_SIZEOF
	EXREF	si_e8x_END

; Constants
sample_e8x_count	EQU	2
; End of File