; $VER: performance_test_wrapper.asm 3.7 (30.01.25)
;
; performance_test_wrapper.asm
; Wrapper around mixer.asm for PerformanceTest program.
;  
;
; Author: Jeroen Knoester
; Version: 3.7
; Revision: 20250130
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3)
	include hardware/custom.i
	include hardware/dmabits.i
	include mixer.i
	include mixer.asm
	
; Constants

; Start of code
		section code,code
;-----------------------------------------------------------------------------
; PerformanceTest support routines
;-----------------------------------------------------------------------------
	; Routine: PTestSetPlgRoutineOffset
	; This routine sets the base offset for the Mixer routines used by the 
	; built in plugins. These routines are provided below and can be called
	; after setting this value correctly.
	;
	; This routine should be called prior to changing between Mixer setting
	; for plugin tests.
	;
	; D0 - number of bytes offset current MixerSetup entry is from first entry
	;      of MixerSetup array
PTestSetPlgRoutineOffset
	move.l	a0,-(sp)						; Stack
	
	lea.l	PlgRoutineOffset,a0
	move.w	d0,(a0)
	
	move.l	(sp)+,a0						; Stack
	rts
	
;-----------------------------------------------------------------------------
; PerformanceTest support data
;-----------------------------------------------------------------------------
PlgRoutineOffset	dc.w	0

;-----------------------------------------------------------------------------
; Mixer tests
;-----------------------------------------------------------------------------

	; Mixer base configuration
MIXER_C_DEFS				EQU	0
MIXER_TIMING_BARS			EQU	0
MIXER_DEFAULT_COLOUR		EQU	$000

MIXER_HQ_MODE				SET 0
MIXER_68020					SET 0
MIXER_WORDSIZED				SET 0
MIXER_SIZEX32				SET 0
MIXER_SIZEXBUF				SET 0
MIXER_ENABLE_CALLBACK		SET 0
MIXER_ENABLE_PLUGINS		SET	0

mixer_32b_cnt				SET mixer_32b_cnt4
mixer_PAL_buffer_size		SET mixer_PAL_buffer_size4
mixer_NTSC_buffer_size		SET mixer_NTSC_buffer_size4

mxslength_word				SET	0
mxsize_x32					SET 0

	; Mixer tests
ptest_start
	MixAllCode _000			; No optimisations
ptest_end
;ptest_start_other
;	PerfTestSupport _000
;ptest_end_other
;ptest_start_var
;	PerfTestData _000
;ptest_end_var

MIXER_WORDSIZED				SET 0	
MIXER_SIZEX32				SET 0
MIXER_SIZEXBUF				SET 0
MIXER_68020					SET 1
mxsize_x32					SET 0
mxslength_word				SET	0
mixer_32b_cnt				SET mixer_32b_cnt4
mixer_PAL_buffer_size		SET mixer_PAL_buffer_size4
mixer_NTSC_buffer_size		SET mixer_NTSC_buffer_size4

ptest_start_020
	MixAllCode _020			; CPU type = 68020
ptest_end_020
;	PerfTestSupport _020
;	PerfTestData _020

MIXER_68020					SET 0
MIXER_SIZEX32				SET 1
mxsize_x32					SET 1
mixer_32b_cnt				SET mixer_32b_cnt32
mixer_PAL_buffer_size		SET mixer_PAL_buffer_size32
mixer_NTSC_buffer_size		SET mixer_NTSC_buffer_size32

ptest_start_32
	MixAllCode _32			; Size x32
ptest_end_32
;	PerfTestSupport _32
;	PerfTestData _32


MIXER_SIZEX32				SET 0
mxsize_x32					SET 0
MIXER_SIZEXBUF				SET 1
mixer_32b_cnt				SET mixer_32b_cnt4
mixer_PAL_buffer_size		SET mixer_PAL_buffer_size4
mixer_NTSC_buffer_size		SET mixer_NTSC_buffer_size4

ptest_start_bufsz
	MixAllCode _bufsz			; Size xBuf
ptest_end_bufsz
;	PerfTestSupport _bufsz
;	PerfTestData _bufsz


MIXER_SIZEXBUF				SET 0
MIXER_WORDSIZED				SET 1
mxslength_word				SET	1

ptest_start_word
	MixAllCode _word			; Length xWord
ptest_end_word
;	PerfTestSupport _word
;	PerfTestData _word


MIXER_SIZEX32				SET 1
mxsize_x32					SET 1
mixer_32b_cnt				SET mixer_32b_cnt32
mixer_PAL_buffer_size		SET mixer_PAL_buffer_size32
mixer_NTSC_buffer_size		SET mixer_NTSC_buffer_size32

ptest_start_word32
	MixAllCode _word32		; Length xWord/Size x32
ptest_end_word32
;	PerfTestSupport _word32
;	PerfTestData _word32


MIXER_SIZEX32				SET 0
mxsize_x32					SET 0
MIXER_SIZEXBUF				SET 1
mixer_32b_cnt				SET mixer_32b_cnt4
mixer_PAL_buffer_size		SET mixer_PAL_buffer_size4
mixer_NTSC_buffer_size		SET mixer_NTSC_buffer_size4

ptest_start_wordbufsz
	MixAllCode _wordbufsz		; Length xWord/Size xBuf
ptest_end_wordbufsz
;	PerfTestSupport _wordbufsz
;	PerfTestData _wordbufsz


MIXER_SIZEX32				SET 1
mxsize_x32					SET 1
mixer_32b_cnt				SET mixer_32b_cnt32
mixer_PAL_buffer_size		SET mixer_PAL_buffer_size32
mixer_NTSC_buffer_size		SET mixer_NTSC_buffer_size32

ptest_start_word32bufsz
	MixAllCode _word32bufsz	; Length xWord/Size xBuf/x32
ptest_end_word32bufsz
;	PerfTestSupport _word32bufsz
;	PerfTestData _word32bufsz


MIXER_WORDSIZED				SET 0	
MIXER_SIZEX32				SET 0
MIXER_SIZEXBUF				SET 0
mxsize_x32					SET 0
mxslength_word				SET	0
mixer_32b_cnt				SET mixer_32b_cnt4
mixer_PAL_buffer_size		SET mixer_PAL_buffer_size4
mixer_NTSC_buffer_size		SET mixer_NTSC_buffer_size4

MIXER_HQ_MODE				SET 1
MIXER_68020					SET 0
ptest_start_hq
	MixAllCode _HQ			; HQ mode
ptest_end_hq
;	PerfTestSupport _HQ
;	PerfTestData _HQ


MIXER_68020					SET 1
ptest_start_hq020
	MixAllCode _HQ020		; HQ mode (68020)
ptest_end_hq020
;	PerfTestSupport _HQ020
;	PerfTestData _HQ020


MIXER_HQ_MODE				SET 0
MIXER_68020					SET 0
MIXER_ENABLE_CALLBACK		SET 1
MIXER_ENABLE_PLUGINS		SET	0
ptest_start_cb
	MixAllCode _cb
ptest_end_cb
;	PerfTestSupport _cb
;	PerfTestData _cb


MIXER_ENABLE_CALLBACK		SET 0
MIXER_ENABLE_PLUGINS		SET	1
ptest_start_pl
	MixAllCode _pl
ptest_end_pl
;	PerfTestSupport _pl
;	PerfTestData _pl


MIXER_ENABLE_CALLBACK		SET 1
MIXER_ENABLE_PLUGINS		SET	1
ptest_start_cbpl
	MixAllCode _cbpl
ptest_end_cbpl
;	PerfTestSupport _cbpl
;	PerfTestData _cbpl


MIXER_68020					SET 1
MIXER_ENABLE_CALLBACK		SET 0
MIXER_ENABLE_PLUGINS		SET	1
ptest_start_pl020
	MixAllCode _pl020
ptest_end_pl020
;	PerfTestSupport _pl020
;	PerfTestData _pl020


PerfTest_routines
		; MixerSetup
		dc.l	MixerSetup_000,MixerSetup_32,MixerSetup_bufsz,MixerSetup_word
		dc.l	MixerSetup_word32,MixerSetup_wordbufsz,MixerSetup_word32bufsz
		dc.l	MixerSetup_020,MixerSetup_HQ,MixerSetup_HQ020,MixerSetup_cb
		dc.l	MixerSetup_pl,MixerSetup_cbpl
perftest_block_end
		; MixerInstallHandler
		dc.l	MixerInstallHandler_000,MixerInstallHandler_32
		dc.l	MixerInstallHandler_bufsz,MixerInstallHandler_word
		dc.l	MixerInstallHandler_word32,MixerInstallHandler_wordbufsz
		dc.l	MixerInstallHandler_word32bufsz,MixerInstallHandler_020
		dc.l	MixerInstallHandler_HQ,MixerInstallHandler_HQ020
		dc.l	MixerInstallHandler_cb,MixerInstallHandler_pl
		dc.l	MixerInstallHandler_cbpl
		; MixerStart
		dc.l	MixerStart_000,MixerStart_32,MixerStart_bufsz,MixerStart_word
		dc.l	MixerStart_word32,MixerStart_wordbufsz,MixerStart_word32bufsz
		dc.l	MixerStart_020,MixerStart_HQ,MixerStart_HQ020,MixerStart_cb
		dc.l	MixerStart_pl,MixerStart_cbpl
		; MixerPlayChannelSample
		dc.l	MixerPlayChannelSample_000,MixerPlayChannelSample_32
		dc.l	MixerPlayChannelSample_bufsz,MixerPlayChannelSample_word
		dc.l	MixerPlayChannelSample_word32,MixerPlayChannelSample_wordbufsz
		dc.l	MixerPlayChannelSample_word32bufsz,MixerPlayChannelSample_020
		dc.l	MixerPlayChannelSample_HQ,MixerPlayChannelSample_HQ020
		dc.l	MixerPlayChannelSample_cb,MixerPlayChannelSample_pl
		dc.l	MixerPlayChannelSample_cbpl
		; MixerStopFX
		dc.l	MixerStopFX_000,MixerStopFX_32,MixerStopFX_bufsz,MixerStopFX_word
		dc.l	MixerStopFX_word32,MixerStopFX_wordbufsz
		dc.l	MixerStopFX_word32bufsz,MixerStopFX_020,MixerStopFX_HQ
		dc.l	MixerStopFX_HQ020,MixerStopFX_cb,MixerStopFX_pl
		dc.l	MixerStopFX_cbpl
		; MixerStop
		dc.l	MixerStop_000,MixerStop_32,MixerStop_bufsz,MixerStop_word
		dc.l	MixerStop_word32,MixerStop_wordbufsz,MixerStop_word32bufsz
		dc.l	MixerStop_020,MixerStop_HQ,MixerStop_HQ020,MixerStop_cb
		dc.l	MixerStop_pl,MixerStop_cbpl
		; MixerRemoveHandler
		dc.l	MixerRemoveHandler_000,MixerRemoveHandler_32
		dc.l	MixerRemoveHandler_bufsz,MixerRemoveHandler_word
		dc.l	MixerRemoveHandler_word32,MixerRemoveHandler_wordbufsz
		dc.l	MixerRemoveHandler_word32bufsz,MixerRemoveHandler_020
		dc.l	MixerRemoveHandler_HQ,MixerRemoveHandler_HQ020
		dc.l	MixerRemoveHandler_cb,MixerRemoveHandler_pl
		dc.l	MixerRemoveHandler_cbpl
		; MixerVolume
		dc.l	MixerVolume_000,MixerVolume_32,MixerVolume_bufsz,MixerVolume_word
		dc.l	MixerVolume_word32,MixerVolume_wordbufsz,MixerVolume_word32bufsz
		dc.l	MixerVolume_020,MixerVolume_HQ,MixerVolume_HQ020,MixerVolume_cb
		dc.l	MixerVolume_pl,MixerVolume_cbpl
		; MixerSetPluginDeferredPtr
		dc.l	MixerSetPluginDeferredPtr_000,MixerSetPluginDeferredPtr_32,MixerSetPluginDeferredPtr_bufsz,MixerSetPluginDeferredPtr_word
		dc.l	MixerSetPluginDeferredPtr_word32,MixerSetPluginDeferredPtr_wordbufsz,MixerSetPluginDeferredPtr_word32bufsz
		dc.l	MixerSetPluginDeferredPtr_020,MixerSetPluginDeferredPtr_HQ,MixerSetPluginDeferredPtr_HQ020,MixerSetPluginDeferredPtr_cb
		dc.l	MixerSetPluginDeferredPtr_pl,MixerSetPluginDeferredPtr_cbpl
		; MixerCalcTicks
		dc.l	MixerCalcTicks_000,MixerCalcTicks_32,MixerCalcTicks_bufsz,MixerCalcTicks_word
		dc.l	MixerCalcTicks_word32,MixerCalcTicks_wordbufsz,MixerCalcTicks_word32bufsz
		dc.l	MixerCalcTicks_020,MixerCalcTicks_HQ,MixerCalcTicks_HQ020,MixerCalcTicks_cb
		dc.l	MixerCalcTicks_pl,MixerCalcTicks_cbpl
		; MixerGetChannelBufferSize
		dc.l	MixerGetChannelBufferSize_000,MixerGetChannelBufferSize_32,MixerGetChannelBufferSize_bufsz,MixerGetChannelBufferSize_word
		dc.l	MixerGetChannelBufferSize_word32,MixerGetChannelBufferSize_wordbufsz,MixerGetChannelBufferSize_word32bufsz
		dc.l	MixerGetChannelBufferSize_020,MixerGetChannelBufferSize_HQ,MixerGetChannelBufferSize_HQ020,MixerGetChannelBufferSize_cb
		dc.l	MixerGetChannelBufferSize_pl,MixerGetChannelBufferSize_cbpl
		; MixerResetCounter
		dc.l	MixerResetCounter_000,MixerResetCounter_32,MixerResetCounter_bufsz,MixerResetCounter_word
		dc.l	MixerResetCounter_word32,MixerResetCounter_wordbufsz,MixerResetCounter_word32bufsz
		dc.l	MixerResetCounter_020,MixerResetCounter_HQ,MixerResetCounter_HQ020,MixerResetCounter_cb
		dc.l	MixerResetCounter_pl,MixerResetCounter_cbpl
		; MixerGetCounter
		dc.l	MixerGetCounter_000,MixerGetCounter_32,MixerGetCounter_bufsz,MixerGetCounter_word
		dc.l	MixerGetCounter_word32,MixerGetCounter_wordbufsz,MixerGetCounter_word32bufsz
		dc.l	MixerGetCounter_020,MixerGetCounter_HQ,MixerGetCounter_HQ020,MixerGetCounter_cb
		dc.l	MixerGetCounter_pl,MixerGetCounter_cbpl

PerfTest_32x_modes
		dc.w	0,1,0,0,1,0,1,0,0,0,0,0,0
PerfTest_word_modes
		dc.w	0,0,0,1,1,1,1,0,0,0,0,0,0
		
PerfTest_data
	; mixer
		dc.l	mixer_000,mixer_32,mixer_bufsz,mixer_word
		dc.l	mixer_word32,mixer_wordbufsz,mixer_word32bufsz
		dc.l	mixer_020,mixer_HQ,mixer_HQ020,mixer_cb
		dc.l	mixer_pl,mixer_cbpl
	; mixer_fx_struct
		dc.l	mixer_fx_struct_000,mixer_fx_struct_32,mixer_fx_struct_bufsz,mixer_fx_struct_word
		dc.l	mixer_fx_struct_word32,mixer_fx_struct_wordbufsz,mixer_fx_struct_word32bufsz
		dc.l	mixer_fx_struct_020,mixer_fx_struct_HQ,mixer_fx_struct_HQ020,mixer_fx_struct_cb
		dc.l	mixer_fx_struct_pl,mixer_fx_struct_cbpl
	; mixer_stored_vbr
		dc.l	mixer_stored_vbr_000,mixer_stored_vbr_32,mixer_stored_vbr_bufsz,mixer_stored_vbr_word
		dc.l	mixer_stored_vbr_word32,mixer_stored_vbr_wordbufsz,mixer_stored_vbr_word32bufsz
		dc.l	mixer_stored_vbr_020,mixer_stored_vbr_HQ,mixer_stored_vbr_HQ020,mixer_stored_vbr_cb
		dc.l	mixer_stored_vbr_pl,mixer_stored_vbr_cbpl
	; mixer_stored_handler
		dc.l	mixer_stored_handler_000,mixer_stored_handler_32,mixer_stored_handler_bufsz,mixer_stored_handler_word
		dc.l	mixer_stored_handler_word32,mixer_stored_handler_wordbufsz,mixer_stored_handler_word32bufsz
		dc.l	mixer_stored_handler_020,mixer_stored_handler_HQ,mixer_stored_handler_HQ020,mixer_stored_handler_cb
		dc.l	mixer_stored_handler_pl,mixer_stored_handler_cbpl
	; mixer_stored_intena
		dc.l	mixer_stored_intena_000,mixer_stored_intena_32,mixer_stored_intena_bufsz,mixer_stored_intena_word
		dc.l	mixer_stored_intena_word32,mixer_stored_intena_wordbufsz,mixer_stored_intena_word32bufsz
		dc.l	mixer_stored_intena_020,mixer_stored_intena_HQ,mixer_stored_intena_HQ020,mixer_stored_intena_cb
		dc.l	mixer_stored_intena_pl,mixer_stored_intena_cbpl
	; mixer_stored_cia
		dc.l	mixer_stored_cia_000,mixer_stored_cia_32,mixer_stored_cia_bufsz,mixer_stored_cia_word
		dc.l	mixer_stored_cia_word32,mixer_stored_cia_wordbufsz,mixer_stored_cia_word32bufsz
		dc.l	mixer_stored_cia_020,mixer_stored_cia_HQ,mixer_stored_cia_HQ020,mixer_stored_cia_cb
		dc.l	mixer_stored_cia_pl,mixer_stored_cia_cbpl
	; mixer_ticks_last
		dc.l	mixer_ticks_last_000,mixer_ticks_last_32,mixer_ticks_last_bufsz,mixer_ticks_last_word
		dc.l	mixer_ticks_last_word32,mixer_ticks_last_wordbufsz,mixer_ticks_last_word32bufsz
		dc.l	mixer_ticks_last_020,mixer_ticks_last_HQ,mixer_ticks_last_HQ020,mixer_ticks_last_cb
		dc.l	mixer_ticks_last_pl,mixer_ticks_last_cbpl
	; mixer_ticks_best
		dc.l	mixer_ticks_best_000,mixer_ticks_best_32,mixer_ticks_best_bufsz,mixer_ticks_best_word
		dc.l	mixer_ticks_best_word32,mixer_ticks_best_wordbufsz,mixer_ticks_best_word32bufsz
		dc.l	mixer_ticks_best_020,mixer_ticks_best_HQ,mixer_ticks_best_HQ020,mixer_ticks_best_cb
		dc.l	mixer_ticks_best_pl,mixer_ticks_best_cbpl
	; mixer_ticks_worst
		dc.l	mixer_ticks_worst_000,mixer_ticks_worst_32,mixer_ticks_worst_bufsz,mixer_ticks_worst_word
		dc.l	mixer_ticks_worst_word32,mixer_ticks_worst_wordbufsz,mixer_ticks_worst_word32bufsz
		dc.l	mixer_ticks_worst_020,mixer_ticks_worst_HQ,mixer_ticks_worst_HQ020,mixer_ticks_worst_cb
		dc.l	mixer_ticks_worst_pl,mixer_ticks_worst_cbpl
	; mixer_ticks_average
		dc.l	mixer_ticks_average_000,mixer_ticks_average_32,mixer_ticks_average_bufsz,mixer_ticks_average_word
		dc.l	mixer_ticks_average_word32,mixer_ticks_average_wordbufsz,mixer_ticks_average_word32bufsz
		dc.l	mixer_ticks_average_020,mixer_ticks_average_HQ,mixer_ticks_average_HQ020,mixer_ticks_average_cb
		dc.l	mixer_ticks_average_pl,mixer_ticks_average_cbpl
	; mixer_ticks_storage_off
		dc.l	mixer_ticks_storage_off_000,mixer_ticks_storage_off_32,mixer_ticks_storage_off_bufsz,mixer_ticks_storage_off_word
		dc.l	mixer_ticks_storage_off_word32,mixer_ticks_storage_off_wordbufsz,mixer_ticks_storage_off_word32bufsz
		dc.l	mixer_ticks_storage_off_020,mixer_ticks_storage_off_HQ,mixer_ticks_storage_off_HQ020,mixer_ticks_storage_off_cb
		dc.l	mixer_ticks_storage_off_pl,mixer_ticks_storage_off_cbpl
	; mixer_ticks_storage
		dc.l	mixer_ticks_storage_000,mixer_ticks_storage_32,mixer_ticks_storage_bufsz,mixer_ticks_storage_word
		dc.l	mixer_ticks_storage_word32,mixer_ticks_storage_wordbufsz,mixer_ticks_storage_word32bufsz
		dc.l	mixer_ticks_storage_020,mixer_ticks_storage_HQ,mixer_ticks_storage_HQ020,mixer_ticks_storage_cb
		dc.l	mixer_ticks_storage_pl,mixer_ticks_storage_cbpl

		
PerfTest_plg_routines
		dc.l	MixerSetup_pl,MixerSetup_pl020
perftest_plg_block_end
		; MixerInstallHandler
		dc.l	MixerInstallHandler_pl,MixerInstallHandler_pl020
		; MixerStart
		dc.l	MixerStart_pl,MixerStart_pl020
		; MixerPlayChannelFX
		dc.l	MixerPlayChannelFX_pl,MixerPlayChannelFX_pl020
		; MixerStopFX
		dc.l	MixerStopFX_pl,MixerStopFX_pl020
		; MixerStop
		dc.l	MixerStop_pl,MixerStop_pl020
		; MixerRemoveHandler
		dc.l	MixerRemoveHandler_pl,MixerRemoveHandler_pl020
		; MixerVolume
		dc.l	MixerVolume_pl,MixerVolume_pl020
		; MixerSetPluginDeferredPtr
		dc.l	MixerSetPluginDeferredPtr_pl,MixerSetPluginDeferredPtr_pl020
		; MixerCalcTicks
		dc.l	MixerCalcTicks_pl,MixerCalcTicks_pl020
		; MixerGetChannelBufferSize
		dc.l	MixerGetChannelBufferSize_pl,MixerGetChannelBufferSize_pl020
		; MixerPlayFX
		dc.l	MixerPlayFX_pl,MixerPlayFX_pl020		
		; MixerResetCounter
		dc.l	MixerResetCounter_pl,MixerResetCounter_pl020
		; MixerGetCounter
		dc.l	MixerGetCounter_pl,MixerGetCounter_pl020
		
PerfTest_plg_data
	; mixer
		dc.l	mixer_pl,mixer_pl020
	; mixer_fx_struct
		dc.l	mixer_fx_struct_pl,mixer_fx_struct_pl020
	; mixer_stored_vbr
		dc.l	mixer_stored_vbr_pl,mixer_stored_vbr_pl020
	; mixer_stored_handler
		dc.l	mixer_stored_handler_pl,mixer_stored_handler_pl020
	; mixer_stored_intena
		dc.l	mixer_stored_intena_pl,mixer_stored_intena_pl020
	; mixer_stored_cia
		dc.l	mixer_stored_cia_pl,mixer_stored_cia_pl020
	; mixer_ticks_last
		dc.l	mixer_ticks_last_pl,mixer_ticks_last_pl020
	; mixer_ticks_best
		dc.l	mixer_ticks_best_pl,mixer_ticks_best_pl020
	; mixer_ticks_worst
		dc.l	mixer_ticks_worst_pl,mixer_ticks_worst_pl020
	; mixer_ticks_average
		dc.l	mixer_ticks_average_pl,mixer_ticks_average_pl020
	; mixer_ticks_storage_off
		dc.l	mixer_ticks_storage_off_pl,mixer_ticks_storage_off_pl020
	; mixer_ticks_storage
		dc.l	mixer_ticks_storage_pl,mixer_ticks_storage_pl020

; Offsets
perftest_block_size				EQU perftest_block_end-PerfTest_routines
perftest_plg_block_size			EQU perftest_plg_block_end-PerfTest_plg_routines

mxsetup							EQU		0
mxinsthandler					EQU		perftest_block_size
mxstart							EQU		perftest_block_size*2
mxplaychsam						EQU		perftest_block_size*3
mxstopfx						EQU		perftest_block_size*4
mxstop							EQU		perftest_block_size*5
mxremhandler					EQU		perftest_block_size*6
mxvolume						EQU		perftest_block_size*7
mxsetplugindeferredptr			EQU		perftest_block_size*8
mxcalcticks						EQU		perftest_block_size*9
mxgetinternalbuffersize			EQU		perftest_block_size*10
mxresetcounter					EQU		perftest_block_size*11
mxgetcounter					EQU		perftest_block_size*12

mxplgsetup						EQU		0
mxplginsthandler				EQU		perftest_plg_block_size
mxplgstart						EQU		perftest_plg_block_size*2
mxplgplaychfx					EQU		perftest_plg_block_size*3
mxplgstopfx						EQU		perftest_plg_block_size*4
mxplgstop						EQU		perftest_plg_block_size*5
mxplgremhandler					EQU		perftest_plg_block_size*6
mxplgvolume						EQU		perftest_plg_block_size*7
mxplgsetplugindeferredptr		EQU		perftest_plg_block_size*8
mxplgcalcticks					EQU		perftest_plg_block_size*9
mxplggetinternalbuffersize		EQU		perftest_plg_block_size*10
mxplgplayfx						EQU		perftest_plg_block_size*11
mxplgresetcounter				EQU		perftest_plg_block_size*12
mxplggetcounter					EQU		perftest_plg_block_size*13

mxmixer							EQU		0
mxmixer_fx_struct				EQU		perftest_block_size
mxmixer_stored_vbr				EQU		perftest_block_size*2
mxmixer_stored_handler			EQU		perftest_block_size*3
mxmixer_stored_intena			EQU		perftest_block_size*4
mxmixer_stored_cia				EQU		perftest_block_size*5
mxmixer_ticks_last				EQU		perftest_block_size*6
mxmixer_ticks_best				EQU		perftest_block_size*7
mxmixer_ticks_worst				EQU		perftest_block_size*8
mxmixer_ticks_average			EQU		perftest_block_size*9
mxmixer_ticks_storage_off		EQU		perftest_block_size*10
mxmixer_ticks_storage			EQU		perftest_block_size*11

mxplgmixer						EQU		0
mxplgmixer_fx_struct			EQU		perftest_plg_block_size
mxplgmixer_stored_vbr			EQU		perftest_plg_block_size*2
mxplgmixer_stored_handler		EQU		perftest_plg_block_size*3
mxplgmixer_stored_intena		EQU		perftest_plg_block_size*4
mxplgmixer_stored_cia			EQU		perftest_plg_block_size*5
mxplgmixer_ticks_last			EQU		perftest_plg_block_size*6
mxplgmixer_ticks_best			EQU		perftest_plg_block_size*7
mxplgmixer_ticks_worst			EQU		perftest_plg_block_size*8
mxplgmixer_ticks_average		EQU		perftest_plg_block_size*9
mxplgmixer_ticks_storage_off	EQU		perftest_plg_block_size*10
mxplgmixer_ticks_storage		EQU		perftest_plg_block_size*11
	

	IF PERF_SIZE_TEST=1
;ptest_other_size			EQU ptest_end_other-ptest_start_other
;ptest_overhead_size			EQU ptest_end_var-ptest_start_var
;		echo "Data size (includes 268 bytes for timer statistics):"
;		printv ptest_overhead_size
ptest_size					EQU ptest_end-ptest_start
ptest_size_32				EQU ptest_end_32-ptest_start_32
ptest_size_bufz				EQU ptest_end_bufsz-ptest_start_bufsz
ptest_size_word				EQU ptest_end_word-ptest_start_word
ptest_size_word32			EQU ptest_end_word32-ptest_start_word32
ptest_size_wordbufsz		EQU ptest_end_wordbufsz-ptest_start_wordbufsz
ptest_size_word32bufsz		EQU ptest_end_word32bufsz-ptest_start_word32bufsz
ptest_size_020				EQU ptest_end_020-ptest_start_020
ptest_size_HQ				EQU ptest_end_hq-ptest_start_hq
ptest_size_HQ020			EQU ptest_end_hq020-ptest_start_hq020
ptest_size_cb				EQU ptest_end_cb-ptest_start_cb
ptest_size_pl				EQU ptest_end_pl-ptest_start_pl
ptest_size_pl020			EQU ptest_end_pl020-ptest_start_pl020
ptest_size_cbpl				EQU ptest_end_cbpl-ptest_start_cbpl
		echo "Code size (no optimisations):"
		printv ptest_size
		echo "Code size (MIXER_SIZEX32):"
		printv ptest_size_32
		echo "Code size (MIXER_SIZEXBUF):"
		printv ptest_size_bufz
		echo "Code size (MIXER_WORDSIZED):"
		printv ptest_size_word
		echo "Code size (MIXER_WORDSIZED/MIXER_SIZEX32):"
		printv ptest_size_word32
		echo "Code size (MIXER_WORDSIZED/MIXER_SIZEXBUF):"
		printv ptest_size_wordbufsz
		echo "Code size (MIXER_WORDSIZED/MIXER_SIZEX32/MIXER_SIZEXBUF):"
		printv ptest_size_word32bufsz
		echo "Code size (68020):"
		printv ptest_size_020
		echo "Code size (HQ):"
		printv ptest_size_HQ
		echo "Code size (HQ/68020):"
		printv ptest_size_HQ020
		echo "Code size (Callback):"
		printv ptest_size_cb
		echo "Code size (Plugins):"
		printv ptest_size_pl
		echo "Code size (Plugins/68020):"
		printv ptest_size_pl020
		echo "Code size (Callback/Plugins):"
		printv ptest_size_cbpl
	ENDIF
; End of File