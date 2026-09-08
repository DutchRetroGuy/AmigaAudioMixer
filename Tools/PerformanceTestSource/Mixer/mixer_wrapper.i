; $VER: mixer_wrapper.i 3.8 (04.02.24)
;
; mixer_wrapper.i
; Include file for mixer_wrapper.asm
;
;
; Author: Jeroen Knoester
; Version: 3.8
; Revision: 20250130
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
	include exref.i

; References
	EXREF	BUILD_MIXER,PTestSetPlgRoutineOffset

	EXREF	BUILD_MIXER,PerfTest_routines
	EXREF	BUILD_MIXER,PerfTest_plg_routines
	EXREF	BUILD_MIXER,PerfTest_32x_modes
	EXREF	BUILD_MIXER,PerfTest_word_modes
	EXREF	BUILD_MIXER,PerfTest_data
	EXREF	BUILD_MIXER,PerfTest_plg_data
	
	; Offsets
	EXREF	BUILD_MIXER,mxsetup
	EXREF	BUILD_MIXER,mxinsthandler
	EXREF	BUILD_MIXER,mxstart
	EXREF	BUILD_MIXER,mxplaychsam
	EXREF	BUILD_MIXER,mxstopfx
	EXREF	BUILD_MIXER,mxstop
	EXREF	BUILD_MIXER,mxremhandler
	EXREF	BUILD_MIXER,mxvolume
	EXREF	BUILD_MIXER,mxsetplugindeferredptr
	EXREF	BUILD_MIXER,mxcalcticks
	EXREF	BUILD_MIXER,mxgetinternalbuffersize
	EXREF	BUILD_MIXER,mxresetcounter
	EXREF	BUILD_MIXER,mxgetcounter
	
	EXREF	BUILD_MIXER,mxmixer
	EXREF	BUILD_MIXER,mxmixer_fx_struct
	EXREF	BUILD_MIXER,mxmixer_stored_vbr
	EXREF	BUILD_MIXER,mxmixer_stored_handler
	EXREF	BUILD_MIXER,mxmixer_stored_intena
	EXREF	BUILD_MIXER,mxmixer_stored_cia
	EXREF	BUILD_MIXER,mxmixer_ticks_last
	EXREF	BUILD_MIXER,mxmixer_ticks_best
	EXREF	BUILD_MIXER,mxmixer_ticks_worst
	EXREF	BUILD_MIXER,mxmixer_ticks_average
	EXREF	BUILD_MIXER,mxmixer_ticks_storage_off
	EXREF	BUILD_MIXER,mxmixer_ticks_storage
	
	EXREF	BUILD_MIXER,mxplgsetup
	EXREF	BUILD_MIXER,mxplginsthandler
	EXREF	BUILD_MIXER,mxplgstart
	EXREF	BUILD_MIXER,mxplgplaychfx
	EXREF	BUILD_MIXER,mxplgstopfx
	EXREF	BUILD_MIXER,mxplgstop
	EXREF	BUILD_MIXER,mxplgremhandler
	EXREF	BUILD_MIXER,mxplgvolume
	EXREF	BUILD_MIXER,mxplgsetplugindeferredptr
	EXREF	BUILD_MIXER,mxplgcalcticks
	EXREF	BUILD_MIXER,mxplggetinternalbuffersize
	EXREF	BUILD_MIXER,mxplgresetcounter
	EXREF	BUILD_MIXER,mxplggetcounter
	
	EXREF	BUILD_MIXER,mxplgmixer
	EXREF	BUILD_MIXER,mxplgmixer_fx_struct
	EXREF	BUILD_MIXER,mxplgmixer_stored_vbr
	EXREF	BUILD_MIXER,mxplgmixer_stored_handler
	EXREF	BUILD_MIXER,mxplgmixer_stored_intena
	EXREF	BUILD_MIXER,mxplgmixer_stored_cia
	EXREF	BUILD_MIXER,mxplgmixer_ticks_last
	EXREF	BUILD_MIXER,mxplgmixer_ticks_best
	EXREF	BUILD_MIXER,mxplgmixer_ticks_worst
	EXREF	BUILD_MIXER,mxplgmixer_ticks_average
	EXREF	BUILD_MIXER,mxplgmixer_ticks_storage_off
	EXREF	BUILD_MIXER,mxplgmixer_ticks_storage
	
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