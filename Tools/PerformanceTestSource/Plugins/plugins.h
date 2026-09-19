/*
 * plugins.h
 *
 * This is the C header file for the plugins for the Audio Mixer. The Audio 
 * Mixer and its plugins are written in assembly, this header file offers an
 * interface to the assembly routines. As supplied, the header file should 
 * work for VBCC and Bebbo's GCC compiler.
 *
 * To use the plugins in C programs, the plugins.asm file still must be
 * assembled into an object file, with plugins_config.i set up correctly for
 * the desired use.
 *
 * Note: this header file contains an abbreviated version of the documentation
 *       for structures and routines, see plugins.i or the mixer 
 *       documentation for more information.
 * Note: in mixer_config.i, the value MIXER_C_DEFS must be set to 1 for this
 *       header file to work as it is also used by plugins.asm to determine
 *       whether or not to generate C style function definitions.
 *
 * Author: Jeroen Knoester
 * Version: 1.2
 * Revision: 202501029
 *
 * TAB size = 4 spaces
 */
#ifndef MIXER_PLUGINS_H
#define MIXER_PLUGIN_H

#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif

#include "../mixer/mixer.h"

/* REGARG define to call assembly routines */
#if defined(BARTMAN_GCC) || defined(__INTELLISENSE__)
// Exploit the fact that Bartman's compiler doesn't add underscore to its C symbols and use them to call underscored mixer function from asm side
#define PLG_API __attribute__((always_inline)) static inline
#define MIX_REGARG(arg, reg) arg
#elif defined(__VBCC__)
#define PLG_API
#define MIX_REGARG(arg, reg) __reg(reg) arg
#elif defined(__GNUC__) // Bebbo
#define PLG_API
#define MIX_REGARG(arg, reg) arg asm(reg)
#endif

/* Constants */
#define MXPLG_MULTIPLIER_4			EQU	0
#define MXPLG_MULTIPLIER_32			EQU	1
#define MXPLG_MULTIPLIER_BUFSIZE	EQU	2

#define MXPLG_PITCH_STANDARD		1
#define MXPLG_PITCH_LOWQUALITY		2

#define MXPLG_PITCH_NO_PRECALC		0
#define MXPLG_PITCH_PRECALC			1

#define MXPLG_VOL_TABLE				0
#define MXPLG_VOL_SHIFT				1

#define MXPLG_SYNC_DELAY			0
#define MXPLG_SYNC_DELAY_ONCE		1
#define MXPLG_SYNC_START			2
#define MXPLG_SYNC_END				3
#define MXPLG_SYNC_LOOP				4
#define MXPLG_SYNC_START_AND_LOOP	5
#define MXPLG_SYNC_NO_OP			6

#define MXPLG_SYNC_ONE				0
#define MXPLG_SYNC_INCREMENT		1
#define MXPLG_SYNC_DECREMENT		2
#define MXPLG_SYNC_DEFERRED			3

/* Types */
typedef struct MXPDPitchInitData
{
	UWORD mpid_pit_mode;		/* Pitch mode to use (MXPLG_PITCH_STANDARD or 
								   MXPLG_PITCH_LOWQUALITY) */
	UWORD mpid_pit_precalc;		/* Whether or not to use pre-calculated length
								   values (MXPLG_PITCH_NO_PRECALC or 
								   MXPLG_PITCH_PRECALC) */
	UWORD mpid_pit_ratio_fp8;	/* FP8.8 ratio to multiply pitch by */
	LONG mpid_pit_length;		/* If MXPLG_PITCH_PRECALC is set, original 
								   length of the sample */
	LONG mpid_pit_loop_offset;	/* If MXPLG_PITCH_PRECALC is set, original 
								   loop offset of the sample */
} MXPDPitchInitData;

typedef struct MXPDVolumeInitData
{
	UWORD mpid_vol_mode;		/* Volume mode to use (MXPLG_VOL_TABLE or 
								   MXPLG_VOL_SHIFT) */
	UWORD mpid_vol_volume;		/* Volume or shift level to use. If 
								   MXPLG_VOL_TABLE is set: 0-16 (16 = max). If 
								   MXPLG_VOL_SHIFT is set: 0-7 (0 = max) */
} MXPDVolumeInitData;
 
typedef struct MXPDRepeatInitData
{
	WORD mpid_rep_delay;		/* Desired delay in mixer ticks (~1 frame 
								   each) */
} MXPDRepeatInitData;
 
typedef struct MXPDSyncInitData
{
	void *mpid_snc_address;		/* Pointer to address to use for either output
								   data or deferred function */
	UWORD mpid_snc_mode;		/* Synchronisation mode to use 
								   (MXPLG_SYNC_DELAY, MXPLG_SYNC_DELAY_ONCE, 
								    MXPLG_SYNC_START, MXPLG_SYNC_END, 
									MXPLG_SYNC_LOOP, MXPLG_SYNC_START_AND_LOOP
									or MXPLG_SYNC_NO_OP) */
	UWORD mpid_snc_type;		/* Synchronisation type to use 
								   (MXPLG_SYNC_ONE, MXPLG_SYNC_INCREMENT, 
								    MXPLG_SYNC_DECREMENT or 
									MXPLG_SYNC_DEFERRED)*/
	UWORD mpid_snc_delay;		/* Desired delay in mixer ticks (~1 frame 
								   each) */
} MXPDSyncInitData;

/* Prototypes */
/* Note, the following functions should only be passed to the mixer via the
   MXPlugin structure and the functions MixerPlayFX()/MixerPlayChannelFX(),
   not called directly:
   
   MixPluginInitDummy()
   MixPluginInitRepeat()
   MixPluginInitSync()
   MixPluginInitPitch()
   
   MixPluginDummy()
   MixPluginRepeat()
   MixPluginSync()
   MixPluginPitch()
   
   Their prototypes are only provided for clarity and to allow them being used
   as function pointers.

   Other functions in this header file can be called normally.
*/   

/*
void MixPluginInitDummy(void)
	This plugin performs no function and changes no data. It can be used in
	place of calling an actual plugin to test plugin functionality, or as a
	NO-OP plugin if the code written to call MixerPlayFX() or 
	MixerPlayChannelFX() in a specific program always wants to pass a plugin,
	even if this is not required for the sample to be played.

	MXPlugin setup:
	--------------
	* mpl_plugin_type   - Determines the type of plugin. Either MIX_PLUGIN_STD
						  or MIX_PLUGIN_NODATA
	* all other fields are ignored
*/
PLG_API void MixPluginInitDummy(void);

/*
void MixPluginInitRepeat(void *mxeffect, void *plugin_init_data, 
                         void *plugin_data, UWORD hardware_channel)
	This plugin repeats playback of the sample specified after a given delay.
	It makes use of the MXPDRepeatInitData structure to pass its parameter.
	See the types above for information how to set up this structure.

	MXPlugin setup:
	--------------
	* mpl_plugin_type	- Set to MIX_PLUGIN_NODATA
	* mpl_init_ptr		- Pointer to MixPluginInitRepeat()
	* mpl_plugin_ptr	- Pointer to MixPluginRepeat()
	* mpl_init_data_ptr	- Pointer to instance of structure MXPDRepeatInitData
*/
PLG_API void MixPluginInitRepeat(MIX_REGARG(void *mxeffect, "a0"),
								 MIX_REGARG(void *plugin_init_data, "a1"),
								 MIX_REGARG(void *plugin_data, "a2"),
								 MIX_REGARG(UWORD hardware_channel, "d0"));

/*
void MixPluginInitSync(void *mxeffect, void *plugin_init_data, 
                       void *plugin_data)
	This plugin is used to give synchronisation/timing information to the
	program playing back samples using the mixer. If offers various modes and
	types of this information. When the mode/type of the synchronisation 
	plugin triggers, it either writes a value to a given address, or calls the
	routine at this address as a deferred plugin routine.
	The plugin makes use of the MXPDSyncInitData structure to pass its
	parameters.
	See the types above for information how to set up this structure.

	Deferred plugin routines have the following function prototype:
	DeferredRoutineExample(A0=output_buffer,A1=plugin_data)

	Note: deferred plugin routines have to preserve all registers, and should
		  be written to be as frugal as possible with CPU time.
	Note: the deferred plugin routine for the synchronisation plugin will be
		  called with the plugin data for the synchronisation plugin in A1.
		  This data follows the definition of MXPDSyncData, as found in 
		  plugins.i
*/
PLG_API void MixPluginInitSync(MIX_REGARG(void *mxeffect, "a0"),
							   MIX_REGARG(void *plugin_init_data, "a1"),
							   MIX_REGARG(void *plugin_data, "a2"));

/*
void MixPluginInitVolume(void *mxeffect, void *plugin_init_data, 
                         void *plugin_data)
	This plugin is used to change the playback volume of the sample specified.
	It operates either by using a lookup table or by using shifts. In case of
	using lookup tables, it supports 16 volume levels: 0 = silence, 15 = 
	maximum volume. In case of using shifts, 0 represents maximum volume and
	silence is represented by either 8, 7 or 6 (depending on the configured
	number of software channels per hardware channel).
	The plugin makes use of the MXPDVolumeInitData structure to pass its
	parameters.
	See the types above for information how to set up this structure.
*/
PLG_API void MixPluginInitVolume(MIX_REGARG(void *mxeffect, "a0"),
								 MIX_REGARG(void *plugin_init_data, "a1"),
								 MIX_REGARG(void *plugin_data, "a2"));

/*
void MixPluginInitPitch(void *mxeffect, void *plugin_init_data, 
                        void *plugin_data)
	This plugin changes the pitch of the specified sample by a given ratio. It
	offers two modes (standard and low quality) and has an option to speed up 
	the initialisation phase by using some pre-calculated values. The ratio
	is given as a fixed point 8.8 value and represents the value to use to 
	multiply the original pitch value (so, 0.5 means playing back at half
	pitch, 2.0 means playing back at double pitch, etc).
	The plugin makes use of the MXPDPitchInitData structure to pass its
	parameters.
	See the types above for information how to set up this structure.

	Note: using pre-calculated values for length & offset does not increase 
		  performance of the actual plugin, it only speeds up the 
		  initialisation that runs when calling MixerPlayFX() or 
		  MixerPlayChannelFX()
	
	MXPlugin setup:
	--------------
	* mpl_plugin_type	- Set to MIX_PLUGIN_STD
	* mpl_init_ptr		- Pointer to MixPluginInitPitch()
	* mpl_plugin_ptr	- Pointer to MixPluginPitch()
	* mpl_init_data_ptr	- Pointer to instance of structure MXPDPitchInitData

*/
PLG_API void MixPluginInitPitch(MIX_REGARG(void *mxeffect, "a0"),
								MIX_REGARG(void *plugin_init_data, "a1"),
								MIX_REGARG(void *plugin_data, "a2"));

/*
void MixPluginDummy(void)
	Plugin routine for the dummy plugin. See MixPluginInitDummy().
*/	
PLG_API void MixPluginDummy(void);

/*
void MixPluginRepeat(void *plugin_data, void *channel_data, 
                     UWORD loop_indicator)
	Plugin routine for the repeat plugin. See MixPluginInitRepeat().
*/
PLG_API void MixPluginRepeat(MIX_REGARG(void *plugin_data, "a1"),
							 MIX_REGARG(void *channel_data, "a2"),
							 MIX_REGARG(UWORD loop_indicator, "d1"));

/*
void MixPluginSync(void *plugin_data, UWORD loop_indicator)
	Plugin routine for the synchronisation plugin. See MixPluginInitSync().
*/
PLG_API void MixPluginSync(MIX_REGARG(void *plugin_data, "a1"),
						   MIX_REGARG(UWORD loop_indicator, "d1"));

/*
void MixPluginVolume(void *plugin_output_buffer, void *plugin_data, 
                     UWORD bytes_to_process, UWORD loop_indicator)
	Plugin routine for the volume plugin. See MixPluginInitVolume().
*/
PLG_API void MixPluginVolume(MIX_REGARG(void *plugin_output_buffer, "a0"),
							 MIX_REGARG(void *plugin_data, "a1"),
							 MIX_REGARG(UWORD bytes_to_process, "d0"),
							 MIX_REGARG(UWORD loop_indicator, "d1"));

/*
void MixPluginPitch(void *plugin_output_buffer, void *plugin_data, 
                    UWORD bytes_to_process, UWORD loop_indicator)
	Plugin routine for the pitch plugin. See MixPluginInitPitch().
*/
PLG_API void MixPluginPitch(MIX_REGARG(void *plugin_output_buffer, "a0"),
							MIX_REGARG(void *plugin_data, "a1"),
							MIX_REGARG(UWORD bytes_to_process, "d0"),
							MIX_REGARG(UWORD loop_indicator, "d1"));
	
/*
ULONG MixPluginGetMultiplier(void)
	Returns the type of sample size multiple the mixer expects. This can be
	used instead of MixerGetSampleMinSize() if the actual value is not 
	relevant, only whether or not it's 4x, 32x or (buffer_size)x.
	
	Returns either MXPLG_MULTIPLIER_4, MXPLG_MULTIPLIER_32 or 
	MXPLG_MULTIPLIER_BUFSIZE.
*/
PLG_API ULONG MixPluginGetMultiplier(void);

/*
LONG MixerPluginGetMaxInitDataSize(void)
	This routine returns the maximum size of any of the built in plugin
	initialisation data structures.
*/
PLG_API LONG MixerPluginGetMaxInitDataSize(void);

/*
LONG MixerPluginGetMaxDataSize(void)
	This routine returns the maximum size of any of the built in plugin data
	structures.
*/
PLG_API LONG MixerPluginGetMaxDataSize(void);

/*
ULONG MixPluginRatioPrecalc(MXEffect *effect_structure, UWORD pitch_ratio, 
                            UWORD shift_value)
	This routine can be used to pre-calculate length and loop offset values
	for plugins that need these values divided by a FP8.8 ratio.
	The routine calculates the values using a pointer to a filled MXEffect
	structure, the ratio value and the shift value.
	
	Currently this routine is only used by/for MixPluginPitch().
	
	Note: the shift value passed to the routine is used to scale the input to
		  create a greater range than would normally be allowed. At a shift of
		  zero, the routine supports input & output values of up to 65535. 
		  Increasing the shift value will increase these limits by a factor of
		  2^shift factor, at a cost of an ever increasing inaccuracy.

*/
PLG_API ULONG MixPluginRatioPrecalc(MIX_REGARG(MXEffect *effect_structure, "a0"),
									MIX_REGARG(UWORD pitch_ratio, "d0"),
									MIX_REGARG(UWORD shift_value, "d1"));

#undef MIX_REGARG

/*
 Bartman GCC specific wrapper functions follow
 */
#if defined(BARTMAN_GCC) // Bartman
PLG_API void MixPluginInitDummy(void)
{
	__asm__ volatile (
		"jsr _MixPluginInitDummy"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginInitRepeat(void *mxeffect,
								 void *plugin_init_data,
								 void *plugin_data,
								 UWORD hardware_channel)
{
	register volatile void *reg_mxeffect __asm("a0") = mxeffect;
	register volatile void *reg_plugin_init_data __asm("a1") = plugin_init_data;
	register volatile void *reg_plugin_data __asm("a2") = plugin_data;
	register volatile UWORD reg_hardware_channel __asm("d0") = hardware_channel;

	__asm__ volatile (
		"jsr _MixPluginInitRepeat\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_mxeffect), "r" (reg_plugin_init_data), "r" (reg_plugin_data),
			"r" (reg_hardware_channel)
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginInitSync(void *mxeffect,
							   void *plugin_init_data,
							   void *plugin_data)
{
	register volatile void *reg_mxeffect __asm("a0") = mxeffect;
	register volatile void *reg_plugin_init_data __asm("a1") = plugin_init_data;
	register volatile void *reg_plugin_data __asm("a2") = plugin_data;

	__asm__ volatile (
		"jsr _MixPluginInitSync\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_mxeffect), "r" (reg_plugin_init_data), "r" (reg_plugin_data)
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginInitVolume(void *mxeffect,
								 void *plugin_init_data,
								 void *plugin_data)
{
	register volatile void *reg_mxeffect __asm("a0") = mxeffect;
	register volatile void *reg_plugin_init_data __asm("a1") = plugin_init_data;
	register volatile void *reg_plugin_data __asm("a2") = plugin_data;

	__asm__ volatile (
		"jsr _MixPluginInitVolume\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_mxeffect), "r" (reg_plugin_init_data), "r" (reg_plugin_data)
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginInitPitch(void *mxeffect,
								void *plugin_init_data,
								void *plugin_data)
{
	register volatile void *reg_mxeffect __asm("a0") = mxeffect;
	register volatile void *reg_plugin_init_data __asm("a1") = plugin_init_data;
	register volatile void *reg_plugin_data __asm("a2") = plugin_data;

	__asm__ volatile (
		"jsr _MixPluginInitPitch\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_mxeffect), "r" (reg_plugin_init_data), "r" (reg_plugin_data)
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginDummy(void)
{
	__asm__ volatile (
		"jsr _MixPluginDummy"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginRepeat(void *plugin_data,
							 void *channel_data,
							 UWORD loop_indicator)
{
	register volatile void *reg_plugin_data __asm("a1") = plugin_data;
	register volatile void *reg_channel_data __asm("a2") = channel_data;
	register volatile UWORD reg_loop_indicator __asm("d1") = loop_indicator;

	__asm__ volatile (
		"jsr _MixPluginRepeat\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_plugin_data), "r" (reg_channel_data), "r" (reg_loop_indicator)
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginSync(void *plugin_data,
						   UWORD loop_indicator)
{
	register volatile void *reg_plugin_data __asm("a1") = plugin_data;
	register volatile UWORD reg_loop_indicator __asm("d1") = loop_indicator;

	__asm__ volatile (
		"jsr _MixPluginSync\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_plugin_data), "r" , "r" (reg_loop_indicator)
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginVolume(void *plugin_output_buffer,
							 void *plugin_data,
							 UWORD bytes_to_process,
							 UWORD loop_indicator)
{
	register volatile void *reg_plugin_output_buffer __asm("a0") = plugin_output_buffer;
	register volatile void *reg_plugin_data __asm("a1") = plugin_data;
	register volatile UWORD reg_bytes_to_process __asm("d0") = bytes_to_process;
	register volatile UWORD reg_loop_indicator __asm("d1") = loop_indicator;

	__asm__ volatile (
		"jsr _MixPluginVolume\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_plugin_output_buffer), "r" (reg_plugin_data), 
			"r" (reg_bytes_to_process), "r" (reg_loop_indicator)
		// Clobbers
		: "cc"
	);
}

PLG_API void MixPluginPitch(void *plugin_output_buffer,
							void *plugin_data,
							UWORD bytes_to_process,
							UWORD loop_indicator)
{
	register volatile void *reg_plugin_output_buffer __asm("a0") = plugin_output_buffer;
	register volatile void *reg_plugin_data __asm("a1") = plugin_data;
	register volatile UWORD reg_bytes_to_process __asm("d0") = bytes_to_process;
	register volatile UWORD reg_loop_indicator __asm("d1") = loop_indicator;

	__asm__ volatile (
		"jsr _MixPluginPitch\n"
		// OutputOperands
		:
		// InputOperands
		: "r" (reg_plugin_output_buffer), "r" (reg_plugin_data), 
			"r" (reg_bytes_to_process), "r" (reg_loop_indicator)
		// Clobbers
		: "cc"
	);
}
							
PLG_API ULONG MixPluginGetMultiplier(void)
{
	__asm__ volatile (
		"jsr _MixPluginGetMultiplier"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

PLG_API LONG MixerPluginGetMaxInitDataSize(void)
{
	__asm__ volatile (
		"jsr _MixerPluginGetMaxInitDataSize"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

PLG_API LONG MixerPluginGetMaxDataSize(void)
{
	__asm__ volatile (
		"jsr _MixerPluginGetMaxDataSize"
		// OutputOperands
		:
		// InputOperands
		:
		// Clobbers
		: "cc"
	);
}

PLG_API ULONG MixPluginRatioPrecalc(MXEffect *effect_structure,
									UWORD pitch_ratio,
									UWORD shift_value)
{
	register volatile MXEffect *reg_effect_structure __asm("a0") = effect_structure;
	register volatile UWORD reg_pitch_ratio __asm("d0") = pitch_ratio;
	register volatile UWORD reg_shift_value __asm("d1") = shift_value;
	register volatile ULONG reg_result __asm("d0");

	__asm__ volatile (
		"jsr _MixPluginRatioPrecalc\n"
		// OutputOperands
		: "r" (reg_result)
		// InputOperands
		: "r" (reg_effect_structure), "r" (reg_pitch_ratio), 
			"r" (reg_shift_value)
		// Clobbers
		: "cc"
	);

	return reg_result;
}
#endif

#endif