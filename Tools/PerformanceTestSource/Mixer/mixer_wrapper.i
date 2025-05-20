; $VER: mixer_wrapper.i 3.7 (04.02.24)
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
	IFND EXREF
EXREF	MACRO
		IFD BUILD_MIXER
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; References
	EXREF	PTestSetPlgRoutineOffset

	EXREF	PerfTest_routines
	EXREF	PerfTest_plg_routines
	EXREF	PerfTest_32x_modes
	EXREF	PerfTest_word_modes
	EXREF	PerfTest_data
	EXREF	PerfTest_plg_data
	
	; Offsets
	EXREF	mxsetup
	EXREF	mxinsthandler
	EXREF	mxstart
	EXREF	mxplaychsam
	EXREF	mxstopfx
	EXREF	mxstop
	EXREF	mxremhandler
	EXREF	mxvolume
	EXREF	mxsetplugindeferredptr
	EXREF	mxcalcticks
	EXREF	mxgetinternalbuffersize
	EXREF	mxresetcounter
	EXREF	mxgetcounter
	
	EXREF	mxmixer
	EXREF	mxmixer_fx_struct
	EXREF	mxmixer_stored_vbr
	EXREF	mxmixer_stored_handler
	EXREF	mxmixer_stored_intena
	EXREF	mxmixer_stored_cia
	EXREF	mxmixer_ticks_last
	EXREF	mxmixer_ticks_best
	EXREF	mxmixer_ticks_worst
	EXREF	mxmixer_ticks_average
	EXREF	mxmixer_ticks_storage_off
	EXREF	mxmixer_ticks_storage
	
	EXREF	mxplgsetup
	EXREF	mxplginsthandler
	EXREF	mxplgstart
	EXREF	mxplgplaychfx
	EXREF	mxplgstopfx
	EXREF	mxplgstop
	EXREF	mxplgremhandler
	EXREF	mxplgvolume
	EXREF	mxplgsetplugindeferredptr
	EXREF	mxplgcalcticks
	EXREF	mxplggetinternalbuffersize
	EXREF	mxplgresetcounter
	EXREF	mxplggetcounter
	
	EXREF	mxplgmixer
	EXREF	mxplgmixer_fx_struct
	EXREF	mxplgmixer_stored_vbr
	EXREF	mxplgmixer_stored_handler
	EXREF	mxplgmixer_stored_intena
	EXREF	mxplgmixer_stored_cia
	EXREF	mxplgmixer_ticks_last
	EXREF	mxplgmixer_ticks_best
	EXREF	mxplgmixer_ticks_worst
	EXREF	mxplgmixer_ticks_average
	EXREF	mxplgmixer_ticks_storage_off
	EXREF	mxplgmixer_ticks_storage
	
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