; $VER: plugins.asm 1.1 (05.04.24)
;
; plugins.asm
; Audio mixer plugin routines
;
; For plugin API, see plugins.i and the rest of the mixer documentation.
;
; Note: all plugin configuration is done via plugins_config.i.
; 
; Author: Jeroen Knoester
; Version: 1.1
; Revision: 20240205
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include	mixer.i
	include mixer_config.i
	include plugins_config.i
	include	plugins.i

	IFD BUILD_MIXER_DEBUG
		include debug.i
	ENDIF
	
; Start of code
		section code,code
		
;-----------------------------------------------------------------------------
; Plugin macros
;-----------------------------------------------------------------------------
		; Macro: MPlLongDiv
		; This macro performs a 32 bit to 32 bit long division. It's used for
		; some plugin initialisation routines.
		; \1 - Data register containing dividend & quotient output
		; \2 - Data register containing divisor
		; \3 - Data register where remainder will be output	
		; \4 - Data register for use as temporary variable
		; \5 - Data register for use as temporary variable
		; \6 - Set to 1 to push & pull /4 and /5 from the stack
		;
		; Note: parameters \1 to \5 require different registers each.
MPlLongDiv	MACRO
		IF \6=1
			movem.l	\4/\5,-(sp)				; Stack
		ENDIF

		; Set up for loop
		moveq	#0,\4						; Quotient=0
		moveq	#0,\3						; Remainder=0
		moveq	#32-1,\5					; Number of bits in dividend

.\@_lp
		add.l	\3,\3						; Remainder=remainder<<1
		btst	\5,\1						; Is dividend[i] equal to 0?
		beq.s	.\@_bit_is_zero

		or.w	#1,\3						; Remainder[0]=1
		
.\@_bit_is_zero
		cmp.l	\2,\3						; Is divisor<remainder?
		blt.s	.\@_smaller

		; Remainder >= divisor
		sub.l	\2,\3						; Remainder = remainder - dividend
		bset	\5,\4						; Quotient[i]=1

.\@_smaller
		dbra	\5,.\@_lp
		
		move.l	\4,\1						; Output in /1
		
		IF \6=1
			movem.l	(sp)+,\4/\5				; Stack
		ENDIF
			ENDM
			
		; Plugin macro's for dealing with correct length/looping conditions
		
		; Macro: MixPluginLoopSetup
		; This macro fetches the correct sample offset to use in A2 and
		; determines the correct length to use for the main loop.
		;
		; Note: this macro contains the .determine_length label used by the
		;       MixPluginLoopEnd macro.
		;
		; Parameters:
		; \1 - structure prefix (i.e. mpd_pit for pitch change)
		;
		; Input registers:
		; A1 - Pointer to plugin data structure. This structure must contain
		;      the following members:
		;         * <prefix>_sample_ptr
		;         * <prefix>_sample_offset
		;         * <prefix>_output_length
		;         * <prefix>_output_offset
		;
		; Returns:
		; D4 - zero (bytes processed source)
		; D5 - bytes to process
		; A2 - Sample pointer + offset
MixPluginLoopSetup	MACRO
		; Always receive mixer buffer size bytes to process
		; So, loop or play silence as needed when sample ends

.fetch_pointers
		move.l	\1_sample_ptr(a1),a2
		add.l	\1_sample_offset(a1),a2

.determine_length
		; Determine length
		; If bytes to process > remaining length, use remaining sample length
		; Else use bytes to process
		; Register use:
		;    D4 - zero (bytes processed source) 
		;    D5 - remaining output length
		moveq	#0,d4
		move.l	\1_output_length(a1),d5		; Total length
		sub.l	\1_output_offset(a1),d5		; D5 = remaining length
		cmp.l	d0,d5
		blt.s	.setup_loop
		
		move.l	d0,d5						; D5 = total bytes to process
		
.setup_loop
					ENDM
		
		; Macro: MixPluginLoopEnd
		; This macro handles updating the sample/loop offsets and continuing
		; to process in case of a looped sample.
		;
		; Note: this macro branches to .determine_length in case bytes remain
		;       to process. See the MixPluginLoopSetup macro.
		; Note: this macro branches to .silence in case of sample end. See 
		;       the MixPluginSilenceLoop macro.
		;
		; Parameters:
		; \1 - structure prefix (i.e. mpd_pit for pitch change)
		;
		; Input registers:
		; D0 - total bytes to process
		; D1 - loop indicator
		; D4 - bytes processed (source)
		; D5 - bytes processed (output)
		;
		; Registers trashed:
		; D6, D7
		;
		; Returns:
		; D0 - remaining bytes to process
MixPluginLoopEnd	MACRO
.loop_end
		; Update the sample offsets
		moveq	#0,d6
		add.l	d4,a2
		add.l	d4,\1_sample_offset(a1)				; Update source offset
		move.l	\1_output_offset(a1),d7
		add.l	d5,d7								; Total output offset
		cmp.l	\1_output_length(a1),d7
		blt.s	.update_offset
		
		; Reset loop offset
		moveq	#1,d6								; Set the reset flag
		move.l	\1_output_loop_offset(a1),d7		; Fetch output loop offset
		move.l	\1_sample_loop_offset(a1),a2		; Fetch sample loop offset
		move.l	a2,\1_sample_offset(a1)
		add.l	\1_sample_ptr(a1),a2				; Corrected sample pointer
		
.update_offset
		move.l	d7,\1_output_offset(a1)				; Store output offset

		; Check if more work needs to be done
		sub.l	d5,d0								; Update bytes remaining
		beq.s	.done
		
		; More work to do, check for end/loop
		tst.w	d6
		beq		.determine_length
		
		; Sample ended or looped
		tst.w	d1
		beq		.silence							; Sample ended
		bra		.determine_length					; Sample looped

.done
					ENDM
		
		; Macro: MixPluginSilenceLoop
		; This macro adds silence to the remainder of the output buffer in
		; case the sample ends.
		;
		; Note: this macro contains the .silence label used by the
		;       MixPluginLoopEnd macro.
		; Note: this macro should be placed below the RTS of the plugin that
		;       uses it.
		;
		; Input registers:
		; D0 - number of bytes to process
		;
		; Trashes:
		; D0,D6
MixPluginSilenceLoop	MACRO
.silence

		; Write silence to remainder of buffer
		moveq	#0,d6
		asr.w	#2,d0						; Convert to longwords
		subq.w	#1,d0
		bmi.s	.done

.si_lp	move.l	d6,(a0)+
		dbra	d0,.si_lp
		bra		.done
						ENDM
						
		; Macro: MixPluginCopyLoop
		; This macro copies over the source sample to the remainder the output
		; buffer in case the plugin does not alter the (remaining part of the)
		; sample.
		;
		; Note: this macro contains the .copy label
		; Note: this macro should be placed below the RTS of the plugin that
		;       uses it.
		;
		; Input registers:
		; D0 - number of bytes to process
		;
		; Trashes:
		; D6,D7
MixPluginCopyLoop	MACRO
.copy
		; Copy contents of sample to output buffer
		move.l	a2,d6
		move.w	d5,d7
		asr.w	#2,d7						; Convert to longwords
		subq.w	#1,d7
		bmi.s	.loop_end

.cp_lp	move.l	(a2)+,(a0)+
		dbra	d7,.cp_lp
		move.l	d6,a2
		bra		.loop_end
					ENDM

;*****************************************************************************
;*****************************************************************************
; Plugins all code macro
; This macro allows adding a postfix to plugin routines & variables. This is
; used by the PerfomanceTest tool to be able to utilise many different 
; configurations for the plugins.
;
; \1 - postfix to use
;
; Note: by default, the plugins will not use a postfix. Enabling this is done
;       by setting the BUILD_MIXER_POSTFIX build flag. This will disable the
;       automatic use of this macro at the end of mixer.asm
; Note: if a postfix is used, it should be the same as the corresponding postfix
;       used for the mixer
; 
;*****************************************************************************
;*****************************************************************************
PlgAllCode	MACRO	

	
;-----------------------------------------------------------------------------
; Plugin initialisation routines
;-----------------------------------------------------------------------------
		; Routine: MixPluginInitDummy
		; This routine is the dummy plugin initialisation routine, provided for
		; testing of the plugin system and its overhead. Note that the dummy
		; plugin will not fill the output buffer, so using it as a PLUGIN_STD
		; will result in playback of whatever is in the plugin output buffer.
		;
		; Plugin type: PLUGIN_NODATA or PLUGIN_STD
		; Plugin data structure: N/A
MixPluginInitDummy\1
		rts
		
		; Routine: MixPluginInitPitch
		; This routine is the initialisation routine for the pitch plugin.
		; The pitch plugin changes the pitch (and duration) of the sample
		; pointed to in the MXEffect structure. There are two modes for the
		; pitch plugin:
		;    * MXPLG_PITCH_STANDARD   - resamples individual bytes (slowest)
		;    * MXPLG_PITCH_LOWQUALITY - resamples longwords at a time, is
		;                               much faster than the standard mode
		;
		; Usage: prefill the following plugin data structure fields
		;    * mpid_pit_mode       - MXPLG_PITCH_STANDARD or 
		;                            MXPLG_PITCH_LOWQUALITY
		;    * mpid_pit_precalc    - Either MXPLG_PITCH_NO_PRECALC or
		;                            MXPLG_PITCH_PRECALC. 
		;
		;                            TODO: rewrite text, precalc fetches from mpid not mfx
		;
		;                            Note that in either case, 
		;                            mpid_pit_ratio_fp8 must be set.
		;
		;                            mpid_pit_precalc will not impact the CPU
		;                            usage of the plugin itself, only the
		;                            initialisation routine will be impacted.
		;
		;    * mpid_pit_ratio_fp8  - the ratio to change the pitch by, given 
		;                            as a 8.8 fixed point math number. The new 
		;                            sample pitch will be multiplied so a 
		;                            ratio of 0.5 will halve the sample's
		;                            pitch, while a ratio of 2 will double the
		;                            pitch (etc).
		;
		;    * mpid_pit_length     - if mpid_pit_precalc is set to 
		;                            MXPLG_PITCH_PRECALC, mpid_pit_length
		;                            needs to be set to the original length of
		;                            the sample (not the pre-calculated value
		;                            from mfx_length).
		;
		;                            Does not need to be filled if 
		;                            mpid_pit_precalc is set to 
		;                            MXPLG_PITCH_NO_PRECALC.
		;    * mpid_pit_loop_offset- if mpid_pit_precalc is set to 
		;                            MXPLG_PITCH_PRECALC, mpid_pit_loop_offset
		;                            needs to be set to the original loop 
		;                            offset of the sample (not the pre-
		;                            calculated value from mfx_loop_offset)
		;
		;                            Does not need to be filled if 
		;                            mpid_pit_precalc is set to 
		;                            MXPLG_PITCH_NO_PRECALC.
		;                            
		;
		; Note: while the plugin does have an optimised path for a pitch 
		;       ratio of 1x the pitch (i.e. the same pitch as the sample
		;       already has), this path is still considerably slower than
		;       playing such samples without use of the pitch plugin.
		; Note: the pitch plugin has a maximum sample size. The input and 
		;       output length are both limited to 262.144 bytes. This limit is
		;       only valid for the real time calculation of mfx_length and 
		;       mfx_loop_offset. If pre-calculated length/loop offset values
		;       are used, this limit can be higher in some circumstances.
		;
		;       See MixPluginRatioPrecalc for more information.
		;
		; Plugin type: PLUGIN_STD
		; Plugin init data structure: MXPDPitchInitData
		;
		; A0 - Pointer to MXEffect structure as passed by MixerPlayFX() or 
		;      MixerPlayChannelFX()
		; A1 - Pointer to plugin initialisation data structure, as passed by
		;      MixerPlayFX() or MixerPlayChannelFX()
		; A2 - Pointer to plugin data structure, as passed by MixerPlayFX() or
		;      MixerPlayChannelFX()
MixPluginInitPitch\1
	IF MXPLUGIN_PITCH=1
		movem.l	d0-d3,-(sp)						; Stack

		; Write base values
		move.l	mfx_sample_ptr(a0),mpd_pit_sample_ptr(a2)
		move.l	mfx_length(a0),mpd_pit_sample_length(a2)
		move.l	mfx_loop_offset(a0),mpd_pit_sample_loop_offset(a2)
		clr.l	mpd_pit_sample_offset(a2)
		clr.l	mpd_pit_output_offset(a2)
		clr.w	mpd_pit_current_fp8(a2)
		
		; 0) Check for pre-calc
		cmp.w	#MXPLG_PITCH_PRECALC,mpid_pit_precalc(a1)
		beq		.precalc
		
		; 1) Check for MXPLG_PITCH_LEVELS
		moveq	#MXPLG_PITCH_LEVELS,d0
		cmp.w	mpid_pit_mode(a1),d0
		bne		.check_ratio
		
		; Look up MXPLG_PITCH_LEVELS ratio
		move.l	a0,-(sp)					; Stack
		
		; Fetch correct FP8.8 ratio
		lea.l	MixPluginLevels_pitch_table\1(pc),a0
		move.w	mpid_pit_ratio_fp8(a1),d2
		moveq	#0,d0
		move.w	d2,d0
		add.w	d0,d0
		move.w	0(a0,d0.w),d0

		move.l	(sp)+,a0					; Stack
		bra		.pitch_test_1x
		
.check_ratio
		; 2) Check if the ratio is valid
		moveq	#0,d0
		move.w	mpid_pit_ratio_fp8(a1),d0
	
		tst.w	d0
		bne.s	.pitch_test_1x
		
		move.w	#$100,d0					; A pitch of zero is illegal
		
.pitch_test_1x
		cmp.w	#$100,d0
		bne.s	.pitch_valid

		; Write 1x ratio / mode
		move.w	d0,mpd_pit_ratio_fp8(a2)
		move.w	#MXPLG_PITCH_1x,mpd_pit_mode(a2)
		move.l	mfx_length(a0),mpd_pit_output_length(a2)
		move.l	mfx_loop_offset(a0),mpd_pit_output_loop_offset(a2)
		bra		.check_looping

.pitch_valid
		; Copy over mpid values
		move.w	mpid_pit_mode(a1),mpd_pit_mode(a2)
		move.w	d0,mpd_pit_ratio_fp8(a2)

		; 3) Write original length into plugin data
		move.l	mfx_length(a0),mpd_pit_sample_length(a2)
		move.l	mfx_loop_offset(a0),mpd_pit_sample_loop_offset(a2)
		
		; 4) Calculate new length value
		moveq	#2,d1					; Set length shift to 2
		bsr		MixPluginPitchRatioPrecalc\1
		move.l	mfx_length(a0),mpd_pit_output_length(a2)
		move.l	mfx_loop_offset(a0),mpd_pit_output_loop_offset(a2)

		; 5) make sure length/offset are multiples of 4
		move.w	mfx_length+2(a0),d0
		move.w	d0,d1
		and.w	#$0003,d1
		beq.s	.check_loop_offset
		
		and.w	#$fffc,d0
		addq.w	#4,d0
		move.w	d0,mfx_length+2(a0)
		
.check_loop_offset
		move.w	mfx_loop_offset+2(a0),d0
		move.w	d0,d1
		and.w	#$0003,d1
		beq.s	.check_looping
		
		and.w	#$fffc,d0
		addq.w	#4,d0
		move.w	d0,mfx_loop_offset+2(a0)

.check_looping
		; 6) Check if the sample is looping
		cmp.w	#MIX_FX_ONCE,mfx_loop(a0)
		beq.s	.done

		; Looping samples with pitch plugin get length = mixer buffer size
		moveq	#0,d0
		move.l	d0,mfx_loop_offset(a0)
		IFD BUILD_MIXER_POSTFIX
			jsr		MixerGetChannelBufferSize\1
		ELSE
			bsr		MixerGetChannelBufferSize\1
		ENDIF
		IF MIXER_WORDSIZED=1
			move.w	d0,mfx_length(a0)
		ELSE
			move.l	d0,mfx_length(a0)
		ENDIF

.done
		; Check for MXPLG_PITCH_LEVELS
		cmp.w	#MXPLG_PITCH_LEVELS,mpid_pit_mode(a1)
		bne		.return

		; Reset pitch ratio field for MXPLG_PITCH_LEVELS
		move.w	mpid_pit_ratio_fp8(a1),mpd_pit_ratio_fp8(a2)
	
.return
		movem.l	(sp)+,d0-d3					; Stack
		rts

.precalc
		; Store precalculated values
		move.l	mpid_pit_length(a1),d0
		move.l	mpid_pit_loop_offset(a1),d1
		move.l	d0,mpd_pit_output_length(a2)
		move.l	d1,mpd_pit_output_loop_offset(a2)
		
		; Check ratio
		move.w	mpid_pit_mode(a1),d1
		move.w	mpid_pit_ratio_fp8(a1),d0
		bne.s	.check_ratio_precalc
		
		move.w	#$100,d0					; Change zero to 1
		
.check_ratio_precalc
		cmp.w	#$100,d0
		bne.s	.pitch_valid_precalc
		
		; Ratio is 1x, change pitch mode to 1x pitch
		move.w	#MXPLG_PITCH_1x,d1
		
.pitch_valid_precalc
		move.w	d0,mpd_pit_ratio_fp8(a2)
		move.w	d1,mpd_pit_mode(a2)
		
		bra		.check_looping
	ENDIF
		rts
		
		; Routine: MixPluginInitVolume
		; This routine is the initialisation routine for the volume plugin.
		; The volume plugin changes the playback volume of the sample
		; pointed to in the MXEffect structure. There are two modes for the
		; volume plugin:
		;    * MXPLG_VOL_TABLE - uses a lookup table
		;    * MXPLG_VOL_SHIFT - uses shift instructions
		;
		; Usage: prefill the following plugin data structure fields
		;    * mpid_vol_mode   - either MXPLG_VOL_TABLE or MXPLG_VOL_SHIFT
		;    * mpid_vol_volume - a value from 0 to 15 (table) or 0 to 7 
		;                        (shift)
		;
		; Note: while the plugin does have an optimised path for both volume
		;       settings that result in silence or playback at maximum volume,
		;       these paths are still considerably slower than playing such 
		;       samples without use of the volume plugin.
		; Note: both variants of this plugin are quite slow, as they have to
		;       do many byte based operations. Overall, on 68000 based systems
		;       the shift based variant will be faster with small shifts (1 or
		;       2), while the table based variant will be faster in other 
		;       cases. On 68020+ based systems the shift based variant will be
		;       faster than the table based variant.
		;
		; Plugin type: PLUGIN_STD
		; Plugin init data structure: MXPDVolumeInitData
		;
		; A0 - Pointer to MXEffect structure as passed by MixerPlayFX() or 
		;      MixerPlayChannelFX()
		; A1 - Pointer to plugin initialisation data structure, as passed by
		;      MixerPlayFX() or MixerPlayChannelFX()
		; A2 - Pointer to plugin data structure, as passed by MixerPlayFX() or
		;      MixerPlayChannelFX()
MixPluginInitVolume\1
	IF MXPLUGIN_VOLUME=1
		move.l	d0,-(sp)					; Stack
		
		; Copy over mpid values
		move.w	mpid_vol_mode(a1),mpd_vol_mode(a2)
		move.w	mpid_vol_volume(a1),mpd_vol_volume(a2)

		; Write length & sample pointer
		move.l	mfx_length(a0),d0
		move.l	d0,mpd_vol_sample_length(a2)
		move.l	d0,mpd_vol_output_length(a2)
		move.l	mfx_sample_ptr(a0),mpd_vol_sample_ptr(a2)
		move.l	mfx_loop_offset(a0),d0
		move.l	d0,mpd_vol_sample_loop_offset(a2)
		move.l	d0,mpd_vol_output_loop_offset(a2)

		; Write remaining values
.cnt
		moveq	#0,d0
		move.l	d0,mpd_vol_sample_offset(a2)
		move.l	d0,mpd_vol_output_offset(a2)
		move.w	mpd_vol_volume(a2),d0
		subq.w	#1,d0
		asl.w	#8,d0
		move.w	d0,mpd_vol_table_offset(a2)
		
.check_looping
		; Check if the sample is looping
		cmp.w	#MIX_FX_ONCE,mfx_loop(a0)
		beq.s	.done

		; Looping samples with pitch plugin get length = mixer buffer size
		moveq	#0,d0
		move.l	d0,mfx_loop_offset(a0)
		IFD BUILD_MIXER_POSTFIX
			jsr		MixerGetChannelBufferSize\1
		ELSE
			bsr		MixerGetChannelBufferSize\1
		ENDIF
		IF MIXER_WORDSIZED=1
			move.w	d0,mfx_length(a0)
		ELSE
			move.l	d0,mfx_length(a0)
		ENDIF

.done
		move.l	(sp)+,d0					; Stack
	ENDIF
		rts
	
		; Routine: MixPluginInitRepeat
		; This routine is the initialisation routine for the repeat plugin.
		; The repeat plugin repeats the sample pointed to in the MXEffect
		; structure after a given delay. The delay is measured in mixer ticks,
		; each of which occurs roughly once a frame.
		;
		; Usage: prefill the following plugin data structure fields
		;    * mpid_rep_delay - the desired delay in mixer ticks
		;
		; Plugin type: PLUGIN_NODATA
		; Plugin init data structure: MXPDRepeatInitData
		;
		; A0 - Pointer to MXEffect structure as passed by MixerPlayFX() or 
		;      MixerPlayChannelFX()
		; A1 - Pointer to plugin initialisation data structure, as passed by
		;      MixerPlayFX() or MixerPlayChannelFX()
		; A2 - Pointer to plugin data structure, as passed by MixerPlayFX() or
		;      MixerPlayChannelFX()
		; D0 - Hardware channel/mixer channel (f.ex. DMAF_AUD0|MIX_CH1)
MixPluginInitRepeat\1
	IF MXPLUGIN_REPEAT=1
		move.l	d0,-(sp)					; Stack
	
		; Copy over mpid values
		move.w	mpid_rep_delay(a1),mpd_rep_delay(a2)
	
		; Set up plugin data
		and.w	#$0f,d0						; Wipe mixer channel
		move.w	d0,mpd_rep_channel(a2)		; Store HW channel
		IF MIXER_WORDSIZED=1
			moveq	#0,d0
			move.w	mfx_length(a0),d0
		ELSE
			move.l	mfx_length(a0),d0
		ENDIF
		move.l	d0,mpd_rep_length(a2)		
		move.l	mfx_sample_ptr(a0),mpd_rep_sample_ptr(a2)
		move.w	mfx_loop(a0),mpd_rep_loop(a2)
		move.w	mfx_priority(a0),mpd_rep_priority(a2)
		IF MIXER_WORDSIZED=1
			move.w	mfx_loop_offset(a0),d0
		ELSE
			move.l	mfx_loop_offset(a0),d0
		ENDIF
		move.l	d0,mpd_rep_loop_offset(a2)
		clr.w	mpd_rep_triggered(a2)
		
		move.l	(sp)+,d0					; Stack
	ENDIF
		rts
		
		; Routine: MixPluginInitSync
		; This routine is the initialisation routine for the sync plugin.
		; The sync plugin changes a given word location in memory when the
		; chosen sync triggers. The delay is measured in mixer ticks, each of
		; which occurs roughly once a frame.
		;
		; Note: due to the way the mixer works, the sync plugin will always
		;       trigger 1 mixer tick (which is roughly 1 frame) prior to the
		;       sample playback reaching the set sync delay. This is true
		;       irrespective of the chosen sync settings.
		; 
		; Usage: prefill the following plugin data structure fields
		;        mpid_snc_address - set to the (word) location in memory to
		;                           use as output
		;        mpid_snc_mode    - set to the desired mode:
		;           *) MXPLG_SYNC_DELAY          - triggers every 
		;                                          mpid_snc_delay ticks
		;           *) MXPLG_SYNC_DELAY_ONCE     - triggers once, after
		;                                          mpid_snc_delay ticks
		;           *) MXPLG_SYNC_START          - triggers once, at the start
		;                                          of playback
		;           *) MXPLG_SYNC_END            - triggers once, at the end
		;                                          of playback
		;           *) MXPLG_SYNC_LOOP           - triggers every time
		;                                          playback loops
		;           *) MXPLG_SYNC_START_AND_LOOP - triggers at the start of
		;                                          playback and again every
		;                                          time playback loops
		;           *) MXPLG_SYNC_NO_OP          - no operation, never
		;                                          triggers
		;        mpid_snc_type    - set to the desired type:
		;           *) MXPLG_SYNC_ONE       - writes the value one to the
		;                                     target address
		;           *) MXPLG_SYNC_INCREMENT - increments the contents of the
		;                                     word at the target address by
		;                                     one
		;           *) MXPLG_SYNC_DECREMENT - decrements the contents of the
		;                                     word at the target address by 
		;                                     one
		;           *) MXPLG_SYNC_DEFERRED  - instead of changing the word at
		;                                     mpid_snc_address, this mode uses
		;                                     the address in mpid_snc_address
		;                                     as the address of a deferred 
		;                                     function, which will be called
		;                                     whenever the chosen sync mode
		;                                     triggers.
		;        mpid_snc_delay   - set to the desired delay in mixer ticks
		;                           (if applicable)
		;        All other fields are automatically filled by the 
		;        initialisation routine.
		;
		; Note: the delay value given in mpid_snc_delay is only used for sync
		;       modes MXPLG_SYNC_DELAY and MXPLG_SYNC_DELAY_ONCE.
		; Note: deferred functions are functions that are called just prior to
		;       leaving the interrupt handler. Like plugins, they are passed a
		;       pointer to the plugin data structure in A1. And just like 
		;       plugins they have to save and restore all registers they use.
		; Note: MXPLG_SYNC_END has a maximum sample size. The length is
		;       limited to 65535 times the mixer playback buffer size (note:
		;       this refers to the per HW channel playback buffer, not the 
		;       value in mixer_buffer_size). 
		;
		;       Normally, this limitation will not cause issues, as this will
		;       number several megabytes of maximum sample length.
		;
		;       Example: at the default period of 322 and using a PAL system,
		;                the maximum sample length supported by 
		;                MXPLG_SYNC_END is 13,9MB.
		;
		; Plugin type: PLUGIN_NODATA
		; Plugin init data structure: MXPDSyncInitData
		;
		; A0 - Pointer to MXEffect structure as passed by MixerPlayFX() or
		;      MixerPlayChannelFX()
		; A1 - Pointer to plugin initialisation data structure, as passed by
		;      MixerPlayFX() or MixerPlayChannelFX()
		; A2 - Pointer to plugin data structure, as passed by MixerPlayFX() or
		;      MixerPlayChannelFX()
MixPluginInitSync\1
	IF MXPLUGIN_SYNC=1
		; Copy over mpid values
		move.l	mpid_snc_address(a1),mpd_snc_address(a2)
		move.w	mpid_snc_mode(a1),mpd_snc_mode(a2)
		move.w	mpid_snc_type(a1),mpd_snc_type(a2)
		move.w	mpid_snc_delay(a1),mpd_snc_delay(a2)
	
		; Set up plugin data
		
		; Check if MXPLG_SYNC_END is selected
		cmp.w	#MXPLG_SYNC_END,mpd_snc_mode(a2)
		bne.s	.write_data
		
		; Check if the sample is looping (i.e. never ends)
		cmp.w	#MIX_FX_ONCE,mfx_loop(a0)
		beq.s	.setup_sync_end
		
		; This is a looping sample, it will never end
		move.w	#MXPLG_SYNC_NO_OP,mpd_snc_mode(a2)
		bra.s	.write_data
		
.setup_sync_end
		movem.l	d0/d1,-(sp)					; Stack
		
		; Set up correct delay value for MXPLG_SYNC_END
		IFD BUILD_MIXER_POSTFIX
			jsr		MixerGetChannelBufferSize\1
		ELSE
			bsr		MixerGetChannelBufferSize\1
		ENDIF
		move.l	mfx_length(a0),d1
		divu.w	d0,d1
		swap	d1
		tst.w	d1
		beq.s	.no_remainder
		
		; Deal with remainder
		add.l	#$10000,d1
		
.no_remainder
		swap	d1
		move.w	d1,mpd_snc_delay(a1)
		
		movem.l	(sp)+,d0/d1					; Stack
		
.write_data
		subq.w	#1,mpd_snc_delay(a2)
		move.w	mpd_snc_delay(a2),mpd_snc_counter(a2)
		clr.w	mpd_snc_started(a2)
		clr.w	mpd_snc_done(a2)
	ENDIF
		rts

;-----------------------------------------------------------------------------
; Plugin routines
;-----------------------------------------------------------------------------
		; Routine: MixPluginDummy
		; This routine is the dummy plugin routine, provided for testing of the 
		; plugin system and its overhead. Note that the dummy
		; plugin will not fill the output buffer, so using it as a PLUGIN_STD
		; will result in playback of whatever is in the plugin output buffer.
		;
		; Plugin type: PLUGIN_NODATA or PLUGIN_STD
		; Plugin data structure: N/A
MixPluginDummy\1
		rts
		
		; Routine: MixPluginPitch
		; This routine forms the pitch plugin routine. See
		; MixPluginInitPitch for more information.
		;
		; Plugin type: PLUGIN_STD
		; Plugin data structure: MXPDPitchData
		;
		;   A0 - Pointer to the output buffer to use
		;   A1 - Pointer to the plugin data structure
		;   D0 - Number of bytes to process
		;   D1 - Loop indicator. Set to 1 if the sample has to restart when
		;        reaching its end. Restart has to be from the loop offset
		;        point
MixPluginPitch\1
	IF MXPLUGIN_PITCH=1
		move.l	d7,-(sp)
		
		tst.w	d0
		beq.s	.done
		
		; Branch of to correct pitch plugin based on mode
		move.w	mpd_pit_mode(a1),d7
		IF MIXER_68020=1
			IF MXPLUGIN_68020_ONLY=1
				mc68020
				jmp		.jp_table(pc,d7.w*4)
				mc68000
			ELSE
				add.w	d7,d7
				add.w	d7,d7
				jmp		.jp_table(pc,d7.w)
			ENDIF
		ELSE
			add.w	d7,d7
			add.w	d7,d7
			jmp		.jp_table(pc,d7.w)
		ENDIF
		
.jp_table
		jmp		MixPluginPitch1x\1(pc)
		jmp		MixPluginPitchStandard\1(pc)
		jmp		MixPluginPitchLowQuality\1(pc)
		jmp		MixPluginPitchLevels\1(pc)
		
.done	move.l	(sp)+,d7
		rts
	ELSE
		rts
	ENDIF

MixPluginPitch1x\1
	IF MXPLUGIN_PITCH=1
		movem.l	d0/d4-d6/a0/a2,-(sp)			; Stack

		; Set up for start of loop
		MixPluginLoopSetup mpd_pit
		
		; Remaining loop set up
		; A2 = sample pointer + offset
		; D5 = bytes to process
		move.l	d5,d4							; D4 = source bytes processed
		bra		.copy
		
		; Deal with end of loop and potential looping of sample
		MixPluginLoopEnd mpd_pit

		movem.l	(sp)+,d0/d4-d6/a0/a2			; Stack
		move.l	(sp)+,d7

		rts
		
		MixPluginSilenceLoop
		
		MixPluginCopyLoop
	ELSE
		rts
	ENDIF
		
MixPluginPitchStandard\1
	IF MXPLUGIN_PITCH=1
		movem.l	d0/d2-d6/a0/a2-a4,-(sp)		; Stack

		; Pre-loop set up
		move.w	d1,-(sp)					; Stack loop indicator
		move.w	mpd_pit_ratio_fp8(a1),d1
		move.w	mpd_pit_current_fp8(a1),d3
		moveq	#0,d2

		; Split FP 8.8 values into two bytes
		move.w	d1,d2
		asr.w	#8,d2						; High-byte delta
		and.w	#$00ff,d1					; Low-byte delta
		move.w	d1,a3						; Store Low-byte delta in temp register

		; Set up for start of loop
		MixPluginLoopSetup mpd_pit
		
		; Remaining loop set up
		; A2 = Sample pointer + offset
		; D5 = bytes to process
		moveq	#0,d6						; D6 = fractional carry
		move.w	a3,d1						; D1 = FP8.8 low byte
		move.w	d5,d7
		and.w	#$3,d7						; Calculate remainder
		move.w	d7,a4						; A4 = remainder
		move.w	d5,d7
		asr.w	#2,d7
		subq.w	#1,d7
		bmi.s	.lp_remainder
		
		; Process D7 longwords
.lp		
		move.b	0(a2,d4.l),(a0)+
		add.b	d1,d3
		addx.l	d6,d4
		add.l	d2,d4
		move.b	0(a2,d4.l),(a0)+
		add.b	d1,d3
		addx.l	d6,d4
		add.l	d2,d4
		move.b	0(a2,d4.l),(a0)+
		add.b	d1,d3
		addx.l	d6,d4
		add.l	d2,d4
		move.b	0(a2,d4.l),(a0)+
		add.b	d1,d3
		addx.l	d6,d4
		add.l	d2,d4
		dbra	d7,.lp
		
.lp_remainder
		; Deal with remainder here
		move.w	a4,d7
		subq.w	#1,d7
		bmi.s	.lp_done

		; Process D7 bytes
.rem_lp	move.b	0(a2,d4.l),(a0)+
		add.b	d1,d3
		addx.l	d6,d4
		add.l	d2,d4
		dbra	d7,.rem_lp
		
.lp_done
		; Fetch loop indicator to D1
		move.w	(sp),d1		
		MixPluginLoopEnd mpd_pit

		; Write resulting fractional part
		move.w	d3,mpd_pit_current_fp8(a1)

		move.w	(sp)+,d1
		movem.l	(sp)+,d0/d2-d6/a0/a2-a4		; Stack
		move.l	(sp)+,d7
		rts
		
		MixPluginSilenceLoop
	ELSE
		rts
	ENDIF
		
MixPluginPitchLowQuality\1
	IF MXPLUGIN_PITCH=1
		movem.l	d0/d2-d6/a0/a2-a4,-(sp)		; Stack

		; Pre-loop set up
		move.w	d1,-(sp)					; Stack loop indicator
		move.w	mpd_pit_ratio_fp8(a1),d1
		move.w	mpd_pit_current_fp8(a1),d3
		moveq	#0,d2
		
		; Round bytes to process
		and.w	#$fffc,d0

		; Split FP 8.8 values into two bytes
		move.w	d1,d2
		lsr.w	#6,d2						; High-byte delta << 2
		and.w	#$fffc,d2					; Round to nearest 4 bytes
		and.w	#$00ff,d1					; Low-byte delta
		move.w	d1,a3						; Store Low-byte delta in temp register

		; Set up for start of loop
		MixPluginLoopSetup mpd_pit
		
		; Remaining loop set up
		; A2 = Sample pointer + offset
		; D5 = bytes to process
		moveq	#4,d6						; D6 = longword mask
		moveq	#0,d7
		move.w	a3,d1						; D1 = FP8.8 low byte
		move.w	d0,a4						; A4 = total bytes to process
		move.w	d5,d0
		asr.w	#2,d0
		subq.w	#1,d0
		bmi.s	.lp_done
		
		; Process D0 longwords
.lp
		move.l	0(a2,d4.l),(a0)+
		add.b	d1,d3
		scs		d7
		and.b	d6,d7
		add.l	d7,d4
		add.l	d2,d4
		dbra	d0,.lp
		
.lp_done
		move.w	a4,d0						; Restore total length to D0
		move.w	(sp),d1						; Fetch loop indicator to D1
		MixPluginLoopEnd mpd_pit

		; Write resulting fractional part
		move.w	d3,mpd_pit_current_fp8(a1)

		move.w	(sp)+,d1
		movem.l	(sp)+,d0/d2-d6/a0/a2-a4		; Stack
		move.l	(sp)+,d7
		rts
		
		MixPluginSilenceLoop
	ENDIF

MixPluginPitchLevels\1
	IF MXPLUGIN_PITCH=1
	IF MXPLUGIN_NO_PITCH_LEVELS=1
		movem.l	d0/d2-d6/a0/a2-a4,-(sp)			; Stack

		move.w	d1,d3
		move.w	mpd_pit_ratio_fp8(a1),d1
		move.w	d1,a3

		; Set up for start of loop
		MixPluginLoopSetup mpd_pit
		
		; Remaining loop set up
		; A2 = sample pointer + offset
		; D5 = bytes to process
		move.w	d5,d2
		move.w	a3,d1
		move.w	d5,a4
		
		bsr		MixPluginLevels_internal\1

		move.w	a4,d5
		move.w	d3,d1
	
		; Deal with end of loop and potential looping of sample
		MixPluginLoopEnd mpd_pit

		movem.l	(sp)+,d0/d2-d6/a0/a2-a4			; Stack
		move.l	(sp)+,d7

		rts
		
		MixPluginSilenceLoop
	ELSE
		rts
	ELSE
		rts
	ENDIF
	ENDIF

		; Internal pitch shifting subroutines
		; Note: all pitch ratios are rounded to nearest rational
MixPluginLevels_internal\1
	IF MXPLUGIN_PITCH=1
	IF MXPLUGIN_NO_PITCH_LEVELS=1
.m68020_indicator	SET MIXER_68020+MXPLUGIN_68020_ONLY
		moveq	#0,d6
		IF .m68020_indicator=2
			mc68020
			jmp .jt_table(pc,d1.w*4)
			mc68000
		ELSE
			move.w	d1,d7
			add.w	d7,d7
			add.w	d7,d7
			jmp .jt_table(pc,d7.w)
		ENDIF

.jt_table
		bra.w	.pitch_level_0
		bra.w	.pitch_level_1
		bra.w	.pitch_level_2
		bra.w	.pitch_level_3
		bra.w	.pitch_level_4
		bra.w	.pitch_level_5
		bra.w	.pitch_level_6
		bra.w	.pitch_level_7
		bra.w	.pitch_level_8
		bra.w	.pitch_level_9
		bra.w	.pitch_level_10
		bra.w	.pitch_level_11
		bra.w	.pitch_level_12
		bra.w	.pitch_level_13
		bra.w	.pitch_level_14
		bra.w	.pitch_level_15
		bra.w	.pitch_level_16
		bra.w	.pitch_level_17
		bra.w	.pitch_level_18
		bra.w	.pitch_level_19
		bra.w	.pitch_level_20
		bra.w	.pitch_level_21
		bra.w	.pitch_level_22
		bra.w	.pitch_level_23
		bra.w	.pitch_level_24
		bra.w	.pitch_level_25
		bra.w	.pitch_level_26
		bra.w	.pitch_level_27
		bra.w	.pitch_level_28
		bra.w	.pitch_level_29
		bra.w	.pitch_level_30
		bra.w	.pitch_level_31

.pitch_level_0:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_0

.lp_0
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		addq.w	#1,a2
		addq.l	#1,d4
		dbra	d2,.lp_0

.remainder_0
		tst.w	d6
		beq		.lp_done_0

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_0(pc,d5.w)

.jt_table_0
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_0
		rts

.pitch_level_1:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_1

.lp_1
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		addq.w	#2,a2
		addq.l	#2,d4
		dbra	d2,.lp_1

.remainder_1
		tst.w	d6
		beq		.lp_done_1

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_1(pc,d5.w)

.jt_table_1
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_1
		rts

.pitch_level_2:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_2

.lp_2
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		addq.w	#3,a2
		addq.l	#3,d4
		dbra	d2,.lp_2

.remainder_2
		tst.w	d6
		beq		.lp_done_2

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_2(pc,d5.w)

.jt_table_2
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_2
		rts

.pitch_level_3:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_3

.lp_3
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		addq.w	#4,a2
		addq.l	#4,d4
		dbra	d2,.lp_3

.remainder_3
		tst.w	d6
		beq		.lp_done_3

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_3(pc,d5.w)

.jt_table_3
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_3
		rts

.pitch_level_4:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_4

.lp_4
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		addq.w	#5,a2
		addq.l	#5,d4
		dbra	d2,.lp_4

.remainder_4
		tst.w	d6
		beq		.lp_done_4

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_4(pc,d5.w)

.jt_table_4
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_4
		rts

.pitch_level_5:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_5

.lp_5
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		addq.w	#6,a2
		addq.l	#6,d4
		dbra	d2,.lp_5

.remainder_5
		tst.w	d6
		beq		.lp_done_5

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_5(pc,d5.w)

.jt_table_5
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_5
		rts

.pitch_level_6:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_6

.lp_6
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		addq.w	#7,a2
		addq.l	#7,d4
		dbra	d2,.lp_6

.remainder_6
		tst.w	d6
		beq		.lp_done_6

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_6(pc,d5.w)

.jt_table_6
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_6
		rts

.pitch_level_7:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_7

.lp_7
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		addq.w	#8,a2
		addq.l	#8,d4
		dbra	d2,.lp_7

.remainder_7
		tst.w	d6
		beq		.lp_done_7

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_7(pc,d5.w)

.jt_table_7
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_7
		rts

.pitch_level_8:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_8

.lp_8
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		add.w	#9,a2
		add.l	#9,d4
		dbra	d2,.lp_8

.remainder_8
		tst.w	d6
		beq		.lp_done_8

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_8(pc,d5.w)

.jt_table_8
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_8
		rts

.pitch_level_9:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_9

.lp_9
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		add.w	#10,a2
		add.l	#10,d4
		dbra	d2,.lp_9

.remainder_9
		tst.w	d6
		beq		.lp_done_9

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_9(pc,d5.w)

.jt_table_9
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_9
		rts

.pitch_level_10:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_10

.lp_10
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		add.w	#11,a2
		add.l	#11,d4
		dbra	d2,.lp_10

.remainder_10
		tst.w	d6
		beq		.lp_done_10

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_10(pc,d5.w)

.jt_table_10
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_10
		rts

.pitch_level_11:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_11

.lp_11
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		add.w	#12,a2
		add.l	#12,d4
		dbra	d2,.lp_11

.remainder_11
		tst.w	d6
		beq		.lp_done_11

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_11(pc,d5.w)

.jt_table_11
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_11
		rts

.pitch_level_12:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_12

.lp_12
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	12(a2),(a0)+
		add.w	#13,a2
		add.l	#13,d4
		dbra	d2,.lp_12

.remainder_12
		tst.w	d6
		beq		.lp_done_12

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_12(pc,d5.w)

.jt_table_12
		move.b	12(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_12
		rts

.pitch_level_13:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_13

.lp_13
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		add.w	#14,a2
		add.l	#14,d4
		dbra	d2,.lp_13

.remainder_13
		tst.w	d6
		beq		.lp_done_13

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_13(pc,d5.w)

.jt_table_13
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_13
		rts

.pitch_level_14:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_14

.lp_14
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	14(a2),(a0)+
		add.w	#15,a2
		add.l	#15,d4
		dbra	d2,.lp_14

.remainder_14
		tst.w	d6
		beq		.lp_done_14

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_14(pc,d5.w)

.jt_table_14
		move.b	14(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_14
		rts

.pitch_level_15:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_15

.lp_15
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		add.w	#16,a2
		add.l	#16,d4
		dbra	d2,.lp_15

.remainder_15
		tst.w	d6
		beq		.lp_done_15

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_15(pc,d5.w)

.jt_table_15
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_15
		rts

.pitch_level_16:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_16

.lp_16
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		add.w	#17,a2
		add.l	#17,d4
		dbra	d2,.lp_16

.remainder_16
		tst.w	d6
		beq		.lp_done_16

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_16(pc,d5.w)

.jt_table_16
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_16
		rts

.pitch_level_17:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_17

.lp_17
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		add.w	#18,a2
		add.l	#18,d4
		dbra	d2,.lp_17

.remainder_17
		tst.w	d6
		beq		.lp_done_17

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_17(pc,d5.w)

.jt_table_17
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_17
		rts

.pitch_level_18:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_18

.lp_18
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		add.w	#19,a2
		add.l	#19,d4
		dbra	d2,.lp_18

.remainder_18
		tst.w	d6
		beq		.lp_done_18

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_18(pc,d5.w)

.jt_table_18
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_18
		rts

.pitch_level_19:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_19

.lp_19
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		add.w	#20,a2
		add.l	#20,d4
		dbra	d2,.lp_19

.remainder_19
		tst.w	d6
		beq		.lp_done_19

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_19(pc,d5.w)

.jt_table_19
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_19
		rts

.pitch_level_20:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_20

.lp_20
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		add.w	#21,a2
		add.l	#21,d4
		dbra	d2,.lp_20

.remainder_20
		tst.w	d6
		beq		.lp_done_20

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_20(pc,d5.w)

.jt_table_20
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_20
		rts

.pitch_level_21:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_21

.lp_21
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		add.w	#22,a2
		add.l	#22,d4
		dbra	d2,.lp_21

.remainder_21
		tst.w	d6
		beq		.lp_done_21

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_21(pc,d5.w)

.jt_table_21
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_21
		rts

.pitch_level_22:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_22

.lp_22
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		add.w	#23,a2
		add.l	#23,d4
		dbra	d2,.lp_22

.remainder_22
		tst.w	d6
		beq		.lp_done_22

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_22(pc,d5.w)

.jt_table_22
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_22
		rts

.pitch_level_23:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_23

.lp_23
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		add.w	#24,a2
		add.l	#24,d4
		dbra	d2,.lp_23

.remainder_23
		tst.w	d6
		beq		.lp_done_23

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_23(pc,d5.w)

.jt_table_23
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_23
		rts

.pitch_level_24:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_24

.lp_24
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		move.b	24(a2),(a0)+
		add.w	#25,a2
		add.l	#25,d4
		dbra	d2,.lp_24

.remainder_24
		tst.w	d6
		beq		.lp_done_24

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_24(pc,d5.w)

.jt_table_24
		move.b	24(a2),-(a0)
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_24
		rts

.pitch_level_25:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_25

.lp_25
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		move.b	24(a2),(a0)+
		move.b	25(a2),(a0)+
		add.w	#26,a2
		add.l	#26,d4
		dbra	d2,.lp_25

.remainder_25
		tst.w	d6
		beq		.lp_done_25

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_25(pc,d5.w)

.jt_table_25
		move.b	25(a2),-(a0)
		move.b	24(a2),-(a0)
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_25
		rts

.pitch_level_26:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_26

.lp_26
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		move.b	24(a2),(a0)+
		move.b	25(a2),(a0)+
		move.b	26(a2),(a0)+
		add.w	#27,a2
		add.l	#27,d4
		dbra	d2,.lp_26

.remainder_26
		tst.w	d6
		beq		.lp_done_26

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_26(pc,d5.w)

.jt_table_26
		move.b	26(a2),-(a0)
		move.b	25(a2),-(a0)
		move.b	24(a2),-(a0)
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_26
		rts

.pitch_level_27:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_27

.lp_27
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		move.b	24(a2),(a0)+
		move.b	25(a2),(a0)+
		move.b	26(a2),(a0)+
		move.b	27(a2),(a0)+
		add.w	#28,a2
		add.l	#28,d4
		dbra	d2,.lp_27

.remainder_27
		tst.w	d6
		beq		.lp_done_27

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_27(pc,d5.w)

.jt_table_27
		move.b	27(a2),-(a0)
		move.b	26(a2),-(a0)
		move.b	25(a2),-(a0)
		move.b	24(a2),-(a0)
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_27
		rts

.pitch_level_28:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_28

.lp_28
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		move.b	24(a2),(a0)+
		move.b	25(a2),(a0)+
		move.b	26(a2),(a0)+
		move.b	27(a2),(a0)+
		move.b	28(a2),(a0)+
		add.w	#29,a2
		add.l	#29,d4
		dbra	d2,.lp_28

.remainder_28
		tst.w	d6
		beq		.lp_done_28

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_28(pc,d5.w)

.jt_table_28
		move.b	28(a2),-(a0)
		move.b	27(a2),-(a0)
		move.b	26(a2),-(a0)
		move.b	25(a2),-(a0)
		move.b	24(a2),-(a0)
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_28
		rts

.pitch_level_29:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_29

.lp_29
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		move.b	24(a2),(a0)+
		move.b	25(a2),(a0)+
		move.b	26(a2),(a0)+
		move.b	27(a2),(a0)+
		move.b	28(a2),(a0)+
		move.b	29(a2),(a0)+
		add.w	#30,a2
		add.l	#30,d4
		dbra	d2,.lp_29

.remainder_29
		tst.w	d6
		beq		.lp_done_29

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_29(pc,d5.w)

.jt_table_29
		move.b	29(a2),-(a0)
		move.b	28(a2),-(a0)
		move.b	27(a2),-(a0)
		move.b	26(a2),-(a0)
		move.b	25(a2),-(a0)
		move.b	24(a2),-(a0)
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_29
		rts

.pitch_level_30:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_30

.lp_30
		move.b	(a2),(a0)+
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		move.b	24(a2),(a0)+
		move.b	25(a2),(a0)+
		move.b	26(a2),(a0)+
		move.b	27(a2),(a0)+
		move.b	28(a2),(a0)+
		move.b	29(a2),(a0)+
		move.b	30(a2),(a0)+
		add.w	#31,a2
		add.l	#31,d4
		dbra	d2,.lp_30

.remainder_30
		tst.w	d6
		beq		.lp_done_30

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_30(pc,d5.w)

.jt_table_30
		move.b	30(a2),-(a0)
		move.b	29(a2),-(a0)
		move.b	28(a2),-(a0)
		move.b	27(a2),-(a0)
		move.b	26(a2),-(a0)
		move.b	25(a2),-(a0)
		move.b	24(a2),-(a0)
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_30
		rts

.pitch_level_31:
		move.w	d2,d6
		and.w	#$1f,d6
		move.w	d6,d7
		add.w	d6,d6
		add.w	d6,d6
		lsr.w	#5,d2
		subq.w	#1,d2
		bmi		.remainder_31

.lp_31
		move.b	(a2),(a0)+
		move.b	1(a2),(a0)+
		move.b	2(a2),(a0)+
		move.b	3(a2),(a0)+
		move.b	4(a2),(a0)+
		move.b	5(a2),(a0)+
		move.b	6(a2),(a0)+
		move.b	7(a2),(a0)+
		move.b	8(a2),(a0)+
		move.b	9(a2),(a0)+
		move.b	10(a2),(a0)+
		move.b	11(a2),(a0)+
		move.b	12(a2),(a0)+
		move.b	13(a2),(a0)+
		move.b	14(a2),(a0)+
		move.b	15(a2),(a0)+
		move.b	16(a2),(a0)+
		move.b	17(a2),(a0)+
		move.b	18(a2),(a0)+
		move.b	19(a2),(a0)+
		move.b	20(a2),(a0)+
		move.b	21(a2),(a0)+
		move.b	22(a2),(a0)+
		move.b	23(a2),(a0)+
		move.b	24(a2),(a0)+
		move.b	25(a2),(a0)+
		move.b	26(a2),(a0)+
		move.b	27(a2),(a0)+
		move.b	28(a2),(a0)+
		move.b	29(a2),(a0)+
		move.b	30(a2),(a0)+
		move.b	31(a2),(a0)+
		add.w	#32,a2
		add.l	#32,d4
		dbra	d2,.lp_31

.remainder_31
		tst.w	d6
		beq		.lp_done_31

		lea.l	1(a0,d7.w),a0
		move.w	#128,d5
		sub.w	d6,d5
		lsr.w	#2,d6
		jmp		.jt_table_31(pc,d5.w)

.jt_table_31
		move.b	31(a2),-(a0)
		move.b	30(a2),-(a0)
		move.b	29(a2),-(a0)
		move.b	28(a2),-(a0)
		move.b	27(a2),-(a0)
		move.b	26(a2),-(a0)
		move.b	25(a2),-(a0)
		move.b	24(a2),-(a0)
		move.b	23(a2),-(a0)
		move.b	22(a2),-(a0)
		move.b	21(a2),-(a0)
		move.b	20(a2),-(a0)
		move.b	19(a2),-(a0)
		move.b	18(a2),-(a0)
		move.b	17(a2),-(a0)
		move.b	16(a2),-(a0)
		move.b	15(a2),-(a0)
		move.b	14(a2),-(a0)
		move.b	13(a2),-(a0)
		move.b	12(a2),-(a0)
		move.b	11(a2),-(a0)
		move.b	10(a2),-(a0)
		move.b	9(a2),-(a0)
		move.b	8(a2),-(a0)
		move.b	7(a2),-(a0)
		move.b	6(a2),-(a0)
		move.b	5(a2),-(a0)
		move.b	4(a2),-(a0)
		move.b	3(a2),-(a0)
		move.b	2(a2),-(a0)
		move.b	1(a2),-(a0)
		move.b	0(a2),-(a0)
		add.w	d6,a2
		add.l	d6,d4
		lea.l	1(a0,d7.w),a0

.lp_done_31
		rts

		ELSE
			rts
		ENDIF
		ELSE
			RTS
		ENDIF

.end_pitch_routines\1
.pitch_routines_size\1 EQU .end_pitch_routines\1-MixPluginLevels_internal\1
		printv .pitch_routines_size\1
		
		; Routine: MixPluginVolume
		; This routine forms the volume plugin routine. See
		; MixPluginInitVolume for more information.
		;
		; Plugin type: PLUGIN_STD
		; Plugin data structure: MXPDVolumeData
		;
		;   A0 - Pointer to the output buffer to use
		;   A1 - Pointer to the plugin data structure
		;   D0 - Number of bytes to process
		;   D1 - Loop indicator. Set to 1 if the sample has restarted at the
		;        loop offset (or at its start in case the loop offset is not
		;        set)	
MixPluginVolume\1
	IF MXPLUGIN_VOLUME=1
		move.l	d7,-(sp)
		
		tst.w	d0
		beq.s	.done
		
		; Branch of to correct volume plugin based on mode
		move.w	mpd_vol_mode(a1),d7
		IF MIXER_68020=1
			IF MXPLUGIN_68020_ONLY=1
				mc68020
				jmp		.jp_table(pc,d7.w*4)
				mc68000
			ELSE
				add.w	d7,d7
				add.w	d7,d7
				jmp		.jp_table(pc,d7.w)
			ENDIF
		ELSE
			add.w	d7,d7
			add.w	d7,d7
			jmp		.jp_table(pc,d7.w)
		ENDIF
		
.jp_table
		jmp		MixPluginVolumeTable\1(pc)
		jmp		MixPluginVolumeShift\1(pc)
		
.done	move.l	(sp)+,d7
		rts
	ELSE
		rts
	ENDIF

		; Table based volume
MixPluginVolumeTable\1
	IF MXPLUGIN_VOLUME=1
		IF MXPLUGIN_NO_VOLUME_TABLES=0
			movem.l	d0/d4-d6/a0/a2-a4,-(sp)		; Stack
			
			DBGBreakPnt
			
			; Set up for start of loop
			MixPluginLoopSetup mpd_vol
			
			; Check for silence (= volume 0)
			move.w	mpd_vol_volume(a1),d6
			beq		.vol_silence
		
			; Generic setup for non-silent volumes
			move.l	a2,a4
			move.l	d5,d4
			
			; Check for maximum volume
			cmp.w	#15,d6
			beq		.copy
			
			; Fill output buffer based on volume table
			lea.l	vol_level_1\1(pc),a3
			move.w	mpd_vol_table_offset(a1),d6
			lea.l	0(a3,d6.w),a3
			moveq	#0,d6
			move.w	d5,d7
			asr.w	#2,d7
			subq.w	#1,d7
			bmi.s	.lp_done

.lp_vol		
			move.b	(a2)+,d6
			move.b	0(a3,d6.w),(a0)+
			move.b	(a2)+,d6
			move.b	0(a3,d6.w),(a0)+
			move.b	(a2)+,d6
			move.b	0(a3,d6.w),(a0)+
			move.b	(a2)+,d6
			move.b	0(a3,d6.w),(a0)+

			dbra	d7,.lp_vol
			
.lp_done
			move.l	a4,a2
			MixPluginLoopEnd mpd_vol

			movem.l	(sp)+,d0/d4-d6/a0/a2-a4		; Stack
			move.l	(sp)+,d7
		ENDIF
		rts
		
.vol_silence
			moveq	#0,d6
			move.l	a2,a4
			move.l	d5,d4
			move.w	d5,d7
			asr.w	#2,d7
			subq.w	#1,d7
			bmi.s	.lp_done
			
.lp_vol_silence
			move.l	d6,(a0)+
			dbra	d7,.lp_vol_silence
			
			bra		.lp_done
		
		MixPluginSilenceLoop
		
		MixPluginCopyLoop
	ELSE
		rts
	ENDIF
		
		; Shift based volume
MixPluginVolumeShift\1
	IF MXPLUGIN_VOLUME=1
		IF MIXER_68020=1
			movem.l	d0/d2-d6/a0-a3,-(sp)	; Stack
		ELSE
			movem.l	d0/d5-d6/a0-a3,-(sp)	; Stack
		ENDIF
		
		; Check if sample looped
		tst.w	d1
		beq.s	.no_loop
		
		; Sample looped, reset offset to loop offset
		move.l	mpd_vol_sample_loop_offset(a1),mpd_vol_sample_offset(a1)
		
.no_loop		
		; Set up volume loop length
		move.w	d0,d7
		lsr.w	#2,d7
		subq.w	#1,d7
		
		; Check for silence (= volume 8)
		move.w	mpd_vol_volume(a1),d6
		cmp.w	#8,d6
		IF MIXER_68020=1
			bge		.silence
		ELSE
			bge.s	.silence
		ENDIF
		
		; Check for maximum volume
		tst.w	d6
		IF MIXER_68020=1
			beq		.max_volume
		ELSE
			beq.s	.max_volume
		ENDIF
		
		; Fill output buffer based on shifting
		move.l	mpd_vol_sample_ptr(a1),a3
		add.l	mpd_vol_sample_offset(a1),a3
		
		IF MIXER_68020=1
			; Setup masks for use in the loop
			IF MXPLUGIN_68020_ONLY=1
				mc68020
				jmp	.shift_mask_jptable(pc,d6.w*8)
				mc68000
			ELSE
				move.w	d6,d5
				asl.w	#3,d5
				jmp	.shift_mask_jptable(pc,d5)
			ENDIF

.shift_mask_jptable
			nop
			nop
			moveq	#$0,d2
			bra.s	.shift_mask_cnt
			move.l	#$80808080,d2
			bra.s	.shift_mask_cnt
			move.l	#$c0c0c0c0,d2
			bra.s	.shift_mask_cnt
			move.l	#$e0e0e0e0,d2
			bra.s	.shift_mask_cnt
			move.l	#$f0f0f0f0,d2
			bra.s	.shift_mask_cnt
			move.l	#$f8f8f8f8,d2
			bra.s	.shift_mask_cnt
			move.l	#$fcfcfcfc,d2
			bra.s	.shift_mask_cnt
			move.l	#$fefefefe,d2
			bra.s	.shift_mask_cnt
			move.l	#$ffffffff,d2

.shift_mask_cnt
			moveq	#-1,d3
			sub.l	d2,d3					; Reverse mask in D3
		ENDIF
		
.lp_vol	
		IF MIXER_68020=1
			move.l	(a3)+,d4
			btst	#31,d4
			sne		d5
			lsl.l	#8,d5
			btst	#23,d4
			sne		d5
			lsl.l	#8,d5
			btst	#15,d4
			sne		d5
			lsl.l	#8,d5
			btst	#7,d4
			sne		d5
			and.l	d2,d5					; Mask for upper bits in D2
			lsr.l	d6,d4					; D6 = shift value
			and.l	d3,d4					; Mask for lower bits in d3
			or.l	d5,d4					; Correct upper bits set in D0
			move.l	d4,(a0)+
		ELSE
			move.b	(a3)+,d5
			asr.b	d6,d5
			move.b	d5,(a0)+
			move.b	(a3)+,d5
			asr.b	d6,d5
			move.b	d5,(a0)+
			move.b	(a3)+,d5
			asr.b	d6,d5
			move.b	d5,(a0)+
			move.b	(a3)+,d5
			asr.b	d6,d5
			move.b	d5,(a0)+
		ENDIF
		dbra	d7,.lp_vol
		bra.s	.update_sample_offset
		
		; Fill output buffer with silence
.silence
		moveq	#0,d6
		
.lp_si	move.l	d6,(a0)+
		dbra	d7,.lp_si
		bra.s	.update_sample_offset
		
		; Fill output buffer with copy of original
.max_volume
		move.l	mpd_vol_sample_ptr(a1),a2
		add.l	mpd_vol_sample_offset(a1),a2
		
.lp_mv	move.l	(a2)+,(a0)+
		dbra	d7,.lp_mv		
		
.update_sample_offset
		moveq	#0,d6
		move.w	d0,d6
		move.l	mpd_vol_sample_offset(a1),d0
		add.l	d6,d0
		cmp.l	mpd_vol_sample_length(a1),d0
		blt.s	.no_reset
		
		; Reset offset here
		move.l	mpd_vol_sample_loop_offset(a1),d0
		
.no_reset
		move.l	d0,mpd_vol_sample_offset(a1)

		IF MIXER_68020=1
			movem.l	(sp)+,d0/d2-d6/a0-a3	; Stack
		ELSE
			movem.l	(sp)+,d0/d5-d6/a0-a3	; Stack
		ENDIF
		move.l	(sp)+,d7
		rts
	ELSE
		rts
	ENDIF
	
		; Routine: MixPluginRepeat
		; This routine forms the repeat plugin routine. See 
		; MixPluginInitRepeat for more information.
		;
		; Plugin type: PLUGIN_NODATA
		; Plugin data structure: MXPDRepeatData
		;
		;   A1 - Pointer to the plugin data structure
		;	A2 - Pointer to the MXChannel structure for the current channel
		;   D1 - Loop indicator. Set to 1 if the sample has restarted at the
		;        loop offset (or at its start in case the loop offset is not
		;        set)
MixPluginRepeat\1
	IF MXPLUGIN_REPEAT=1
		; Test if the effect triggered already
		tst.w	mpd_rep_triggered(a1)
		bne.s	.done
		
		; Count down the delay
		subq.w	#1,mpd_rep_delay(a1)
		bpl.s	.done

		move.l	a0,-(sp)					; Stack

		; Update triggered flag
		move.w	#1,mpd_rep_triggered(a1)
		
		; Set deferred action routine
		lea.l	MixPluginRepeatDeferred\1(pc),a0
		IFD BUILD_MIXER_POSTFIX
			jsr		MixerSetPluginDeferredPtr\1
		ELSE
			bsr		MixerSetPluginDeferredPtr\1
		ENDIF
		move.l	(sp)+,a0					; Stack
.done
		rts
	ELSE
		rts
	ENDIF
		
		; Routine: MixPluginRepeatDeferred
		; This routine is the deferred routine for MixPluginRepeat. It does
		; the call to MixerPlayFX required to actually repeat the sample when
		; the trigger hits.
		;
		; Note: this is a deferred routine, it should not be called as a
		;       plugin, only via setting it up first using 
		;       MixerSetPluginDeferredPtr in a plugin call.
		;
		; Plugin data structure: MXPDRepeatData
		;
		;   A1 - Pointer to the plugin data structure
MixPluginRepeatDeferred\1
	IF MXPLUGIN_REPEAT=1
		; Delay done, fire the repeat
		movem.l	d0/a0,-(sp)					; Stack

		; Fill FX struct
		lea.l	plugin_fx_struct\1(pc),a0
		move.l	mpd_rep_length(a1),mfx_length(a0)
		move.l	mpd_rep_sample_ptr(a1),mfx_sample_ptr(a0)
		move.w	mpd_rep_loop(a1),mfx_loop(a0)
		move.w	mpd_rep_priority(a1),mfx_priority(a0)
		move.l	mpd_rep_loop_offset(a1),mfx_loop_offset(a0)
		clr.l	mfx_plugin_ptr(a0)
		
		; Play the sample again (if a channel is free)
		move.w	mpd_rep_channel(a1),d0
		IFD BUILD_MIXER_POSTFIX
			jsr		MixerPlayFX\1
		ELSE
			bsr		MixerPlayFX\1
		ENDIF

		movem.l	(sp)+,d0/a0					; Stack
		rts
	ELSE
		rts
	ENDIF
		
		; Routine: MixPluginSync
		; This routine forms the sync plugin routine. See MixPluginInitSync
		; for more information.
		;
		;   A0 - Pointer to the output buffer to use
		;   A1 - Pointer to the plugin data structure
		;   D0 - Number of bytes to process
		;   D1 - Loop indicator. Set to 1 if the sample has restarted at the
		;        loop offset (or at its start in case the loop offset is not
		;        set)
MixPluginSync\1
	IF MXPLUGIN_SYNC=1
		; Test if the sync plugin is done
		tst.w	mpd_snc_done(a1)
		bne		.done

		movem.l	d6/d7/a0,-(sp)				; Stack
		
		; Set flag register to 0
		moveq	#0,d7
		
		; Fetch mode and jump to handler
		move.w	mpd_snc_mode(a1),d6
		IF MIXER_68020=1
			IF MXPLUGIN_68020_ONLY=1
				mc68020
				jmp		.jp_table(pc,d6.w*4)
				mc68000
			ELSE
				add.w	d6,d6
				add.w	d6,d6
				jmp		.jp_table(pc,d6.w)
			ENDIF
		ELSE
			add.w	d6,d6
			add.w	d6,d6
			jmp		.jp_table(pc,d6.w)
		ENDIF
		
.jp_table
		jmp		.sync_delay(pc)
		jmp		.sync_delay_once(pc)
		jmp		.sync_start(pc)
		jmp		.sync_delay_once(pc)
		jmp		.sync_loop(pc)
		jmp		.sync_start_and_loop(pc)

		; Sync mode nop handler
.sync_nop
		bra		.sync_update_done
		
		; Sync mode delay handler
.sync_delay
		subq.w	#1,mpd_snc_counter(a1)
		smi		d7
		bpl.s	.sync_update
		
		; Reset counter
		move.w	mpd_snc_delay(a1),mpd_snc_counter(a1)
		bra.s	.sync_update
		
		; Sync mode delay once handler
.sync_delay_once
		subq.w	#1,mpd_snc_counter(a1)
		smi		d7
		bpl.s	.sync_update
		
		; Plugin is done
		st		mpd_snc_done(a1)
		bra.s	.sync_update
		
		; Sync mode start handler
.sync_start
		tst.w	mpd_snc_started(a1)
		bne.s	.sync_update
		
		; Plugin is done
		st		d7
		move.w	d7,mpd_snc_started(a1)
		move.w	d7,mpd_snc_done(a1)
		bra.s	.sync_update
		
		; Sync mode loop handler
.sync_loop
		tst.w	d1
		sne		d7
		bra.s	.sync_update
		
		; Sync mode start and loop handler
.sync_start_and_loop
		tst.w	mpd_snc_started(a1)
		bne.s	.sync_loop
		
		st		d7
		move.w	d7,mpd_snc_started(a1)

		; Update trigger value if needed
.sync_update
		tst.w	d7
		beq.s	.sync_update_done
		
		; Fetch
		move.l	mpd_snc_address(a1),a0
		
		; Fetch sync type and jump to correct update method
		move.w	mpd_snc_type(a1),d6
		IF MIXER_68020=1
			IF MXPLUGIN_68020_ONLY=1
				mc68020
				jmp		.jp_table2(pc,d6.w*4)
				mc68000
			ELSE
				add.w	d6,d6
				add.w	d6,d6
				jmp		.jp_table2(pc,d6.w)
			ENDIF
		ELSE
			add.w	d6,d6
			add.w	d6,d6
			jmp		.jp_table2(pc,d6.w)
		ENDIF
		
.jp_table2
		jmp		.sync_one(pc)
		jmp		.sync_increment(pc)
		jmp		.sync_decrement(pc)
		jmp		.sync_deferred(pc)

		; Set trigger value to 1
.sync_one
		move.w	#1,(a0)
		movem.l	(sp)+,d6/d7/a0				; Stack
		rts

		; Trigger value incremented by 1
.sync_increment
		addq.w	#1,(a0)
		movem.l	(sp)+,d6/d7/a0				; Stack
		rts

		; Trigger value decremented by 1
.sync_decrement
		subq.w	#1,(a0)
		movem.l	(sp)+,d6/d7/a0				; Stack
		rts
		
.sync_deferred
		; Set deferred action routine
		IFD BUILD_MIXER_POSTFIX
			jsr		MixerSetPluginDeferredPtr\1
		ELSE
			bsr		MixerSetPluginDeferredPtr\1
		ENDIF

.sync_update_done
		movem.l	(sp)+,d6/d7/a0				; Stack

.done
		rts
	ELSE
		rts
	ENDIF

;-----------------------------------------------------------------------------
; Plugin support routines
;-----------------------------------------------------------------------------
		; Routine: MixerPluginGetMultiplier
		; This routine returns the minimum size a sample must be a multiple
		; of.
		;
		; D0 - Minimum multiple size
MixPluginGetMultiplier\1
		IF MIXER_SIZEX32=1
			IF MIXER_SIZEXBUF=1
				moveq	#MXPLG_MULTIPLIER_BUFSIZE,d0
			ELSE
				moveq	#MXPLG_MULTIPLIER_32,d0
			ENDIF
		ELSE
			IF MIXER_SIZEXBUF=1
				moveq	#MXPLG_MULTIPLIER_BUFSIZE,d0
			ELSE
				moveq	#MXPLG_MULTIPLIER_4,d0
			ENDIF
		ENDIF
		rts

		; Routine: MixerPluginGetMaxInitDataSize
		; This routine returns the maximum size of any of the plugin init data
		; structures.
MixerPluginGetMaxInitDataSize\1
		move.l	#mxplg_max_idata_size,d0
		rts
		
		; Routine: MixerPluginGetMaxDataSize
		; This routine returns the maximum size of any of the plugin data
		; structures.
MixerPluginGetMaxDataSize\1
		move.l	#mxplg_max_data_size,d0
		rts

		; Routine: MixPluginPitchRatioPrecalc
		; This routine can be used to pre-calculate length and loop offset
		; values for plugins that need these values divided by a FP8.8 ratio.
		; The routine calculates the values using a pointer to a filled 
		; MXEffect structures in A0, the ratio value in D0 and the shift value
		; in D1.
		;
		; Currently this routine is only used by/for MixPluginPitch.
		;
		; Note: the shift value passed to the routine is used to scale the
		;       input to create a greater range than would normally be
		;       allowed. At a shift of zero, the routine supports input & 
		;       output values of up to 65535. Increasing the shift value will
		;       increase these limits by a factor of 2^shift factor, at a cost
		;       of an ever increasing inaccuracy.
		;
		; A0 - Pointer to filled MXEffect structure
		; D0 - FP8.8 ratio value
		; D1 - Shift value
MixPluginPitchRatioPrecalc\1
		movem.l	d0-d3/d5-d7,-(sp)			; Stack

		; Save shift value in D2 & ratio in D3
		moveq	#0,d3
		move.w	d1,d2
		move.w	d0,d3

		; Fetch length
		IF MIXER_68020=0
			IF MIXER_WORDSIZED=1
				moveq	#0,d0
				move.w	mfx_length(a0),d0
				move.l	mfx_loop_offset(a0),d1
			ELSE
				move.l	mfx_length(a0),d0
				move.l	mfx_loop_offset(a0),d1
			ENDIF
		ELSE
			move.l	mfx_length(a0),d0
			move.l	mfx_loop_offset(a0),d1
		ENDIF

		; 1) Check if the ratio is valid
		tst.w	d3
		bne.s	.test_1x
		
		move.w	#$100,d3					; A ratio of zero is illegal
		
.test_1x
		cmp.w	#$100,d3
		beq		.done						; A ratio of 1 means no division
		
		; 2) apply pre-shift to length and offset
		lsr.l	d2,d0
		lsr.l	d2,d1
		
		; 3) Convert divided length & offset to 16.8 fixed point
		moveq	#16,d5
		lsl.l	d5,d0						; D0 = 16.8 & prepared for divide
		lsl.l	d5,d1						; D1 = 16.8 & prepared for divide
		
		; 4) divide 16.8 fixed point length by mpd_pit_ratio_fp8
		IF MIXER_68020=1
			IF MXPLUGIN_68020_ONLY=1
				mc68020
				divu.l	d3,d0
				mc68000
			ELSE
				MPlLongDiv d0,d3,d7,d5,d6,0
			ENDIF
		ELSE
			MPlLongDiv d0,d3,d7,d5,d6,0
		ENDIF

		; 5) divide 16.8 fixed point loop offset by mpd_pit_ratio_fp8
		tst.l	d1
		beq.s	.convert_to_int				; Skip loop offset of zero
		
		IF MIXER_68020=1
			IF MXPLUGIN_68020_ONLY=1
				mc68020
				divu.l	d3,d1
				mc68000
			ELSE
				MPlLongDiv d1,d3,d7,d5,d6,0
			ENDIF
		ELSE
			MPlLongDiv d1,d3,d7,d5,d6,0
		ENDIF

.convert_to_int
		; 7) convert 16.8 fixed point length & offset back to integers
		moveq	#8,d5
		sub.b	d2,d5
		lsr.l	d5,d0						; D0 = int
		lsr.l	d5,d1						; D1 = int
		
.write_length
		; 8) write results
		move.l	d0,mfx_length(a0)
		move.l	d1,mfx_loop_offset(a0)
		
.done
		movem.l	(sp)+,d0-d3/d5-d7			; Stack
		rts

; Plugin data
	IF MIXER_68020=1
		cnop 0,4
	ENDIF
plugin_fx_struct\1		blk.b	mfx_SIZEOF

; Pitch ratios in fp8.8 format
MixPluginLevels_pitch_table\1
		dc.w	8,16,24,32,40,48,56,64
		dc.w	72,80,88,96,104,112,120,128
		dc.w	136,144,152,160,168,176,184,192
		dc.w	200,208,216,224,232,240,248,256

	IF MXPLUGIN_VOLUME=1
		IF MXPLUGIN_NO_VOLUME_TABLES=0
vol_level_1\1	dc.b 0,0,0,0,0,0,0,0
				dc.b 1,1,1,1,1,1,1,1
				dc.b 1,1,1,1,1,1,1,2
				dc.b 2,2,2,2,2,2,2,2
				dc.b 2,2,2,2,2,2,3,3
				dc.b 3,3,3,3,3,3,3,3
				dc.b 3,3,3,3,3,4,4,4
				dc.b 4,4,4,4,4,4,4,4
				dc.b 4,4,4,4,5,5,5,5
				dc.b 5,5,5,5,5,5,5,5
				dc.b 5,5,5,6,6,6,6,6
				dc.b 6,6,6,6,6,6,6,6
				dc.b 6,6,7,7,7,7,7,7
				dc.b 7,7,7,7,7,7,7,7
				dc.b 7,8,8,8,8,8,8,8
				dc.b 8,8,8,8,8,8,8,8
				dc.b -9,-8,-8,-8,-8,-8,-8,-8
				dc.b -8,-8,-8,-8,-8,-8,-8,-8
				dc.b -7,-7,-7,-7,-7,-7,-7,-7
				dc.b -7,-7,-7,-7,-7,-7,-7,-6
				dc.b -6,-6,-6,-6,-6,-6,-6,-6
				dc.b -6,-6,-6,-6,-6,-6,-5,-5
				dc.b -5,-5,-5,-5,-5,-5,-5,-5
				dc.b -5,-5,-5,-5,-5,-4,-4,-4
				dc.b -4,-4,-4,-4,-4,-4,-4,-4
				dc.b -4,-4,-4,-4,-3,-3,-3,-3
				dc.b -3,-3,-3,-3,-3,-3,-3,-3
				dc.b -3,-3,-3,-2,-2,-2,-2,-2
				dc.b -2,-2,-2,-2,-2,-2,-2,-2
				dc.b -2,-2,-1,-1,-1,-1,-1,-1
				dc.b -1,-1,-1,-1,-1,-1,-1,-1
				dc.b -1,0,0,0,0,0,0,0

vol_level_2\1	dc.b 0,0,0,0,1,1,1,1
				dc.b 1,1,1,1,2,2,2,2
				dc.b 2,2,2,3,3,3,3,3
				dc.b 3,3,3,4,4,4,4,4
				dc.b 4,4,5,5,5,5,5,5
				dc.b 5,5,6,6,6,6,6,6
				dc.b 6,7,7,7,7,7,7,7
				dc.b 7,8,8,8,8,8,8,8
				dc.b 9,9,9,9,9,9,9,9
				dc.b 10,10,10,10,10,10,10,11
				dc.b 11,11,11,11,11,11,11,12
				dc.b 12,12,12,12,12,12,13,13
				dc.b 13,13,13,13,13,13,14,14
				dc.b 14,14,14,14,14,15,15,15
				dc.b 15,15,15,15,15,16,16,16
				dc.b 16,16,16,16,17,17,17,17
				dc.b -17,-17,-17,-17,-17,-16,-16,-16
				dc.b -16,-16,-16,-16,-15,-15,-15,-15
				dc.b -15,-15,-15,-15,-14,-14,-14,-14
				dc.b -14,-14,-14,-13,-13,-13,-13,-13
				dc.b -13,-13,-13,-12,-12,-12,-12,-12
				dc.b -12,-12,-11,-11,-11,-11,-11,-11
				dc.b -11,-11,-10,-10,-10,-10,-10,-10
				dc.b -10,-9,-9,-9,-9,-9,-9,-9
				dc.b -9,-8,-8,-8,-8,-8,-8,-8
				dc.b -7,-7,-7,-7,-7,-7,-7,-7
				dc.b -6,-6,-6,-6,-6,-6,-6,-5
				dc.b -5,-5,-5,-5,-5,-5,-5,-4
				dc.b -4,-4,-4,-4,-4,-4,-3,-3
				dc.b -3,-3,-3,-3,-3,-3,-2,-2
				dc.b -2,-2,-2,-2,-2,-1,-1,-1
				dc.b -1,-1,-1,-1,-1,0,0,0

vol_level_3\1	dc.b 0,0,0,1,1,1,1,1
				dc.b 2,2,2,2,2,3,3,3
				dc.b 3,3,4,4,4,4,4,5
				dc.b 5,5,5,5,6,6,6,6
				dc.b 6,7,7,7,7,7,8,8
				dc.b 8,8,8,9,9,9,9,9
				dc.b 10,10,10,10,10,11,11,11
				dc.b 11,11,12,12,12,12,12,13
				dc.b 13,13,13,13,14,14,14,14
				dc.b 14,15,15,15,15,15,16,16
				dc.b 16,16,16,17,17,17,17,17
				dc.b 18,18,18,18,18,19,19,19
				dc.b 19,19,20,20,20,20,20,21
				dc.b 21,21,21,21,22,22,22,22
				dc.b 22,23,23,23,23,23,24,24
				dc.b 24,24,24,25,25,25,25,25
				dc.b -26,-25,-25,-25,-25,-25,-24,-24
				dc.b -24,-24,-24,-23,-23,-23,-23,-23
				dc.b -22,-22,-22,-22,-22,-21,-21,-21
				dc.b -21,-21,-20,-20,-20,-20,-20,-19
				dc.b -19,-19,-19,-19,-18,-18,-18,-18
				dc.b -18,-17,-17,-17,-17,-17,-16,-16
				dc.b -16,-16,-16,-15,-15,-15,-15,-15
				dc.b -14,-14,-14,-14,-14,-13,-13,-13
				dc.b -13,-13,-12,-12,-12,-12,-12,-11
				dc.b -11,-11,-11,-11,-10,-10,-10,-10
				dc.b -10,-9,-9,-9,-9,-9,-8,-8
				dc.b -8,-8,-8,-7,-7,-7,-7,-7
				dc.b -6,-6,-6,-6,-6,-5,-5,-5
				dc.b -5,-5,-4,-4,-4,-4,-4,-3
				dc.b -3,-3,-3,-3,-2,-2,-2,-2
				dc.b -2,-1,-1,-1,-1,-1,0,0

vol_level_4\1	dc.b 0,0,1,1,1,1,2,2
				dc.b 2,2,3,3,3,3,4,4
				dc.b 4,5,5,5,5,6,6,6
				dc.b 6,7,7,7,7,8,8,8
				dc.b 9,9,9,9,10,10,10,10
				dc.b 11,11,11,11,12,12,12,13
				dc.b 13,13,13,14,14,14,14,15
				dc.b 15,15,15,16,16,16,17,17
				dc.b 17,17,18,18,18,18,19,19
				dc.b 19,19,20,20,20,21,21,21
				dc.b 21,22,22,22,22,23,23,23
				dc.b 23,24,24,24,25,25,25,25
				dc.b 26,26,26,26,27,27,27,27
				dc.b 28,28,28,29,29,29,29,30
				dc.b 30,30,30,31,31,31,31,32
				dc.b 32,32,33,33,33,33,34,34
				dc.b -34,-34,-34,-33,-33,-33,-33,-32
				dc.b -32,-32,-31,-31,-31,-31,-30,-30
				dc.b -30,-30,-29,-29,-29,-29,-28,-28
				dc.b -28,-27,-27,-27,-27,-26,-26,-26
				dc.b -26,-25,-25,-25,-25,-24,-24,-24
				dc.b -23,-23,-23,-23,-22,-22,-22,-22
				dc.b -21,-21,-21,-21,-20,-20,-20,-19
				dc.b -19,-19,-19,-18,-18,-18,-18,-17
				dc.b -17,-17,-17,-16,-16,-16,-15,-15
				dc.b -15,-15,-14,-14,-14,-14,-13,-13
				dc.b -13,-13,-12,-12,-12,-11,-11,-11
				dc.b -11,-10,-10,-10,-10,-9,-9,-9
				dc.b -9,-8,-8,-8,-7,-7,-7,-7
				dc.b -6,-6,-6,-6,-5,-5,-5,-5
				dc.b -4,-4,-4,-3,-3,-3,-3,-2
				dc.b -2,-2,-2,-1,-1,-1,-1,0

vol_level_5\1	dc.b 0,0,1,1,1,2,2,2
				dc.b 3,3,3,4,4,4,5,5
				dc.b 5,6,6,6,7,7,7,8
				dc.b 8,8,9,9,9,10,10,10
				dc.b 11,11,11,12,12,12,13,13
				dc.b 13,14,14,14,15,15,15,16
				dc.b 16,16,17,17,17,18,18,18
				dc.b 19,19,19,20,20,20,21,21
				dc.b 21,22,22,22,23,23,23,24
				dc.b 24,24,25,25,25,26,26,26
				dc.b 27,27,27,28,28,28,29,29
				dc.b 29,30,30,30,31,31,31,32
				dc.b 32,32,33,33,33,34,34,34
				dc.b 35,35,35,36,36,36,37,37
				dc.b 37,38,38,38,39,39,39,40
				dc.b 40,40,41,41,41,42,42,42
				dc.b -43,-42,-42,-42,-41,-41,-41,-40
				dc.b -40,-40,-39,-39,-39,-38,-38,-38
				dc.b -37,-37,-37,-36,-36,-36,-35,-35
				dc.b -35,-34,-34,-34,-33,-33,-33,-32
				dc.b -32,-32,-31,-31,-31,-30,-30,-30
				dc.b -29,-29,-29,-28,-28,-28,-27,-27
				dc.b -27,-26,-26,-26,-25,-25,-25,-24
				dc.b -24,-24,-23,-23,-23,-22,-22,-22
				dc.b -21,-21,-21,-20,-20,-20,-19,-19
				dc.b -19,-18,-18,-18,-17,-17,-17,-16
				dc.b -16,-16,-15,-15,-15,-14,-14,-14
				dc.b -13,-13,-13,-12,-12,-12,-11,-11
				dc.b -11,-10,-10,-10,-9,-9,-9,-8
				dc.b -8,-8,-7,-7,-7,-6,-6,-6
				dc.b -5,-5,-5,-4,-4,-4,-3,-3
				dc.b -3,-2,-2,-2,-1,-1,-1,0

vol_level_6\1	dc.b 0,0,1,1,2,2,2,3
				dc.b 3,4,4,4,5,5,6,6
				dc.b 6,7,7,8,8,8,9,9
				dc.b 10,10,10,11,11,12,12,12
				dc.b 13,13,14,14,14,15,15,16
				dc.b 16,16,17,17,18,18,18,19
				dc.b 19,20,20,20,21,21,22,22
				dc.b 22,23,23,24,24,24,25,25
				dc.b 26,26,26,27,27,28,28,28
				dc.b 29,29,30,30,30,31,31,32
				dc.b 32,32,33,33,34,34,34,35
				dc.b 35,36,36,36,37,37,38,38
				dc.b 38,39,39,40,40,40,41,41
				dc.b 42,42,42,43,43,44,44,44
				dc.b 45,45,46,46,46,47,47,48
				dc.b 48,48,49,49,50,50,50,51
				dc.b -51,-51,-50,-50,-50,-49,-49,-48
				dc.b -48,-48,-47,-47,-46,-46,-46,-45
				dc.b -45,-44,-44,-44,-43,-43,-42,-42
				dc.b -42,-41,-41,-40,-40,-40,-39,-39
				dc.b -38,-38,-38,-37,-37,-36,-36,-36
				dc.b -35,-35,-34,-34,-34,-33,-33,-32
				dc.b -32,-32,-31,-31,-30,-30,-30,-29
				dc.b -29,-28,-28,-28,-27,-27,-26,-26
				dc.b -26,-25,-25,-24,-24,-24,-23,-23
				dc.b -22,-22,-22,-21,-21,-20,-20,-20
				dc.b -19,-19,-18,-18,-18,-17,-17,-16
				dc.b -16,-16,-15,-15,-14,-14,-14,-13
				dc.b -13,-12,-12,-12,-11,-11,-10,-10
				dc.b -10,-9,-9,-8,-8,-8,-7,-7
				dc.b -6,-6,-6,-5,-5,-4,-4,-4
				dc.b -3,-3,-2,-2,-2,-1,-1,0

vol_level_7\1	dc.b 0,0,1,1,2,2,3,3
				dc.b 4,4,5,5,6,6,7,7
				dc.b 7,8,8,9,9,10,10,11
				dc.b 11,12,12,13,13,14,14,14
				dc.b 15,15,16,16,17,17,18,18
				dc.b 19,19,20,20,21,21,21,22
				dc.b 22,23,23,24,24,25,25,26
				dc.b 26,27,27,28,28,28,29,29
				dc.b 30,30,31,31,32,32,33,33
				dc.b 34,34,35,35,35,36,36,37
				dc.b 37,38,38,39,39,40,40,41
				dc.b 41,42,42,42,43,43,44,44
				dc.b 45,45,46,46,47,47,48,48
				dc.b 49,49,49,50,50,51,51,52
				dc.b 52,53,53,54,54,55,55,56
				dc.b 56,56,57,57,58,58,59,59
				dc.b -60,-59,-59,-58,-58,-57,-57,-56
				dc.b -56,-56,-55,-55,-54,-54,-53,-53
				dc.b -52,-52,-51,-51,-50,-50,-49,-49
				dc.b -49,-48,-48,-47,-47,-46,-46,-45
				dc.b -45,-44,-44,-43,-43,-42,-42,-42
				dc.b -41,-41,-40,-40,-39,-39,-38,-38
				dc.b -37,-37,-36,-36,-35,-35,-35,-34
				dc.b -34,-33,-33,-32,-32,-31,-31,-30
				dc.b -30,-29,-29,-28,-28,-28,-27,-27
				dc.b -26,-26,-25,-25,-24,-24,-23,-23
				dc.b -22,-22,-21,-21,-21,-20,-20,-19
				dc.b -19,-18,-18,-17,-17,-16,-16,-15
				dc.b -15,-14,-14,-14,-13,-13,-12,-12
				dc.b -11,-11,-10,-10,-9,-9,-8,-8
				dc.b -7,-7,-7,-6,-6,-5,-5,-4
				dc.b -4,-3,-3,-2,-2,-1,-1,0

vol_level_8\1	dc.b 0,1,1,2,2,3,3,4
				dc.b 4,5,5,6,6,7,7,8
				dc.b 9,9,10,10,11,11,12,12
				dc.b 13,13,14,14,15,15,16,17
				dc.b 17,18,18,19,19,20,20,21
				dc.b 21,22,22,23,23,24,25,25
				dc.b 26,26,27,27,28,28,29,29
				dc.b 30,30,31,31,32,33,33,34
				dc.b 34,35,35,36,36,37,37,38
				dc.b 38,39,39,40,41,41,42,42
				dc.b 43,43,44,44,45,45,46,46
				dc.b 47,47,48,49,49,50,50,51
				dc.b 51,52,52,53,53,54,54,55
				dc.b 55,56,57,57,58,58,59,59
				dc.b 60,60,61,61,62,62,63,63
				dc.b 64,65,65,66,66,67,67,68
				dc.b -68,-68,-67,-67,-66,-66,-65,-65
				dc.b -64,-63,-63,-62,-62,-61,-61,-60
				dc.b -60,-59,-59,-58,-58,-57,-57,-56
				dc.b -55,-55,-54,-54,-53,-53,-52,-52
				dc.b -51,-51,-50,-50,-49,-49,-48,-47
				dc.b -47,-46,-46,-45,-45,-44,-44,-43
				dc.b -43,-42,-42,-41,-41,-40,-39,-39
				dc.b -38,-38,-37,-37,-36,-36,-35,-35
				dc.b -34,-34,-33,-33,-32,-31,-31,-30
				dc.b -30,-29,-29,-28,-28,-27,-27,-26
				dc.b -26,-25,-25,-24,-23,-23,-22,-22
				dc.b -21,-21,-20,-20,-19,-19,-18,-18
				dc.b -17,-17,-16,-15,-15,-14,-14,-13
				dc.b -13,-12,-12,-11,-11,-10,-10,-9
				dc.b -9,-8,-7,-7,-6,-6,-5,-5
				dc.b -4,-4,-3,-3,-2,-2,-1,-1

vol_level_9\1	dc.b 0,1,1,2,2,3,4,4
				dc.b 5,5,6,7,7,8,8,9
				dc.b 10,10,11,11,12,13,13,14
				dc.b 14,15,16,16,17,17,18,19
				dc.b 19,20,20,21,22,22,23,23
				dc.b 24,25,25,26,26,27,28,28
				dc.b 29,29,30,31,31,32,32,33
				dc.b 34,34,35,35,36,37,37,38
				dc.b 38,39,40,40,41,41,42,43
				dc.b 43,44,44,45,46,46,47,47
				dc.b 48,49,49,50,50,51,52,52
				dc.b 53,53,54,55,55,56,56,57
				dc.b 58,58,59,59,60,61,61,62
				dc.b 62,63,64,64,65,65,66,67
				dc.b 67,68,68,69,70,70,71,71
				dc.b 72,73,73,74,74,75,76,76
				dc.b -77,-76,-76,-75,-74,-74,-73,-73
				dc.b -72,-71,-71,-70,-70,-69,-68,-68
				dc.b -67,-67,-66,-65,-65,-64,-64,-63
				dc.b -62,-62,-61,-61,-60,-59,-59,-58
				dc.b -58,-57,-56,-56,-55,-55,-54,-53
				dc.b -53,-52,-52,-51,-50,-50,-49,-49
				dc.b -48,-47,-47,-46,-46,-45,-44,-44
				dc.b -43,-43,-42,-41,-41,-40,-40,-39
				dc.b -38,-38,-37,-37,-36,-35,-35,-34
				dc.b -34,-33,-32,-32,-31,-31,-30,-29
				dc.b -29,-28,-28,-27,-26,-26,-25,-25
				dc.b -24,-23,-23,-22,-22,-21,-20,-20
				dc.b -19,-19,-18,-17,-17,-16,-16,-15
				dc.b -14,-14,-13,-13,-12,-11,-11,-10
				dc.b -10,-9,-8,-8,-7,-7,-6,-5
				dc.b -5,-4,-4,-3,-2,-2,-1,-1

vol_level_10\1	dc.b 0,1,1,2,3,3,4,5
				dc.b 5,6,7,7,8,9,9,10
				dc.b 11,11,12,13,13,14,15,15
				dc.b 16,17,17,18,19,19,20,21
				dc.b 21,22,23,23,24,25,25,26
				dc.b 27,27,28,29,29,30,31,31
				dc.b 32,33,33,34,35,35,36,37
				dc.b 37,38,39,39,40,41,41,42
				dc.b 43,43,44,45,45,46,47,47
				dc.b 48,49,49,50,51,51,52,53
				dc.b 53,54,55,55,56,57,57,58
				dc.b 59,59,60,61,61,62,63,63
				dc.b 64,65,65,66,67,67,68,69
				dc.b 69,70,71,71,72,73,73,74
				dc.b 75,75,76,77,77,78,79,79
				dc.b 80,81,81,82,83,83,84,85
				dc.b -85,-85,-84,-83,-83,-82,-81,-81
				dc.b -80,-79,-79,-78,-77,-77,-76,-75
				dc.b -75,-74,-73,-73,-72,-71,-71,-70
				dc.b -69,-69,-68,-67,-67,-66,-65,-65
				dc.b -64,-63,-63,-62,-61,-61,-60,-59
				dc.b -59,-58,-57,-57,-56,-55,-55,-54
				dc.b -53,-53,-52,-51,-51,-50,-49,-49
				dc.b -48,-47,-47,-46,-45,-45,-44,-43
				dc.b -43,-42,-41,-41,-40,-39,-39,-38
				dc.b -37,-37,-36,-35,-35,-34,-33,-33
				dc.b -32,-31,-31,-30,-29,-29,-28,-27
				dc.b -27,-26,-25,-25,-24,-23,-23,-22
				dc.b -21,-21,-20,-19,-19,-18,-17,-17
				dc.b -16,-15,-15,-14,-13,-13,-12,-11
				dc.b -11,-10,-9,-9,-8,-7,-7,-6
				dc.b -5,-5,-4,-3,-3,-2,-1,-1

vol_level_11\1	dc.b 0,1,1,2,3,4,4,5
				dc.b 6,7,7,8,9,10,10,11
				dc.b 12,12,13,14,15,15,16,17
				dc.b 18,18,19,20,21,21,22,23
				dc.b 23,24,25,26,26,27,28,29
				dc.b 29,30,31,32,32,33,34,34
				dc.b 35,36,37,37,38,39,40,40
				dc.b 41,42,43,43,44,45,45,46
				dc.b 47,48,48,49,50,51,51,52
				dc.b 53,54,54,55,56,56,57,58
				dc.b 59,59,60,61,62,62,63,64
				dc.b 65,65,66,67,67,68,69,70
				dc.b 70,71,72,73,73,74,75,76
				dc.b 76,77,78,78,79,80,81,81
				dc.b 82,83,84,84,85,86,87,87
				dc.b 88,89,89,90,91,92,92,93
				dc.b -94,-93,-92,-92,-91,-90,-89,-89
				dc.b -88,-87,-87,-86,-85,-84,-84,-83
				dc.b -82,-81,-81,-80,-79,-78,-78,-77
				dc.b -76,-76,-75,-74,-73,-73,-72,-71
				dc.b -70,-70,-69,-68,-67,-67,-66,-65
				dc.b -65,-64,-63,-62,-62,-61,-60,-59
				dc.b -59,-58,-57,-56,-56,-55,-54,-54
				dc.b -53,-52,-51,-51,-50,-49,-48,-48
				dc.b -47,-46,-45,-45,-44,-43,-43,-42
				dc.b -41,-40,-40,-39,-38,-37,-37,-36
				dc.b -35,-34,-34,-33,-32,-32,-31,-30
				dc.b -29,-29,-28,-27,-26,-26,-25,-24
				dc.b -23,-23,-22,-21,-21,-20,-19,-18
				dc.b -18,-17,-16,-15,-15,-14,-13,-12
				dc.b -12,-11,-10,-10,-9,-8,-7,-7
				dc.b -6,-5,-4,-4,-3,-2,-1,-1

vol_level_12\1	dc.b 0,1,2,2,3,4,5,6
				dc.b 6,7,8,9,10,10,11,12
				dc.b 13,14,14,15,16,17,18,18
				dc.b 19,20,21,22,22,23,24,25
				dc.b 26,26,27,28,29,30,30,31
				dc.b 32,33,34,34,35,36,37,38
				dc.b 38,39,40,41,42,42,43,44
				dc.b 45,46,46,47,48,49,50,50
				dc.b 51,52,53,54,54,55,56,57
				dc.b 58,58,59,60,61,62,62,63
				dc.b 64,65,66,66,67,68,69,70
				dc.b 70,71,72,73,74,74,75,76
				dc.b 77,78,78,79,80,81,82,82
				dc.b 83,84,85,86,86,87,88,89
				dc.b 90,90,91,92,93,94,94,95
				dc.b 96,97,98,98,99,100,101,102
				dc.b -102,-102,-101,-100,-99,-98,-98,-97
				dc.b -96,-95,-94,-94,-93,-92,-91,-90
				dc.b -90,-89,-88,-87,-86,-86,-85,-84
				dc.b -83,-82,-82,-81,-80,-79,-78,-78
				dc.b -77,-76,-75,-74,-74,-73,-72,-71
				dc.b -70,-70,-69,-68,-67,-66,-66,-65
				dc.b -64,-63,-62,-62,-61,-60,-59,-58
				dc.b -58,-57,-56,-55,-54,-54,-53,-52
				dc.b -51,-50,-50,-49,-48,-47,-46,-46
				dc.b -45,-44,-43,-42,-42,-41,-40,-39
				dc.b -38,-38,-37,-36,-35,-34,-34,-33
				dc.b -32,-31,-30,-30,-29,-28,-27,-26
				dc.b -26,-25,-24,-23,-22,-22,-21,-20
				dc.b -19,-18,-18,-17,-16,-15,-14,-14
				dc.b -13,-12,-11,-10,-10,-9,-8,-7
				dc.b -6,-6,-5,-4,-3,-2,-2,-1

vol_level_13\1	dc.b 0,1,2,3,3,4,5,6
				dc.b 7,8,9,10,10,11,12,13
				dc.b 14,15,16,16,17,18,19,20
				dc.b 21,22,23,23,24,25,26,27
				dc.b 28,29,29,30,31,32,33,34
				dc.b 35,36,36,37,38,39,40,41
				dc.b 42,42,43,44,45,46,47,48
				dc.b 49,49,50,51,52,53,54,55
				dc.b 55,56,57,58,59,60,61,62
				dc.b 62,63,64,65,66,67,68,68
				dc.b 69,70,71,72,73,74,75,75
				dc.b 76,77,78,79,80,81,81,82
				dc.b 83,84,85,86,87,88,88,89
				dc.b 90,91,92,93,94,94,95,96
				dc.b 97,98,99,100,101,101,102,103
				dc.b 104,105,106,107,107,108,109,110
				dc.b -111,-110,-109,-108,-107,-107,-106,-105
				dc.b -104,-103,-102,-101,-101,-100,-99,-98
				dc.b -97,-96,-95,-94,-94,-93,-92,-91
				dc.b -90,-89,-88,-88,-87,-86,-85,-84
				dc.b -83,-82,-81,-81,-80,-79,-78,-77
				dc.b -76,-75,-75,-74,-73,-72,-71,-70
				dc.b -69,-68,-68,-67,-66,-65,-64,-63
				dc.b -62,-62,-61,-60,-59,-58,-57,-56
				dc.b -55,-55,-54,-53,-52,-51,-50,-49
				dc.b -49,-48,-47,-46,-45,-44,-43,-42
				dc.b -42,-41,-40,-39,-38,-37,-36,-36
				dc.b -35,-34,-33,-32,-31,-30,-29,-29
				dc.b -28,-27,-26,-25,-24,-23,-23,-22
				dc.b -21,-20,-19,-18,-17,-16,-16,-15
				dc.b -14,-13,-12,-11,-10,-10,-9,-8
				dc.b -7,-6,-5,-4,-3,-3,-2,-1

vol_level_14\1	dc.b 0,1,2,3,4,5,6,7
				dc.b 7,8,9,10,11,12,13,14
				dc.b 15,16,17,18,19,20,21,21
				dc.b 22,23,24,25,26,27,28,29
				dc.b 30,31,32,33,34,35,35,36
				dc.b 37,38,39,40,41,42,43,44
				dc.b 45,46,47,48,49,49,50,51
				dc.b 52,53,54,55,56,57,58,59
				dc.b 60,61,62,63,63,64,65,66
				dc.b 67,68,69,70,71,72,73,74
				dc.b 75,76,77,77,78,79,80,81
				dc.b 82,83,84,85,86,87,88,89
				dc.b 90,91,91,92,93,94,95,96
				dc.b 97,98,99,100,101,102,103,104
				dc.b 105,105,106,107,108,109,110,111
				dc.b 112,113,114,115,116,117,118,119
				dc.b -119,-119,-118,-117,-116,-115,-114,-113
				dc.b -112,-111,-110,-109,-108,-107,-106,-105
				dc.b -105,-104,-103,-102,-101,-100,-99,-98
				dc.b -97,-96,-95,-94,-93,-92,-91,-91
				dc.b -90,-89,-88,-87,-86,-85,-84,-83
				dc.b -82,-81,-80,-79,-78,-77,-77,-76
				dc.b -75,-74,-73,-72,-71,-70,-69,-68
				dc.b -67,-66,-65,-64,-63,-63,-62,-61
				dc.b -60,-59,-58,-57,-56,-55,-54,-53
				dc.b -52,-51,-50,-49,-49,-48,-47,-46
				dc.b -45,-44,-43,-42,-41,-40,-39,-38
				dc.b -37,-36,-35,-35,-34,-33,-32,-31
				dc.b -30,-29,-28,-27,-26,-25,-24,-23
				dc.b -22,-21,-21,-20,-19,-18,-17,-16
				dc.b -15,-14,-13,-12,-11,-10,-9,-8
				dc.b -7,-7,-6,-5,-4,-3,-2,-1
				
		cnop 0,4
		ENDIF
	ENDIF
		
		IF MIXER_C_DEFS=1
; C style routine aliases
_MixPluginInitDummy\1				EQU MixPluginInitDummy\1
_MixPluginInitRepeat\1				EQU MixPluginInitRepeat\1
_MixPluginInitSync\1				EQU MixPluginInitSync\1
_MixPluginInitVolume\1				EQU MixPluginInitVolume\1
_MixPluginInitPitch\1				EQU MixPluginInitPitch\1

_MixPluginDummy\1					EQU MixPluginDummy\1
_MixPluginRepeat\1					EQU MixPluginRepeat\1
_MixPluginSync\1					EQU MixPluginSync\1
_MixPluginVolume\1					EQU MixPluginVolume\1
_MixPluginPitch\1					EQU MixPluginPitch\1
_MixPluginPitchRatioPrecalc\1		EQU	MixPluginPitchRatioPrecalc\1

_MixPluginGetMultiplier\1			EQU MixPluginGetMultiplier\1
_MixerPluginGetMaxInitDataSize\1	EQU MixerPluginGetMaxInitDataSize\1
_MixerPluginGetMaxDataSize\1		EQU MixerPluginGetMaxDataSize\1

	XDEF	_MixPluginInitDummy\1
	XDEF	_MixPluginInitRepeat\1
	XDEF	_MixPluginInitSync\1
	XDEF	_MixPluginInitVolume\1
	XDEF	_MixPluginInitPitch\1

	XDEF	_MixPluginDummy\1
	XDEF	_MixPluginRepeat\1
	XDEF	_MixPluginSync\1
	XDEF	_MixPluginVolume\1
	XDEF	_MixPluginPitch\1

	XDEF	_MixPluginGetMultiplier\1
	XDEF	_MixerPluginGetMaxInitDataSize\1
	XDEF	_MixerPluginGetMaxDataSize\1
	XDEF	_MixPluginPitchRatioPrecalc\1

		ENDIF
	ENDM
	
;*****************************************************************************
;*****************************************************************************
; End of plugins code base macro
;*****************************************************************************
;*****************************************************************************

;-----------------------------------------------------------------------------
; Run Plugins Macro if not in postfix mode
;-----------------------------------------------------------------------------
	IFND BUILD_MIXER_POSTFIX
		PlgAllCode
	ENDIF

; End of File