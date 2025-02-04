; $VER: MultiMixer.asm 1.0 (17.03.23)
;
; MultiMixer.asm
; Example showing the audio mixer in MIXER_MULTI mode.
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20230317
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
	include MultiMixer.i
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
		lea.l	palpertxt,a3
		bsr		PrintFG
		bra		.print_main
		
.printntsc_main
		lea.l	ntschtxt,a3
		bsr		PrintFG
		lea.l	ntscpertxt,a3
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
		move.w	#0,hw_position		
	
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
		jmp		.act_up(pc)
		jmp		.chan_up(pc)
		dc.l	0
		jmp		.hw_up(pc)

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

.hw_up
		; Change HW channel value up
		move.w	hw_position,d0
		beq		.done
		
		subq.w	#4,d0
		move.w	d0,hw_position
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
		jmp		.act_down(pc)
		jmp		.chan_down(pc)
		dc.l	0
		jmp		.hw_down(pc)

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
		cmp.w	#8,d0
		beq		.done
		
		addq.w	#4,d0
		move.w	d0,act_position
		bra		.done

.hw_down
		; Change HW channel value down
		move.w	hw_position,d0
		cmp.w	#12,d0
		beq		.done
		
		addq.w	#4,d0
		move.w	d0,hw_position

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
		lea.l	hwchantxt_ptrs,a3
		move.w	hw_position,d1
		move.l	0(a3,d1.w),a3
		bsr		PrintSubbuffer
		
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
		jmp		.stop(pc)
		
.play
		lea.l	effect_struct,a0
		move.w	#MIX_FX_ONCE,d1
		tst.w	d0
		beq.s	.write_lp_indicator
		
		move.w	#MIX_FX_LOOP,d1
		
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
		
		; Update current sample
		addq.w	#1,d0
		cmp.w	d1,d0
		blt.s	.write_current_sample
		
		moveq	#0,d0
		
.write_current_sample
		move.w	d0,current_sample		
		
		; Select channel to use
		moveq	#0,d0						; Clear channel
		move.w	hw_position,d1
		asr.w	#2,d1						; Correct bit
		bset	d1,d0						; D0 = AUDx
		move.w	chan_position,d1
		beq.s	.auto_channel
		asr.w	#2,d1
		addq.w	#3,d1						; Correct bit
		bset	d1,d0						; D0 = AUDx|MIX_CHx

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
		moveq	#0,d0						; Clear channel
		move.w	hw_position,d1
		asr.w	#2,d1						; Correct bit
		bset	d1,d0						; D0 = AUDx
		move.w	chan_position,d1
		beq.s	.stop_all
		asr.w	#2,d1
		addq.w	#3,d1						; Correct bit
		bset	d1,d0						; D0 = AUDx|MIX_CHx
		
.stop_ch
		; Stop the selected channel
		bsr		MixerStopFX
		bra		.done
		
.stop_all
		or.w	#MIX_CH0|MIX_CH1|MIX_CH2|MIX_CH3,d0
		bsr		MixerStopFX

.done
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
led_status		dc.w	0
main_done		dc.w	0
frame_cnt		dc.w	0
input_result	dc.w	0

cursor_position	dc.w	0
chan_position	dc.w	0
act_position	dc.w	0
hw_position		dc.w	0

current_sample	dc.w	0

		cnop 0,4
effect_struct	blk.b	mfx_SIZEOF

		section audio,data_c
		cnop 0,4
mixer_buffer	blk.b	mixer_buffer_size

; End of File