; $VER: plugins.i 1.1 (04.02.24)
;
; plugins.i
; Include file for plugins.asm
;
; Note: all plugin configuration is done via plugins_config.i.
;
; Plugin API (see mixer documentation for full information)
; --------------------------------------------------------- 
;
; General
; -------
; Plugins for the mixer consist of routines that are called by the mixer 
; during mixer interrupts using a specific API. They are not designed to be
; called separately. Plugins are not supposed to change sample source data,
; and instead work through output buffers which store altered sample data. If
; a plugin does not need to alter sample data to function (for instance, the 
; synchronisation plugin does not actually change audio output, but instead is
; meant to signal the main program of a timed sample playback event), then it
; can run in a mode were no sample output buffer is required.
;
; Plugins consist of up to three routines:
; *) a plugin initialisation routine, which does setup for the plugin prior to
;    playing back the sample. These routines are called when calling the 
;    various MixerPlayFX routines.
;
;    Plugin initialisation routines also set up any data required by plugin
;    routines. 
; *) a plugin routine, which does the actual work of the plugin. These 
;    routines are called every mixer interrupt for samples playing using a
;    plugin. Depending on plugin type, they either need to fill an output
;    buffer with the audio data to play, or not.
;
;    Note: plugin routines are not allowed to call MixerPlaySample/MixerPlayFX
;          type routines, as doing so can cause the mixer interrupt to crash.
; *) an optional deferred plugin routine, which is called at the end of every
;    mixer interrupt for samples playing using plugin. These routines are
;    required only when playing back entirely new samples is needed for the
;    plugin, as calling MixerPlaySample/MixerPlayFX type routines during the
;    mixing loop is not supported.
;
; Apart from deferred plugin routines (which are set up directly by plugin 
; routines themselves), all these routines and any data they need are passed 
; to the mixer using the MXPlugin structure, which can be found in mixer.i.
;
; For more information on how to fill this structure, see mixer.i or the
; mixer documentation.
;
; Plugin output buffers
; ---------------------
; In order to support altering of sample data in a non-destructive way, the
; plugin system makes use of an intermediate buffer per mixer channel. The
; mixer routine MixerSetup() takes an additional parameter:
;
; A1=plugin_buffer
;    Pointer to a block of any type of memory at least 
;    mixer_plugin_buffer_size (from mixer.i) bytes in size.
;
;    Note: the value for mixer_plugin_buffer_size can also be obtained by
;          calling MixerGetPluginsBufferSize(), from mixer.i.
;
; Plugin (initialisation) data
; ----------------------------
; Plugins may need some data that persists between calls of the plugin
; routines to work. In order to prevent race conditions, this data must be
; stored alongside the mixer channel data, rather than separately.
;
; To support this, when running using plugins, the routine MixerSetup() takes
; additional parameters:
;
; D1=plugin_data_length.w
;    Maximum length of any of the plugin data structures. This must be either 
;    mxplg_max_data_size, or the largest data size of any custom plugins.
;
;    Note: the value for mxplg_max_data_size can also be obtained by calling
;          MixerPluginGetMaxDataSize().
;
; A2=plugin_data
;    Pointer to a block of any type of memory, sized D1 multiplied by
;	 mixer_total_channels from mixer.i.
;
;    Note: The value for mixer_total_channels can also be gotten by calling
;          MixerGetTotalChannelCount(), included from mixer.i.
;
; In order to correctly set up this internal data used by plugins and prevent
; race conditions, the plugin data is set up indirectly via the various plugin
; initialisation routines that each plugin should have.
;
; These initialisation routines are passed a pointer to plugin initialisation
; data, which in turn is used to set up the data for the plugins themselves.
;
; Plugin routine calling conventions
; ----------------------------------
; All plugin initialisation routines, plugin routines and deffered plugin
; routines use pre-defined calling conventions. These conventions have to be
; kept for custom made plugins as well.
;
; Plugin initialisation routine calling conventions:
;    - Initialisation routines have the following parameters:
;         A0 - Pointer to MXEffect structure as passed by MixerPlayFX() or
;              MixerPlayChannelFX()
;         A1 - Pointer to plugin initialisation data structure, as passed by
;              MixerPlayFX() or MixerPlayChannelFX()
;         A2 - Pointer to plugin data structure, as passed by MixerPlayFX() or
;              MixerPlayChannelFX(). This block of memory is set up by the
;              initialisation routine to contain the data the plugin requires
;              to work
;         D0 - Hardware channel/mixer channel (f.ex. DMAF_AUD0|MIX_CH1)
;    - Depending on what the plugin itself needs, these parameters can be
;      omitted / left blank.
;    - Initialisation routines have to preserve all registers
;    - Initialisation routines should limit themselves to setting up the data
;      required for use by the plugin and any calculations (etc) to achieve
;      this. They should not be used for other purposes.
;    - Initialisation routines can have any name, though following the
;      convention in plugins.i of naming them MixPluginInit<plugin name> is
;      suggested.
;
; Plugin routine calling conventions:
;    - Plugin routines have the following parameters:
;         A0 - Pointer to the output buffer to use
;         A1 - Pointer to the plugin data
;	      A2 - Pointer to the MXChannel structure for the current channel
;              (see note below)
;         D0 - Number of bytes to process
;         D1 - Loop indicator. Set to 1 if the sample has restarted at the
;              loop offset (or at its start in case the loop offset is not
;              set)
;    - Depending on what the plugin itself needs, these parameters can be
;      omitted / left blank.
;    - Plugin routines have to preserve all registers
;	 - Plugin routines are not allowed to call any mixer routine that causes a
;      new sample to be played. If this is needed, create a separate deferred
;      plugin routine that does call this/these routine(s). Then, in the 
;      plugin routine call MixerSetPluginDeferredPtr() with the function 
;      pointer for the deferred plugin routine instead.
;    - Plugin routines should limit themselves to actions required for the
;      plugin and attempt to be a frugal as possible with the amount of CPU
;      time they use.
;    - Plugin routines can have any name, though following the convention in
;      plugins.i of naming them MixPlugin<plugin name> is suggested.
;
;    Note: the structure passed in A2 is an internal mixer structure which may
;          change between versions. Do not alter its contents with any plugin
;          routines. It is provided solely to enable calling 
;          MixerSetPluginDeferredPtr(), if needed.
;
; Deferred plugin routine calling conventions:
;    - Deferred plugin routines have the following parameters:
;         A0 - Pointer to the output buffer in use
;         A1 - Pointer to the plugin data
;    - Depending on what the plugin itself needs, these parameters can be
;      omitted / left blank.
;    - Deferred plugin routines have to preserve all registers
;	 - Unlike plugin routines, deferred plugin routines are allowed to call
;      any mixer routine that causes a new sample to be played.
;    - Deferred plugin routines should limit themselves to actions required 
;      to play back new samples / after mixing is done and attempt to be a 
;      frugal as possible with the amount of CPU time they use.
;    - Deferred plugin routines can have any name, though following the 
;      convention in plugins.asm of naming them MixPlugin<plugin name>Deferred
;      is suggested.
;
; Structures
; ----------
; Structure definitions can be found at the bottom of plugins.i.
; The following structures are used by various plugin initialisation routines.
;
; MXPDPitchInitData
;	* mpid_pit_mode        - The mode to use for the pitch plugin. Either 
;                            MXPLG_PITCH_STANDARD or MXPLG_PITCH_LOWQUALITY.
;                            The latter is much faster, but also results in
;                            lower quality output.
;	* mpid_pit_precalc     - Whether or not the values in the MXEffect 
;                            structure contain pre-calculated values for the
;                            altered pitch sample's new length and loop 
;                            offset. Set using either MXPLG_PITCH_NO_PRECALC
;                            or MXPLG_PITCH_PRECALC. If set to the former, the
;                            initialisation routine will calculate the new
;                            length & loop offset for the MXEffect structure
;                            in real time, which costs extra CPU time. 
;                            (note that the plugin routine itself is 
;                             unaffected)
;	* mpid_pit_ratio_fp8   - The ratio to change the pitch by, given as a 8.8
;                            fixed point math number. The new sample pitch 
;                            will be multiplied so a ratio of 0.5 will halve 
;                            the sample's pitch, while a ratio of 2.0 will
;                            double the pitch (etc).
;	* mpid_pit_length      - If MXPLG_PITCH_PRECALC is set, this field has to
;                            contain the original length of the sample, 
;                            without pitch shift.
;	* mpid_pit_loop_offset - If MXPLG_PITCH_PRECALC is set, this field has to
;                            contain the original loop offset of the sample, 
;                            without pitch shift.
;
; MXPDVolumeInitData
;	* mpid_vol_mode        - The mode to use for the volume plugin. Either
;                            MXPLG_VOL_TABLE or MXPLG_VOL_SHIFT. The former
;                            uses a lookup table (byte based) to change the
;                            volume, the latter uses shift instructions.
;	* mpid_vol_volume      - The desired volume. For table lookups, this
;                            ranges from 0 (silence) to 15 (maximum volume).
;                            In case of shifts, this ranges from 0 (maxium
;                            volume) to 8 (silence)
;
;                            Note that the shift value for silence is
;                            dependent on the mixer mode and the number of 
;                            channels the mixer can mix (as set in 
;                            mixer_config.i):
;                                                  Shift value for silence
;                            HQ Mode/1-4 channels       8
;                            Normal/1 channel       	8
;                            Normal/2 channels          7
;                            Normal/3 channels          7
;                            Normal/4 channels          6
; 
; MXPDRepeatInitData
;	* mpid_rep_delay       - The desired delay in mixer ticks. Mixer ticks
;                            occur roughly once per frame, when the mixer
;                            interrupt triggers.
; 
; MXPDSyncInitData
;	* mpid_snc_address     - Set to the location in memory to use as output
;                            for the synchronisation plugin. This location has
;                            to be 1 word wide.
;	* mpid_snc_mode        - Set to the desired synchronisation mode. Several
;                            modes are available:
;                              *) MXPLG_SYNC_DELAY
;                                 Triggers every mpid_snc_delay ticks
;                              *) MXPLG_SYNC_DELAY_ONCE
;                                 Triggers once, after mpid_snc_delay ticks
;                              *) MXPLG_SYNC_START
;                                 Triggers once, at the start of playback
;                              *) MXPLG_SYNC_END
;                                 Triggers once, at the end of playback
;                              *) MXPLG_SYNC_LOOP
;                                 Triggers every time playback loops
;                              *) MXPLG_SYNC_START_AND_LOOP
;                                 Triggers at the start of playback and again
;                                 every time playback loops
;                              *) MXPLG_SYNC_NO_OP
;                                 No operation, never triggers
;	* mpid_snc_type        - Set to the desired synchronisation type. Several
;                            types are available:
;                              *) MXPLG_SYNC_ONE
;                                 Writes the value one to the target address
;                              *) MXPLG_SYNC_INCREMENT
;                                 Increments the contents of the word at the
;                                 target address by one
;                              *) MXPLG_SYNC_DECREMENT
;                                 Decrements the contents of the word at the
;                                 target address by one
;                              *) MXPLG_SYNC_DEFERRED
;                                 Instead of changing the word at 
;                                 mpid_snc_address, this mode uses the address
;                                 in mpid_snc_address as the address of a
;                                 deferred plugin function, which will be
;                                 called at the end of any interrupt in which
;                                 the chosen sync mode triggers.
;	* mpid_snc_delay       - The desired delay in mixer ticks. Mixer ticks
;                            occur roughly once per frame, when the mixer
;                            interrupt triggers.
;
; Plugin routines
; ---------------
; Because each plugin uses both an initialisation routine and a plugin 
; routine and the calling convention of each of these routines is always the
; same, the initialisation and plugin routines will be described without
; function prototypes and instead show the correct way to set up the MXPlugin
; structure for the mixer instead, as well as describe the functionality of
; the plugin, which initialisation data structure to use and how to fill it.
;
; Other / support routines will be described as normal and can be found in the
; Support Routines section.
;
; MixPluginInitDummy() / MixPluginDummy()
;   This plugin performs no function and changes no data. It can be used in
;   place of calling an actual plugin to test plugin functionality, or as a
;   NO-OP plugin if the code written to call MixerPlayFX() or 
;   MixerPlayChannelFX() in a specific program always wants to pass a plugin,
;   even if this is not required for the sample to be played.
;
;   MXPlugin setup:
;   --------------
;   * mpl_plugin_type   - Determines the type of plugin. Either MIX_PLUGIN_STD
;                         or MIX_PLUGIN_NODATA
;   * all other fields are ignored
;
; MixPluginInitRepeat() / MixPluginRepeat()
;   This plugin repeats playback of the sample specified after a given delay.
;   It makes use of the MXPDRepeatInitData structure to pass its parameter.
;   See the section Structures above for information how to set up this
;   structure.
;
;   MXPlugin setup:
;   --------------
;	* mpl_plugin_type	- Set to MIX_PLUGIN_NODATA
;	* mpl_init_ptr		- Pointer to MixPluginInitRepeat()
;	* mpl_plugin_ptr	- Pointer to MixPluginRepeat()
;	* mpl_init_data_ptr	- Pointer to instance of structure MXPDRepeatInitData
;
; MixPluginInitSync() / MixPluginSync()
;   This plugin is used to give synchronisation/timing information to the
;   program playing back samples using the mixer. If offers various modes and
;   types of this information. When the mode/type of the synchronisation 
;   plugin triggers, it either writes a value to a given address, or calls the
;   routine at this address as a deferred plugin routine.
;   The plugin makes use of the MXPDSyncInitData structure to pass its
;   parameters.
;   See the section Structures above for information how to set up this
;   structure.
;  
;   Deferred plugin routines have the following function prototype:
;   DeferredRoutineExample(A0=output_buffer,A1=plugin_data)
;
;   Note: deferred plugin routines have to preserve all registers, and should
;         be written to be as frugal as possible with CPU time.
;   Note: the deferred plugin routine for the synchronisation plugin will be
;         called with the plugin data for the synchronisation plugin in A1.
;         This data follows the definition of MXPDSyncData, as found in 
;         plugins.i
;
;   MXPlugin setup:
;   --------------
;	* mpl_plugin_type	- Set to MIX_PLUGIN_NODATA
;	* mpl_init_ptr		- Pointer to MixPluginInitSync()
;	* mpl_plugin_ptr	- Pointer to MixPluginSync()
;	* mpl_init_data_ptr	- Pointer to instance of structure MXPDSyncInitData
;
; MixPluginInitVolume() / MixPluginVolume()
;   This plugin is used to change the playback volume of the sample specified.
;   It operates either by using a lookup table or by using shifts. In case of
;   using lookup tables, it supports 16 volume levels: 0 = silence, 15 = 
;   maximum volume. In case of using shifts, 0 represents maximum volume and
;   silence is represented by either 8, 7 or 6 (depending on the configured
;   number of software channels per hardware channel).
;   The plugin makes use of the MXPDVolumeInitData structure to pass its
;   parameters.
;   See the section Structures above for information how to set up this
;   structure.
;
;   MXPlugin setup:
;   --------------
;	* mpl_plugin_type	- Set to MIX_PLUGIN_STD
;	* mpl_init_ptr		- Pointer to MixPluginInitVolume()
;	* mpl_plugin_ptr	- Pointer to MixPluginVolume()
;	* mpl_init_data_ptr	- Pointer to instance of structure MXPDVolumeInitData
;
; MixPluginInitPitch() / MixPluginPitch()
;   This plugin changes the pitch of the specified sample by a given ratio. It
;   offers two modes (standard and low quality) and has an option to speed up 
;   the initialisation phase by using some pre-calculated values. The ratio
;   is given as a fixed point 8.8 value and represents the value to use to 
;   multiply the original pitch value (so, 0.5 means playing back at half
;   pitch, 2.0 means playing back at double pitch, etc).
;   The plugin makes use of the MXPDPitchInitData structure to pass its
;   parameters.
;   See the section Structures above for information how to set up this
;   structure.
;
;   Note: using pre-calculated values for length & offset does not increase 
;         performance of the actual plugin, it only speeds up the 
;         initialisation that runs when calling MixerPlayFX() or 
;         MixerPlayChannelFX()
;
;   MXPlugin setup:
;   --------------
;	* mpl_plugin_type	- Set to MIX_PLUGIN_STD
;	* mpl_init_ptr		- Pointer to MixPluginInitPitch()
;	* mpl_plugin_ptr	- Pointer to MixPluginPitch()
;	* mpl_init_data_ptr	- Pointer to instance of structure MXPDPitchInitData
; 
; Support routines
; ----------------
; D0=MixPluginGetMultiplier()
;	Returns the type of sample size multiple the mixer expects. This can be
;   used instead of MixerGetSampleMinSize() if the actual value is not 
;   relevant, only whether or not it's 4x, 32x or (buffer_size)x.
;
;   Returns either MXPLG_MULTIPLIER_4, MXPLG_MULTIPLIER_32 or 
;   MXPLG_MULTIPLIER_BUFSIZE.
;
; D0=MixerPluginGetMaxInitDataSize()
;   This routine returns the maximum size of any of the built in plugin
;   initialisation data structures.
;
; D0=MixerPluginGetMaxDataSize()
;   This routine returns the maximum size of any of the built in plugin data
;   structures.
;
; MixPluginRatioPrecalc(A0=effect_structure,D0=pitch_ratio,D1=shift_value)
;   This routine can be used to pre-calculate length and loop offset values
;   for plugins that need these values divided by a FP8.8 ratio.
;   The routine calculates the values using a pointer to a filled MXEffect
;   structures in A0, the ratio value in D0 and the shift value in D1.
;
;   Currently this routine is only used by/for MixPluginPitch().
;
;   Note: the shift value passed to the routine is used to scale the input to
;         create a greater range than would normally be allowed. At a shift of
;         zero, the routine supports input & output values of up to 65535. 
;         Increasing the shift value will increase these limits by a factor of
;         2^shift factor, at a cost of an ever increasing inaccuracy.
;
; Author: Jeroen Knoester
; Version: 1.1
; Revision: 20240204
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include	exec/types.i

	include	plugins_config.i

	IFND	MIXER_PLUGINS_I
MIXER_PLUGINS_I	SET	1

	IFND	BUILD_MIXER_WRAPPER

; References macro
EXREF	MACRO
		IFD BUILD_PLUGINS
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM

; References
	EXREF	MixPluginInitDummy
	EXREF	MixPluginInitRepeat
	EXREF	MixPluginInitSync
	EXREF	MixPluginInitVolume
	EXREF	MixPluginInitPitch
	
	EXREF	MixPluginDummy
	EXREF	MixPluginRepeat
	EXREF	MixPluginSync
	EXREF	MixPluginVolume
	EXREF	MixPluginPitch
	
	EXREF	MixPluginGetMultiplier
	EXREF	MixerPluginGetMaxInitDataSize
	EXREF	MixerPluginGetMaxDataSize
	EXREF	MixPluginRatioPrecalc
	
	ENDIF

; Constants
MXPLG_MULTIPLIER_4			EQU	0
MXPLG_MULTIPLIER_32			EQU	1
MXPLG_MULTIPLIER_BUFSIZE	EQU	2

MXPLG_PITCH_1x				EQU 0			; For internal use only, do not
											; use when filling plugin data
MXPLG_PITCH_STANDARD		EQU	1
MXPLG_PITCH_LOWQUALITY		EQU	2
MXPLG_PITCH_LEVELS			EQU	3

MXPLG_PITCH_NO_PRECALC		EQU	0
MXPLG_PITCH_PRECALC			EQU	1

MXPLG_VOL_TABLE				EQU	0
MXPLG_VOL_SHIFT				EQU	1

MXPLG_SYNC_DELAY			EQU 0
MXPLG_SYNC_DELAY_ONCE		EQU 1
MXPLG_SYNC_START			EQU	2
MXPLG_SYNC_END				EQU	3
MXPLG_SYNC_LOOP				EQU	4
MXPLG_SYNC_START_AND_LOOP	EQU	5
MXPLG_SYNC_NO_OP			EQU	6

MXPLG_SYNC_ONE				EQU	0
MXPLG_SYNC_INCREMENT		EQU	1
MXPLG_SYNC_DECREMENT		EQU	2
MXPLG_SYNC_DEFERRED			EQU	3

; Structures (public)
 STRUCTURE MXPDPitchInitData,0
	UWORD	mpid_pit_mode
	UWORD	mpid_pit_precalc
	UWORD	mpid_pit_ratio_fp8
	LONG	mpid_pit_length
	LONG	mpid_pit_loop_offset
	LABEL	mpid_pit_SIZEOF

 STRUCTURE MXPDVolumeInitData,0
	UWORD	mpid_vol_mode
	UWORD	mpid_vol_volume
	LABEL	mpid_vol_SIZEOF
 
 STRUCTURE MXPDRepeatInitData,0
	WORD	mpid_rep_delay
	LABEL	mpid_rep_SIZEOF
 
 STRUCTURE MXPDSyncInitData,0
	APTR	mpid_snc_address
	UWORD	mpid_snc_mode
	UWORD	mpid_snc_type
	UWORD	mpid_snc_delay
	LABEL	mpid_snc_SIZEOF
	
mxplg_max_idata_size	SET		0
	IFD BUILD_MIXER_WRAPPER
mxplg_max_idata_size	SET		mpid_rep_SIZEOF
	ELSE
	IF MXPLUGIN_REPEAT=1
mxplg_max_idata_size	SET		mpid_rep_SIZEOF
	ENDIF
	ENDIF
	
	IFD BUILD_MIXER_WRAPPER
		IF mpid_snc_SIZEOF>mxplg_max_idata_size
mxplg_max_idata_size	SET		mpid_snc_SIZEOF
		ENDIF
	ELSE
	IF MXPLUGIN_SYNC=1
		IF mpid_snc_SIZEOF>mxplg_max_idata_size
mxplg_max_idata_size	SET		mpid_snc_SIZEOF
		ENDIF
	ENDIF
	ENDIF
	
	IFD BUILD_MIXER_WRAPPER
		IF mpid_vol_SIZEOF>mxplg_max_idata_size
mxplg_max_idata_size	SET		mpid_vol_SIZEOF
		ENDIF
	ELSE
	IF MXPLUGIN_VOLUME=1
		IF mpid_vol_SIZEOF>mxplg_max_idata_size
mxplg_max_idata_size	SET		mpid_vol_SIZEOF
		ENDIF
	ENDIF
	ENDIF
	
	IFD BUILD_MIXER_WRAPPER
		IF mpid_pit_SIZEOF>mxplg_max_idata_size
mxplg_max_idata_size	SET		mpid_pit_SIZEOF
		ENDIF
	ELSE
	IF MXPLUGIN_PITCH=1
		IF mpid_pit_SIZEOF>mxplg_max_idata_size
mxplg_max_idata_size	SET		mpid_pit_SIZEOF
		ENDIF
	ENDIF
	ENDIF


; Structures (internal)
 STRUCTURE MXPDPitchData,0
	LONG	mpd_pit_original_length
	LONG	mpd_pit_length
	APTR	mpd_pit_sample_ptr
	LONG	mpd_pit_loop_offset
	LONG	mpd_pit_sample_offset
	LONG	mpd_pit_output_offset
	UWORD	mpd_pit_mode
	UWORD	mpd_pit_ratio_fp8	
	UWORD	mpd_pit_current_fp8
	LABEL	mpd_pit_SIZEOF

 STRUCTURE MXPDVolumeData,0
	LONG	mpd_vol_length
	APTR	mpd_vol_sample_ptr
	LONG	mpd_vol_loop_offset
	LONG	mpd_vol_sample_offset
	UWORD	mpd_vol_mode
	UWORD	mpd_vol_table_offset
	UWORD	mpd_vol_volume
	UWORD	mpd_vol_align					; For 68020+ performance
	LABEL	mpd_vol_SIZEOF

 STRUCTURE MXPDRepeatData,0
	ULONG	mpd_rep_length
	APTR	mpd_rep_sample_ptr
	LONG	mpd_rep_loop_offset
	UWORD	mpd_rep_loop
	UWORD	mpd_rep_priority
	UWORD	mpd_rep_channel
	WORD	mpd_rep_delay
	UWORD	mpd_rep_triggered
	UWORD	mpd_rep_align					; For 68020+ performance
	LABEL	mpd_rep_SIZEOF
	
 STRUCTURE MXPDSyncData,0
	APTR	mpd_snc_address
	UWORD	mpd_snc_mode
	UWORD	mpd_snc_type
	UWORD	mpd_snc_delay
	UWORD	mpd_snc_counter
	UWORD	mpd_snc_started
	UWORD	mpd_snc_done
	LABEL	mpd_snc_SIZEOF

mxplg_max_data_size	SET		0
	IFD BUILD_MIXER_WRAPPER
mxplg_max_data_size	SET		mpd_rep_SIZEOF
	ELSE
	IF MXPLUGIN_REPEAT=1
mxplg_max_data_size	SET		mpd_rep_SIZEOF
	ENDIF
	ENDIF
	
	IFD BUILD_MIXER_WRAPPER
		IF mpd_snc_SIZEOF>mxplg_max_data_size
mxplg_max_data_size	SET		mpd_snc_SIZEOF
		ENDIF
	ELSE
	IF MXPLUGIN_SYNC=1
		IF mpd_snc_SIZEOF>mxplg_max_data_size
mxplg_max_data_size	SET		mpd_snc_SIZEOF
		ENDIF
	ENDIF
	ENDIF
	
	IFD BUILD_MIXER_WRAPPER
		IF mpd_vol_SIZEOF>mxplg_max_data_size
mxplg_max_data_size	SET		mpd_vol_SIZEOF
		ENDIF
	ELSE
	IF MXPLUGIN_VOLUME=1
		IF mpd_vol_SIZEOF>mxplg_max_data_size
mxplg_max_data_size	SET		mpd_vol_SIZEOF
		ENDIF
	ENDIF
	ENDIF
	
	IFD BUILD_MIXER_WRAPPER
		IF mpd_pit_SIZEOF>mxplg_max_data_size
mxplg_max_data_size	SET		mpd_pit_SIZEOF
		ENDIF
	ELSE
	IF MXPLUGIN_PITCH=1
		IF mpd_pit_SIZEOF>mxplg_max_data_size
mxplg_max_data_size	SET		mpd_pit_SIZEOF
		ENDIF
	ENDIF
	ENDIF
	
	ENDC	; MIXER_PLUGINS_I
; End of File