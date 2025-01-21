; $VER: mixer.i 3.7 (21.01.25)
;
; mixer.i
; Include file for mixer.asm
;
; Note: all mixer configuration is done via mixer_config.i, please do not edit
;       the constants in this file.
;
; Note: the audio mixer expects samples to be pre-processed such that adding
;       sample values together for all mixer channels can never exceed 8 bit
;       signed limits or overflow from positive to negative (or vice versa).
;
; Note: the audio mixer requires samples to be a multiple of a certain number 
;       of bytes for correct playback. The exact number of bytes depends on 
;       the configuration in mixer_config.i.
;
;       The number of bytes is as follows:
;       *) if none of the options below apply, the samples need to be a 
;          multiple of 4 bytes in length
;       *) if MIXER_SIZEX32 is set to 1, the samples need to be a multiple of
;          32 bytes in length
;       *) if MIXER_SIZEXBUF is set to 1, the samples need to be a multiple of
;          the PAL or NTSC buffer size in length (depending on the video
;          system passed to MixerSetup())
;       *) if MIXER_SIZEX32 and MIXER_SIZEXBUF are set to one, the samples
;          need to be a multiple of the PAL/NTSC buffer size and a multiple of
;          32 bytes in length (depending on the video system passed to
;          MixerSetup())
;
;       The file mixer.i contains the equates mixer_PAL_multiple and 
;       mixer_NTSC_multiple which give the exaxt multiple requirements for
;       samples. Note that in most cases these two will be the same value,
;       only if MIXER_SIZEXBUF is set to 1 the number will be different 
;       between these two.
; 
; Mixer API (see mixer documentation for more information)
; ----------------------------------------------------------------------------
;
; Structures
; ----------
; Structure definitions can be found at the bottom of mixer.i.
; The following structures are used by various mixer routines.
;
; MXEffect
;	This structure defines a sound effect. It is used by most routines that
;	play back sound effects, as well as by plugin intialisation routines. For
;	more information about plugins, see the plugins API in plugins.i.
;
;	The MXEffect structure has the following members:
;	* mfx_length		- the length of the sample to play in bytes. Must be
;						  passed as a longword even if MIXER_WORDSIZED is set
;						  to 1.
;	* mfx_sample_ptr	- Pointer to the sample to play. Samples can be placed
;						  in any type of memory. Longword alignment is 
;						  preferred on 68020+ systems for performance reasons.
;	* mfx_loop			- Determines the type of looping to use for the 
;						  sample. Set to MIX_FX_ONCE to play a sample once,
;						  MIX_FX_LOOP to play a sample that loops forever, or
;						  MIX_FX_LOOP_OFFSET to play a sample that repeats 
;						  playback at a given offset in the sample.
;	* mfx_priority		- Determines the priority of the sample to play. 
;						  Samples of higher priority can overwrite already 
;						  playing, non-looping, samples of lower priority if 
;						  no free mixer channel can be found.
;	* mfx_loop_offset	- If loop mode is MIX_FX_LOOP_OFFSET, this determines
;						  the offset in bytes the sample will restart playback
;						  from when the end of the sample is reached. Must be
;						  passed as a longword even if MIXER_WORDSIZED is set
;						  to 1.
;	* mfx_plugin_ptr	- If MIXER_ENABLE_PLUGINS is set to 1, set this to 
;						  either 0 for samples that don't use a plugin, or to
;						  the address of a filled MXPlugin structure if using
;						  a plugin is desired.
;
; MXPlugin
;	This structure defines a plugin for use with a mixer sound effect. For
;	more information about plugins, see the plugins API in plugins.i. Plugins
;	are only available if MIXER_ENABLE_PLUGINS is set to 1 in mixer_config.i
;
;	The MXPlugin structure has the following members:
;	* mpl_plugin_type	- Determines the type of plugin. Either MIX_PLUGIN_STD
;						  for standard plugins, or MIX_PLUGIN_NODATA for
;						  plugins that do not alter sample buffer data.
;	* mpl_init_ptr		- Pointer to the plugin initialisation routine to use. 
;						  For more information on plugin initialisation 
;						  routines, see the plugins API in plugins.i.
;	* mpl_plugin_ptr	- Pointer to the plugin routine to use. For more 
;						  information about plugin routines, see the plugins 
;						  API in plugins.i.
;	* mpl_init_data_ptr	- Pointer to the plugin initialisation data to use.
;						  For more information about plugin initialisation
;						  data, see  the plugins API in plugins.i.
;
; Routines
; --------
;
; MixerSetup(A0=buffer,A1=plugin_buffer,A2=plugin_data,D0=video_system.w,
;            D1=plugin_data_length.w)
;	Prepares the mixer structure for use by the mixing routines and sets mixer
;   playback volume to the maximum hardware volume of 64. Must be called prior
;   to any other mixing routines. A0 must point to a block of memory in Chip 
;   RAM at least mixer_buffer_size bytes in size. D0 must contain either 
;   MIX_PAL if running on a PAL system, or MIX_NTSC when running on a NTSC 
;   system.
;
;   If the video system is unknown, set D0 to MIX_PAL.
;
;	If MIXER_ENABLE_PLUGINS is set to one, A1, A2 and D1 also need to be set.
;	If not, they can be omitted.
;
;	A1 must point to a block of memory (any RAM type) at least
;	mixer_plugin_buffer_size bytes in size. D1 must be set to the maximum size
;	of any of the possible plugin data structures. If no custom plugins are
;	used, this size is the value mxplg_max_data_size, found in plugins.i. This
;	value can also be gotten by calling MixerPluginGetMaxDataSize(), found in
;	plugins.i. 
;
;	If custom plugins are used, this value must be either the largest data 
;	size of the custom plugins, or the mxplg_max_data_size, whichever is 
;	larger.
;
;	A2 must point to a block of memory sized D1 multiplied by
;	mixer_total_channels from mixer.i. The value for mixer_total_channels can
;	also be gotten by calling MixerGetTotalChannelCount().
;
;   Note: on 68020+ systems, it is advisable to align the various buffers to a
;         4 byte boundary for optimal performance.
; 
; MixerInstallHandler(A0=VBR,D0=save_vector.w)
;	Sets up the mixer interrupt handler. MixerSetup must be called prior to
;	calling this routine. Pass the VBR or zero in A0. D0 controls whether or 
;   not the old interrupt vector will be saved. Set it to 0 to save the vector
;   for future restoring and to 1 to skip saving the vector.
;
; MixerRemoveHandler()
;   Removes the mixer interrupt handler. MixerStop should be called prior to
;	calling this routine to make sure audio DMA is stopped.
;
; MixerStart()
;	Starts mixer playback (initially playing back silence). MixerSetup and 
;	MixerInstallHandler must have been called prior to calling this routine.
;
;   Note: if MIXER_CIA_TIMER is set to 1, this routine also starts the CIA 
;         timer to measure performance metrics.
;
; MixerStop()
;	Stops mixer playback. MixerSetup and MixerInstallHandler must have been 
;   called prior to calling this routine.
;
;   Note: if MIXER_CIA_TIMER is set to 1, this routine also stops the CIA
;         timer used to measure performance metrics. The results are found in
;         mixer_ticks_last, mixer_ticks_best and mixer_ticks_worst (these 
;         variables are not available if MIXER_CIA_TIMER is set to 0).
;
; MixerVolume(D0=volume.w)
;   Set the desired hardware output volume used by the mixer (valid values are
;   0 to 64).
;
; D0=MixerPlayFX(A0=effect_structure,D0=hardware_channel)
;   Adds the sample defined in the MXEffect structure pointed to by A0 on the 
;   the hardware channel given in D0. If MIXER_SINGLE is set to 1, the 
;   hardware channel does not need to be given in D0. Determines the best
;   mixer channel to play back on based on priority and age. If no applicable
;   channel is free (for instance due to higher priority samples playing), the
;   routine will not play the sample.
;
;   D0 returns the hardware & mixer channel the sample will play on, or -1 if
;   no free channel could be found.
;
;   Note: the MXEffect structure definition can be found at the bottom of 
;         mixer.i, values are as described in the Structures section of the 
;	      API.
;
; D0=MixerPlayChannelFX(A0=effect_structure,D0=mixer_channel)
;   Adds the sample defined in the MXEffect structure pointed to by A0 on the 
;   the hardware and mixer channel given in D0. If MIXER_SINGLE is set to 1, 
;   the hardware channel does not need to be given in D0, but the mixer 
;   channel must still be set. Determines whether to play back the sample 
;   based on priority and age. If the channel isn't free (for instance due to
;   a higher priority sample playing), the routine will not play the sample.
;
;   D0 returns the hardware & mixer channel the sample will play on, or -1 if
;   no free channel could be found.
;
;   Note: the MXEffect structure definition can be found at the bottom of 
;         mixer.i, values are as described in the Structures section of the 
;	      API.
;   Note: a mixer channel refers to the internal virtual channels the mixer 
;         uses to mix samples together. By exposing these virtual channels, 
;         more fine grained control over playback becomes possible.
;
;         Mixer channels range from MIX_CH0 to MIX_CH3, depending on the 
;         maximum number of software channels available as defined in 
;         mixer_config.i.
;
; MixerStopFX(D0=mixer_channel_mask)
;   Stops playback on the given hardware/mixer channel combination in D0. If
;   MIXER_SINGLE is set to 1, the hardware channel does not need to be given
;   in D0, but the mixer channel must still be set. If MIXER_MULTI or 
;   MIXER_MULTI_PAIRED are set to 1, multiple hardware channels can be 
;   selected at the same time. In this case the playback is stopped on the 
;   given mixer channels across all selected hardware channels.
;
;   Note: see MixerPlayChannelFX for an explanation of mixer channels.
;
; D0=MixerPlaySample(A0=sample,D0=hardware_channel,D1=length,
;                    D2=signed_priority.w,D3=loop_indicator.w,
;                    D4=loop_offset)
;   Adds the sample pointed to by A0 on the hardware channel given in D0. If 
;   MIXER_SINGLE is set to 1, the hardware channel does not need to be given 
;   in D0. Determines the best mixer channel to play back on based on priority
;   and age. If no applicable channel is free (for instance due to higher 
;   priority samples playing), the routine will not play the sample.
;
;   Other values that need to be set are D1, which sets the length of the 
;   sample (signed long, unless MIXER_WORDSIZED is set to 1, in which case the
;   length is an unsigned word). D2 gives the desired priority of the sample.
;   Samples of higher priority can overwrite already playing samples of lower
;   priority if no free mixer channel can be found. D3 has to contain either 
;   MIX_FX_ONCE for samples that need to play once, or one of MIX_FX_LOOP or 
;	MIX_FX_LOOP_OFFSET for samples that should loop forever. MIX_FX_LOOP loops
;	back to the start of the sample, MIX_FX_LOOP_OFFSET restarts at the given
;	loop offset in D4 (signed long, unless MIXER_WORDSIZED is set to 1, in 
;	which case the length is an unsigned word). Looping samples can only be
;	stopped by either calling MixerStop or MixerStopFX.
;
;   D0 returns the hardware & mixer channel the sample will play on, or -1 if
;   no free channel could be found.
;
;	Note: loop_offset (D4) is an optional parameter that only needs to contain
;	      a value in case MIX_FX_LOOP_OFFSET is set.
;
; D0=MixerPlayChannelSample(A0=sample,D0=mixer_channel,D1=length,
;                           D2=signed_priority.w,D3=loop_indicator.w, 
;                           D4=loop_offset)
;   Adds the sample pointed to by A0 on the hardware/mixer channel given in 
;   D0. If MIXER_SINGLE is set to 1, the hardware channel does not need to be 
;   given in D0. Determines whether to play back the sample based on priority
;   and age. If the channel isn't free (for instance due to a higher priority
;   sample playing), the routine will not play the sample.
;
;   Other values that need to be set are D1, which sets the length of the 
;   sample (signed long, unless MIXER_WORDSIZED is set to 1, in which case the
;   length is an unsigned word). D2 gives the desired priority of the sample.
;   Samples of higher priority can overwrite already playing samples of lower
;   priority if no free mixer channel can be found. D3 has to contain either 
;   MIX_FX_ONCE for samples that need to play once, or one of MIX_FX_LOOP or 
;	MIX_FX_LOOP_OFFSET for samples that should loop forever. MIX_FX_LOOP loops
;	back to the start of the sample, MIX_FX_LOOP_OFFSET restarts at the given
;	loop offset in D4 (signed long, unless MIXER_WORDSIZED is set to 1, in 
;	which case the length is an unsigned word). Looping samples can only be 
;	stopped by either calling MixerStop or MixerStopFX.
;
;   D0 returns the hardware & mixer channel the sample will play on, or -1 if
;   no free channel could be found.
;
;	Note: loop_offset (D4) is an optional parameter that only needs to contain
;	      a value in case MIX_FX_LOOP_OFFSET is set.
;   Note: see MixerPlayChannelFX for an explanation of mixer channels.
;
; D0=MixerGetBufferSize()
;	Returns the size of the Chip RAM buffer size that needs to be allocated
;	and passed to MixerSetup(). Note that this routine merely returns the
;	value of mixer_buffer_size, which is defined in mixer.i. The function of
;	this routine is to offer a method for C programs to gain access to this
;	value without needing access to mixer.i.
;
; D0=MixerGetChannelBufferSize()
;   Returns the value of the internal mixer buffer size. Its primary purpose
;   is to give plugins a way to get this value without needing access to the
;   mixer structure.
;
; D0=MixerGetSampleMinSize()
;	Returns the minimum sample size. This is the minimum sample size the mixer
;   can play back correctly. Samples must always be a multiple of this value 
;   in length.
;
;	Normally this value is 4, but optimisation options in mixer_config.i can
;	can increase this.
;
;	Note: this routine is usually not needed as the minimum sample size is 
;	      implied by the mixer_config.i setup. Its primary function is to give
;	      the correct value in case MIXER_SIZEXBUF has been set to 1 in 
;	      mixer_config.i, in which case the minimum sample size will depend on
;	      the video system selected when calling MixerSetup (PAL or NTSC).
; 	Note: MixerSetup() must have been called prior to calling this routine.
;
; D0=MixerGetChannelStatus(D0=mixer_channel)
;	Returns whether or not the hardware/mixer channel given in D0 is in use.
;	If MIXER_SINGLE is set to 1, the hardware channel does not need to be 
;	given in D0.
;
;	If the channel is not used, the routine will return MIX_CH_FREE. If the
;	channel is in use, the routine will return MIX_CH_BUSY.
;
; D0=MixerGetTotalChannelCount()
;	Returns the total number of channels the mixer supports for sample
;	playback.
;
;
; If MIXER_ENABLE_RETURN_VECTOR is set to 1, an addition routine is available:
;
; MixerSetReturnVector(A0=return_function_ptr)
;   This routine sets the optional vector the mixer can call at to at
;   the end of interrupt execution.
;
;   Note: this vector should point to a standard routine ending in RTS.
;	Note: this routine should be called after MixerSetup() has been run.
;
;
; IF MIXER_EXTERNAL_IRQ_DMA is set to 1, an additional routine is available:
;
; MixerSetIRQDMACallbacks(A0=callback_structure)
;   This routine sets up the vectors used for callback routines to
;   manage setting up interrupt vectors and DMA flags. These callback
;   routines.
;
;   Callback vectors have to be passed through the MXIRQDMACallbacks
;   structure. This structure contains the following members:
;   * mxicb_set_irq_vector 
;     - Function pointer to routine that sets the IRQ vector for audio
;       interrupts. 
;       Parameter: A1 = vector to mixer interrupt handler
;   * mxicb_remove_irq_vector
;     - Function pointer to routine that removes the IRQ vector for
;       audio interrupts.
;   * mxicb_set_irq_bits
;     - Function pointer to routine that sets the correct bits in INTENA
;       to enable audio interrupts for the mixer. 
;       Parameter: D1 = INTENA bits to set
;   * mxicb_clear_irq_bits
;     - Function pointer to routine that clears the audio interrupt bits
;   * mxicb_disable_irq
;     - Function pointer to routine that disables audio interrupts
;   * mxicb_enable_irq
;     - Function pointer to routine that enables audio interrupts.
;   * mxicb_acknowledge_irq
;     - Function pointer to routine that acknowledges audio interrupt.
;       Parameter: D4 = INTREQ value
;   * mxicb_enable_dma
;     - Function pointer to routine that enables audio DMA.
;       Parameter: D0 = DMACON value
;   * mxicb_disable_dma
;     - Function pointer to routine that disables audio DMA.
;       Paramater: D6 = DMACON value
;
;   Note: MixerSetup should be run before this routine
;   Note: all callback routines should save & restore all registers they
;         use
;
;
; If MIXER_ENABLE_CALLBACK is set to 1, additional routines are available:
;
; MixerEnableCallback(A0=callback_function_ptr)
;	This function enables the callback function and sets it to the given 
;	function pointer in A0. 
;
;	Callback functions take two parameters: The HW channel/mixer channel
;	combination in D0 and the pointer to the start of the sample that just
;	finished playing in A0.
;
;	Callback functions are called whenever a sample ends playback. This
;	excludes looping samples and samples stopped by a call to MixerStopFX or
;	MixerStop.
;
; MixerDisableCallback()
;	This function disables the callback function.
;
;
; If MIXER_ENABLE_PLUGINS is set to 1, additional routines are available:
;
; D0=MixerGetPluginsBufferSize()
;	This routine returns the value of mixer_plugin_buffer_size, the 
;	required size of the RAM buffer that needs to be allocated and 
;	passed to MixerSetup() if MIXER_ENABLE_PLUGINS is set to 1.
;
;	Note: this routine is usually not needed as the plugin buffer size is
;	      given in mixer.i. Its primary function is to expose this value to C
;	      programs.
;
; MixerSetPluginDeferredPtr(A0=deferred_function_ptr,A2=mxchannel)
;	This routine is called by a plugin whenever it needs to do a deferred 
;	(=post mixing loop) action. This is useful in case a plugin needs to start
;	playback of a new sample, as this cannot be done during the mixing loop to
;	prevent race conditions.
;
;	Note: this routine should *only* be used by plugin routines and never in
;	      other situations as that will likely crash the mixer interrupt
;	      handler.
;   Note: see plugins.i for more details on deferred functions
;
;
; If MIXER_CIA_TIMER is set to 1, an additional routine is available:
;
; MixerCalcTicks()
;   Calculates the average number of CIA ticks that passed during the last 128
;   calls of the mixer interrupt handler. Results are found in 
;   mixer_ticks_average.
;
; If MIXER_COUNTER is set to 1, two additional routines are available:
;
; MixerResetCounter()
;   This routine sets the mixer interrupt counter to 0.
;
; D0=MixerGetCounter()
;   This routine gets the current value of the mixer interrupt counter. The
;   counter is word sized.
;
;
; Author: Jeroen Knoester
; Version: 3.7
; Revision: 20250125
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include	exec/types.i
	include hardware/dmabits.i
	include mixer_config.i
	
	IFND	MIXER_I
MIXER_I	SET	1

; References macro
EXREF	MACRO
		IFD BUILD_MIXER
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM

; References
	EXREF	MixerSetup
	EXREF	MixerInstallHandler
	EXREF	MixerRemoveHandler
	EXREF	MixerStart
	EXREF	MixerStop
	EXREF	MixerVolume

	EXREF	MixerPlayFX
	EXREF	MixerPlayChannelFX
	EXREF	MixerStopFX
	
	EXREF	MixerPlaySample
	EXREF	MixerPlayChannelSample
	
	EXREF	MixerGetBufferSize
	EXREF	MixerGetChannelBufferSize
	EXREF	MixerGetSampleMinSize
	EXREF	MixerGetChannelStatus
	EXREF	MixerGetTotalChannelCount

	EXREF	MixerSetReturnVector
	EXREF	MixerSetIRQDMACallbacks
	
	EXREF	MixerEnableCallback
	EXREF	MixerDisableCallback
	
	EXREF	MixerGetPluginsBufferSize
	EXREF	MixerSetPluginDeferredPtr

	IF MIXER_CIA_TIMER=1
		EXREF	MixerCalcTicks

		EXREF	mixer_ticks_last
		EXREF	mixer_ticks_best
		EXREF	mixer_ticks_worst
		EXREF	mixer_ticks_average
	ENDIF
	
	IF MIXER_COUNTER=1
		EXREF	MixerResetCounter
		EXREF	MixerGetCounter
	ENDIF
	
	EXREF	mixer

; Constants
MIX_PAL					EQU	0				; Amiga system type
MIX_NTSC				EQU	1				
	
MIX_FX_ONCE				EQU	1				; Play back FX once
MIX_FX_LOOP				EQU	-1				; Play back FX as continous loop
MIX_FX_LOOP_OFFSET		EQU	-2				; Play back FX as continous loop
											; Loop restarts at given loop
											; offset, rather than at fx start.
	
MIX_CH0					EQU	16				; Mixer software channel 0
MIX_CH1					EQU	32				; ..
MIX_CH2					EQU	64				; ..
MIX_CH3					EQU	128				; Mixer software channel 3

MIX_CH_FREE				EQU	0				; Channel is not playing a sample
MIX_CH_BUSY				EQU	1				; Channel is playing a sample

MIX_PLUGIN_STD			EQU	0				; Standard plugin
MIX_PLUGIN_NODATA		EQU	1				; Plugin that doesn't update
											; sample data

mixer_output_aud0	EQU	mixer_output_channels&1
mixer_output_aud1	EQU	(mixer_output_channels>>1)&1
mixer_output_aud2	EQU	(mixer_output_channels>>2)&1
mixer_output_aud3	EQU	(mixer_output_channels>>3)&1
mixer_output_count	EQU	mixer_output_aud0+mixer_output_aud1+mixer_output_aud2+mixer_output_aud3

mixer_total_channels	EQU mixer_sw_channels*mixer_output_count

mixer_PAL_cycles 		EQU	3546895
mixer_NTSC_cycles		EQU	3579545

	IF MIXER_PER_IS_NTSC=0
mixer_PAL_period		EQU	mixer_period
mixer_NTSC_period		EQU (mixer_period*mixer_NTSC_cycles)/mixer_PAL_cycles
	ELSE
mixer_NTSC_period		EQU	mixer_period
mixer_PAL_period		EQU (mixer_period*mixer_PAL_cycles)/mixer_NTSC_cycles
	ENDIF

; Note: do not use mixer_PAL_buffer_size or mixer_NTSC_buffer_size below to
;       get the buffer size, always refer to mixer_buffer_size instead as the
;       mixer internally requires multiple buffers to work correctly and
;       mixer_buffer_size takes this into account.
	IF MIXER_68020=0
		IF MIXER_SIZEX32=1
mixer_PAL_buffer_size	EQU	((mixer_PAL_cycles/mixer_PAL_period/50)&65504)+32
mixer_NTSC_buffer_size	EQU	((mixer_NTSC_cycles/mixer_NTSC_period/60)&65504)+32
		ELSE
mixer_PAL_buffer_size	EQU	((mixer_PAL_cycles/mixer_PAL_period/50)&65532)+4
mixer_NTSC_buffer_size	EQU	((mixer_NTSC_cycles/mixer_NTSC_period/60)&65532)+4
		ENDIF
	ELSE
mixer_PAL_buffer_size	EQU	((mixer_PAL_cycles/mixer_PAL_period/50)&65532)+4
mixer_NTSC_buffer_size	EQU	((mixer_NTSC_cycles/mixer_NTSC_period/60)&65532)+4
	ENDIF

; Note: use mixer_buffer_size to get the correct size for the mixer Chip RAM
;       block to allocate.
mixer_buffer_size		EQU	mixer_PAL_buffer_size*(1+(mixer_output_count*2))
mixer_32b_cnt			EQU mixer_PAL_buffer_size/32

.mixer_sam_mult			SET 4
.mixer_sam_mult_ntsc	SET 4
	IF MIXER_SIZEX32=1
.mixer_sam_mult			SET 32
.mixer_sam_mult_ntsc	SET 32
	ENDIF
	IF MIXER_SIZEXBUF=1
.mixer_sam_mult			SET mixer_PAL_buffer_size
.mixer_sam_mult_ntsc	SET mixer_NTSC_buffer_size
	ENDIF
mixer_PAL_multiple		EQU .mixer_sam_mult
mixer_NTSC_multiple		EQU .mixer_sam_mult_ntsc

; Note: use mixer_plugin_buffer_size to get the correct size for the mixer
;       plugin memory to allocate. This memory can be in any memory region,
;		Chip, Slow or Fast RAM.
	IF MIXER_ENABLE_PLUGINS=1 
mixer_plugin_buffer_size	EQU	(mixer_PAL_buffer_size*mixer_sw_channels)*mixer_output_count
	ENDIF
	
; Public structures
 STRUCTURE MXEffect,0	
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
	
 STRUCTURE MXPlugin,0
	UWORD	mpl_plugin_type
	APTR	mpl_init_ptr
	APTR	mpl_plugin_ptr
	APTR	mpl_init_data_ptr
	LABEL	mpl_SIZEOF

; Internal (private) structures
 STRUCTURE MXChannel,0
	IF MIXER_68020=0
		IF MIXER_WORDSIZED=1
			UWORD	mch_remaining_length
			UWORD	mch_length
			UWORD	mch_loop_length
		ELSE
			LONG	mch_remaining_length
			LONG	mch_length
			LONG	mch_loop_length
		ENDIF
	ELSE
		LONG	mch_remaining_length
		LONG	mch_length
		LONG	mch_loop_length
	ENDIF
	APTR	mch_sample_ptr
	APTR	mch_loop_ptr
	IF MIXER_ENABLE_CALLBACK=1
		APTR	mch_orig_sam_ptr
	ENDIF
	IF MIXER_ENABLE_PLUGINS=1
		APTR	mch_plugin_ptr
		APTR	mch_plugin_deferred_ptr
		APTR	mch_plugin_data_ptr
		APTR	mch_plugin_output_buffer
		UWORD	mch_plugin_type
	ENDIF
	UWORD	mch_channel_id
	UWORD	mch_status
	UWORD	mch_priority
	UWORD	mch_age
	IF MIXER_68020=1
		IF MIXER_ENABLE_PLUGINS=1
			UWORD	mch_align
		ENDIF
	ENDIF
	LABEL	mch_SIZEOF
	
 STRUCTURE MXMixerEntry,0
	STRUCT	mxe_active_channels,4*4
	STRUCT	mxe_pointers,4*4
	STRUCT	mxe_buffers,4*2
	STRUCT	mxe_channels,mch_SIZEOF*4
	IF MIXER_MULTI_PAIRED=1
		UWORD	mxe_active
		IF MIXER_68020=1
			UWORD	mxe_align
		ENDIF
	ENDIF
	LABEL	mxe_SIZEOF

 STRUCTURE MXMixer,0
	IF MIXER_SINGLE=1
		STRUCT	mx_mixer_entries,mxe_SIZEOF
	ELSE
		STRUCT	mx_mixer_entries,mxe_SIZEOF*4
	ENDIF
	APTR	mx_empty_buffer
	IF MIXER_ENABLE_CALLBACK=1
		APTR	mx_callback_ptr
	ENDIF
	APTR	mx_counter_ptr
	UWORD	mx_buffer_size
	UWORD	mx_buffer_size_w
	UWORD	mx_irq_bits
	UWORD	mx_hw_channels
	UWORD	mx_hw_period
	UWORD	mx_volume
	UWORD	mx_status
	UWORD	mx_vidsys
	IF MIXER_COUNTER=1
		UWORD	mx_counter
	ENDIF
	LABEL	mx_SIZEOF
	
 STRUCTURE MXIRQDMACallbacks,0
	APTR	mxicb_set_irq_vector
	APTR	mxicb_remove_irq_vector
	APTR	mxicb_set_irq_bits
	APTR	mxicb_clear_irq_bits
	APTR	mxicb_disable_irq
	APTR	mxicb_enable_irq
	APTR	mxicb_acknowledge_irq
	APTR	mxicb_enable_dma
	APTR	mxicb_disable_dma
	LABEL	mxicb_SIZEOF
	
	ENDC	; MIXER_I
; End of File