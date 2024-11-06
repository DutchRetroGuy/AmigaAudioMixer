/*
 * mixer.h
 *
 * This is the C header file for the Audio Mixer. The Audio Mixer is written
 * in assembly, this header file offers an interface to the assembly routines.
 * As supplied, the header file should work for VBCC and Bebbo's GCC compiler.
 *
 * To use the Audio Mixer in C programs, the mixer.asm file still must be 
 * assembled into an object file, with mixer_config.i set up correctly for the
 * desired use.
 *
 * Note: in mixer_config.i, the value MIXER_C_DEFS must be set to 1 for this
 *       header file to work.
 *
 * Author: Jeroen Knoester
 * Version: 3.7
 * Revision: 20240204
 *
 * TAB size = 4 spaces
 */
#ifndef MIXER_H
#define MIXER_H

#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif

/* REGARG define to call assembly routines */
#if !defined(MIX_REGARG)
#if defined(__VBCC__)
#define MIX_REGARG(arg, reg) __reg(reg) arg
#elif defined(__GNUC__) // Bebbo
#define MIX_REGARG(arg, reg) arg asm(reg)
#endif
#endif

/* Constants */
#define MIX_PAL  0			/* Amiga system type */
#define MIX_NTSC 1

#define MIX_FX_ONCE			 1/* Play back FX once */
#define MIX_FX_LOOP			-1/* Play back FX as continous loop */
#define MIX_FX_LOOP_OFFSET	-2/* Play back FX as continous loop,
							     loop restarts playback at given
							     sample loop offset */
	
#define MIX_CH0  16			/* Mixer software channel 0 */
#define MIX_CH1	 32			/* .. */
#define MIX_CH2	 64			/* .. */
#define MIX_CH3	128			/* Mixer software channel 3 */

#define	MIX_CH_FREE	0		/* Mixer channel is free for use */
#define	MIC_CH_BUSY	1		/* Mixer channel is busy */

#define	MIX_PLUGIN_STD    0	/* Plugin is of standard type */
#define	MIX_PLUGIN_NODATA 1	/* Plugin is of no data type */

/* Types */
typedef struct MXEffect
{
	LONG mfx_length;		/* Length of sample */
	void *mfx_sample_ptr;	/* Pointer to sample in any RAM (even address) */
	UWORD mfx_loop;			/* Loop indicator (MIX_FX_ONCE, MIX_FX_LOOP or 
							   MIX_FX_LOOP_OFFSET) */
	UWORD mfx_priority;		/* Priority indicator (higher is better) */
	LONG mfx_loop_offset;	/* Offset to loop restart point in case 
							   MIX_FX_LOOP_OFFSET is set as looping mode */
	void *mfx_plugin;		/* NULL or a pointer to an instance of 
	                           MXPluginList, containing a plugin to use while
							   playing back the sample */
} MXEffect;

typedef struct MXPlugin
{
	UWORD mpl_plugin_type;		/* Type of plugin (MIX_PLUGIN_STD or 
								   MIX_PLUGIN_NODATE) */
	void (*mpl_init_ptr)();		/* Pointer to initialisation function for the 
								   plugin */
	void (*mpl_plugin_ptr)();	/* Pointer to plugin function */
	void *mpl_init_data_ptr;	/* Pointer to data used by the plugin 
								   initialisation function */
} MXPlugin;

/* Prototypes */

void MixerSetReturnVector (MIX_REGARG(void (*irq_routine)(), "a0"));

/* 
ULONG MixerGetBufferSize(void)
	Returns the size of the Chip RAM buffer size that needs to be allocated
	and passed to MixerSetup(). Note that this routine merely returns the
	value of mixer_buffer_size, which is defined in mixer.i. The function of
	this routine is to offer a method for C programs to gain access to this
	value without needing access to mixer.i.
*/
ULONG MixerGetBufferSize(void);

/*
ULONG MixerGetPluginsBufferSize(void)
	Returns the value of mixer_plugin_buffer_size, the required size of the 
	RAM buffer that needs to be allocated and passed to MixerSetup() if 
	MIXER_ENABLE_PLUGINS is set to 1 in mixer_config.i.
	
	Note: this buffer can be located in any type of RAM.
	Note: this function is only available if MIXER_ENABLE_PLUGINS is set to 1
	      in mixer_config.i
*/
ULONG MixerGetPluginsBufferSize(void);

/*
ULONG MixerGetTotalChannelCount(void)
	Returns the total number of channels the mixer supports for sample
	playback.
*/
ULONG MixerGetTotalChannelCount(void);

/*
ULONG MixerGetSampleMinSize(void)
	Returns the minimum sample size. This is the minimum sample size the mixer
	can play back correctly. Samples must always be a multiple of this value in
	length.

	Normally this value is 4, but optimisation options in mixer_config.i can
	can increase this.

	Note: this routine is usually not needed as the minimum sample size is 
	      implied by the mixer_config.i setup. Its primary function is to give
	      the correct value in case MIXER_SIZEXBUF has been set to 1 in 
	      mixer_config.i, in which case the minimum sample size will depend on
	      the video system selected when calling MixerSetup (PAL or NTSC).
	Note: MixerSetup() must have been called prior to calling this function.
*/
ULONG MixerGetSampleMinSize(void);

/* 
void MixerSetup(void *buffer,void *plugin_buffer,void *plugin_data, 
                UWORD video_system, UWORD plugin_data_length)
	Prepares the mixer structure for use by the mixing routines and sets mixer
	playback volume to the maximum hardware volume of 64. Must be called prior
	to any other mixing routines.
   
	- buffer must point to a block of memory in Chip RAM at least 
	  mixer_buffer_size bytes in size.
	- video_system must contain either MIX_PAL if running on a PAL system, or
	  MIX_NTSC when running on a NTSC system.

	If the video system is unknown, set video_system to MIX_PAL.
	  
	If MIXER_ENABLE_PLUGINS is set to 0 in mixer.config, set other parameters
	to NULL or 0 respectively. If MIXER_ENABLE_PLUGINS is set to 1, instead
	fill these parameters as follows:
	  
	- plugin_buffer must point to a block of memory in any type of RAM at
	  least mixer_plugin_buffer_size bytes in size.
	- plugin_data_length must be set to the maximum size of any of the 
	  possible plugin data structures. If no custom plugins are used, this
	  size is the value mxplg_max_data_size, found in plugins.i. This value
	  can be obtained by calling MixerPluginGetMaxDataSize(), found in 
	  plugins.i.

	  If custom plugins are used, this value must be either the largest data
	  size of the custom plugins, or mxplg_max_data_size, whichever is larger.
	- plugin_data must point to a block of memory sized plugin_data_length 
	  multiplied by mixer_total_channels from mixer.i. The value for 
	  mixer_total_channels can be obtained by calling 
	  MixerGetTotalChannelCount().

	Note: on 68020+ systems, it is advisable to align the various buffers to a
	       4 byte boundary for optimal performance.
*/
void MixerSetup (MIX_REGARG(void *buffer, "a0"),
                 MIX_REGARG(void *plugin_buffer, "a1"),
                 MIX_REGARG(void *plugin_data, "a2"),
                 MIX_REGARG(UWORD vidsys,"d0"),
				 MIX_REGARG(UWORD plugin_data_length,"d1"));

/* 
void MixerInstallHandler(void *VBR,UWORD save_vector)
	Sets up the mixer interrupt handler. MixerSetup() must be called prior to
	calling this routine. 
	- Pass the VBR value or zero in VBR. 
	- save_vector controls whether or not the old interrupt vector will be 
	  saved. Set it to 0 to save the vector for future restoring and to 1 to skip
	  saving the vector.
   */
void MixerInstallHandler(MIX_REGARG(void *VBR,"a0"),
                         MIX_REGARG(UWORD save_vector,"d0"));

/* 
void MixerRemoveHandler(void)
	Removes the mixer interrupt handler. MixerStop() should be called prior to
	calling this routine to make sure audio DMA is stopped.
*/
void MixerRemoveHandler(void);

/* 
void MixerStart(void)
	Starts mixer playback (initially playing back silence). MixerSetup() and
	MixerInstallHandler() must have been called prior to calling this 
	function.
*/
void MixerStart(void);

/* 
void MixerStop(void)
	Stops mixer playback. MixerSetup() and MixerInstallHandler() must have
	been called prior to calling this function.
*/
void MixerStop(void);

/* 
void MixerVolume(UWORD volume)
	Set the desired hardware output volume used by the mixer (valid values are
	0 to 64).
*/
void MixerVolume(MIX_REGARG(UWORD volume,"d0"));

/* 
ULONG MixerPlayFX(MXEffect *effect_structure,
                  ULONG hardware_channel)
	Adds the sample defined in the MXEffect pointed to by effect_structure on
	the the hardware channel given in hardware_channel. If MIXER_SINGLE is set
	to 1 in mixer_config.i, the hardware channel can be left a 0. Determines
	the best mixer channel to play back on based on priority and age. If no 
	applicable channel is free (for instance due to higher priority samples 
	playing), the routine will not play the sample.

	Returns the hardware & mixer channel the sample will play on, or -1 if no
	free channel could be found.

	Note: the MXEffect definition can be found at the top of this file.
*/
ULONG MixerPlayFX(MIX_REGARG(MXEffect *effect_structure,"a0"),
                  MIX_REGARG(ULONG hardware_channel,"d0"));

/* 
ULONG MixerPlayChannelFX(MXEffect *effect_structure,
                         ULONG mixer_channel)
	Adds the sample defined in the MXEffect pointed to by effect_structure on
	the the hardware and mixer channel given in mixer_channel. If MIXER_SINGLE
	is set to 1 in mixer_config.i, the hardware	channel bits can be left zero,
	but the mixer channel bit must still be	set. Determines whether to play 
	back the sample based on priority and age. If the channel isn't free (for
	instance due to a higher priority sample playing), the routine will not 
	play the sample.

	Returns the hardware & mixer channel the sample will play on,	or -1 if 
	no free channel could be found.

	Note: the MXEffect definition can be found at the top of of this file, 
          values are as described at the MixerPlaySample() routine.
	Note: a mixer channel refers to the internal virtual channels the mixer
	      uses to mix samples together. By exposing these virtual channels,
	      more fine grained control over playback becomes possible.

	      Mixer channels range from MIX_CH0 to MIX_CH3, depending on the 
	      maximum number of software channels available as defined in 
	      mixer_config.i.
*/
ULONG MixerPlayChannelFX(MIX_REGARG(MXEffect *effect_structure,"a0"),
                         MIX_REGARG(ULONG mixer_channel,"d0"));

/*
void MixerStopFX(ULONG mixer_channel_mask)
	Stops playback on the given hardware/mixer channel combination in 
	channel_mask. If MIXER_SINGLE is set to 1 in mixer_config.i, the hardware
	channel bits can be left zero, but the mixer channel bits must still be 
	set. If MIXER_MULTI or MIXER_MULTI_PAIRED are set to 1 in mixer_config.i,
	multiple hardware channels can be selected at the same time. In this case
	the playback is stopped on the given mixer channels across all selected 
	hardware channels.

	Note: see MixerPlayChannelFX() for an explanation of mixer channels.
*/
void MixerStopFX(MIX_REGARG(UWORD mixer_channel_mask,"d0"));

/* 
ULONG MixerGetChannelStatus(MIX_REGARGS(UWORD mixer_channel,"d0"));
	Returns whether or not the hardware/mixer channel given in D0 is in use.
	If MIXER_SINGLE is set to 1, the hardware channel does not need to be 
	given in D0.

	If the channel is not used, the routine will return MIX_CH_FREE. If the
	channel is in use, the routine will return MIX_CH_BUSY.
 */
ULONG MixerGetChannelStatus(MIX_REGARG(UWORD mixer_channel,"d0"));

/*
void MixerEnableCallback(void *callback_function_ptr)
	This function enables the callback function and sets it to the given 
	function pointer. 

	Callback functions take two parameters: The HW channel/mixer channel
	combination in D0 and the pointer to the start of the sample that just
	finished playing in A0.

	Callback functions are called whenever a sample ends playback. This
	excludes looping samples and samples stopped by a call to MixerStopFX() or
	MixerStop().

	Note: this function is only available if MIXER_ENABLE_CALLBACK is set to 1
	      in mixer_config.i
*/
void MixerEnableCallback(MIX_REGARG(int (*callback_function_ptr)(),"a0"));

/*
void MixerDisableCallback(void)
	This function disables the callback function.

	Note: this function is only available if MIXER_ENABLE_CALLBACK is set to 1
	      in mixer_config.i
*/
void MixerDisableCallback(void);

/*
void MixerSetPluginDeferredPtr(void *deferred_function_ptr, void *mxchannel_ptr)
	This routine is called by a plugin whenever it needs to do a deferred 
	(=post mixing loop) action. This is useful in case a plugin needs to start
	playback of a new sample, as this cannot be done during the mixing loop to
	prevent race conditions.

	Note: this routine should *only* be used by plugin routines and never in
	      other situations as that will likely crash the mixer interrupt
	      handler.
	Note: see plugins.h for more details on deferred functions
	Note: this function is only available if MIXER_ENABLE_PLUGINS is set to 1
	      in mixer_config.i
*/
void MixerSetPluginDeferredPtr(MIX_REGARG(void (*deferred_function_ptr)(),"a0"),
							   MIX_REGARG(void *mxchannel_ptr,"a2"));

/*
ULONG MixerPlaySample(void *sample,ULONG hardware_channel,LONG length,
                      WORD signed_priority,UWORD loop_indicator, 
					  LONG loop_offset)
	Adds the sample pointed to by sample on the hardware channel given in
	hardware_channel. If MIXER_SINGLE is set to 1 in mixer_config.i, the
	hardware channel can be left 0. Determines the best mixer channel to play
	back on based on priority and age. If no applicable channel is free (for
	instance due to higher priority samples playing), the routine will not 
	play the sample.

	Other values that need to be set are length, which sets the length of the 
	sample (signed long, unless MIXER_WORDSIZED is set to 1 in mixer_config.i,
	in which case the length is an unsigned word). The desired priority of the
	sample is set in signed_priority. Samples of higher priority can overwrite 
	already playing samples of lower priority if no free mixer channel can be 
	found. The loop_indicator has to contain either MIX_FX_ONCE for samples 
	that need to play once, or one of MIX_FX_LOOP or MIX_FX_LOOP_OFFSET for 
	samples that should loop forever. MIX_FX_LOOP loops	back to the start of 
	the sample, MIX_FX_LOOP_OFFSET restarts at the value given for loop_offset
	(signed long, unless MIXER_WORDSIZED is set to 1, in which case 
	loop_offset is an unsigned word). Looping samples can only be stopped by 
	either calling MixerStop() or MixerStopFX().

	Returns the hardware & mixer channel the sample will play on, or -1 if no
	free channel could be found.
	
	Note: this function is deprecated,use MixerPlayFX() instead.
*/
ULONG MixerPlaySample(MIX_REGARG(void *sample,"a0"),
                      MIX_REGARG(ULONG hardware_channel,"d0"),
					  MIX_REGARG(LONG length,"d1"),
					  MIX_REGARG(WORD signed_priority,"d2"),
					  MIX_REGARG(UWORD loop_indicator,"d3"),
					  MIX_REGARG(LONG loop_offset,"d4"));

/*
ULONG MixerPlayChannelSample(void *sample,ULONG mixer_channel,LONG length,
                             WORD signed_priority,UWORD loop_indicator, 
							 LONG loop_offset)
	Adds the sample pointed to by sample on the hardware/mixer channel given
	in mixer_channel. If MIXER_SINGLE is set to 1 in mixer_config.i, the 
	hardware channel bits do not need to be set, but the mixer channel bit 
	must still be given. Determines whether to play back the sample based on
	priority and age. If the channel isn't free (for instance due to a higher 
	priority sample playing), the routine will not play the sample.

	Other values that need to be set are length, which sets the length of the 
	sample (signed long, unless MIXER_WORDSIZED is set to 1 in mixer_config.i,
	in which case the length is an unsigned word). Set the desired priority of
	the sample in signed_priority. Samples of higher priority can overwrite 
	already playing samples of lower priority if no free mixer channel can be
	found. The loop_indicator has to contain either MIX_FX_ONCE for samples 
	that need to play once, or one of MIX_FX_LOOP or MIX_FX_LOOP_OFFSET for 
	samples that should loop forever. MIX_FX_LOOP loops	back to the start of 
	the sample, MIX_FX_LOOP_OFFSET restarts at the value given for loop_offset
	(signed long, unless MIXER_WORDSIZED is set to 1, in which case 
	loop_offset is an unsigned word). Looping samples can only be stopped by 
	either calling MixerStop() or MixerStopFX().

	Returns the hardware & mixer channel the sample will play on, or -1 if no
	free channel could be found.

	Note: see MixerPlayChannelFX() for an explanation of mixer channels.
	Note: this function is deprecated,use MixerPlayChannelFX() instead.
*/
ULONG MixerPlayChannelSample(MIX_REGARG(void *sample,"a0"),
                             MIX_REGARG(ULONG hardware_channel,"d0"),
					         MIX_REGARG(LONG length,"d1"),
					         MIX_REGARG(WORD signed_priority,"d2"),
					         MIX_REGARG(UWORD loop_indicator,"d3"),
							 MIX_REGARG(LONG loop_offset,"d4"));

#undef MIX_REGARG
#endif