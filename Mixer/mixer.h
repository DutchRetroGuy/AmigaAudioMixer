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
 * Revision: 20250129
 *
 * TAB size = 4 spaces
 */
#ifndef MIXER_H
#define MIXER_H

#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif

/* REGARG define to call assembly routines */
#if defined(BARTMAN_GCC) || defined(__INTELLISENSE__)
// Exploit the fact that Bartman's compiler doesn't add underscore to its C symbols and use them to call underscored mixer function from asm side
#define MIX_API __attribute__((always_inline)) static inline
#define MIX_REGARG(arg, reg) arg
#elif defined(__VBCC__)
#define MIX_API
#define MIX_REGARG(arg, reg) __reg(reg) arg
#elif defined(__GNUC__) // Bebbo
#define MIX_API
#define MIX_REGARG(arg, reg) arg asm(reg)
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

/* Note: see the documentation and plugins.h for more information
         about the functions in this structure and their arguments. */
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

/* Note: the callback functions and their arguments are fully described at
         MixerSetIRQDMACallbacks() further down in this file. */
typedef struct MXIRQDMACallbacks
{
	void (*mxicb_set_irq_vector)();		/* Pointer to function to set audio
										   interrupt vector */
	void (*mxicb_remove_irq_vector)();	/* Pointer to function to remove audio
										   interrupt vector */
	void (*mxicb_set_irq_bits)();		/* Pointer to function to set INTENA
										   bit(s) */
	void (*mxicb_disable_irq)();		/* Pointer to function to disable 
										   audio interrupt(s) */
	void (*mxicb_acknowledge_irq)();	/* Pointer to function to acknowledge
										   interrupt request was serviced */
	void (*mxicb_set_dmacon)();			/* Pointer to function that sets
										   DMACON to given value */
} MXIRQDMACallbacks;

/* Prototypes */

/* 
ULONG MixerGetBufferSize(void)
	Returns the size of the Chip RAM buffer size that needs to be allocated
	and passed to MixerSetup(). Note that this routine merely returns the
	value of mixer_buffer_size, which is defined in mixer.i. The function of
	this routine is to offer a method for C programs to gain access to this
	value without needing access to mixer.i.
*/
MIX_API ULONG MixerGetBufferSize(void);

/*
ULONG MixerGetPluginsBufferSize(void)
	Returns the value of mixer_plugin_buffer_size, the required size of the 
	RAM buffer that needs to be allocated and passed to MixerSetup() if 
	MIXER_ENABLE_PLUGINS is set to 1 in mixer_config.i.
	
	Note: this buffer can be located in any type of RAM.
	Note: this function is only available if MIXER_ENABLE_PLUGINS is set to 1
	      in mixer_config.i
*/
MIX_API ULONG MixerGetPluginsBufferSize(void);

/*
ULONG MixerGetTotalChannelCount(void)
	Returns the total number of channels the mixer supports for sample
	playback.
*/
MIX_API ULONG MixerGetTotalChannelCount(void);

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
MIX_API ULONG MixerGetSampleMinSize(void);

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
MIX_API void MixerSetup (MIX_REGARG(void *buffer, "a0"),
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
MIX_API void MixerInstallHandler(MIX_REGARG(void *VBR,"a0"),
								 MIX_REGARG(UWORD save_vector,"d0"));

/* 
void MixerRemoveHandler(void)
	Removes the mixer interrupt handler. MixerStop() should be called prior to
	calling this routine to make sure audio DMA is stopped.
*/
MIX_API void MixerRemoveHandler(void);

/* 
void MixerStart(void)
	Starts mixer playback (initially playing back silence). MixerSetup() and
	MixerInstallHandler() must have been called prior to calling this 
	function.
*/
MIX_API void MixerStart(void);

/* 
void MixerStop(void)
	Stops mixer playback. MixerSetup() and MixerInstallHandler() must have
	been called prior to calling this function.
*/
MIX_API void MixerStop(void);

/* 
void MixerVolume(UWORD volume)
	Set the desired hardware output volume used by the mixer (valid values are
	0 to 64).
*/
MIX_API void MixerVolume(MIX_REGARG(UWORD volume,"d0"));

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
MIX_API ULONG MixerPlayFX(MIX_REGARG(MXEffect *effect_structure,"a0"),
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
MIX_API ULONG MixerPlayChannelFX(MIX_REGARG(MXEffect *effect_structure,"a0"),
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
MIX_API void MixerStopFX(MIX_REGARG(UWORD mixer_channel_mask,"d0"));

/* 
ULONG MixerGetChannelStatus(MIX_REGARGS(UWORD mixer_channel,"d0"));
	Returns whether or not the hardware/mixer channel given in D0 is in use.
	If MIXER_SINGLE is set to 1, the hardware channel does not need to be 
	given in D0.

	If the channel is not used, the routine will return MIX_CH_FREE. If the
	channel is in use, the routine will return MIX_CH_BUSY.
 */
MIX_API ULONG MixerGetChannelStatus(MIX_REGARG(UWORD mixer_channel,"d0"));

/*
void MixerSetReturnVector(MIX_REGARG(void (*return_routine)(), "a0"));
	This routine sets the optional vector the mixer can call at to at the end
	of interrupt execution.

	Note: this vector should point to a standard routine ending in RTS.
	Note: this routine should be called after MixerSetup() has been run.
 */
MIX_API void MixerSetReturnVector(MIX_REGARG(void (*irq_routine)(), "a0"));

/*
void MixerSetIRQDMACallbacks(MIX_REGARGS(MXIRQDMACallbacks *callbacks,"a0"));
	This routine sets up the vectors used for callback routines to
	manage setting up interrupt vectors and DMA flags. This routine and 
	associated callbacks are only required if MIXER_EXTERNAL_IRQ_DMA is set to
	1 in mixer_config.i.
	
	Callback vectors have to be passed through the MXIRQDMACallbacks
	structure. This structure contains the following members:
	* mxicb_set_irq_vector 
	  - Function pointer to routine that sets the IRQ vector for audio
		interrupts. 
		Parameter: A0 = vector to mixer interrupt handler
		
		Note: the mixer interrupt handler will return using RTS rather
		      than RTE when using external IRQ/DMA callbacks. This behaviour
		      can be overridden by setting MIXER_EXTERNAL_RTE to 1, in which
		      case the interrupt handler will exit using RTE.
	* mxicb_remove_irq_vector
	  - Function pointer to routine that removes the IRQ vector for
		audio interrupts. 
		
		Note: if MIXER_EXTERNAL_BITWISE is set to 1, this routine is also
	          responsible for resetting INTENA to the value it had prior to
			  calling MixerInstallHandler() if this is desired.
			  
			  when MIXER_EXTERNAL_BITWISE is set to 0, this is done by the
			  mixer automatically
	* mxicb_set_irq_bits
	  - Function pointer to routine that sets the correct bits in INTENA
		to enable audio interrupts for the mixer. 
		Parameter: D0 = INTENA bits to set
		
		Note: if MIXER_EXTERNAL_BITWISE is set to 1, the relevant bits are
		      passed as individual INTENA values, where the set/clear bit is
			  set as appropriate
	* mxicb_disable_irq
	  - Function pointer to routine that disables audio interrupts
        Parameter: D0 = INTENA bits to disable

		Note: if MIXER_EXTERNAL_BITWISE is set to 1, the relevant bits are
		      passed as individual INTENA values, where the set/clear bit is
			  set as appropriate
        Note: this is a separate routine from mxicb_set_irq_bits because 
              disabling interrupts should also make sure to reset the 
              corresponding bits in INTREQ
	* mxicb_acknowledge_irq
	  - Function pointer to routine that acknowledges audio interrupt.
		Parameter: D0 = INTREQ value
		
		Note: this will always pass the INTREQ value for a single channel.
	* mxicb_set_dmacon
	  - Function pointer to routine that enables audio DMA.
		Parameter: D0 = DMACON value
		
		Note: if MIXER_EXTERNAL_BITWISE is set to 1, the relevant bits are
		      passed as individual DMACON values, where the set/clear bit is
			  set as appropriate

	
    Note: MixerSetup should be run before this routine
    Note: if MIXER_C_DEFS is set to 0, all callback routines should save &
          restore all registers they use. 

          If MIXER_C_DEFS is set to 1, registers d0,d1,a0 and a1 will be
          pushed to and popped from the stack by the mixer. All callback 
          routines should save & restore all other registers they use.
    Note: this routine is only available if MIXER_EXTERNAL_IRQ_DMA is set 
          to 1.
*/
MIX_API void MixerSetIRQDMACallbacks(MIX_REGARG(MXIRQDMACallbacks *callbacks,"a0"));

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
MIX_API void MixerEnableCallback(MIX_REGARG(ULONG (*callback_function_ptr)(),"a0"));

/*
void MixerDisableCallback(void)
	This function disables the callback function.

	Note: this function is only available if MIXER_ENABLE_CALLBACK is set to 1
	      in mixer_config.i
*/
MIX_API void MixerDisableCallback(void);

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
MIX_API void MixerSetPluginDeferredPtr(MIX_REGARG(void (*deferred_function_ptr)(),"a0"),
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
MIX_API ULONG MixerPlaySample(MIX_REGARG(void *sample,"a0"),
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
MIX_API ULONG MixerPlayChannelSample(MIX_REGARG(void *sample,"a0"),
									 MIX_REGARG(ULONG hardware_channel,"d0"),
									 MIX_REGARG(LONG length,"d1"),
									 MIX_REGARG(WORD signed_priority,"d2"),
									 MIX_REGARG(UWORD loop_indicator,"d3"),
									 MIX_REGARG(LONG loop_offset,"d4"));

#undef MIX_REGARG

/*
 Bartman GCC specific wrapper functions follow
 */
#if defined(BARTMAN_GCC) // Bartman
MIX_API ULONG MixerGetBufferSize(void) {
	register volatile ULONG reg_result __asm("d0");
	__asm__ volatile (
		"jsr _MixerGetBufferSize"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		:
		// Clobbers
		: "cc"
	);

	return reg_result;
}

MIX_API ULONG MixerGetPluginsBufferSize(void)
{
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixerGetPluginsBufferSize"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		:
		// Clobbers
		: "cc"
	);

	return reg_result;
}

MIX_API ULONG MixerGetTotalChannelCount(void)
{
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixerGetTotalChannelCount"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		:
		// Clobbers
		: "cc"
	);

	return reg_result;
}

MIX_API ULONG MixerGetSampleMinSize(void) {
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixerGetSampleMinSize"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		:
		// Clobbers
		: "cc"
	);

	return reg_result;
}

MIX_API void MixerSetup(void *buffer, UWORD vidsys) {
	register volatile void *reg_buffer __asm("a0") = buffer;
	register volatile UWORD reg_vidsys __asm("d0") = vidsys;

	__asm__ volatile (
		"jsr _MixerSetup\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_buffer), "r" (reg_vidsys)
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerInstallHandler(void *VBR, UWORD save_vector) {
	register volatile void *reg_VBR __asm("a0") = VBR;
	register volatile UWORD reg_save_vector __asm("d0") = save_vector;

	__asm__ volatile (
		"jsr _MixerInstallHandler\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_VBR), "r" (reg_save_vector)
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerRemoveHandler(void) {
	__asm__ volatile (
		"jsr _MixerRemoveHandler"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerStart(void) {
	__asm__ volatile (
		"jsr _MixerStart"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerStop(void) {
	__asm__ volatile (
		"jsr _MixerStop"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerVolume(UWORD volume) {
	register volatile UWORD reg_volume __asm("d0") = volume;

	__asm__ volatile (
		"jsr _MixerVolume\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_volume)
		// Clobbers
		: "cc"
	);
}

MIX_API ULONG MixerPlayFX(
	MXEffectStructure *effect_structure, ULONG hardware_channel
) {
	register volatile MXEffectStructure *reg_effect_structure __asm("a0") = effect_structure;
	register volatile ULONG reg_hardware_channel __asm("d0") = hardware_channel;
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixerPlayFX\n"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		: "r" (reg_effect_structure), "r" (reg_hardware_channel)
		// Clobbers
		: "cc"
	);

	return reg_result;
}

MIX_API ULONG MixerChannelPlayFX(
	MXEffectStructure *effect_structure, ULONG mixer_channel
) {
	register volatile MXEffectStructure *reg_effect_structure __asm("a0") = effect_structure;
	register volatile ULONG reg_mixer_channel __asm("d0") = mixer_channel;
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixerChannelPlayFX\n"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		: "r" (reg_effect_structure), "r" (reg_mixer_channel)
		// Clobbers
		: "cc"
	);

	return reg_result;
}

MIX_API void MixerStopFX(UWORD mixer_channel_mask) {
	register volatile UWORD reg_mixer_channel_mask __asm("d0") = mixer_channel_mask;

	__asm__ volatile (
		"jsr _MixerStopFX\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_mixer_channel_mask)
		// Clobbers
		: "cc"
	);
}

MIX_API ULONG MixerGetChannelStatus(UWORD mixer_channel)
{
	register volatile UWORD reg_mixer_channel __asm("d0") = hardware_channel;
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixerGetChannelStatus\n"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		: "r" (reg_mixer_channel)
		// Clobbers
		: "cc"
	);

	return reg_result;
}

MIX_API void MixerSetReturnVector(void (*return_routine)())
{
	register volatile void (*reg_return_routine)() __asm("a0") = return_routine;

	__asm__ volatile (
		"jsr _MixerSetReturnVector\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_return_routine)
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerSetIRQDMACallbacks(MXIRQDMACallbacks *callbacks)
{
	register volatile MXIRQDMACallbacks *reg_callbacks __asm("a0") = callbacks;

	__asm__ volatile (
		"jsr _MixerSetIRQDMACallbacks\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_callbacks)
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerEnableCallback(ULONG (*callback_function_ptr)())
{
	register volatile ULONG (*reg_callback)() __asm("a0") = callback_function_ptr;

	__asm__ volatile (
		"jsr _MixerEnableCallback\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_callback)
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerDisableCallback(void)
{
	__asm__ volatile (
		"jsr _MixerDisableCallback"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

MIX_API void MixerSetPluginDeferredPtr(void (*deferred_function_ptr)(),
									   void *mxchannel_ptr)
{
	register volatile void (*reg_deffered)() __asm("a0") = deferred_function_ptr;
	register volatile void *reg_channel __asm("a2") = mxchannel_ptr;

	__asm__ volatile (
		"jsr _MixerSetPluginDeferredPtr\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_deffered), "r" (reg_channel)
		// Clobbers
		: "cc"
	);
}


MIX_API ULONG MixerPlaySample(
	void *sample, ULONG hardware_channel, LONG length, WORD signed_priority,
	UWORD loop_indicator
) {
	register volatile void *reg_sample __asm("a0") = sample;
	register volatile ULONG reg_hardware_channel __asm("d0") = hardware_channel;
	register volatile LONG reg_length __asm("d1") = length;
	register volatile WORD reg_signed_priority __asm("d2") = signed_priority;
	register volatile UWORD reg_loop_indicator __asm("d3") = loop_indicator;
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixerPlaySample\n"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		: "r" (reg_sample), "r" (reg_hardware_channel), "r" (reg_length),
			"r" (reg_signed_priority), "r" (reg_loop_indicator)
		// Clobbers
		: "cc"
	);

	return reg_result;
}

MIX_API ULONG MixerPlayChannelSample(
	void *sample, ULONG mixer_channel, LONG length, WORD signed_priority,
	UWORD loop_indicator
) {
	register volatile void *reg_sample __asm("a0") = sample;
	register volatile ULONG reg_mixer_channel __asm("d0") = mixer_channel;
	register volatile LONG reg_length __asm("d1") = length;
	register volatile WORD reg_signed_priority __asm("d2") = signed_priority;
	register volatile UWORD reg_loop_indicator __asm("d3") = loop_indicator;
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixerPlayChannelSample\n"
		// OutputOperands
		: "=r" (reg_result)
		// InputOperands
		: "r" (reg_sample), "r" (reg_mixer_channel), "r" (reg_length),
			"r" (reg_signed_priority), "r" (reg_loop_indicator)
		// Clobbers
		: "cc"
	);

	return reg_result;
}
#endif

#endif