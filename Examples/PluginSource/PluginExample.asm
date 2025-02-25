; $VER: PluginExample.asm 1.0 (05.02.24)
;
; PluginExample.asm
; Example showing the audio mixer in MIXER_SINGLE mode with plugins enabled.
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20240205
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

	include displaybuffers.i
	include blitter.i
	include copperlists.i
	include font.i
	include converter.i
	include mixer.i
	include samples.i
	include plugins.i
	include PluginExample.i
	include strings.i
	include support.i

; Custom chips offsets
custombase			EQU	$dff000

; External references
	XREF	WaitEOF
	XREF	WaitRaster
	
	XDEF	clist_ptrs
	XDEF	palette
	XDEF	subpal
	
; Start of code
		section code,code
		
		; Main code starts here
_main	move.l	$4.w,a6				; Fetch sysbase
		move.l	a4,vbr_ptr			; Save VBR pointer

		; Allocate all memory
		bsr		AllocAll
		bne		.error
		
;-----------------------------------------
; Set up initial screen
;-----------------------------------------
		
		; Set custombase here
		lea.l	custombase,a6
		
		; Activate blitter DMA
DMAVal	SET		DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER
		move.w	#DMAVal,dmacon(a6)

		; Wait on blitter
		BlitWait a6
		move.l	#$ffffffff,bltafwm(a6)	; Preset blitter mask value
		
		; Setup Copperlist
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
		
		; Add prepare sample screen text
		moveq	#0,d4
		lea.l	palhtxt,a3
		cmp.b	#50,VidFreq
		beq.s	.printh1
		
		lea.l	ntschtxt,a3

.printh1
		bsr		PrintFG
		lea.l	preptxt,a3
		jsr		PrintFG
		
		; Add subbuffer text
		moveq	#0,d4
		lea.l	subpreptxt,a3
		bsr		PrintSubbuffer
		
		; Enable DMA
DMAVal	SET		DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER
		move.w	#DMAVal,dmacon(a6)

		; Activate copper list
		lea.l	clist1,a0
		move.l	a0,cop1lc(a6)
		move.w	#1,copjmp1(a6)

;-----------------------------------------
; Set up Mixer/samples
;-----------------------------------------
		move.b	$bfe001,d0					; Fetch CIAA PRA
		and.b	#$2,d0
		move.b	d0,led_status
		or.b	#$2,d0
		move.b	d0,$bfe001					; Disable audio filter

		; Prepare sample data
		IF MIXER_HQ_MODE=1
			moveq	#1,d1
		ELSE
			moveq	#mixer_sw_channels,d1
		ENDIF
		bsr		PrepSamples
		
		; Set up the mixer
		lea.l	mixer_buffer,a0
		lea.l	plugin_buffer,a1
		lea.l	plugin_data,a2
		move.w	#mxplg_max_data_size,d1
		move.w	#MIX_PAL,d0
		cmp.b	#50,VidFreq					; Check if this is a PAL system
		beq.s	.mixer_setup
		
		move.w	#MIX_NTSC,d0
		
.mixer_setup
		bsr		MixerSetup

		; Set up the mixer interrupt handler (initially to standard mix)
		move.l	vbr_ptr,a0
		moveq	#0,d0
		bsr		MixerInstallHandler
		
		; Start the mixer
		bsr		MixerStart
		
;-----------------------------------------
; Display title screen
;-----------------------------------------
		; Clear foreground
		; Blitsize vcount has been halved and hcount doubled to fit
		move.w	#(buffer_scroll_hgt*2)<<6|((display_width+(32*2))/8),d0
		move.l	fg_buf1,a0
		jsr		BlitClearScreen
		
		; Wait on blitter
		BlitWait a6
		
		; Add title text
		moveq	#0,d4
		cmp.b	#50,VidFreq
		bne.s	.printntsc_title

		lea.l	palhtxt,a3
		bsr		PrintFG
		bra		.print_title
		
.printntsc_title
		lea.l	ntschtxt,a3
		bsr		PrintFG

.print_title
		lea.l	titletxt,a3
		jsr		PrintFG

		; Display subbuffer status text
		moveq	#0,d4
		lea.l	substarttxt,a3
		bsr		PrintSubbuffer
		
		; Wait on fire button
.title_lp
		movem.l	d0/d1,-(sp)
		move.w	#$2c,d0
		jsr		WaitRaster
		movem.l	(sp)+,d0/d1

		; Fetch input
		bsr		ReadInput
		
		; Compare with previous input		
		cmp.w	input_result,d7
		beq		.title_lp					; Wait until input changes
		
		; Store current input result to prevent repeats
		move.w	d7,input_result
		
		; Test for the different options:
		; *) fire button moves to the main program
.tst_jfire
		; Test fire button
		btst	#8,d7
		beq		.title_lp

		; Fire button was pressed, continue

;-----------------------------------------
; Show main screen
;-----------------------------------------
.show_main	
		; Clear foreground
		; Blitsize vcount has been halved and hcount doubled to fit
		move.w	#(buffer_scroll_hgt*2)<<6|((display_width+(32*2))/8),d0
		move.l	fg_buf1,a0
		jsr		BlitClearScreen
		
		; Wait on blitter
		BlitWait a6
		
		; Add title text
		moveq	#0,d4
		cmp.b	#50,VidFreq
		bne.s	.printntsc_main

		lea.l	palhtxt,a3
		bsr		PrintFG
		bra		.print_main
		
.printntsc_main
		lea.l	ntschtxt,a3
		bsr		PrintFG	

.print_main
		lea.l	maintxt,a3
		jsr		PrintFG

		; Display subbuffer status text
		moveq	#0,d4
		lea.l	subtxt,a3
		bsr		PrintSubbuffer
		
;-----------------------------------------
; Main loop setup
;-----------------------------------------
		
		; Clear frame counter / done flag / current sample
		clr.w	frame_cnt
		clr.w	main_done
		clr.w	current_sample
		
		; Set cursor position to default
		move.w	#1<<2,cursor_position

		; Set channel/action/module positions to defaults
		move.w	#0,chan_position
		move.w	#0,act_position
		move.w	#0,pl_position
		
		; Reset current plugin
		clr.w	plugin_data_current
		
;-----------------------------------------
; Main loop
;-----------------------------------------	
.main_lp
		movem.l	d0/d1,-(sp)
		move.w	#$2c,d0
		jsr		WaitRaster
		movem.l	(sp)+,d0/d1
		
		; Fetch input
		bsr		ReadInput
		
		; Handle input
		bsr		HandleInput

		; Update cursor display
		bsr		UpdateCursor
		
		; Handle sync plugin events
		bsr		HandleSync
		
		; Update frame counter
		add.w	#1,frame_cnt
		tst.w	main_done
		beq		.main_lp

;-----------------------------------------
; Program exit
;-----------------------------------------

		; Wait on Blitter
		BlitWait a6

		; Fetch VBR
		move.l	vbr_ptr,a0

		; Disable audio mixer
		bsr		MixerStop

		; Restore led status
		move.b	$bfe001,d0					; Fetch CIAA PRA
		or.b	led_status,d0
		move.b	d0,$bfe001					; Disable audio filter
		
DMAVal	SET		DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER
		move.w	#DMAVal,dmacon(a6)
		
		; Deallocate memory
		move.l	$4.w,a6
		bsr		FreeAll
		
		; Remove Mixer interrupt handler
		bsr		MixerRemoveHandler
		
		; Exit program
.error	lea.l	custombase,a6
		rts
		
;-----------------------------------------
; Main loop support routines
;-----------------------------------------
		; Routine: HandleInput
		; This routine handles the user input to the example program.
		;
		; D7 - input value from ReadInput
HandleInput
		; Compare with previous input		
		cmp.w	input_result,d7
		beq		.done						; Wait until input changes
		
		; Store current input result to prevent repeats
		move.w	d7,input_result
		
		; Test for the different options:
		; *) left mouse button exits program
		; *) fire button plays or stops sample
		; *) left/right joystick moves selection cursor
		; *) up/down change selected option
		
		; Test left mouse button
.tst_mlft
		btst	#10,d7
		beq		.tst_jfire
		
		; Exit program
		move.w	#1,main_done
		bra		.done
		
.tst_jfire
		; Test fire button
		btst	#8,d7
		beq		.tst_jleft
		
		; Play/stop sample
		bsr		MixerAction
		bra		.done
		
.tst_jleft
		; Test left
		btst	#2,d7
		beq		.tst_jright
		
		; Move cursor left
		move.w	cursor_position,d0
		btst	#2,d0						; Check for left-most position
		bne		.done
		
		asl.w	#1,d0
		move.w	d0,cursor_position
		bra		.done
		
.tst_jright
		; Test right
		btst	#3,d7
		beq		.tst_jup
		
		; Move cursor right
		move.w	cursor_position,d0
		btst	#0,d0						; Check for right-most position
		bne		.done
		
		asr.w	#1,d0
		move.w	d0,cursor_position
		bra		.done
		
.tst_jup
		; Test up
		btst	#0,d7
		beq		.tst_jdown
		
		move.w	cursor_position,d0
		subq.w	#1,d0
		add.w	d0,d0
		add.w	d0,d0
		jmp		.jptable_up(pc,d0.w)
		
.jptable_up
		jmp		.pl_up(pc)
		jmp		.act_up(pc)
		dc.l	0
		jmp		.chan_up(pc)

.chan_up
		; Change channel value up
		move.w	chan_position,d0
		beq		.done
		
		subq.w	#4,d0
		move.w	d0,chan_position
		bra		.done
		
.act_up
		; Change action value up
		move.w	act_position,d0
		beq		.done
		
		subq.w	#4,d0
		move.w	d0,act_position
		bra		.done

.pl_up
		; Change plugin value up
		move.w	pl_position,d0
		beq		.done
		
		subq.w	#4,d0
		move.w	d0,pl_position
		bra		.done
		
.tst_jdown
		; Test down
		btst	#1,d7
		beq		.done
		
		move.w	cursor_position,d0
		subq.w	#1,d0
		add.w	d0,d0
		add.w	d0,d0
		jmp		.jptable_down(pc,d0.w)
		
.jptable_down
		jmp		.pl_down(pc)
		jmp		.act_down(pc)
		dc.l	0
		jmp		.chan_down(pc)

.chan_down
		; Change channel value down
		move.w	chan_position,d0
		cmp.w	#16,d0
		beq		.done
		
		addq.w	#4,d0
		move.w	d0,chan_position
		bra		.done
		
.act_down
		; Change action value down
		move.w	act_position,d0
		cmp.w	#12,d0
		beq		.done
		
		addq.w	#4,d0
		move.w	d0,act_position
		bra		.done

.pl_down
		; Change plugin value down
		move.w	pl_position,d0
		cmp.w	#24,d0
		beq		.done
		
		addq.w	#4,d0
		move.w	d0,pl_position

		; End of input handling
.done
		rts
		
		; Routine: UpdateCursor
		; This routine updates the cursor display
UpdateCursor
		move.w	cursor_position,d0
		asl.b	#5,d0
		
		moveq	#0,d4
		asl.b	#1,d0
		addx.b	d4,d4
		lea.l	chantxt_ptrs,a3
		move.w	chan_position,d1
		move.l	0(a3,d1.w),a3
		bsr		PrintSubbuffer
		
		moveq	#0,d4
		asl.b	#1,d0
		addx.b	d4,d4
		lea.l	acttxt_ptrs,a3
		move.w	act_position,d1
		move.l	0(a3,d1.w),a3
		bsr		PrintSubbuffer
		
		moveq	#0,d4
		asl.b	#1,d0
		addx.b	d4,d4
		lea.l	pltxt_ptrs,a3
		move.w	pl_position,d1
		move.l	0(a3,d1.w),a3
		bsr		PrintSubbuffer
		rts

		; Routine: MixerAction
		; This routine is called when the fire button is pressed and takes the
		; required action based on the current settings for action/channel.
MixerAction
		movem.l	d0-d7/a0-a6,-(sp)			; Stack
		
		; Fetch correct action
		move.w	act_position,d0
		jmp		.act_jptable(pc,d0.w)
		
.act_jptable
		jmp		.play(pc)
		jmp		.play(pc)
		jmp		.play(pc)
		jmp		.stop(pc)
		
.play
		lea.l	effect_struct,a0
		move.w	#MIX_FX_ONCE,d1
		tst.w	d0
		beq.s	.write_lp_indicator
		
		cmp.w	#8,d0
		beq.s	.loop_offset

		move.w	#MIX_FX_LOOP,d1
		bra.s	.write_lp_indicator

.loop_offset
		move.w	#MIX_FX_LOOP_OFFSET,d1
		
.write_lp_indicator
		; Write loop indicator & priority
		move.w	d1,mfx_loop(a0)
		move.w	#1,mfx_priority(a0)
	
		; Fetch sample data
		lea.l	sample_info,a1
		move.w	(a1),d1						; Sample count
		lea.l	si_STRT_o(a1),a1
		move.w	current_sample,d0
		move.w	d0,d2
		mulu	#si_SIZEOF,d2				; Offset to current sample

		; Fill remaining part of the FX structure
		move.l	4(a1,d2.w),a2
		move.l	(a2),a2
		move.l	a2,mfx_sample_ptr(a0)
		move.l	8(a1,d2.w),mfx_length(a0)
		move.l	12(a1,d2.w),mfx_loop_offset(a0)
		
		; Deal with plugin here
		clr.l	mfx_plugin_ptr(a0)
		move.w	pl_position,d3
		beq.s	.update_sample

		; Set up the plugin and plugin data structures
		bsr		SetupPluginStructs
		
.update_sample
		; Update current sample
		addq.w	#1,d0
		cmp.w	d1,d0
		blt.s	.write_current_sample
		
		moveq	#0,d0
		
.write_current_sample
		move.w	d0,current_sample		
		
		; Select channel to use
		moveq	#0,d0						; MIXER_SINGLE does not need HW
											; channel set.
		move.w	chan_position,d1
		beq.s	.auto_channel
		asr.w	#2,d1
		addq.w	#3,d1						; Correct bit
		bset	d1,d0						; D0 = MIX_CHx

		; Play on the requested mixer channel
		; A0 = Pointer to effect structure
		; D0 = Mixer channel requested (MIX_CH0..MIX_CH3)
		bsr		MixerPlayChannelFX
		bra		.done
		
.auto_channel
		; Play on any free/lower priority/higher age channel
		; A0 = Pointer to effect structure
		bsr		MixerPlayFX
		bra		.done

.stop		
		; Select channel to stop
		moveq	#0,d0						; MIXER_SINGLE does not need HW
											; channel set.
		move.w	chan_position,d1
		beq.s	.stop_all
		asr.w	#2,d1
		addq.w	#3,d1						; Correct bit
		bset	d1,d0						; D0 = MIX_CHx
		
.stop_ch
		; Stop the selected channel
		bsr		MixerStopFX
		bra		.done
		
.stop_all
		move.w	#MIX_CH0+MIX_CH1+MIX_CH2+MIX_CH3,d0
		bsr		MixerStopFX

.done
		movem.l	(sp)+,d0-d7/a0-a6			; Stack
		rts
		
;------------------------------------
; Plugin routines
;------------------------------------
		; Routine: PluginExampleInit
		; This routine sets up the plugin data for use by the example plugin.
		;
		; Notes:
		; All plugin initialisation routines are called with the following
		; parameters:
		;   A0 - Pointer to the MXEffect structure used when calling 
		;        MixerPlayFX or MixerPlayChannelFX
		;   A1 - Pointer to plugin initialisation data structure, as passed by
		;        MixerPlayFX or MixerPlayChannelFX
		;   A2 - Pointer to plugin data structure, as passed by MixerPlayFX or
		;        MixerPlayChannelFX
		;
		; Plugin initialisation routines do not return any value(s)
		;
		; Plugin initialisation routines must save and restore all registers
		; they alter
		;
		; The purpose of passing the MXEffect structure to the plugin
		; initialisation routine is to allow plugins to alter the length and 
		; loop offset of the sample that is processed by them. This allows for
		; a larger range of effects than forcing the length/loop offset would.
PluginExampleInit
		movem.l	d0-d2/a0/a2,-(sp)			; Stack

		bsr		MixPluginGetMultiplier
		move.w	d0,d2

		; Round length of sample to nearest multiple of plugin_sample_length
		move.l	mfx_length(a0),d0
		move.l	d0,d1
		divu.w	plugin_sample_length,d0
		swap	d0
		
		; Limit remains to either a multiple of 4 or a multiple of 32
		cmp.w	#MXPLG_MULTIPLIER_32,d2
		bne.s	.multiple_4_len
		
		and.l	#$0000ffe0,d0	; Limit to multiple of 32 bytes
		bra.s	.update_length
		
.multiple_4_len
		and.l	#$0000fffc,d0	; Limit to multiple of  4 bytes

.update_length
		; Round length down
		sub.l	d0,d1
		tst.l	d1
		bne.s	.write_length
		
		move.w	plugin_sample_length,d1
		
.write_length
		move.l	d1,mfx_length(a0)			; Update MXEffect struct
		
		; Round loop offset to nearest multiple of plugin_sample_length
		move.l	mfx_loop_offset(a0),d0
		move.l	d0,d1
		divu.w	plugin_sample_length,d0
		swap	d0
		
		; Limit remains to either a multiple of 4 or a multiple of 32
		cmp.w	#MXPLG_MULTIPLIER_32,d2
		bne.s	.multiple_4_off
		
		and.l	#$0000ffe0,d0	; Limit to multiple of 32 bytes
		bra.s	.update_offset
		
.multiple_4_off
		and.l	#$0000fffc,d0	; Limit to multiple of  4 bytes

.update_offset
		; Round offset down
		sub.l	d0,d1
		tst.l	d1
		bne.s	.write_offset
		
		move.w	plugin_sample_length,d1
		
.write_offset
		move.l	d0,mfx_loop_offset(a0)		; Update MXEffect struct

		; Set up plugin data
		lea.l	plugin_sample,a0
		move.l	a0,exp_SineData(a2)
		move.w	plugin_sample_length,exp_SineLength(a2)
		clr.w	exp_CurrentPos(a2)
		
		movem.l	(sp)+,d0-d2/a0/a2			; Stack
		rts
		
		; Routine: PluginExample
		; This routine replaces the selected sample with a sine wave.
		;
		; Notes:
		; All plugins are called with the following parameters:
		;   A0 - Pointer to the output buffer to use
		;   A1 - Pointer to the plugin data structure as passed when calling
		;        MixerPlayFX or MixerPlayChannelFX
		;   D0 - Number of bytes to process
		;   D1 - Loop indicator. Set to 1 if the sample has restarted at the
		;        loop offset (or at its start in case the loop offset is not
		;        set)
		;
		; Plugins do not return any value(s)
		;
		; Plugins must save and restore all registers they alter
		;
		; Plugins have to keep track of the playback position of the source
		; sample (if required). The mixer does not pass this information, as
		; the pointer value it would pass is not accurate in case of using 
		; plugins that alter sample length and/or loop offsets.
		;
		; There are two types of plugins:
		;   *) Standard plugins, which have to fill the output buffer in A0
		;      with D0 bytes of data.
		;	*) No data plugins, which do not supply any data to an output
		;      buffer.
		;
		; The example plugin used the plugin data to get the length of and 
		; pointer to the sine wave sample. This could easily have been done in
		; the routine itself, the purpose is to show the method for passing
		; data to a plugin.
PluginExample
		movem.l	d0-d2/a0/a2,-(sp)		; DBG Stack
		
		; Set up for loop
		asr.w	#2,d0					; Longword count in D0
		subq.w	#1,d0
		move.w	exp_CurrentPos(a1),d1	; Current pos in D1
		move.w	exp_SineLength(a1),d2	; Sample length in D2
		move.l	exp_SineData(a1),a2		; Sine wave pointer in A2
		
		; Loop over the sine wave
.lp		move.l	0(a2,d1.w),(a0)+
		addq.w	#4,d1
		cmp.w	d1,d2
		bgt.s	.lp_done
		moveq	#0,d1
		
.lp_done
		dbra	d0,.lp
		
		move.w	d1,exp_CurrentPos(a1)	; Store current position
		
		movem.l	(sp)+,d0-d2/a0/a2		; Stack
		rts
		
		; Routine: SetupPluginStructs
		; This routine 
SetupPluginStructs
		; Fetch plugin struct
		lea.l	plugin_struct,a3

		; Set up plugin struct
		lea.l	plugin_types,a4
		lea.l	0(a4,d3.w),a4
		move.l	(a4),d4						; D4 = plugin type
		move.w	d4,mpl_plugin_type(a3)
		lea.l	plugin_init_ptrs,a4
		move.l	0(a4,d3.w),a4				; A4 = plugin init pointer
		move.l	a4,mpl_init_ptr(a3)
		lea.l	plugin_ptrs,a4
		move.l	0(a4,d3.w),a4				; A4 = plugin pointer
		move.l	a4,mpl_plugin_ptr(a3)
	
		; Set up plugin init data struct
		move.w	plugin_data_current,d4
		move.w	d4,d5
		mulu	#mxplg_max_idata_size,d5	; Fetch plugin init data struct #
		lea.l	plugin_init_data,a4
		lea.l	0(a4,d5.w),a4				; A4 = plugin init data entry
		move.l	a4,mpl_init_data_ptr(a3)
		
		; Fill plugin data struct
		jmp		.jp_table(pc,d3.w)
		
.jp_table
		nop
		nop
		jmp		.fill_plugin_example_data(pc)
		jmp		.fill_plugin_pitch_data(pc)
		jmp		.fill_plugin_pitch_lq_data(pc)
		jmp		.fill_plugin_volume_data(pc)
		jmp		.fill_plugin_sync_data(pc)
		jmp		.fill_plugin_repeat_data(pc)
		
		
.write_plugin_struct
		; Write plugin struct pointer to effect struct
		move.l	a3,mfx_plugin_ptr(a0)

		; Update current plugin data entry
		addq.w	#1,d4
		cmp.w	#mixer_total_channels,d4
		bne.s	.write_plugin_data_current
		
		; Reset entry
		moveq	#0,d4
		
.write_plugin_data_current
		move.w	d4,plugin_data_current
		rts
		
		; Plugin data setup
.fill_plugin_example_data
		bra		.write_plugin_struct
		
.fill_plugin_pitch_data
		move.w	#MXPLG_PITCH_STANDARD,mpid_pit_mode(a4)
		;move.w	#MXPLG_PITCH_LOWQUALITY,mpid_pit_mode(a4)
		move.w	#MXPLG_PITCH_NO_PRECALC,mpid_pit_precalc(a4)
		move.w	#$100,mpid_pit_ratio_fp8(a4)
		;move.w	#$100,mpid_pit_ratio_fp8(a4)
		bra		.write_plugin_struct
		
.fill_plugin_pitch_lq_data
		;move.w	#MXPLG_PITCH_LOWQUALITY,mpid_pit_mode(a4)
		move.w	#MXPLG_PITCH_LEVELS,mpid_pit_mode(a4)
		move.w	#MXPLG_PITCH_NO_PRECALC,mpid_pit_precalc(a4)
		;move.w	#$180,mpid_pit_ratio_fp8(a4)
		move.w	#15,mpid_pit_ratio_fp8(a4)
		bra		.write_plugin_struct

.fill_plugin_volume_data
		move.w	#MXPLG_VOL_TABLE,mpid_vol_mode(a4)
		move.w	#0,mpid_vol_volume(a4)
		bra		.write_plugin_struct

.fill_plugin_repeat_data
		move.w	#10,mpid_rep_delay(a4)
		bra		.write_plugin_struct
		
.fill_plugin_sync_data
		move.l	a0,-(sp)					; Stack
		lea.l	sync_trigger,a0
		clr.w	(a0)
		move.l	a0,mpid_snc_address(a4)
		move.w	#10,mpid_snc_delay(a4)
		move.w	#MXPLG_SYNC_START_AND_LOOP,mpid_snc_mode(a4)
		move.w	#MXPLG_SYNC_ONE,mpid_snc_type(a4)
		move.l	(sp)+,a0					; Stack
		bra		.write_plugin_struct

		; Routine: HandleSync
		; This routine handles responding to sync plugin trigger events.
HandleSync
		movem.l	d7/a0/a1,-(sp)				; Stack
		
		; Handle set sync trigger
		tst.w	sync_trigger
		beq.s	.no_sync_trigger

		; Reset sync trigger
		clr.w	sync_trigger
		move.w	sync_colour_count,sync_colour_current
		
.no_sync_trigger
		; Check if any work remains for the callback
		tst.w	sync_colour_current
		bmi.s	.no_sync
		
		; Load new colour zero into Copper list & lower counter by one
		move.w	sync_colour_count,d7
		sub.w	sync_colour_current,d7
		
		add.w	d7,d7						; Offset into colours
		lea.l	sync_colours,a0
		lea.l	pal2,a1
		lea.l	22(a1),a1
		move.w	0(a0,d7.w),(a1)				; Write colour
		
		subq.w	#1,sync_colour_current
.no_sync
		movem.l	(sp)+,d7/a0/a1				; Stack
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
			dc.w	$778,$e50,$aab,$fa3,$5db,$fff,$0f8,$bbb
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
saved_vector	dc.l	0
led_status		dc.w	0
main_done		dc.w	0
frame_cnt		dc.w	0
input_result	dc.w	0

cursor_position	dc.w	0
chan_position	dc.w	0
act_position	dc.w	0
pl_position		dc.w	0

current_sample	dc.w	0

		cnop 0,4
effect_struct		blk.b	mfx_SIZEOF
effect_struct_pl	blk.b	mfx_SIZEOF


		; Plugin variables & data
plugin_struct			blk.b	mpl_SIZEOF

		; Set plugin data block to 4x the max plugin data structure size
plugin_init_data		blk.b	mxplg_max_idata_size*mixer_total_channels
plugin_data				blk.b	mxplg_max_data_size*mixer_total_channels
plugin_data_current		dc.w	0

plugin_sample_length	dc.w	48
plugin_sample			dc.b	0,4,8,12,15,19,22,25
						dc.b	27,29,30,31,31,31,30,29
						dc.b	27,25,22,19,15,12,8,4
						dc.b	0,-4,-8,-12,-15,-19,-22,-25
						dc.b	-27,-29,-30,-31,-32,-31,-30,-29
						dc.b	-27,-25,-22,-19,-15,-12,-8,-4
						
plugin_init_ptrs		dc.l	0,PluginExampleInit
						dc.l	MixPluginInitPitch,MixPluginInitPitch
						dc.l	MixPluginInitVolume,MixPluginInitSync
						dc.l	MixPluginInitRepeat
plugin_ptrs				dc.l	0,PluginExample
						dc.l	MixPluginPitch,MixPluginPitch,MixPluginVolume
						dc.l	MixPluginSync,MixPluginRepeat
plugin_types			dc.l	0,MIX_PLUGIN_STD,MIX_PLUGIN_STD,MIX_PLUGIN_STD
						dc.l	MIX_PLUGIN_STD,MIX_PLUGIN_NODATA
						dc.l	MIX_PLUGIN_NODATA

sync_trigger			dc.w	0
sync_colour_count		dc.w	7
sync_colour_current		dc.w	0
sync_colours			dc.w	$400,$822,$caa,$fff,$caa,$822,$400,$ee0

		cnop 0,4
plugin_buffer	blk.b	mixer_plugin_buffer_size

		; Mixer buffer(s)
		section audio,data_c
		cnop 0,4
mixer_buffer	blk.b	mixer_buffer_size


; End of File