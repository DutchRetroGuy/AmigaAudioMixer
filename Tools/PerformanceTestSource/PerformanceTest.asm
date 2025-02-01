; $VER: PerformanceTest.asm 1.1 (25.03.23)
;
; PerformanceTest.asm
; Tool measuring mixer performance in various situations. Uses settings from
; mixer_config.i to determine number of voices/mode/etc.
; 
;
; Author: Jeroen Knoester
; Version: 1.1
; Revision: 20230325
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include exec/types.i
	include	exec/exec.i
	include hardware/custom.i
	include hardware/dmabits.i
	include hardware/intbits.i
	include hardware/cia.i

	include	debug.i
	include displaybuffers.i
	include blitter.i
	include copperlists.i
	include font.i
	include converter.i
	include mixer.i
	include mixer_wrapper.i
	include plugins.i
	include plugins_wrapper.i
	include PerformanceTest.i
	include strings.i
	include support.i

; Custom chips offsets
custombase			EQU	$dff000
ciabase				EQU $bfe000

; External references
	XREF	WaitEOF
	XREF	WaitRaster
	
	XDEF	clist_ptrs
	XDEF	palette
	XDEF	subpal
	
; Constants
	IF MIXER_PER_IS_NTSC=0
mixer_frequency			EQU	mixer_PAL_cycles/mixer_period
	ELSE
mixer_frequency			EQU	mixer_NTSC_cycles/mixer_period
	ENDIF

; Reserve roughly 3 seconds of sample space
sample1_size			EQU	((mixer_frequency*3)&$fffffffc)+4

	IF sample1_size > 65535
sample1_word_size		EQU 65535
	ELSE
sample1_word_size		EQU sample1_size
	ENDIF
	
; Start of code
		section code,code
		
		; Main code starts here
_main	move.l	$4.w,a6				; Fetch sysbase
		move.l	a4,vbr_ptr			; Save VBR pointer

		; Allocate all memory
		bsr		AllocAll
		bne		.error
		
		; Set up period texts (up to 3 characters / 3551 HZ and up)
		move.w	#mixer_period,d0
		cmp.w	#999,d0
		bcs.s	.fill_period_val
		
		move.w	#999,d0
		
.fill_period_val
		lea.l	perstxt,a0
		lea.l	10(a0),a0
		bsr		ResultToDec
		lea.l	permtxt,a0
		lea.l	10(a0),a0
		bsr		ResultToDec
		
		; Set custombase here
		lea.l	custombase,a6
		
		; Activate blitter DMA
DMAVal	SET		DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER
		move.w	#DMAVal,dmacon(a6)

		; Wait on blitter
		BlitWait a6
		move.l	#$ffffffff,bltafwm(a6)	; Preset blitter mask value
		
		; Setup copper list pointers
		move.l	#clist1,clist_ptrs
		moveq	#0,d1
		moveq	#0,d2
		moveq	#2,d3
		bsr		SetFGPtrs	; Set bitplane pointers for foreground		
		bsr		SetSBPtrs	; Set up bitplane pointers for subbuffer
		bsr		SetFGPal	; Set up foreground palette
		bsr		SetSBPal	; Set up subbuffer palette
		
		; Check if Copperlist needs to be altered for NTSC display
		cmp.b	#50,VidFreq
		beq		.clear_fg

		; Update Copperlist for NTSC if needed
		lea.l	clist1,a0
		move.w	#$1492,6(a0)				; DIWSTRT
		move.w	#$05b1,10(a0)				; DIWSTOP
		lea.l	pal1,a0
		move.w	#$1201,-4(a0)				; VWait 1
		lea.l	shifts,a0
		move.w	#$01fe,4(a0)				; PAL wait
		move.w	#$f401,8(a0)				; VWait 2
		move.w	#$f4c5,16(a0)				; VWait 3
		
.clear_fg
		; Clear foreground
		; Blitsize vcount has been halved and hcount doubled to fit
		move.w	#(buffer_scroll_hgt*2)<<6|((display_width+(32*2))/8),d0
		move.l	fg_buf1,a0
		jsr		BlitClearScreen

		; Fill starting data for subbuffer
		jsr		DrawSubBuffer

		; Wait on blitter
		BlitWait a6
		
		; Add title screen text
		moveq	#0,d4
		lea.l	palhtxt,a3
		cmp.b	#50,VidFreq
		beq.s	.printh1
		
		lea.l	ntschtxt,a3

.printh1
		bsr		PrintFG
		lea.l	titletxt,a3
		jsr		PrintFG
		
		IF MIXER_SINGLE=1
			lea.l	perstxt,a3
			bsr		PrintFG
			lea.l	singhtxt,a3
			bsr		PrintFG
		ELSE
			lea.l	permtxt,a3
			bsr		PrintFG
			lea.l	multhtxt,a3
			bsr		PrintFG
		ENDIF
		
		; Add subbuffer text
		moveq	#0,d4
		lea.l	subtxt,a3
		bsr		PrintSubbuffer
		
		; Enable DMA
DMAVal	SET		DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER
		move.w	#DMAVal,dmacon(a6)

		; Activate copper list
		lea.l	clist1,a0
		move.l	a0,cop1lc(a6)
		move.w	#1,copjmp1(a6)

;-----------------------------------------
; Main loop setup
;-----------------------------------------
		move.b	$bfe001,d0					; Fetch CIAA PRA
		and.b	#$2,d0
		move.b	d0,led_status
		or.b	#$2,d0
		move.b	d0,$bfe001					; Disable audio filter

		; Fill the sample buffer with noise
		bsr		InitLFSR
		move.l	sample1_mix,a0
		move.l	#(sample1_size/4)-1,d7

.clear_lp
		bsr		GetRandom
		move.l	d0,(a0)+
		subq.l	#1,d7
		bne.s	.clear_lp
		
		; Set up for loop
		moveq	#0,d0
		moveq	#13-1,d7
		
		; Loop over all mixer tests
.perf_loop
		bsr		RunPerformanceTest
		addq.w	#1,d0
		dbra	d7,.perf_loop
		
		; Set up for loop
		moveq	#9-1,d7
		
		; Loop over all plugin tests
.perf_loop_plg
		bsr		RunPerformanceTestPlg
		addq.w	#1,d0
		dbra	d7,.perf_loop_plg
		
		; Clear foreground
		; Blitsize vcount has been halved and hcount doubled to fit
		move.w	#(buffer_scroll_hgt*2)<<6|((display_width+(32*2))/8),d0
		move.l	fg_buf1,a0
		jsr		BlitClearScreen
		
		; Update subbuffer text
		moveq	#0,d4
		lea.l	ressbtxt,a3
		jsr		PrintSubbuffer

		moveq	#0,d0						; Reset display type
		move.w	d0,current_page				; Reset page number to 0

		; Show results
.show_results
		; Update result text	
		bsr		WriteResults
		
		; Print results text
		moveq	#0,d4
		lea.l	palhtxt,a3
		cmp.b	#50,VidFreq
		beq.s	.printh2
		
		lea.l	ntschtxt,a3

.printh2
		bsr		PrintFG
		
		; Select which page to print
		lea.l	resscrtxt,a3
		btst	#1,d0
		beq.s	.print_page

		lea.l	resscrtxt_2,a3

.print_page
		jsr		PrintFG	
		
		IF MIXER_SINGLE=1
			lea.l	perstxt,a3
			bsr		PrintFG
			lea.l	singhtxt,a3
			bsr		PrintFG
		ELSE
			lea.l	permtxt,a3
			bsr		PrintFG
			lea.l	multhtxt,a3
			bsr		PrintFG
		ENDIF
		
;-----------------------------------------
; Main loop
;-----------------------------------------
.main_lp
		move.w	d0,-(sp)
		jsr		WaitEOF
		move.w	(sp)+,d0
		
		; Fetch input
		bsr		ReadInput
		
		; Compare with previous input		
		cmp.w	input_result,d7
		beq		.main_lp					; Wait until input changes
		
		; Store current input result to prevent repeats
		move.w	d7,input_result
		
		; Test for the different options:
		; *) right mouse button switches display type
		; *) left mouse button exits program
		
		; Test right mouse button
		btst	#11,d7
		beq		.tst_lft
		
		; Fetch current page
		move.w	current_page,d0
		
		; Increment page number
		addq.w	#1,d0
		move.w	d0,current_page
		
		cmp.w	#4,d0
		blt		.show_results
		
		moveq	#0,d0
		move.w	d0,current_page
		bra		.show_results
		
		; Test left mouse button
.tst_lft
		btst	#10,d7
		beq		.no_inp
		
		; Exit program
		bra		.done
		
.no_inp
		bra		.main_lp
		
		; Wait on Blitter
.done
		jsr		WaitEOF
		lea.l	custombase,a6
		BlitWait a6

		; Restore led status
		move.b	$bfe001,d0					; Fetch CIAA PRA
		or.b	led_status,d0
		move.b	d0,$bfe001					; Disable audio filter
		
		; Restore keyboard
		lea.l	ciabase,a6
		move.b	#$ff,ciatblo(a6)	; TB=$ffff
		move.b	#$ff,ciatbhi(a6)
		; Re-enable CIA-A interrupts for AmigaOS
		move.b	#$8f,ciaicr(a6)
		
		; Deallocate memory
		move.l	$4.w,a6
		bsr		FreeAll
		
		; Exit program
.error	lea.l	custombase,a6
		rts
		
		; Routine: RunPerformanceTest
		; This routine runs the performance test for the given performance
		; test routines.
		;
		; D0 - test number to run
RunPerformanceTest
		movem.l	d0-d7/a0-a6,-(sp)			; Stack

		; Fetch the 32x indicator
		lea.l	PerfTest_32x_modes,a1
		lea.l	PerfTest_word_modes,a2

		; Save the test number
		move.w	d0,d6
		add.w	d6,d6
		move.w	0(a1,d6.w),d4				; 32x indicator
		move.w	0(a2,d6.w),d5				; word indicator
		add.w	d6,d6						; Offset into pointer array

		; Fetch and store pointer to mixer_ticks_last
		lea.l	PerfTest_data,a1
		lea.l	mxmixer_ticks_last(a1),a1
		lea.l	0(a1,d6.w),a1
		move.l	(a1),calcres_ptr

		; Fetch the correct routines
		lea.l	PerfTest_routines,a1
		lea.l	0(a1,d6.w),a1				; Base pointer for this test
											; number.
											
		; Fetch the correct size
		move.l	#sample1_size,d1
		tst.w	d5
		beq.s	.no_wordsz
		
		move.l	#sample1_word_size,d1
.no_wordsz

		; Add subbuffer text (1/3)
		move.w	d6,d7
		mulu	#3,d7
		lea.l	cntxt_ptrs,a3
		move.l	0(a3,d7.w),a3
		move.w	d4,-(sp)
		move.w	#0,d4
		bsr		PrintSubbuffer
		move.w	(sp)+,d4
		
		; Run test 1: play once
		move.w	#MIX_FX_ONCE,d3
		bsr		RunSingleTest
		moveq	#0,d5
		bsr		WritePerfResults
		
		; Add subbuffer text (2/3)
		move.w	d6,d7
		mulu	#3,d7
		lea.l	cntxt_ptrs,a3
		move.l	4(a3,d7.w),a3
		move.w	d4,-(sp)
		move.w	#0,d4
		bsr		PrintSubbuffer
		move.w	(sp)+,d4
		
		; Run test 2: play loop
		move.w	#MIX_FX_LOOP,d3
		bsr		RunSingleTest
		moveq	#8,d5
		bsr		WritePerfResults
		
		; Add subbuffer text (3/3)
		move.w	d6,d7
		mulu	#3,d7
		lea.l	cntxt_ptrs,a3
		move.l	8(a3,d7.w),a3
		move.w	d4,-(sp)
		move.w	#0,d4
		bsr		PrintSubbuffer
		move.w	(sp)+,d4
		
		; Run test 3: play short loop
		moveq	#28,d1						; A length of 28 bytes is not the 
											; actual worst case scenario for
											; loops (this would be 4 bytes),
											; but it is bad enough to trigger
											; the longest possible 4 byte 
											; block mix instead of using 32 
											; byte blocks.
		tst.w	d4
		beq.s	.run_short_loop
		
		move.w	#32,d1						; A length of 32 is the worst case
											; loop size for modes running the
											; 32x size multipliers.
		
.run_short_loop		
		move.w	#MIX_FX_LOOP,d3
		bsr		RunSingleTest
		moveq	#16,d5
		bsr		WritePerfResults

		movem.l	(sp)+,d0-d7/a0-a6			; Stack
		rts
		
		; Routine: RunPerformanceTestPlg
		; This routine runs the performance test for the given performance
		; test routines (for plugins).
		;
		; D0 - test number to run
RunPerformanceTestPlg
		movem.l	d0-d7/a0-a6,-(sp)			; Stack

		; Save the test number
		move.w	d0,d6
		add.w	d6,d6
		add.w	d6,d6						; Offset into jump table

		; Fetch the correct mixer routines
		lea.l	PerfTest_plg_routines,a1	; Pointer to mixer (plugins test)
		lea.l	PerfTest_plg_data,a3
		lea.l	mxplgmixer_ticks_last(a3),a3
		lea.l	PLPerfTest_init_routines,a4
		lea.l	PLPerfTest_routines,a5
		cmp.w	#19,d0
		blt.s	.calc_offset

		moveq	#4,d0
		lea.l	4(a1),a1					; 68020 mixer routines
		lea.l	4(a3),a3
		bra.s	.set_plg_offset

.calc_offset
		moveq	#0,d0

.set_plg_offset
		move.l	(a3),calcres_ptr
		bsr		PTestSetPlgRoutineOffset
		
		; Add subbuffer text
		move.w	d6,d5
		add.w	#26*4,d5
		lea.l	cntxt_ptrs,a3
		move.l	0(a3,d5.w),a3
		move.w	d4,-(sp)
		move.w	#0,d4
		bsr		PrintSubbuffer
		move.w	(sp)+,d4
		
		; Run test 1: play once
		move.l	#sample1_size,d1
		move.w	#MIX_FX_ONCE,d3
		bsr		RunSingleTestPlg
		moveq	#0,d5
		bsr		WritePerfResultsPlg

		movem.l	(sp)+,d0-d7/a0-a6			; Stack
		rts
		
		; Routine: RunSingleTest
		; Runs a single test loop for the performance test
		;
		; D1 - size of sample
		; D3 - sample type
RunSingleTest
		movem.l	d4/d5/d6,-(sp)
		
		; Set variables for use with the mixer
		lea.l	mixer_buffer,a0
		moveq	#0,d4

		; Select for PAL or NTSC mixing
		move.w	#MIX_PAL,d0
		cmp.b	#50,VidFreq
		beq.s	.mixer_setup
			
		move.w	#MIX_NTSC,d0

.mixer_setup
		movem.l	d1/a1/a3,-(sp)				; Stack
		move.l	mxsetup(a1),a3
		lea.l	plugin_buffer,a1			; Fetch plugin buffer
		lea.l	plugin_data,a2				; Fetch plugin data buffer
		move.w	#mxplg_max_data_size,d1
		jsr		(a3)						; MixerSetup
		movem.l	(sp)+,d1/a1/a3				; Stack

		; Set up the mixer interrupt handler
		move.l	vbr_ptr,a0
		moveq	#0,d0
		move.l	mxinsthandler(a1),a2		; MixerInstallHandler
		jsr		(a2)						
		
		; Start the mixer
		move.l	mxstart(a1),a2				; MixerStart
		jsr		(a2)
		
		; Set volume to 0
		moveq	#0,d0
		move.l	mxvolume(a1),a2				; MixerVolume
		jsr		(a2)
		
		; Fetch MixerPlayChannelSample routine
		move.l	mxplaychsam(a1),a2

		; Reset the mixer counter
		move.l	mxresetcounter(a1),a3		; MixerResetCounter
		jsr		(a3)
		
		; Get MixerGetCounter
		move.l	mxgetcounter(a1),a3			; MixerGetCounter

		; Loop for 132 frames (to make sure at least 128 have been filled 
		; while samples are mixed)
		move.w	#132,d7
		mulu	#mixer_output_count,d7

.timing_loop
		; Add 4 samples to channel 0
		; A0=sample,D0=hardware_channel.w,D1=signed_length.l,
		; D2=signed_priority.w,D3=loop_indicator.w,D4=loop_offset.l
		moveq	#1,d2
		move.l	sample1_mix,a0
		move.w	#DMAF_AUD0|MIX_CH0,d0
		jsr		(a2)						; MixerPlayChannelSample
		move.w	#DMAF_AUD0|MIX_CH1,d0
		jsr		(a2)						; MixerPlayChannelSample
		move.w	#DMAF_AUD0|MIX_CH2,d0
		jsr		(a2)						; MixerPlayChannelSample
		move.w	#DMAF_AUD0|MIX_CH3,d0
		jsr		(a2)						; MixerPlayChannelSample

		; Check if counter value is equal to D7
		jsr		(a3)
		cmp.w	d0,d7
		blt.s	.timing_done

		nop									; no action

		; Loop back
		bra.s	.timing_loop
		
.timing_done

		; Disable audio mixer
		move.l	mxstop(a1),a2				; MixerStop
		jsr		(a2)

		; Fetch VBR
		move.l	vbr_ptr,a0

		; Remove Mixer interrupt handler
		move.l	mxremhandler(a1),a2			; MixerRemoveHandler
		jsr		(a2)

		; Stop the looping samples
		move.l	mxstopfx(a1),a2				; MixerStopFX
		move.w	#DMAF_AUD0|MIX_CH0|MIX_CH1|MIX_CH2|MIX_CH3,d0
		jsr		(a2)

		; Calculate result
		move.l	mxcalcticks(a1),a2
		jsr		(a2)						; MixerCalcTicks

		movem.l	(sp)+,d4/d5/d6
		rts
		
		; Routine: RunSingleTestPlg
		; Runs a single test loop for the performance test (plugins version)
		;
		; A1 - Pointer to plugin routines
		; D1 - size of sample
		; D3 - sample type
		; D6 - jump table offset
RunSingleTestPlg
		movem.l	d4/d5/d6,-(sp)
		
		; Fetch plugin data
		lea.l	plugin_init_data,a3
		
		; Set up plugin data for all 16 channels
		sub.w	#13*4,d6
		jmp		.jp_table(pc,d6.w)
		
.jp_table
		jmp		.setup_sync(pc)
		jmp		.setup_repeat(pc)
		jmp		.setup_voltab(pc)
		jmp		.setup_volshift(pc)
		jmp		.setup_pitch(pc)
		jmp		.setup_pitchlq(pc)
		jmp		.setup_pitch_020(pc)
		jmp		.setup_voltab_020(pc)
		jmp		.setup_volshift_020(pc)
		
.setup_sync
		lea.l	plsync(a4),a4
		lea.l	plsync(a5),a5
		lea.l	plugin_sync,a6
		moveq	#MIX_PLUGIN_NODATA,d4
		moveq	#16-1,d7

.setup_sync_lp
		move.l	a6,mpid_snc_address(a3)
		move.w	#1,mpid_snc_delay(a3)
		move.w	#MXPLG_SYNC_DELAY_ONCE,mpid_snc_mode(a3)
		move.w	#MXPLG_SYNC_ONE,mpid_snc_type(a3)
		
		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_sync_lp
		bra		.set_vars
		
.setup_repeat
		lea.l	plrepeat(a4),a4
		lea.l	plrepeat(a5),a5
		moveq	#MIX_PLUGIN_NODATA,d4
		moveq	#16-1,d7
		
.setup_repeat_lp		
		move.w	#1,mpid_rep_delay(a3)
		
		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_repeat_lp
		bra		.set_vars
		
.setup_voltab
		lea.l	plvolume(a4),a4
		lea.l	plvolume(a5),a5
		moveq	#MIX_PLUGIN_STD,d4
		moveq	#16-1,d7
		
.setup_voltab_lp
		move.w	#MXPLG_VOL_TABLE,mpid_vol_mode(a3)
		move.w	#8,mpid_vol_volume(a3)
		
		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_voltab_lp
		bra		.set_vars
		
.setup_volshift
		lea.l	plvolume(a4),a4
		lea.l	plvolume(a5),a5
		moveq	#MIX_PLUGIN_STD,d4
		moveq	#16-1,d7
		
.setup_volshift_lp
		move.w	#MXPLG_VOL_SHIFT,mpid_vol_mode(a3)
		move.w	#3,mpid_vol_volume(a3)
		
		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_volshift_lp
		bra		.set_vars
		
.setup_pitch
		lea.l	plpitch(a4),a4
		lea.l	plpitch(a5),a5
		moveq	#MIX_PLUGIN_STD,d4
		moveq	#16-1,d7
		
.setup_pitch_lp
		move.w	#MXPLG_PITCH_STANDARD,mpid_pit_mode(a3)
		move.w	#MXPLG_PITCH_NO_PRECALC,mpid_pit_precalc(a3)
		move.w	#$0c0,mpid_pit_ratio_fp8(a3)
		
		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_pitch_lp
		bra		.set_vars
		
.setup_pitchlq
		lea.l	plpitch(a4),a4
		lea.l	plpitch(a5),a5
		moveq	#MIX_PLUGIN_STD,d4
		moveq	#16-1,d7
		
.setup_pitchlq_lp
		move.w	#MXPLG_PITCH_LOWQUALITY,mpid_pit_mode(a3)
		move.w	#MXPLG_PITCH_NO_PRECALC,mpid_pit_precalc(a3)
		move.w	#$0c0,mpid_pit_ratio_fp8(a3)
		
		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_pitchlq_lp
		bra		.set_vars
		
.setup_pitch_020
		lea.l	plpitch(a4),a4
		lea.l	plpitch(a5),a5
		moveq	#MIX_PLUGIN_STD,d4
		moveq	#16-1,d7
		
.setup_pitch_020_lp
		move.w	#MXPLG_PITCH_STANDARD,mpid_pit_mode(a3)
		move.w	#MXPLG_PITCH_NO_PRECALC,mpid_pit_precalc(a3)
		move.w	#$0c0,mpid_pit_ratio_fp8(a3)

		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_pitch_020_lp
		bra		.set_vars
		
.setup_voltab_020
		lea.l	plvolume(a4),a4
		lea.l	plvolume(a5),a5
		moveq	#MIX_PLUGIN_STD,d4
		moveq	#16-1,d7

.setup_voltab_020_lp		
		move.w	#MXPLG_VOL_TABLE,mpid_vol_mode(a3)
		move.w	#8,mpid_vol_volume(a3)
		
		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_voltab_020_lp
		bra		.set_vars
		
.setup_volshift_020
		lea.l	plvolume(a4),a4
		lea.l	plvolume(a5),a5
		moveq	#MIX_PLUGIN_STD,d4
		moveq	#16-1,d7

.setup_volshift_020_lp		
		move.w	#MXPLG_VOL_SHIFT,mpid_vol_mode(a3)
		move.w	#3,mpid_vol_volume(a3)

		lea.l	mxplg_max_idata_size(a3),a3
		dbra	d7,.setup_volshift_020_lp

.set_vars
		; Set variables for use with the mixer
		lea.l	mixer_buffer,a0

		; Select for PAL or NTSC mixing
		move.w	#MIX_PAL,d0
		cmp.b	#50,VidFreq
		beq.s	.mixer_setup
			
		move.w	#MIX_NTSC,d0

.mixer_setup
		movem.l	d1/a1/a3,-(sp)				; Stack
		move.l	mxplgsetup(a1),a3
		lea.l	plugin_buffer,a1			; Fetch plugin buffer
		lea.l	plugin_data,a2				; Fetch plugin data buffer
		move.w	#mxplg_max_data_size,d1
		jsr		(a3)						; MixerSetup
		movem.l	(sp)+,d1/a1/a3				; Stack

		; Set up the mixer interrupt handler
		move.l	vbr_ptr,a0
		moveq	#0,d0
		move.l	mxplginsthandler(a1),a2		; MixerInstallHandler
		jsr		(a2)						
		
		; Start the mixer
		move.l	mxplgstart(a1),a2			; MixerStart
		jsr		(a2)
		
		; Set volume to 0
		moveq	#0,d0
		moveq	#0,d0
		move.l	mxplgvolume(a1),a2			; MixerVolume
		jsr		(a2)

		; Fetch MixerPlayChannelFX routine
		move.l	mxplgplaychfx(a1),a2

		; Save function pointer
		move.l	a1,a6
		
		; Start playback of samples on all channels
		lea.l	plugin_init_data,a3
		lea.l	effect_struct,a0
		lea.l	plugin_struct,a1

		bsr		FillStructs					; Fill Effect & Plugin structure
		move.w	#DMAF_AUD0|MIX_CH0,d0
		jsr		(a2)
		lea.l	mxplg_max_idata_size(a3),a3
		IF mixer_sw_channels>1
			bsr		FillStructs				; Fill Effect & Plugin structure
			move.w	#DMAF_AUD0|MIX_CH1,d0
			jsr		(a2)
			lea.l	mxplg_max_idata_size(a3),a3
		ENDIF
		IF mixer_sw_channels>2
			bsr		FillStructs				; Fill Effect & Plugin structure
			move.w	#DMAF_AUD0|MIX_CH2,d0
			jsr		(a2)
			lea.l	mxplg_max_idata_size(a3),a3
		ENDIF
		IF mixer_sw_channels>3
			bsr		FillStructs				; Fill Effect & Plugin structure
			move.w	#DMAF_AUD0|MIX_CH3,d0
			jsr		(a2)
			lea.l	mxplg_max_idata_size(a3),a3
		ENDIF
		
		; Reset the mixer counter
		move.l	mxplgresetcounter(a6),a2	; MixerResetCounter
		jsr		(a2)
		
		; Get MixerGetCounter
		move.l	mxplggetcounter(a6),a2		; MixerGetCounter
		
		; Loop for 132 frames (to make sure at least 128 have been filled 
		; while samples are mixed)
		move.w	#132,d7
		mulu	#mixer_output_count,d7

.timing_loop
		; Check if counter value is equal to D7
		jsr		(a2)
		cmp.w	d0,d7
		blt.s	.timing_done

		nop									; no action

		; Loop back
		bra.s	.timing_loop
		
.timing_done
		; Restore function pointer
		move.l	a6,a1

		; Disable audio mixer
		move.l	mxplgstop(a1),a2			; MixerStop
		jsr		(a2)

		; Fetch VBR
		move.l	vbr_ptr,a0

		; Remove Mixer interrupt handler
		move.l	mxplgremhandler(a1),a2		; MixerRemoveHandler
		jsr		(a2)

		; Stop the looping samples
		move.l	mxplgstopfx(a1),a2			; MixerStopFX
		move.w	#DMAF_AUD0|MIX_CH0|MIX_CH1|MIX_CH2|MIX_CH3,d0
		jsr		(a2)

		; Calculate result
		move.l	mxplgcalcticks(a1),a2		; MixerCalcTicks
		jsr		(a2)

		movem.l	(sp)+,d4/d5/d6
		rts
		
		; Routine: FillStructs
		; This routine fills the effect & plugin structs for use with
		; the MixerPlayChannelFX routine.
FillStructs
		; Fill effect structure
		move.l	d1,mfx_length(a0)
		move.l	#sample1,mfx_sample_ptr(a0)
		move.w	#MIX_FX_ONCE,mfx_loop(a0)
		move.w	#1,mfx_priority(a0)
		clr.l	mfx_loop_offset(a0)
		move.l	a1,mfx_plugin_ptr(a0)

		; Fill plugin structure
		move.w	d4,mpl_plugin_type(a1)
		move.l	(a4),mpl_init_ptr(a1)
		move.l	(a5),mpl_plugin_ptr(a1)
		move.l	a3,mpl_init_data_ptr(a1)
		
		rts

		; Routine: WritePerfResults
		; This routine writes the result of the last performance measurements
		; to the results table.
		;
		; D5 - offset into table (8*sub test number)
		; D6 - test number *4
WritePerfResults
		movem.l	d6/a3/a4,-(sp)				; Stack

		mulu	#6,d6
		lea.l	res_PerfTest,a3
		lea.l	0(a3,d5.w),a3
		lea.l	0(a3,d6.w),a3
		move.l	calcres_ptr,a4
		move.w	(a4)+,(a3)+
		move.w	(a4)+,(a3)+
		move.w	(a4)+,(a3)+
		move.w	(a4)+,(a3)+

		movem.l	(sp)+,d6/a3/a4				; Stack
		rts
		
		; Routine: WritePerfResultsPlg
		; This routine writes the result of the last performance measurements
		; to the results table (plugins version)
		;
		; D6 - test number *4
WritePerfResultsPlg
		movem.l	d6/a3/a4,-(sp)				; Stack

		sub.w	#13*4,d6					; Reset count for plugins
		mulu	#2,d6
		lea.l	PerfTest_Plg_Sync,a3
		lea.l	0(a3,d6.w),a3
		move.l	calcres_ptr,a4
		move.w	(a4)+,(a3)+
		move.w	(a4)+,(a3)+
		move.w	(a4)+,(a3)+
		move.w	(a4)+,(a3)+

		movem.l	(sp)+,d6/a3/a4				; Stack
		rts

		; Routine: ResultToDec
		; Converts binary result to decimal digits (max: 9999).
		; Positive numbers only.
		;
		; D0 - Number to convert
		; A0 - Pointer to result (4 character string)
ResultToDec
		movem.l	a0/d0/d7,-(sp)				; Stack

		; Pre-clear output
		move.b	#" ",(a0)
		move.b	#" ",1(a0)
		move.b	#" ",2(a0)
		move.b	#" ",3(a0)

		and.l	#$ffff,d0
		cmp.w	#9999,d0
		ble.s	.convert_loop

		; Clamp to 9999
		move.w	#9999,d0

.convert_loop
		
		lea.l	4(a0),a0					; Move to last digit + 1
		moveq	#4-1,d7						; Repeat up to four digits
.lp		divu	#10,d0						; Divide result by ten
		tst.l	d0
		beq		.done

		swap	d0				
		move.w	d0,d1						; Get remainder
		add.w	#48,d1						; Convert to ASCII
		move.b	d1,-(a0)					; Store in string
		move.w	#0,d0						; Clear remainder
		swap	d0
		dbra	d7,.lp
		
.done	movem.l	(sp)+,d0/d7/a0				; Stack
		rts

		; Routine: ResultToPerc
		; Converts binary result to percentage of frame time.
		; Positive numbers only (max percentage 99,9%).
		;
		; D0 - Number to convert
		; A0 - Pointer to result (5 character string)
ResultToPerc
		movem.l	d0-d2/a0,-(sp)					; Stack
		
		; Pre-clear output (rest is cleared in ResultToDec)
		move.b	#" ",4(a0)

		; Select total cycles based on video system in use
		move.w	#((227*313)*2)/10,d1			; Total CIA cycles (PAL)
		cmp.b	#50,VidFreq
		beq.s	.cal_perc1

		; Total CIA cycles (NTSC)			
		move.w #(((226*131)*2)/10)+(((227*131)*2)/10),d1
		
.cal_perc1
		move.w	d1,d2						
		asr.w	#1,d2						; Store half total cycle count
		mulu	#1000,d0
		divu	d1,d0						; Top 2 or 3 digits of percentage
		swap	d0
		move.w	d0,d1
		swap	d0

		; Compare remainder to half CIA cycles (NTSC)
		cmp.w	d2,d1
		blt.s	.no_round
		
		addq.w	#1,d0
.no_round
		; D0 contains percentage * 10
		and.l	#$ffff,d0
		cmp.w	#999,d0
		ble.s	.convert_dec
		
		; Clamp at 99,9%
		move.w	#999,d0
		
.convert_dec
		bsr		ResultToDec

		; A0 points to result
		move.b	1(a0),(a0)
		move.b	2(a0),1(a0)
		move.b  #".",2(a0)
		move.b	#"%",4(a0)
		
		; Make sure at least 0.0 is shown
		cmp.w	#10,d0
		bge.s	.over_one_perc
		
		move.b	#"0",1(a0)
		
.over_one_perc
		cmp.w	#1,d0
		bge.s	.over_zero
		
		move.b	#"0",3(a0)
		
.over_zero
		movem.l	(sp)+,d0-d2/a0					; Stack
		rts
		
		; Routine: WriteResults
		; This routine writes the results of the performance tests to screen.
		;
		; D0 - set to 0 to display raw digits
		;      set to 1 to display percentages
WriteResults
		movem.l	d0-d7/a0-a6,-(sp)			; Stack

		; Set up for displaying results
		lea.l	res_PerfTest,a1				; Pointer to 1st result
		lea.l	resscrtxt,a2
		lea.l	res_offset(a2),a2			; Pointer to 1st output

		moveq	#1,d6						; Offset
		lea.l	ResultToDec(pc),a3			; Fetch function pointer
		btst	#0,d0
		beq.s	.loop_setup

		moveq	#0,d6						; Offset
		lea.l	ResultToPerc(pc),a3			; Fetch function pointer

.loop_setup
		; Set up for loop
		moveq	#48-1,d7

		; Loop over all results
.lp		
		; Switch to page 2 after reaching 24th position
		cmp.w	#23,d7
		bne.s	.cnt_lp

		lea.l	resscrtxt_2,a2
		lea.l	res_offset(a2),a2			; Pointer to 2nd page

.cnt_lp
		move.w	2(a1),d0 					; Fetch best result
		move.b	#" ",(a2)
		move.b	#" ",1(a2)
		lea.l	0(a2,d6.w),a0				; Output location
		jsr		(a3)

		move.w	4(a1),d0					; Fetch worst result
		move.b	#" ",6(a2)
		move.b	#" ",7(a2)
		lea.l	6(a2,d6.w),a0				; Output location
		jsr		(a3)

		move.w	6(a1),d0					; Fetch average result
		move.b	#" ",12(a2)
		move.b	#" ",13(a2)
		lea.l	12(a2,d6.w),a0				; Output location
		jsr		(a3)

		move.w	0(a1),d0					; Fetch last result
		move.b	#" ",19(a2)
		move.b	#" ",20(a2)
		lea.l	19(a2,d6.w),a0				; Output location
		jsr		(a3)

		lea.l	8(a1),a1					; Next set of results
		lea.l	res_line_offset(a2),a2		; Next line
		dbra	d7,.lp

		movem.l	(sp)+,d0-d7/a0-a6			; Stack
		rts


;------------------------------------
; Data follows
;------------------------------------
		
		section data,data
		cnop	0,2
		
		; Palette entries for main screen
		; Background colour	0
		; Foreground layer	1-15 		(from plane 1,3,5)
		; Transparancy col. 16					(for sprites)
		; Sprites			17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
palette		dc.w	$000									; Background colour
			dc.w	$223,$008,$500,$000,$445,$a21,$382		; FG col  (#1-15)
			dc.w	$778,$e50,$aab,$fa3,$5db,$fff,$666,$999
			dc.w	$000									; Transp. (#16)
			dc.w	$22b,$444,$ddd,$000,$22b,$444,$ddd		; SPR col (#17-31)
			dc.w	$000,$22b,$444,$ddd,$000,$22b,$444,$ddd

		; Palette entries for subscreen (8 colours)
subpal		dc.w	$000,$440,$660,$880,$aa0,$cc0,$ee0,$000

		; Foreground main buffer
		; Buffer size for FGM: 
		;	304x224x4
fg_buf1			dc.l	0

		; Sub buffer
		; Buffer size for FGS: 288x16x3
sb_buf			dc.l	0
sb_buf_o		EQU	sb_buf-fg_buf1

		; Variables - copper list pointer
clist_ptrs		dc.l	0
clist_ptrs_o	EQU	clist_ptrs-fg_buf1

		; Variables - other
vbr_ptr			dc.l	0
vbl_done		dc.w	0
vbl_vector		dc.l	0
led_status		dc.w	0
input_result	dc.w	0
pt_status		dc.w	0
mix_status		dc.w	0
current_sample	dc.w	0
current_page	dc.w	0
calcres_ptr		dc.l	0
frame_timer		dc.w	0

sample1_mix		dc.l	sample1
sample_info		dc.l	0
	XDEF sample1_mix
	XDEF sample_info
	
		; Performance test results (binary)
res_PerfTest					dc.w 0,0,0,0	; No optimisations
res_PerfTest_loop				dc.w 0,0,0,0
res_PerfTest_short_loop			dc.w 0,0,0,0
res_PerfTest_32					dc.w 0,0,0,0	; Size x32
res_PerfTest_32_loop			dc.w 0,0,0,0
res_PerfTest_32_short_loop		dc.w 0,0,0,0
PerfTest_bufsz					dc.w 0,0,0,0	; Size xBuf
PerfTest_bufsz_loop				dc.w 0,0,0,0
PerfTest_bufsz_short_loop		dc.w 0,0,0,0
PerfTest_word					dc.w 0,0,0,0	; Length xWord
PerfTest_word_loop				dc.w 0,0,0,0
PerfTest_word_short_loop		dc.w 0,0,0,0
PerfTest_word32					dc.w 0,0,0,0	; Length xWord/Size x32
PerfTest_word32_loop			dc.w 0,0,0,0
PerfTest_word32_short_loop		dc.w 0,0,0,0
PerfTest_wordbufsz				dc.w 0,0,0,0	; Length xWord/Size xBuf
PerfTest_wordbufsz_loop			dc.w 0,0,0,0
PerfTest_wordbufsz_short_loop	dc.w 0,0,0,0
PerfTest_word32bufsz			dc.w 0,0,0,0	; Length xWord/Size xBuf/x32
PerfTest_word32bufsz_loop		dc.w 0,0,0,0
PerfTest_word32bufsz_short_loop	dc.w 0,0,0,0
PerfTest_020					dc.w 0,0,0,0	; CPU type = 68020
PerfTest_020_loop				dc.w 0,0,0,0
PerfTest_020_short_loop			dc.w 0,0,0,0
PerfTest_HQ						dc.w 0,0,0,0	; HQ mode
PerfTest_HQ_loop				dc.w 0,0,0,0
PerfTest_HQ_short_loop			dc.w 0,0,0,0
PerfTest_HQ_020					dc.w 0,0,0,0
PerfTest_HQ_020_loop			dc.w 0,0,0,0
PerfTest_HQ_020_short_loop		dc.w 0,0,0,0
PerfTest_Callback				dc.w 0,0,0,0	; No callback present
PerfTest_Callback_loop			dc.w 0,0,0,0
PerfTest_Callback_short_loop	dc.w 0,0,0,0
PerfTest_Plugins				dc.w 0,0,0,0	; No plugins present
PerfTest_Plugins_loop			dc.w 0,0,0,0
PerfTest_Plugins_short_loop		dc.w 0,0,0,0
PerfTest_CBPLG					dc.w 0,0,0,0	; No callback/plugins present
PerfTest_CBPLG_loop				dc.w 0,0,0,0
PerfTest_CBPLG_short_loop		dc.w 0,0,0,0

	; Plugin performance test results (binary)
PerfTest_Plg_Sync				dc.w 0,0,0,0
PerfTest_Plg_Repeat				dc.w 0,0,0,0
PerfTest_Plg_Pitch				dc.w 0,0,0,0
PerfTest_Plg_PitchLQ			dc.w 0,0,0,0
PerfTest_Plg_Pitch_020			dc.w 0,0,0,0
PerfTest_Plg_Vol_Tab			dc.w 0,0,0,0
PerfTest_Plg_Vol_Shft			dc.w 0,0,0,0
PerfTest_Plg_Vol_Tab_020		dc.w 0,0,0,0
PerfTest_Plg_Vol_Shft_020		dc.w 0,0,0,0


		cnop 0,4
effect_struct			blk.b	mfx_SIZEOF

		cnop 0,4
plugin_buffer			blk.b	mixer_plugin_buffer_size

		cnop 0,4
sample1					blk.b	sample1_size

		cnop 0,4
fx_struct				blk.b	mfx_SIZEOF

		cnop 0,4
plugin_struct			blk.b	mpl_SIZEOF

		cnop 0,4
plugin_init_data		blk.b	mxplg_max_idata_size*16
plugin_data				blk.b	mxplg_max_data_size*16
plugin_sync				dc.w	0

		section audio,data_c
		cnop 0,4
mixer_buffer			blk.b	mixer_buffer_size

; End of File