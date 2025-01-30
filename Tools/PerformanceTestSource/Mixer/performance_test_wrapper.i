; $VER: performance_test_wrapper.i 3.6 (04.02.24)
;
; performance_test_wrapper.i
; Include file for performance_test_wrapper.asm
;
;
; Author: Jeroen Knoester
; Version: 3.7
; Revision: 20250130
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
	include mixer_config.i

; References macro
EXREF	MACRO
		IFD BUILD_MIXER_PMIX
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

;-----------------------------------------------------------------------------
; Constants
;-----------------------------------------------------------------------------									

NOTE: ALL THESE COME FROM MIXER.I
MAKE A SPECIAL IF/ENDIF CONSTRUCT TO EXTRACT ONLY THESE FROM MIXER.I

MIX_CH0					EQU	16				; Mixer software channel 0
MIX_CH1					EQU	32				; ..
MIX_CH2					EQU	64				; ..
MIX_CH3					EQU	128				; Mixer software channel 3

MIX_PLUGIN_STD			EQU	0				; Standard plugin
MIX_PLUGIN_NODATA		EQU	1				; Plugin that doesn't update

mixer_PAL_cycles 		EQU	3546895
mixer_NTSC_cycles		EQU	3579545
			
	IF MIXER_PER_IS_NTSC=0
mixer_PAL_period		EQU	mixer_period
mixer_NTSC_period		EQU (mixer_period*mixer_NTSC_cycles)/mixer_PAL_cycles
	ELSE
mixer_NTSC_period		EQU	mixer_period
mixer_PAL_period		EQU (mixer_period*mixer_PAL_cycles)/mixer_NTSC_cycles
	ENDIF

mixer_PAL_buffer_size	EQU	((mixer_PAL_cycles/mixer_PAL_period/50)&65504)+32
mixer_NTSC_buffer_size	EQU	((mixer_NTSC_cycles/mixer_NTSC_period/60)&65504)+32

mixer_output_channels	EQU	DMAF_AUD0
mixer_output_aud0		EQU	mixer_output_channels&1
mixer_output_aud1		EQU	(mixer_output_channels>>1)&1
mixer_output_aud2		EQU	(mixer_output_channels>>2)&1
mixer_output_aud3		EQU	(mixer_output_channels>>3)&1
mixer_output_count		EQU	mixer_output_aud0+mixer_output_aud1+mixer_output_aud2+mixer_output_aud3

mixer_buffer_size			EQU	mixer_PAL_buffer_size*(1+(mixer_output_count*2))
mixer_plugin_buffer_size	EQU	(mixer_PAL_buffer_size*mixer_sw_channels)*mixer_output_count

; Dummy structures
; Note: these need to be updated if their definition in mixer.i changes!
 STRUCTURE PERFMXEffect,0	
	LONG	mfx_length						; Note: always use a longword 
											; for this value, even when 
											; MIXER_WORDSIZED is set to 1
	APTR	mfx_sample_ptr
	UWORD	mfx_loop
	UWORD	mfx_priority
	LONG	mfx_loop_offset					; Note: always use a longword 
											; for this value, even when 
											; MIXER_WORDSIZED is set to 1
	APTR	mfx_plugin_ptr
	LABEL	mfx_SIZEOF
	
 STRUCTURE PERFMXPlugin,0
	UWORD	mpl_plugin_type
	APTR	mpl_init_ptr
	APTR	mpl_plugin_ptr
	APTR	mpl_init_data_ptr
	LABEL	mpl_SIZEOF

; End of File