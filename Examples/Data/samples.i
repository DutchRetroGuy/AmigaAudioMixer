; $VER: samples.i 1.0 (07.03.19)
;
; samples.i
; Include file for samples.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; References macro
EXREF	MACRO
		IFD BUILD_SAMPLES
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
		
; External references
	EXREF	sample1
	EXREF	sample2
	EXREF	sample3
	EXREF	sample4
	EXREF	sample5
	EXREF	sample6
	EXREF	sample7
	EXREF	sample8

	EXREF	sample1_size
	EXREF	sample2_size
	EXREF	sample3_size
	EXREF	sample4_size
	EXREF	sample5_size
	EXREF	sample6_size
	EXREF	sample7_size
	EXREF	sample8_size
	
	EXREF	sample_total_size
	
	EXREF	sample1_mix
	EXREF	sample2_mix
	EXREF	sample3_mix
	EXREF	sample4_mix
	EXREF	sample5_mix
	EXREF	sample6_mix
	EXREF	sample7_mix
	EXREF	sample8_mix
	
	EXREF	sample_info
	EXREF	si_STRT_o
	EXREF	si_SIZEOF
	EXREF	si_END

; Constants
sample_count	EQU	8
; End of File