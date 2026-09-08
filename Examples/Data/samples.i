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

	include exref.i
		
; External references
	EXREF	BUILD_SAMPLES,sample1
	EXREF	BUILD_SAMPLES,sample2
	EXREF	BUILD_SAMPLES,sample3
	EXREF	BUILD_SAMPLES,sample4
	EXREF	BUILD_SAMPLES,sample5
	EXREF	BUILD_SAMPLES,sample6
	EXREF	BUILD_SAMPLES,sample7
	EXREF	BUILD_SAMPLES,sample8

	EXREF	BUILD_SAMPLES,sample1_size
	EXREF	BUILD_SAMPLES,sample2_size
	EXREF	BUILD_SAMPLES,sample3_size
	EXREF	BUILD_SAMPLES,sample4_size
	EXREF	BUILD_SAMPLES,sample5_size
	EXREF	BUILD_SAMPLES,sample6_size
	EXREF	BUILD_SAMPLES,sample7_size
	EXREF	BUILD_SAMPLES,sample8_size
	
	EXREF	BUILD_SAMPLES,sample_total_size
	
	EXREF	BUILD_SAMPLES,sample1_mix
	EXREF	BUILD_SAMPLES,sample2_mix
	EXREF	BUILD_SAMPLES,sample3_mix
	EXREF	BUILD_SAMPLES,sample4_mix
	EXREF	BUILD_SAMPLES,sample5_mix
	EXREF	BUILD_SAMPLES,sample6_mix
	EXREF	BUILD_SAMPLES,sample7_mix
	EXREF	BUILD_SAMPLES,sample8_mix
	
	EXREF	BUILD_SAMPLES,sample_info
	EXREF	BUILD_SAMPLES,si_STRT_o
	EXREF	BUILD_SAMPLES,si_SIZEOF
	EXREF	BUILD_SAMPLES,si_END

; Constants
sample_count	EQU	8
; End of File