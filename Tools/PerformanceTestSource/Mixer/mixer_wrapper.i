; $VER: mixer_wrapper.i 3.6 (04.02.24)
;
; mixer_wrapper.i
; Include file for mixer_wrapper.asm
;
;
; Author: Jeroen Knoester
; Version: 3.7
; Revision: 20250130
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes

; References macro
EXREF	MACRO
		IFD BUILD_MIXER
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM

; References
	EXREF	PTestSetPlgRoutineOffset

	EXREF	PerfTest_routines
	EXREF	PerfTest_plg_routines
	EXREF	PerfTest_32x_modes
	EXREF	PerfTest_word_modes
	EXREF	PerfTest_data
	EXREF	PerfTest_plg_data
	
;-----------------------------------------------------------------------------
; Performance test configuration
;-----------------------------------------------------------------------------
PERF_SIZE_TEST			SET 0		; Set to 1 to get a report on the various 
									; code sizes of each mixer option.
									;
									; Note that data size is an approximation
									; as the largest possible structure is 
									; always in use when the performance test
									; is run.

; End of File