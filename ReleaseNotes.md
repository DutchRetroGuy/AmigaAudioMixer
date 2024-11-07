Release notes for the Audio Mixer

v3.7
----
* (NEW) The mixer now optionally supports using callbacks to handle IRQ and
        DMA registers, rather than the mixer doing so natively. This option
		allows for, amongst other things, implementing an OS-legal interrupt
		server for the mixer, or implementing the mixer as part of another
		API.
		
		This option is configured to be off by default, use 
		MIXER_EXTERNAL_IRQ_DMA to enable it.
* (NEW) The mixer now supports calling a routine at the end of interrupt 
        processing, to allow user code to execute actions as close to the
        mixer interrupt loop as possible. This option is configured to be off
        by default, use MIXER_ENABLE_RETURN_VECTOR to enable it.
		
        The vector for this routine can be set by calling MixerSetReturnVector().
* (BUGFIX) Fixed a potential issue with the include guard in mixer_config.i
* (MAINTENANCE) The makefile now automatically synchronises the mixer & plugin
                files from the main Mixer & Plugin directories to the various
                example Mixer & Plugin directories.
* (MAINTENANCE) The makefile is now platform agnostic and will work on both
                Windows based systems and Unix-like systems (including Linux,
                BSD & Mac OS X).

v3.6
----
* (NEW) The mixer now supports a high quality mixing mode, which does not
        require pre-processed samples, but rather uses standard 8-bit samples.
        Note that this mode uses significantly more CPU time.
* (NEW) The mixer now supports the use of plugin routines which will be called
        during sample playback. These routines can alter the data being played
        back, or work as synchronisation/control routines for timing and other
        purposes. There are several plugins provided by default. It is also
        possible to create custom plugins for use with the mixer.

        The following plugins are provided:
           * MixPluginRepeat - repeats a sample after a given delay
           * MixPluginSync - sets a trigger when a given condition occurs
           * MixPluginVolume - changes the volume of the sample playing back
           * MixPluginPitch - changes the pitch of the sample playing back
* (NEW) The mixer now has the option of calling a callback function whenever a
        non-looping sample ends playing.
* (NEW) New loop mode added, MIX_FX_LOOP_OFFSET, which allows samples to loop
        from an offset into the sample rather than from the start of the 
        sample.
* (NEW) Added function MixerGetChannelStatus(), which returns whether or not
        the given channel is in use by the mixer.
* (NEW) Added an optional counter of number of mixer interrupts that have
        executed since the counter started. Counter can be reset with 
        MixerResetCounter() and read using MixerGetCounter().
* (NEW) A new example has been added to show HQ mode. The example is named
        SingleMixerHQExample.
* (NEW) New examples have been added to show callback and plugin use. The 
        examples are named CallbackExample and PluginExample.
* (NEW) The CMixerExample has been updated to also show callback and plugin
        use.
* (NEW) The PerformanceTest has been updated to also measure performance of
        callback and plugin use.
* (DEPRECATED) The routines MixerPlaySample() and MixerPlayChannelSample() are
               deprecated. They have been updated for 3.6 with the new loop 
               offset mode, but will not support plugins or potential other 
               changes in future versions of the mixer.
			   
               Replacement routines to use are MixerPlayFX() and 
               MixerPlayChannelFX().
			   
               For compatibility with previous versions, the old functions
               will remain existing as is for the forseeable future.
* (MAINTENANCE) The source directories for all examples have been renamed to
                <example>Source and all binary examples now have a name ending
                in 'Example'.
* (MAINTENANCE) The MinimalMixer example now uses MixerPlayFX() instead of 
                MixerPlaySample()
* (MAINTENANCE) The code for CMixerExample has been updates to use 
                MixerPlayFX() instead of MixerPlaySample()
* (MAINTENANCE) The code for the various functions to play samples through the
                mixer has been adjusted so that most of the functionality is 
                handled by one shared function to increase maintainability.
* (BUGFIX) The performance test tool now supports combined mixer routine sizes
           above 64KB.
* (BUGFIX) The performance test tool now no longer uses more sample space than
           needed.
* (BUGFIX) The performance test tool now uses samples of addequate length, no
           matter the selected period.
* (BUGFIX) The performance test tool now correctly runs 132 mixer interrupt
           executions per test, rather than 132 detected vblanks as the mixer
           interrupt could delay those and cause them to not be detected.
* (BUGFIX) The performance test tool now correctly uses the 68020 optimised
           interrupt handler when MIXER_68020 is set to 1
* (BUGFIX) The various functions added to return information (such as
           MixerGetBufferSize()) now always return a longword value.
* (BUGFIX) The functions MixerPlaySample, MixerPlayChannelSample, MixerPlayFX
           and MixerPlayChannelFX now correctly save and restore register D1
           to the stack.
* (BUGFIX) If MIXER_WORDSIZED is set to 1, the mixer now correctly uses the 
           2nd word of mfx_length and mfx_loop_offset in the MXEffect
           structure.
* (BUGFIX) If MIXER_SIZEXBUF is set to 1, the mixer no longer skips the first
           frame of sample playback.
* (BUGFIX) If MIXER_68020 is set to 1, the mixer no longer selects channels
           above the mixer_sw_channels limit to play back samples on when 
           using MixerPlayFX() or MixerPlaySample().
* (BUGFIX) The linux/unix version of the makefile now has the correct commands
           for make install & make clean to work
* (BUGFIX) The mixer makefile will no longer give a "Could not find" error
           when using make clean.
* (BUGFIX) The mixer makefile will no longer give a "1 file copied" message
           when using make install.
* (BUGFIX) The HTML version of the documentation no longer contains any broken
           links.

v3.2
----
* (MAINTENANCE) updated mixer.h to be more compliant with the C standard.
* (BUGFIX) updated the way XREF and XDEF references are handled for 
           compatibility with vasm 1.9d and other assemblers that don't 
           support XREF's in the same file as the symbol definitions they
           reference.

v3.1
----
* initial release of the Audio Mixer project
