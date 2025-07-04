# Audio Mixer 3.7 documentation

## Table of Contents

- [Overview](#overview)
- [Release notes](#release-notes)
- [Requirements](#requirements)
- [Configuration](#configuration)
- [Assembling/compiling the mixer, converter, examples & tools](#assemblingcompiling-the-mixer-converter-examples--tools)
- [Pre-processing samples](#pre-processing-samples)
- [Using the mixer](#using-the-mixer)
- [Combining the mixer and a music player](#combining-the-mixer-and-a-music-player)
- [Examples](#examples)
- [Tools](#tools)
- [API Changes between version 3.1/3.2 and 3.7](#api-changes-between-version-3132-and-37)
- [Mixer API](#mixer-api)
- [Callback API](#callback-api)
- [Plugin API](#plugin-api)
- [Converter API](#converter-api)
- [Performance measuring API](#performance-measuring-api)
- [Using the mixer in C programs](#using-the-mixer-in-c-programs)
- [Troubleshooting](#troubleshooting)
- [Performance data](#performance-data)
- [Best practices for source samples](#best-practices-for-source-samples)
- [Acknowledgments](#acknowledgements)
- [License/Disclaimer](#licensedisclaimer)

### Overview

The Audio Mixer is a configurable SFX engine designed to play back multiple samples at the same time on a single hardware channel. It achieves a high level of performance on even low end Amiga's (such as the A500) by making use of optimised code and pre-processed samples. It is designed to be able to co-exist with music playback routines, as long as the music playback routine supports disabling access/playback to the hardware channel(s) the Audio Mixer uses.

If desired, multiple hardware channels can be assigned to the Audio Mixer, allowing for even more samples to be played at the same time. The Audio Mixer supports native Amiga audio through Paula only and is designed for use in programs that disable the OS.

#### Features:

- Up to four samples can be mixed onto a single hardware channel.
- High performance: mixing four samples onto a single channel at 11KHz takes only 3.7% CPU time on a 7MHz 68000 without Fast RAM.
- Optional high quality mode that uses much more CPU time, but plays full 8-bit samples, rather than lower quality pre-processed ones.
- Can be run while a music playback routine is running, as long as the music routine does not access the hardware channel(s) used by the Audio Mixer.
- Up to four hardware channels can be assigned to the Audio Mixer, allowing up to 16 samples being played back at the same time.
- Sample playback is priority based, so that drowning out of important effects can be prevented.
- Samples can be stored anywhere in RAM, including in Fast RAM and Slow RAM.
- Samples can be set to loop from either sample start, or from a given offset into the sample and both looping/non-looping samples can be stopped on request.
- Samples can be assigned to one of the virtual channels the mixer uses (up to 4 per hardware channel), allowing fine-grained control of SFX playback.
- Supports the use of optional plugins via a plugin system. These plugins can either be used as control/communication mechanism to other code, or to alter sample data in real time. There are several plugins included and custom plugins are also supported.  
  The included plugins are:
  - *MixPluginRepeat()*
    - Plays the sample sample again after a given delay.
  - *MixPluginSync()*
    - Allows various ways to synchronise sample playback with the code that calls the mixer.
  - *MixPluginVolume()*
    - Allows changing of the playback volume of the sample being played.
  - *MixPluginPitch()*
    - Allows changing of the pitch of the sample being played.
- Supports the use of a callback routine whenever sample playback ends, to allow custom code to be executed on sample end. The callback routine can immediately play back another sample if desired, which allows for seamless sample-to-sample playback using this method.
- Supports playback of samples of any size that will fit in RAM\*.
- Sample rate used can be configured at assembly time, using standard Paula period values.
- Fully PC relative code is used to make relocation as easy as possible.
- Optionally supports using callbacks to handle IRQ and DMA registers, rather than the mixer doing so natively.

\*) in practice, this is limited by the largest maximum single block of free RAM that exists. A system with multiple memory expansions will be limited to a much smaller maximum sample size than the total RAM size would seem to indicate.

### Release Notes

Release notes for the Audio Mixer
#### v3.7.2
- (BUGFIX) MixerPlayFX channel determination fixed when MIXER_68020 is set

#### v3.7.1
- (BUGFIX) MixerPlayFX, MixerPlayChannelFX, MixerPlaySample and MixerPlayChannelSample now return the correct channel value in D0.
- (BUGFIX) MixerPlayFX, MixerPlayChannelFX, MixerPlaySample and MixerPlayChannelSample now store the rounded sample length back to the MXEffect structure.
- (BUGFIX) Tables used by MixPluginVolume have been corrected to take into account the non-signed nature of the register offset used.

#### v3.7
- (NEW) The mixer.h and plugins.h file now support Bartman GCC in addition to Bebbo and VBCC.
- (NEW) A new C based example has been added that showcases using the new external IRQ/DMA option to run the mixer using Amiga OS interrupt handlers. The example is called OSLegalExample.
- (NEW) A new example has been added that showcases the use of external IRQ/DMA callbacks to handle IRQ and DMA registers. The example is called ExternalIRQExample.
- (NEW) The mixer now optionally supports using callbacks to handle IRQ and DMA registers, rather than the mixer doing so natively. This option allows for, amongst other things, implementing an OS-legal interrupt server for the mixer, or implementing the mixer as part of another API.
  - This option is configured to be off by default, use MIXER_EXTERNAL_IRQ_DMA to enable it.
  - The callbacks can be set by calling MixerSetIRQDMACallbacks().
- (NEW) The mixer now supports calling a routine at the end of interrupt processing, to allow user code to execute actions as close to the mixer interrupt loop as possible. This option is configured to be off by default, use MIXER_ENABLE_RETURN_VECTOR to enable it.
  - The vector for this routine can be set by calling MixerSetReturnVector().
- (BUGFIX) Performance test now correctly uses 68020 routines for 68020 plugin tests.
- (BUGFIX) Fixed a potential issue with the include guard in mixer_config.i
- (MAINTENANCE) mixer.asm, mixer.i, mixer.h, plugins.asm, plugins.i. plugins.h are now kept in only one directory, their main ones. Any duplicates needed for building the examples are now temporarily placed in the example directories and cleaned updated afterwards.
- (MAINTENANCE) The makefile now uses batch based copy and delete operations where possible.
- (MAINTENANCE) The makefile is now platform agnostic and will work on both Windows based systems and Unix-like systems (including Linux, BSD & Mac OS X).

#### v3.6

- (NEW) The mixer now supports a high quality mixing mode, which does not require pre-processed samples, but rather uses standard 8-bit samples. Note that this mode uses significantly more CPU time.
- (NEW) The mixer now supports the use of plugin routines which will be called during sample playback. These routines can alter the data being played back, or work as synchronisation/control routines for timing and other purposes. There are several plugins provided by default. It is also possible to create custom plugins for use with the mixer.
  - The following plugins are provided:
   - MixPluginRepeat - repeats a sample after a given delay
   - MixPluginSync - sets a trigger when a given condition occurs
   - MixPluginVolume - changes the volume of the sample playing back
   - MixPluginPitch - changes the pitch of the sample playing back
- (NEW) The mixer now has the option of calling a callback function whenever a non-looping sample ends playing.
- (NEW) New loop mode added, MIX_FX_LOOP_OFFSET, which allows samples to loop from an offset into the sample rather than from the start of the sample.
- (NEW) Added function MixerGetChannelStatus(), which returns whether or not the given channel is in use by the mixer.
- (NEW) Added an optional counter of number of mixer interrupts that have executed since the counter started. Counter can be reset with *MixerResetCounter()* and read using *MixerGetCounter()*.
- (NEW) A new example has been added to show HQ mode. The example is named SingleMixerHQExample.
- (NEW) New examples have been added to show callback and plugin use. The examples are named CallbackExample and PluginExample.
- (NEW) The CMixerExample has been updated to also show callback and plugin use.
- (NEW) The PerformanceTest has been updated to also measure performance of callback and plugin use.
- (DEPRECATED) The routines *MixerPlaySample()* and *MixerPlayChannelSample()* are deprecated. They have been updated for 3.6 with the new loop offset mode, but will not support plugins or potential other changes in future versions of the mixer.
  - Replacement routines to use are *MixerPlayFX()* and *MixerPlayChannelFX()*.  
  - For compatibility with previous versions, the old functions will remain existing as is for the forseeable future.
- (MAINTENANCE) The source directories for all examples have been renamed to \<example\>Source and all binary examples now have a name ending in 'Example'.
- (MAINTENANCE) The MinimalMixer example now uses *MixerPlayFX()* instead of *MixerPlaySample()*
- (MAINTENANCE) The code for CMixerExample has been updates to use *MixerPlayFX()* instead of MixerPlaySample()
- (MAINTENANCE) The code for the various functions to play samples through the mixer has been adjusted so that most of the functionality is handled by one shared function to increase maintainability.
- (BUGFIX) The performance test tool now supports combined mixer routine sizes above 64KB.
- (BUGFIX) The performance test tool now no longer uses more sample space than needed.
- (BUGFIX) The performance test tool now uses samples of addequate length, no matter the selected period.
- (BUGFIX) The performance test tool now correctly runs 132 mixer interrupt executions per test, rather than 132 detected vblanks as the mixer interrupt could delay those and cause them to not be detected.
- (BUGFIX) The performance test tool now correctly uses the 68020 optimised interrupt handler when MIXER_68020 is set to 1
- (BUGFIX) The various functions added to return information (such as MixerGetBufferSize()) now always return a longword value.
- (BUGFIX) The functions *MixerPlaySample()*, *MixerPlayChannelSample()*, *MixerPlayFX()* and *MixerPlayChannelFX()* now correctly save and restore register D1 to the stack.
- (BUGFIX) If MIXER_WORDSIZED is set to 1, the mixer now correctly uses the 2nd word of mfx_length and mfx_loop_offset in the MXEffect structure.
- (BUGFIX) If MIXER_SIZEXBUF is set to 1, the mixer no longer skips the first frame of sample playback.
- (BUGFIX) If MIXER_68020 is set to 1, the mixer no longer selects channels above the mixer_sw_channels limit to play back samples on when using *MixerPlayFX()* or *MixerPlaySample()*.
- (BUGFIX) The linux/unix version of the makefile now has the correct commands for make install & make clean to work
- (BUGFIX) The mixer makefile will no longer give a "Could not find" error when using make clean.
- (BUGFIX) The mixer makefile will no longer give a "1 file copied" message when using make install.
- (BUGFIX) The HTML version of the documentation no longer contains any broken links.

#### v3.2

- (MAINTENANCE) updated mixer.h to be more compliant with the C standard.
- (BUGFIX) updated the way XREF and XDEF references are handled for compatibility with vasm 1.9d and other assemblers that don't support XREF's in the same file as the symbol definitions they reference.

#### v3.1

- initial release of the Audio Mixer project

### Requirements

There are three parts to the requirements for using the Audio Mixer. The first are the requirements for assembling (and optionally compiling) the Audio Mixer (plus examples & tools), the second are the requirements for running the mixer in a program. Both of these requirements are listed below. Lastly, there are the requirements for the examples and tools.

#### Requirements for assembling the mixer:

- A macro assembler & linker compatible with VASM style macro's and VASM style directives (preferably VASM/VLINK).
- The Amiga Native Development Kit (NDK). Version 1.3 or higher is required.
- A system with enough disk space and RAM to run the chosen assembler and linker for the project. (note: assembly has only been tested on a PC using cross assembly)
- Optional, but highly recommended: make

#### Optional requirements for compiling the included C programs:

- All requirements for assembling the mixer.
- A C compiler capable of generating Amiga OS executables for systems based on the 68000 series of processors.

If you require an assembler, linker or compiler to assemble/compile the provided source, VASM/VLINK and VBCC can be found here:

- VASM - <http://sun.hasenbraten.de/vasm/>
- VLINK - <http://sun.hasenbraten.de/vlink/>
- VBCC - <http://sun.hasenbraten.de/vbcc/>

Note that VBCC includes VASM/VLINK, as well as make and the Amiga NDK 3.9.

Also note that other assemblers, linkers and compilers should also be capable of assembling/compiling the provided source, though some changes to the makefile and/or assembler options might be needed.

#### Requirements for running the mixer:

- An Amiga\* with at least Kickstart 1.3 and some Chip Memory\*\*

#### Requirements for running the examples & tools:

- An Amiga\* with at least Kickstart 1.3, 512KB of Chip RAM and an additional 512KB of any RAM (Chip, Fast or Slow RAM).

Note that the Audio Mixer is designed for programs that disable the OS and directly access the custom chip set. The code is compatible with both 68000 and higher processors\*. Keep in mind that certain systems\*\*\* can have issues running code that disables the OS.

For reference, the mixer has successfully been tested on the following:

- WinUAE emulating various systems, all running in Cycle Exact mode  
  (not tested using JIT or "fastest possible" configurations)
- A500/A600 with 68000@7MHz and varying amounts of Chip/Slow/Fast RAM
- A600 with 68030@25MHz and 32MB of Fast RAM
- A1200 with 68020@14MHz
- A1200 with 68020@14MHz/8MB Fast RAM
- A1200 with 68030@50MHz/16MB Fast RAM

Further, the mixer has been reported to successfully work on:

- A500 with ACA+@42MHz
- Various 68030 based systems
- An A1200 with a TF1260 accelerator

\*) This should include emulators & FPGA systems, as long as these systems include accurate emulation/re-creation of the Amiga Chip Set, 68000 and certain Kickstart functionality. Compatibility with FPGA systems is not guaranteed.

\*\*) Exact required amount depends on the size of the samples and rest of the program. The mixer itself requires about 4-8KB of any RAM for code & variables and about 0.5-8KB of Chip RAM for mixing buffers (these values depends on the number of hardware channels configured and the chosen period value)

\*\*\*) In particular, Amiga systems that are highly expanded sometimes include expansions that are incompatible with software that takes over the system, such as network cards that rely on the NMI interrupt. On such systems, extra steps might be needed. Such as disabling the network prior to running the code or using a wrapper such as WHDLoad.

### Configuration

In order to reach high performance, the Audio Mixer needs to be configured at assembly time, rather than at runtime. This is done using the mixer_config.i file, which contains all but one of the configurable options for the mixer. Options in this file can't be changed at runtime. The only option that can be changed at runtime is the system's video type (PAL/NTSC).

The configuration consists of six sections. In the first section, the mixer type is selected. In the second, the playback mode is selected. In the third section, the mixer playback settings are selected. In the fourth section various optimisation settings can be enabled or disabled. The fifth section selects performance measurement options and the sixth section sets advanced options.

1.  #### Mixer type

    - The mixer can run in one of three ways. In the mixer type selection section, the desired playback type is selected. The three types are:

      - MIXER_SINGLE
      - MIXER_MULTI
      - MIXER_MULTI_PAIRED

      The first type, *MIXER_SINGLE*, uses a single hardware channel to play back mixer output on. It allows up to 4 samples to be mixed at the same time onto the selected channel.

      The second type, *MIXER_MULTI*, uses multiple hardware channels to play back mixer output on. Each of these hardware channels can have its own set of samples mixed onto it. In total, this mode allows up to four hardware channels to be selected, each of which can play back up to 4 samples mixed together (for a total of up to 16 samples played back at the same time).

      The third type, *MIXER_MULTI_PAIRED*, is similar to *MIXER_MULTI* in that it uses multiple hardware channels to play back mixer output on. However, unlike *MIXER_MULTI*, two of the four hardware channels are paired. The paired channels will always play back the same output from the mixer. The result is that the paired channel is effectively playing back on both the left and the right speaker at the same time, creating a centred output.

      In *MIXER_MULTI_PAIRED* type AUD2 and AUD3 are used to create the centred channel. As such both of these channels must always be selected. The other two hardware channels can optionally also be selected and will act as though running in *MIXER_MULTI type*.

      To select which type to use, change the desired equate to 1 and set the others to 0. For example, to set up for *MIXER_SINGLE* type, set up this section of the mixer_config.i file as follows:

      ```
      MIXER_SINGLE         EQU 1
      MIXER_MULTI          EQU 0
      MIXER_MULTI_PAIRED   EQU 0
      ```

2.  #### Mixer mode

    - The mixer supports two modes of playback. In the mixer mode selection section, the desired mode is selected.

      ```
      MIXER_HQ_MODE        EQU 0
      ```

      Setting the value for *MIXER_HQ_MODE* to 1 enables the high quality playback mode. This mode does not require pre-processed samples, but rather plays back standard 8-bit samples. Enabling this mode costs much more CPU time, but does allow higher quality playback.

3.  #### Mixer playback settings

    - In order to correctly play back samples, the mixer playback settings need to be configured. The values that need to be set up are:

      - mixer_output_channels
      - mixer_sw_channels
      - mixer_period
      - MIXER_PER_IS_NTSC

      *mixer_output_channels* configures which hardware channel(s) the mixer will use for output. When *MIXER_SINGLE* is set to 1, only one channel can be selected, otherwise multiple channels can be selected. Channel selection is done using the standard DMA flag indicators: DMAF_AUD0...DMAF_AUD3.

      Note that when *MIXER_MULTI_PAIRED* is set to 1, at least DMAF_AUD2 and DMAF_AUD3 must be selected.

      To select which channels to use, change the equate to the desired hardware channels, combining multiple channels using the or operator. For example:

      ```
      mixer_output_channels   EQU DMAF_AUD2|DMAF_AUD3
      ```

      *mixer_sw_channels* selects the maximum number of software mixed voices the mixer will use. This can be set at any value in the range of 1 to 4. Selecting fewer channels will reduce the maximum number of samples that can be mixed together. It will also lower CPU overhead of the mixer and will allow for samples with higher maximum / minimum amplitude values to be used (this in turn makes the samples sound less quiet/have a higher dynamic range).

      See ["Pre-processing samples"](#pre-processing-samples) for more information on the topic of maximum / minimum amplitude values.

      To select the number of software mixed voices, change the equate to the desired number. For example:

      ```
      mixer_sw_channels   EQU 4
      ```

      *mixer_period* sets the period value used by Paula for playing back the mixer output. The value is limited by the normal limits for Paula for 15KHz display modes. The supported range is 124\* to 65535. For completeness, a lower value corresponds to a higher sample rate.

      Selecting a lower period will increase mixer CPU overhead compared to a higher period. To select the period, change the equate to the desired period value. For example, to set the mixer to play back at ~11KHz set the value to:

      ```
      mixer_period   EQU 322
      ```

      \*) PAL limit. The NTSC limit is 123.

      *MIXER_PER_IS_NTSC* is a flag that can be set if the period value set in *mixer_period* assumes an NTSC system. This flag is separate from the runtime video system selection that can be provided during mixer setup. It is only used to determine in which direction the PAL/NTSC period value conversion should operate.

4.  #### Optimisation options

    - The mixer offers a variety of different optimisation options that can be set to improve the performance of the mixer (usually in exchange for one or more tradeoffs). Some of these options have a larger effect, some have a smaller effect and some only change the performance in certain edge cases.

      By default all these options are disabled. Unless otherwise noted, options can be combined for potentially greater gains. The available options are:

      - MIXER_68020
      - MIXER_WORDSIZED
      - MIXER_SIZEX32
      - MIXER_SIZEXBUF

      The option *MIXER_68020* can be set to 1 to change code generation to be optimised for 68020+ based systems. It improves performance on such systems, by making more effective use of the cache. Setting it also reduces object size and significantly reduces performance on 68000/68010 based systems.

      (note that the mixer will still run on 68000 based systems even when this option is set to 1).

      To enable the option, set the equate to 1:

      ```
      MIXER_68020   EQU 1
      ```

      NOTE: Setting this option to 1 disables \*all\* other optimisation options.

      The option *MIXER_WORDSIZED* can be set to 1 to limit the maximum sample size to be one unsigned word (64KB). If set to 0, sample length is limited to a signed long value (~2GB). Setting this option to 1 provides a small increase in performance by changing some operations to be word sized.

      To enable the option, set the equate to 1:

      ```
      MIXER_WORDSIZED   EQU 1
      ```

      The option *MIXER_SIZEX32* can be set to 1 to force the mixer to only process samples in blocks of 32 bytes. This can provide a small performance boost when playing several small looping samples at the same time. In normal use the performance increase is negligible.

      To enable the option, set the equate to 1:

      ```
      MIXER_SIZEX32   EQU 1
      ```

      NOTE: setting this option to 1 requires all samples to be a multiple of 32 bytes in length, rather than the standard 4 bytes.

      The option *MIXER_SIZEXBUF* can be set to 1 to force the mixer to only process samples in blocks of the *mixer_PAL_buffer_size* or *mixer_NTSC_buffer_size* (depending on which video system is selected at runtime. This value is calculated in mixer.i), which is to say in blocks of 1/50th or 1/60th of a second. Setting this option to 1 results in an increase in performance at the cost of sample size flexibility.

      To enable the option, set the equate to 1:

      ```
      MIXER_SIZEXBUF   EQU 1
      ```

      NOTE: setting this option to 1 requires all samples to be a multiple of *mixer_PAL_buffer_size* or *mixer_NTSC_buffer_size* in length (depending on the selected video system), rather than the standard 4 bytes.

5.  #### Performance measurement options

    - The mixer has several options to help programmers to measure the performance of the chosen settings. The available options are:

      - MIXER_TIMING_BARS
      - MIXER_DEFAULT_COLOUR
      - MIXER_CIA_TIMER
      - MIXER_CIA_KBOARD_RES
      - MIXER_COUNTER

      Setting *MIXER_TIMING_BARS* to 1 changes the behaviour of the mixer to show CPU time used by changing colour 0 to various different colours based on what the mixer is currently doing. This allows programmers to visualise the impact of the mixer on the system.

      The colours used are:

      - \$B0B (bright magenta) =\> Interrupt handler  
        This colour denotes the overhead for the interrupt handler, such as stack operations, interrupt acknowledgement and Paula register writes.
          
      - \$909 (magenta) =\> Channel update  
        This colour denotes the overhead for the selection of samples to be mixed during the current interrupt.
          
      - \$707 (dark magenta) =\> Mixing  
        This colour denotes the time spent on mixing the samples.
          
      - \$099 (cyan) =\> Other  
        This colour is used for mixer routines that are expected to be called frequently, but are not part of the interrupt handler. This includes the various routines to play back and/or stop samples.

      To enable this option, set the equate to 1:

      ```
      MIXER_TIMING_BARS   EQU 1
      ```

      The setting *MIXER_DEFAULT_COLOUR* changes which colour the mixer will use when it reaches the end of a routine or interrupt. Changing this allows for better integration with existing graphics.

      To select a colour, set the equate to the desired hexadecimal colour value:

      ```
      MIXER_DEFAULT_COLOUR   EQU $456
      ```

      Note that this option only has an effect if *MIXER_TIMING_BARS* is set to 1.

      Setting *MIXER_CIA_TIMER* to 1 enables the use of CIA-A timer A to measure performance of the mixer interrupt handler (which includes the mixing of samples). Note that for correct measuring of performance, it's recommended no higher priority\* interrupts are allowed to fire, otherwise the results will be skewed.

      \*) The mixer uses audio interrupts, which run at level 4. This means interrupts at level 5+ can interrupt the mixer and skew results of the measurements.

      The CIA timer will be used to generate several values (include via mixer.i):

      - *mixer_ticks_last*  
        This word will contain the number of CIA timer ticks the last mixer interrupt took to complete.
          
      - *mixer_ticks_best*  
        This word will contain the best (=lowest) number of CIA timer ticks the mixer interrupt took to complete since start. In most cases, this represents the time an idle interrupt takes (one where no sample is playing)
          
      - *mixer_ticks_worst*  
        This word will contain the worst (=highest) number of CIA timer ticks the mixer interrupt took since start.
          
      - *mixer_ticks_average*  
        This word is initially filled with 0, but can be updated by calling the routine *MixerCalcTicks()* (included from mixer.i). After this routine is called, this word will contain the average number of CIA timer ticks the mixer interrupt took over the last 128 frames.

      To enable this option, set the equate to 1:

      ```
      MIXER_CIA_TIMER   EQU 1
      ```

      NOTE: setting this option to 1 assumes CIA-A timer A is available for use.  
      NOTE: the routine *MixerCalcTicks()* and the values mixer_ticks_last/best/ worst/average are only available if this option is set to 1.
	  NOTE: this option should not be enabled if MIXER_EXTERNAL_IRQ_DMA is set with the goal of using Amiga OS interrupt handlers for the mixer interrupt.

      The option *MIXER_CIA_KBOARD_RES* is used to restore the keyboard for Amiga OS if *MIXER_CIA_TIMER* is set to one and *MixerRemoveHandler()* is called. If this option is not set, the CIA-A timer will merely be stopped. If this option is set, the CIA-A timer registers and control register A will be set such that the keyboard will function correctly in the OS.

      To correctly use this feature, call *MixerRemoveHandler()* as the last thing prior to re-enabling the OS.

      To enable this option, set the equate to 1:

      ```
      MIXER_CIA_KBOARD_RES   EQU 1
      ```

      NOTE: this option is only valid if *MIXER_CIA_TIMER* is set to one.  
      NOTE: if this option is not set, but *MIXER_CIA_TIMER* is set to one and the program returns to the OS, the keyboard may lose functionality (depending on the OS version and Amiga keyboard type).

      If the program never returns to the OS, or runs via WHDLoad, this setting is not required.

      The option *MIXER_COUNTER* can be used to enable a built in counter, which counts the number of mixer interrupts that has been executed. This can be useful, since mixer interrupts occur at roughly 1/50th or 1/60th of a second, but not quite once per frame. The counter maintained is word sized and can be accessed using the functions *MixerResetCounter()* and *MixerGetCounter()*

      To enable the counter, set the equate to 1:  

      ```
      MIXER_COUNTER          EQU 1
      ```

6.  #### Advanced options

    - The mixer provides three advanced settings which may be of use for some users. Options provided are:

      - MIXER_ENABLE_CALLBACK
      - MIXER_ENABLE_PLUGINS
	  - MIXER_ENABLE_RETURN_VECTOR
      - MIXER_SECTION
	  - MIXER_EXTERNAL_IRQ_DMA
	  - MIXER_EXTERNAL_BITWISE
	  - MIXER_EXTERNAL_RTE
      - MIXER_NO_ECHO
      - MIXER_C_DEFS

      The option *MIXER_ENABLE_CALLBACK* can be used to enable support for callback routines. Callback routines are automatically called whenever any sample ends playback naturally (but not when playback is stopped manually). Enabling this option has a small CPU overhead cost.

      The routines *MixerEnableCallback()* and *MixerDisableCallback()* are used to set and remove a callback function respectively. See the [Callback API](#callback-api) for more information about callback routines.

      To enable callback routine support, set the equate to 1:

      ```
      MIXER_ENABLE_CALLBACK   EQU 1
      ```

      The option *MIXER_ENABLE_PLUGINS* can be used to enable support for running plugins. Plugins are routines that are executed by the mixer whenever a mixer interrupt occurs and a sample with an attached plugin is being mixed. Plugin routines can be used to non-destructively alter sample contents to change what is played back, to play back new samples when certain situations occur and to communicate information (such as timing information) to code outside of the mixer. See the [Plugin API](#plugin-api) for more information.

      Enabling plugin support has a small CPU overhead cost. The plugin routines themselves can add significant CPU overhead if they non-destructively alter sample contents. Apart from built-in plugins, the system also supports custom plugins.

      To enable plugin support, set the equate to 1:

      ```
      MIXER_ENABLE_PLUGINS    EQU 1
      ```

      The option *MIXER_ENABLE_RETURN_VECTOR* can be used to enable calling a routine at the end of the mixer interrupt handler.
	  
	  Enabling return vector support has a small CPU overhead cost. In addition, the routine called will also add to the interrupt overhead.

      To enable return vector support, set the equate to 1:

      ```
      MIXER_ENABLE_RETURN_VECTOR    EQU 1
      ```

      The option *MIXER_SECTION* can be used to disable adding the mixer to section code,code. By default this option is set to 1 and the mixer is added to section code,code. If set to 0, the mixer is not added to any section.

      To enable this option, set the equate to 1:

      ```
      MIXER_SECTION   EQU 1
      ```

      NOTE: normally, this setting should not be changed. But in certain situations it can be useful to not utilise sections. In those cases, set the value to 0.


      The option *MIXER_EXTERNAL_IRQ_DMA* can be used to enable external handling of the INTENA, INTREQ and DMACON registers. In addition it also enables setting the interrupt handler vector. If this setting is enabled, these tasks will be given to callbacks the mixer will call when needed. Setting up these callbacks is done through the MixerSetIRQDMACallbacks() function. See the ["Mixer API"](#mixer-api) for more information.

      Enabling external IRQ and DMA support has a small CPU overhead cost.

      To enable external IRQ and DMA support, set the equate to 1:

      ```
      MIXER_EXTERNAL_IRQ_DMA    EQU 1
	  ```
	  
      The option *MIXER_EXTERNAL_BITWISE* can be used to enable the mixer IRQ & DMA callback support to only set one bit per callback. This option is only available if MIXER_EXTERNAL_IRQ_DMA is set to 1.

      Enabling bitwise operations has a small CPU overhead cost.

      To enable bitwise operations, set the equate to 1:

      ```
      MIXER_EXTERNAL_BITWISE    EQU 1
	  ```
	  
      The option *MIXER_EXTERNAL_RTE* can be used to change the behaviour of the MIXER_EXTERNAL_IRQ_DMA setting. Normally, this will cause the mixer interrupt to end in an RTS instruction. Setting this option to 1 changes that to be an RTE. This option is only available if MIXER_EXTERNAL_IRQ_DMA is set to 1.

      To enable external RTE support, set the equate to 1:

      ```
      MIXER_EXTERNAL_RTE    EQU 1
	  ```

      The option *MIXER_NO_ECHO* can be set to 1 to disable the use of the "echo" directive to display certain messages during assembly. Not all assemblers support the use of the "echo" directive and with this option such assemblers might still be usable.

      To enable this option, set the equate to 1:

      ```
      MIXER_NO_ECHO   EQU 1
      ```

      The option *MIXER_C_DEFS* can be set to 1 to enable C style function definition aliases. This allows C compilers to link the mixer.o file correctly. If disabled, these aliases are not created and linking mixer.o in C programs will likely fail.

      To enable this option, set the equate to 1:

      ```
      MIXER_C_DEFS            EQU 1
      ```

### Assembling/compiling the mixer, converter, examples & tools

The Audio Mixer consists of the mixer itself, an example sample conversion routine, plus examples and tools. All of these are provided in the form of the source code in 68000 assembly. The source code has been written for use with VASM/VLINK or assemblers/linkers that are compatible with VASM/VLINK directives. The Audio Mixer also comes with two C programs, one to show how integration with the assembly routines works and one tool to pre-process samples. The C source code has been compiled and tested using VBCC with an Amiga OS 1.3 target.

For convenience, the package is distributed with binary versions of the examples and tools. These binary versions have been made using the default configuration of 4 channel mixing (per hardware channel) and an 11KHz sample rate. No optimisation options have been enabled.

In order to assemble, compile and/or link the provided source code, a makefile has been supplied. Before using the makefile, four variables in the makefile must be configured. These variables are:

- INSTLOC  
  Set this variable to the directory you wish to install the examples and the mixer/converter objects to. The makefile will attempt to create this directory if it doesn't exist. It will do the same for one or more subdirectories in this directory.
    
- LIBS  
  Set this variable to the directory that contains the Amiga library from the Amiga NDK (v1.3+)
    
- SYSTEMDIR  
  Set this variable to the directory that contains the Amiga NDK (1.3+) assembly include files.
    
- COMPILE_C  
  Set this variable to 1 to enable compiling the C programs

This makefile has several different options:

- make  
  assembles all objects and links the examples/tools
    
- make install  
  assembles all objects and links the examples/tools. Also copies the result to the configured installation directory
    
- make mixer  
  assembles only the mixer & converter object files

Note that the makefile uses VASM & VLINK and assumes both are in the current path (as vasmm68k_mot and vlink respectively). Also note that the makefile uses VBCC as it's C compiler.

For those who wish to manually assemble/compile, make sure to keep in mind that the examples/tools have a variety of dependencies you'll have to also assemble. On top of the internal dependencies, the mixer, examples and tools also have the Amiga NDK (1.3+) as a dependency.

The order of linking for the assembly examples/tools should be PhotonsMiniWrapper.o first, everything else after that (this goes for each assembly language example/tool).

Assembling the mixer & converter object files should be simpler as the list of dependencies is limited to the NDK (1.3+) and the files in the mixer or converter directory itself.

When assembling (parts) of the mixer code manually, it's important to note that various files require a specific symbol to be set when assembling them. This symbol should not be set when assembling different files. The full list of symbols and what file needs which symbol can be found in the makefile.

Setting these symbols can normally be done as a (command line) option for the assembler.

As an example, assembling mixer.asm requires the symbol BUILD_MIXER to be set. If VASM is being used, this is done by specifying -DBUILD_MIXER as one of the command line parameters. For reference, the full VASM command line used to build the mixer object file is as follows:

```
vasmm68k_mot -nowarn=62 -kick1hunks -Fhunk -m68000 -allmp -I. -IC:\Development\AmigaDev\NDK13\INCLUDES1.3\INCLUDE.I -I.\Mixer -DBUILD_MIXER .\Mixer\mixer.asm -o .\Mixer\mixer.o
```

The supplied makefile has been created for use under Windows. A version for systems using UNIX style commands and directories is also supplied, as makefile_unix.mak.

### Pre-processing samples

The mixer requires pre-processed samples in order to play back mixed sound correctly\*. The pre-processing consists of two steps: making sure the samples are of the correct length to be mixed and making sure the sample data does not exceed minimum/maximum values for the number of samples to be mixed at the same time.

\*) when the mixer is run in the high quality mode, sample pre-processing is limited to merely making sure the samples meet the length requirements. No limits on sample data values exist. In this case, step "Sample data minimum/maximum values" of the steps below can be skipped.

A detailed description of both steps follows.

1.  #### Sample length requirements

    The mixer will always process samples in a multiple of a minimum number of bytes. The consequence of this is that samples provided to the mixer must also be a multiple of that minimum number of bytes in length. The minimum length multiple required depends on the configuration as set up in mixer_config.i.

    - If no optimisation options are enabled, samples must be a multiple of 4 bytes in length.
    - If *MIXER_68020* is set to 1, samples must be a multiple of 4 bytes in length. Setting *MIXER_68020* to 1 overrides all other optimisation flags, so this value will not change depending on other set flags.
    - If *MIXER_SIZEX32* is set to 1, samples must be a multiple of 32 bytes in length.
    - If *MIXER_SIZEXBUF* is set to 1, samples must be a multiple of either *mixer_PAL_buffer_size* or *mixer_NTSC_buffer_size* in length, depending on the video system selected during *MixerSetup()*.
    - *MIXER_SIZEX32* and *MIXER_SIZEXBUF* can be selected at the same time, in which case both limitations apply (i.e. the *mixer_PAL_buffer_size* / *mixer_NTSC_buffer_size* must now also be a multiple of 32 bytes).

    The mixer offers a routine (*MixerGetSampleMinSize()*) to get the minimum number of bytes that samples must be a multiple in length of.

    The easiest way to make sure samples are of the correct length is to pad them with zeroes to the required minimum multiple length. Note that this will work even in the case of *MIX_SIZEXBUF* and supporting both PAL and NTSC, as *mixer_PAL_buffer_size* will always be larger than *mixer_NTSC_buffer_size* for any possible configuration.

    This means that the easiest way to deal with *MIXER_SIZEXBUF* in a program that supports both PAL and NTSC is to pad the samples with zeroes to a multiple of *mixer_PAL_buffer_size*.

2.  #### Sample data minimum/maximum values

    For performance reason, the mixer does no range or overflow checking on any samples it adds. This means that samples that are not limited to a certain range of values can create over/underflows. These over/underflows create very audible and very ugly distortions of sound. To prevent this, the mixer requires all sample data points to be kept in a range that allows them to be added together under all circumstances without generating over/ underflow.

    The limits are based directly on the maximum number of samples mixed together (as set in mixer_config.i):

    - if *mixer_sw_channels*=1, the range is -128 to +127 (sample bytes/1)
    - if *mixer_sw_channels*=2, the range is -64 to +63 (sample bytes/2)
    - if *mixer_sw_channels*=3, the range is -43 to +42 (sample bytes/3)
    - if *mixer_sw_channels*=4, the range is -32 to +32 (sample bytes/4)

    All samples used by the mixer should only have data points in the value ranges given above. It should be pointed out that this pre-processing will have an effect on the volume of the samples played back. The higher the number of channels that can be mixed, the quieter the samples will sound.

    It is highly recommended to keep this in mind for both the samples to be used and any/all music that will be played alongside the samples played back using the mixer. Choosing the correct HW volume for any module playing back is an important part of making the mixer output sound best.

    For more information on how to get good quality samples for use with the mixer, see ["Best practices for source samples"](#best-practices-for-source-samples).

The mixer provides both a tool (SampleConverter) and an assembly routine (*ConvertSampleDivide()*) to aid in pre-processing samples. Both of these are also described in the documentation. See ["Tools"](#tools) and ["Converter API"](#converter-api) for more details.

Note that using these specific options is not required, it's certainly possible to create a separate converter (for example one that does bulk conversion) for this purpose, or to generate the initial samples such that they already conform to the requirements.

Indeed, the assembly routine provided is quite slow due to the byte-by-byte lookup that it needs to do for the conversion, so pre-processing samples at or before assembly/compile time is recommended for projects that include many samples.

### Using the mixer

After configuring and assembling the mixer, the resulting object file (mixer.o) can be linked into other programs to provide the mixer API (as described in ["Mixer API"](#mixer-api)).

In order to use the mixer, several steps need to be taken. A basic example follows (in Assembly and C). The example assumes *MIXER_SINGLE* is set to 1 and callback routines & plugins are disabled (*MIXER_ENABLE_CALLBACK* & *MIXER_ENABLE_PLUGINS* are both set to 0).

Note: while initially setting up the mixer, it can be useful to set *MIXER_TIMING_BARS* to 1 in mixer_config.i to have a visual representation of the mixer working (or not working if something went wrong).

1.  #### Allocate/reserve a block of Chip RAM

    This block has to be equal in size to the value of *mixer_buffer_size* as found in mixer.i\*.

    \*) the mixer provides the support routine *MixerGetBufferSize()* to get the correct size if using mixer.i is not desired. *MixerGetBufferSize()* returns the correct size in D0.

           Assembly:                                C:
           move.l   #mixer_buffer_size,d0           size = MixerGetBufferSize();
           ; allocate memory using the above size   /* allocate memory here */
           ; alternatively, use a block of memory
           ; defined in a Chip RAM section of this
           ; size.

2.  #### Set up the mixer

    This is done by calling the routine *MixerSetup()*, with the current video system and the block of allocated Chip RAM from step one as parameters.

           Assembly:                                C:
           ; Pointer to Chip RAM block in A0        /* buffer points to Chip RAM
           moveq   #MIX_PAL,d0                         block */
           bsr     MixerSetup                       MixerSetup(buffer, NULL, NULL, MIX_PAL, 0);

3.  #### Start the interrupt handler

    This is done by calling the routine *MixerInstallHandler()*. This routine requires the value of the Vector Base Register (VBR)\* and a flag that tells the routine whether or not to save the pre-existing interrupt vectors to be able to restore them later when the handler is removed.

    Note that the value of the flag to save the vectors is 0 and to not save the vectors is 1.

    \*) this is always 0 on 68000 based systems, but on systems with a 68010 or higher this value can be different (this is especially true on systems with a 68030+, which usually remap the VBR to Fast RAM for improved performance).

           Assembly:                                C:
           ; VBR value in A0                        /* VBR value in vbr */
           moveq   #0,d0                            MixerInstallHandler(vbr, 0);
           bsr     MixerInstallHandler

4.  #### Start the mixer

    This is done by calling the routine *MixerStart()*

           Assembly:                                C:
           bsr      MixerStart                      MixerStart();

5.  #### The mixer is now running, SFX can now be played back using one of the playback routines

    These routines include *MixerPlayFX()*. To use *MixerPlayFX()* as an example, this routine has 2 parameters:

    1.  Pointer to an instance of the MXEffect structure in A0
    2.  The hardware channel to use in D0, or 0 if mixer_config.i has *MIXER_SINGLE* set to 1.

    The MXEffect structure needs to have the following members filled for basic sample playback:

    - mfx_length  
      The length of the sample to play
    - mfx_sample_ptr  
      Pointer to the (pre-processed) sample to play
    - mfx_loop  
      The loop indicator. Either *MIX_FX_ONCE* to play back a sample once, *MIX_FX_LOOP* to play back a sample in a loop forever or *MIX_FX_LOOP_OFFSET* to play back a sample looping back to a given loop offset forever.
    - mfx_priority  
      The priority of the sample - higher priority samples can overwrite already playing lower priority samples if needed.
    - mfx_loop_offset  
      Set to the desired offset into the sample when *MIX_FX_LOOP_OFFSET* is used, leave 0 otherwise.
    - mfx_plugin_ptr leave at 0 (NULL for C programs)

    *MixerPlayFX()* returns the mixer channel used in D0, or -1 if no free channel can be found.

           Assembly:
           lea.l   effect_struct,a0               ; Assumed to be a block of memory
                                                  ; mfx_SIZEOF bytes in length.
           move.l  #sample_length,mfx_length(a0)
           move.l  sample,mfx_sample_ptr(a0)
           move.w  #MIX_FX_ONCE,mfx_loop(a0)
           move.w  #1,mfx_priority(a0)
           clr.l   mfx_loop_offset(a0)
           clr.l   mfx_plugin_ptr(a0)
           moveq   #0,d0                          ; Channel can be left 0 when using
                                                  ; MIXER_SINGLE
           
           C:
           MXEffect effect_struct;

           effect_struct.mfx_length = sample_length;
           effect_struct.mfx_sample_ptr = sample;
           effect_struct.mfx_loop = MIX_FX_ONCE;
           effect_struct.mfx_priority = 1;
           effect_struct.mfx_loop_offset = 0;
           effect_struct.mfx_plugin_ptr = NULL;

           MixerPlayFX(&effect_struct, 0); /* Channel can be left 0 when using 
                                              MIXER_SINGLE */

6.  #### If desired, sample playback on a channel can be stopped

    This is done by calling the *MixerStopFx()* routine. This routine has one argument, a channel mask. The channel mask combines the hardware channel (or 0 if *MIXER_SINGLE* is set to 1) and the mixer channel as returned by *MixerPlaySample()* into a single value. Samples playing back on this combination of channels will be stopped.

           Assembly:                                C:
           ; MIXER_SINGLE=1, so no HW channel       /* MIXER_SINGLE=1, so no HW
           ; is needed.                                channel is needed */
           move.w   #MIX_CH0,d0                     MixerStopFX(MIX_CH0);
           bsr      MixerStopFX

    For more information about mixer channels vs hardware channels, see ["Mixer API"](#mixer-api). For more information about using the mixer in C programs, see ["Using the mixer in C programs"](#using-the-mixer-in-c-programs).

7.  #### To stop the mixer (and all playback on it)

    Call the routine *MixerStop()*.

           Assembly:                                C:
           bsr      MixerStop                       MixerStop();

8.  #### At the end of the program, or once no more mixing is required

    Call the routine *MixerRemoveHandler()*. This will remove the interrupt handler and optionally restore the old interrupt vectors (if the flag to do so was set to 0 when calling *MixerInstallHandler()*)

           Assembly:                                C:
           bsr      MixerRemoveHandler              MixerRemoveHandler();

For more information on using the various mixer routines, see ["Mixer API"](#mixer-api) For more information of integrating the mixer in C programs, see ["Using the mixer in C programs"](#using-the-mixer-in-c-programs).

### Combining the mixer and a music player

It's possible to combine the mixer with an existing music player, such as the PTPlayer 6.3\* from Frank Wille or the LSP player from Arnaud Carré. Other music players could also be compatible, depending on how the player deals with channels on which no music is played.

\*) Note that only version 6.3+ will work, version 6.2 and below miss a patch designed to block channels correctly for use with the mixer.

Version 6.3 was released to Aminet on 26-03-2023 and can be found here: <https://aminet.net/package/mus/play/ptplayer>

In order to combine the mixer with a music player, the music player can't touch any of the hardware registers of any of the channels configured to be used by the mixer. For example, if mixer_config.i has *mixer_output_channels* set to DMAF_AUD2, then the music player can't touch AUD2 in any way while the mixer is running. This includes the audio interrupt for this channel, which also can't be used.

This requires two things: a music track that omits the channel(s) as configured in mixer_config.i and a music player that doesn't touch channels that aren't in use.

The first is a matter of composition, the second needs to be supported by the player itself. Some players support this directly (by not touching unused channels), some support this indirectly (for instance, by having a function that disables one or more channels from being used). If the selected player does not natively support channels being disabled, it's sometimes possible to patch the player by looking through it for instances of the audio registers for the selected channel(s) being used and removing them from the code.

If both of these are taken care of, what remains is activating the mixer and music player in the correct order. Generally speaking, the music player should be started first, the mixer second\*. Depending on the music player, one or more frames may have to be waited before the mixer can be successfully started.

\*) this is because many music players initialise all audio channels when they start, even if the channels are empty or disabled.

One thing to keep in mind is that some music players trash some of the registers used when setting them up, so be sure to initialise the registers used by the mixer routines correctly prior to calling any of them.

The mixer contains an example using Frank Wille's PTPlayer that shows how to make use of it and the mixer together. This is the SingleMixer example. See ["Examples"](#examples) for more information.

#### For PTPlayer 6.3, the way to set it up is as follows:

1.  initialise PTPlayer as normal
2.  call the routine *\_mt_channelmask()* with the correct channel mask in D0
3.  set up the mixer as described in ["Using the mixer"](#using-the-mixer)
4.  both the mixer and PTPlayer should now work, allowing music and sound effects at the same time. Note that SFX playback should be done exclusively through the mixer, not using the built in SFX abilities of PTPlayer.

The SingleMixer example also shows how to integrate LSP.

#### For LSP, the way to set it up is as follows:

1.  initialise the LSP CIA player as normal (don't forget to enable the CIA interrupt as in the LSP example)
2.  set up the mixer as described in ["Using the mixer"](#using-the-mixer)
3.  both the mixer and LSP should now work, allowing music and sound effects at the same time.

For other music players, try initialising the music player first, then the mixer. If this does not work, look in the documentation of the music player for ways to disable playback on one or more channels and use that. If that also does not work, it may be required to patch the music player to not touch the channel(s) reserved for mixing.

In all cases, the music track(s) used should not use the channel(s) reserved for mixing to play back audio. Other things (i.e. commands such as pattern jumps) should still work.

### Examples

The mixer comes with a number of example programs which show the abilities of the mixer as well as giving working examples of how to use the mixer. The following examples are provided:

- #### MinimalMixerExample

  An example program with a minimum of extra features or support code. The purpose of the example is to show a simple case of using the mixer. Note that this example does not disable the OS, assumes the VBR is at address 0 and that the code is running on a PAL Amiga.

- #### SingleMixerExample

  An example program showing the abilities of the mixer when *MIXER_SINGLE* is set to 1. The example program shows both non-looping and looping samples and has two different music players built in (PTPlayer by Frank Wille and LSP by Arnaud Carré) which can be selected or disabled.

  The example also shows the ability to select an internal mixer channel for SFX and the ability to stop SFX playback for any/all of the internal mixer channels on demand.

  This program disables the OS, automatically selects between PAL and NTSC and uses the VBR register to set up the interrupt.

  Note that switching the music on or off, or switching between the two music players will cause the mixer to stop playback of any playing samples due to the required reset of the interrupt handler.

- #### SingleMixerHQExample

  An example program showing the abilities of the mixer when *MIXER_SINGLE* is set to 1 and *MIXER_HQ_MODE* is also set to 1.

  It has the same options and functionality as the SingleMixerExample, but uses the High Quality mixing mode for higher quality sample playback.

- #### MultiMixerExample

  An example program that shows the ability of the mixer to run on multiple hardware channels. This example allows mixing of up to 16 samples at the same time and uses all four hardware channels to be able to do this.

  The example allows you to pick a hardware channel and internal mixer channel to play SFX on. SFX can be both non-looping or looping. SFX can be stopped when desired.

  This program disables the OS, automatically selects between PAL and NTSC and uses the VBR register to set up the interrupt. It does not contain music playback.

- #### MultiPairedMixerExample

  An example program that shows the ability of the mixer to create a paired channel which allows for seamless centred SFX to be played back. The example allows you to pick a hardware channel (AUD2 is paired with AUD3) and an internal mixer channel to play SFX on. SFX can be both non-looping or looping. SFX can be stopped when desired.

  This program disables the OS, automatically selects between PAL and NTSC and uses the VBR register to set up the interrupt. It does not contain music playback.

- #### CallbackExample

  An example program that shows the ability of the mixer to use callback routines. The example runs with *MIXER_SINGLE* set to 1 and allows you to pick an internal mixer channel to play SFX on and set whether or not to loop the SFX. It also allows you to select whether or not to use a callback routine.

- #### PluginExample

  An example program that shows the ability of the mixer to use plugins. The example runs with *MIXER_SINGLE* set to 1 and allows you to pick an internal mixer channel to play SFX on and set whether or not to loop the SFX.

  It also allows you to select a plugin to use. You can select no plugin, an example custom plugin that replaces the sample played back by a simple sine wave, the built-in repeat plugin, the built-in synchronisation plugin, the built-in volume plugin and the built-in pitch change plugin.

- #### ExternalIRQExample

  An example program with external IRQ/DMA handling enabled and a minimum of extra features or support code. The purpose of the example is to show a simple case of using external IRQ/DMA handling with the mixer. Note that this example does not disable the OS, assumes the VBR is at address 0 and that the code is running on a PAL Amiga.

- #### CMixerExample

  An example program that shows the ability of the mixer to be integrated in C programs. Like the MinimalMixerExample, the example is kept as simple as possible. Note that this example does not disable the OS, assumes the VBR is at address 0 and that the code is running on a PAL Amiga.

  Unlike the MinimalMixerExample however, it also shows the use of plugins and callback routines. The plugin used to showcase plugin use is the pitch change plugin.

- #### OSLegalExample

  An example program in C that shows how to use the mixer in an OS legal way.

### Tools

Alongside the mixer, two tools have been included. These tools are:

- #### PerformanceTest

  A tool to measure the performance of a given mixer configuration. This tool shows a detailed set of performance figures for all the various optimisation flags (as well as no optimisations enabled). It also shows results for the high quality mode, callback routines and the use of the various built-in plugins. In total, it runs 48 performance tests and displays the results. Results pages can can be switched with the right mouse button. There are four pages: default/non-HQ tests in CIA ticks, default/non-HQ tests as a CPU use percentage, HQ/callback/plugin tests in CIA ticks and HQ/callback/plugins as a CPU use percentage.

  To use the PerformanceTest, change the mixer_config.i found in the Mixer subdirectory of the PerformanceTestSource directory and assemble the PerformanceTest program using make. Then run the resulting PerformanceTest executable on the Amiga environment you wish to check the performance results for.

  Note that the PerformanceTest uses a changed version of the mixer, with its own mixer_config.i/mixer.i and mixer.asm. The core routines are identical, but the PerformanceTest variant has been changed to enable multiple different versions of the mixer code (with different performance flags enabled or disabled) to co-exist at the same time.

  The mixer_config.i is similarly changed to only include those parts which are needed to be configured for testing the performance being included.

  This program disables the OS, automatically selects between PAL and NTSC and uses the VBR register to set up the interrupt. It does not contain music playback. While no sound will be heard, the PerformanceTest program does mix and play back sample data via Paula. However, the volume is set to zero and therefore it results in no sound being heard.

- #### SampleConverter

  A tool written in standard C to convert samples to the correct limits for use with the mixer, as described in ["Pre-processing samples"](#pre-processing-samples). The included binary (and makefile instructions) is for Amiga systems, but the code only required the C standard libraries and thus should be easily recompilable on other target systems.

  Usage:

      SampleConverter <number of software channels> <input file> <output file>

  Where the number of software channels is the value given for *mixer_sw_channels* in mixer_config.i, input is the sample input file name and output file is the output file name. Note that SampleConverter expects 8 bit signed raw sample data as input and will likewise output this format.

  The output file is padded with zeroes to the nearest multiple of four bytes if required. If the output is to be used with a mixer configuration where *MIXER_SIZEX32* or *MIXER_SIZEXBUF* is set, the sample will still need to be padded with zeroes to a multiple of either 32 bytes or *mixer_PAL_buffer_size* bytes after the conversion.

  Note that this conversion process is only strictly needed for the standard mixing mode, the high quality mode can play back normal 8-bit samples. However, it can still be useful to run the SampleConverter with the number of software channels set to 1 as a convenient way to pad the samples to a multiple of 4 bytes (which is still required for the high quality mode).

### API Changes between version 3.1/3.2 and 3.7

Version 3.7 of the mixer makes several changes to the existing API. These changes are summarised in this section. For more detailed information, see [Mixer API](#mixer-api), [Callback API](#callback-api), [Plugin API](#plugin-api) and [Performance Measuring API](#performance-measuring-api).

#### New API's

There are new API's for callbacks and plugins (see [Callback API](#callback-api) and [Plugin API](#plugin-api))

#### Constants

There are several new constants and variables defined in mixer.i/mixer.h:

- MIX_FX_LOOP_OFFSET
- MIX_CH_FREE
- MIX_CH_BUSY
- MIX_PLUGIN_STD (part of the Plugin API)
- MIX_PLUGIN_NODATA (part of the Plugin API)
- mixer_plugin_buffer_size (part of the Plugin API)

#### Type definitions

There are some changes surrounding the type definitions in mixer.i/mixer.h:

- The definition of MXEffect has changed
- There is a new type, MXPlugin (part of the Plugin API)

#### Functions

Several existing functions have their parameters changed:

- *MixerSetup()*
- *MixerPlaySample()*
- *MixerPlayChannelSample()*

Several existing functions have been deprecated and are provided solely for backwards compatibility:

- *MixerPlaySample()*
- *MixerPlayChannelSample*()

Note: these functions will no longer be updated with new features for new versions after 3.6. They do not support the use of plugins.

There are several new functions:

- *MixerGetChannelStatus()*
- *MixerGetTotalChannelCount()*
- *MixerGetChannelBufferSize()*
- *MixerEnableCallback()* (part of the Callback API)
- *MixerDisableCallback()* (part of the Callback API)
- *MixerGetPluginsBufferSize()* (part of the Plugin API)
- *MixerSetPluginDeferredPtr()* (part of the Plugin API)
- *MixerResetCounter()* (part of the Performance Measuring API)
- *MixerGetCounter()* (part of the Performance Measuring API)

There are several new plugins:

- *MixPluginRepeat()* (part of the Plugin API)
- *MixPluginSync()* (part of the Plugin API)
- *MixPluginPitch()* (part of the Plugin API)
- *MixPluginVolume()* (part of the Plugin API)

### Mixer API

The mixer provides several routines, constants and variables\* to enable mixing samples\*\*. It also makes use of several elements of the Amiga NDK (1.3+) for convenience and clarity.

In particular, it makes use of the exec_types.i include file to have a set of standard data types and a standardized way to define structures in assembly. It also makes use of several constants provided by the Amiga NDK.

\*) Note that only routines/constants/variables used to play back samples using the mixer will be documented. There are internal routines, constants and variables that are not needed to play back samples and these are not documented.

\*\*) Note that samples played back by the mixer can be stored in any type of RAM (not just Chip RAM). Also note that samples played back by the mixer must be pre-processed as described in ["Pre-processing samples"](#pre-processing-samples).

For 68020+ based systems, it's recommended to store samples on 4 byte boundaries to get optimal performance.

#### NDK constants used follow:

- DMAF_AUD0 / DMAF_AUD1 / DMAF_AUD2 / DMAF_AUD3  
  These four constants refer to the four hardware audio channels the Amiga sound chip, Paula, provides. They are used by various mixer routines as well as mixer_config.i to identify the destination hardware channel(s) to be used for mixed output.

  Note that mixer routines that require a hardware channel only require one of these if the mixer is running with *MIXER_MULTI* or *MIXER_MULTI_PAIRED* set to 1. If *MIXER_SINGLE* is set instead, mixer routines that require a hardware channel simply ignore the hardware channel set.

#### Constant info follows:

- MIX_PAL / MIX_NTSC  
  These two constants are used to indicate whether the mixer should run in PAL or NTSC mode when calling *MixerSetup()*. The difference between these two modes is a very small change in the period value used and a change in the size of number of bytes the mixer processes. If the mixer is set to run in PAL mode, it will mix enough bytes to fill 1/50th of a second per interrupt. If it is set to run in NTSC bytes, the mixer will instead mix enough bytes to fill 1/60th of a second per interrupt.

  Effectively, this changes the frequency of the interrupts to 1/50th or 1/60th of a second.

- MIX_FX_ONCE / MIX_FX_LOOP / MIX_FX_LOOP_OFFSET  
  These three constants are used to indicate whether a sample should be played back once by the mixer, or be played back in a loop. They are used by various mixer routines that play back samples.

  - MIX_FX_ONCE  
    play back the sample once
  - MIX_FX_LOOP  
    play back the sample in a loop, restarting at the beginning of the sample
  - MIX_FX_LOOP_OFFSET  
    play back the sample in a loop, restarting at the given offset into the sample, rather than at the beginning

  Note: none of these constants has the value zero.

- MIX_CH0 / MIX_CH1 / MIX_CH2 / MIX_CH3  
  These four constants are used to indicate which internal mixer channel should be used when calling routines that allow choosing an internal mixer channel. Routines that do not allow this choice will select an internal channel automatically using priority and age.

  Each hardware channel the mixer is configured to use in mixer_config.i has between 1 and 4 internal mixer channels associated with it. How many of these internal channels are available depends on the value of *mixer_sw_channels* in mixer_config.i.

  When using a routine that allows choosing an internal mixer channel, these values select which of the internal channels to use. This is useful to have more control over what samples are being played. Note that when selecting an internal channel, priority still applies - a lower priority sample will not overwrite a higher priority one.

- MIX_CH_FREE / MIX_CH_BUSY  
  These two constants are used by MixerGetChannelStatus() to indicate whether a given internal mixer channel is free, or busy playing back a sample.

#### Variable info follows:

- mixer_buffer_size  
  This variable contains the calculated total size of the Chip RAM buffer that needs to be passed to *MixerSetup()* for use by the mixer. For optimal performance on 68020+ systems, this buffer should be aligned on a four byte boundary.

  Note that this value is not identical to either *mixer_PAL_buffer_size* or *mixer_NTSC_buffer_size*, which should not be used to determine the size of the Chip RAM buffer.

  See also *MixerGetBufferSize()*

- mixer_PAL_buffer_size  
  This variable contains the calculated size needed by the mixer to play back 1/50th of a second of sample data. It's mostly useful to determine the amount of bytes to pad samples with in case *MIXER_SIZEXBUF* is set.

  See also *MixerGetSampleMinSize()*

- mixer_NTSC_buffer_size  
  This variable contains the calculated size needed by the mixer to play back 1/60th of a second of sample data. It's mostly useful to determine the amount of bytes to pad samples with in case *MIXER_SIZEXBUF* is set if the mixer is expected to never run in PAL mode.

  See also *MixerGetSampleMinSize()*

#### Structure info follows:

- MXEffect  
  This structure defines a sample to be played back by the mixer. It is used by routines that expect a pointer to the effect structure rather than individually set registers.

  The structure elements are as follows:

  - mfx_length  
    Length of the sample in bytes (signed long unless *MIXER_WORDSIZED* is set to 1 in mixer_config.i, in which case the length is an unsigned word)

  - mfx_sample_ptr  
    Pointer to the pre-processed sample to play

  - mfx_loop  
    Either *MIX_FX_ONCE* to play back the sample once, *MIX_FX_LOOP* to play the sample on a loop or *MIX_FX_LOOP_OFFSET* to play the sample on a loop that restarts at the given *mfx_loop_offset*.

  - mfx_priority  
    Signed priority value, higher priority samples can overwrite lower priority samples.

    Note that looping samples (once playing) can never be overwritten.

  - mfx_loop_offset  
    Offset into the sample at which it will restart playback if the loop mode is set to *MIX_FX_LOOP_OFFSET*.

  - mfx_plugin_ptr  
    The value set here is only used if *MIXER_ENABLE_PLUGINS* is set to 1.

    Set to 0 (NULL) if no plugin is to be used for this sample, or set to a pointer to an instance of MXPlugin if a plugin is to be used.

    See [Plugin API](#plugin-api) for more information.

  - mfx_SIZEOF  
    Gives the length of the structure in bytes

- MXIRQDMACallbacks
  This structure is only available if *MIXER_EXTERNAL_IRQ_DMA* is set to 1 and is used by the function
  MixerSetIRQDMACallbacks() to set the callback function pointers it requires.

  The structure elements are as follows:

  - mxicb_set_irq_vector 
    Function pointer to routine that sets the IRQ vector for audio interrupts. 
    This function has a parameter:

    - A0 = vector to mixer interrupt handler

    Note: the mixer interrupt handler will return using RTS rather
          than RTE when using external IRQ/DMA callbacks. This
          behaviour can be overridden by setting 
          MIXER_EXTERNAL_RTE to 1, in which case the interrupt
          handler will exit using RTE.
  - mxicb_remove_irq_vector
    Function pointer to routine that removes the IRQ vector for audio interrupts.

    Note: if MIXER_EXTERNAL_BITWISE is set to 1, this routine is 
          also responsible for resetting INTENA to the value it 
          had prior to calling MixerInstallHandler(), if this is
          desired.
          When MIXER_EXTERNAL_BITWISE is set to 0, this is done by
          the mixer automatically
  - mxicb_set_irq_bits
    Function pointer to routine that sets the correct bits in INTENA to enable audio interrupts for the mixer.

    This function has a parameter:
    - D0 = INTENA bits to set

    Note: if MIXER_EXTERNAL_BITWISE is set to 1, the relevant bits
          are passed as individual INTENA values, where the 
          set/clear bit is set as appropriate
  - mxicb_disable_irq
    Function pointer to routine that disables audio interrupts

    This function has a parameter:
    - D0 = INTENA bits to disable

    Note: if MIXER_EXTERNAL_BITWISE is set to 1, the relevant bits
          are passed as individual INTENA values, where the
          set/clear bit is set as appropriate
    Note: this is a separate routine from mxicb_set_irq_bits
          because disabling interrupts should also make sure to
          reset the corresponding bits in INTREQ
  - mxicb_acknowledge_irq
    Function pointer to routine that acknowledges audio interrupt.

    This function has a parameter:
    - D0 = INTREQ value

    Note: this will always pass the INTREQ value for a single
          channel.
  - mxicb_set_dmacon
    Function pointer to routine that enables audio DMA.

    This function has a parameter:
    - D0 = DMACON value

    Note: if MIXER_EXTERNAL_BITWISE is set to 1, the relevant bits
          are passed as individual DMACON values, where the
          set/clear bit is set as appropriate

#### Routine info follows:

*MixerSetup(A0=buffer, A1=plugin_buffer, A2=plugin_data, D0=video_system.w, D1=plugin_data_length.w)*  
This routine prepares the mixer structure for use by the mixing routines and sets mixer playback volume to the maximum hardware volume of 64. The routine must be called prior to any other mixing routines. The routine has two parameters:

- A0 - must point to a block of memory in Chip RAM at least *mixer_buffer_size* bytes in size.  
  Note: on 68020+ systems, it is advisable to align the Chip RAM buffer to a 4 byte boundary for optimal performance.

- D0 - must contain either *MIX_PAL* if running on a PAL system, or *MIX_NTSC* when running on a NTSC system. If the video system is unknown, set D0 to *MIX_PAL*.

  If MIXER_ENABLE_PLUGINS is set to one, A1, A2 and D1 also need to be set. If not, they can be omitted / left to 0.

- A1 - must point to a block of memory (any RAM type) at least *mixer_plugin_buffer_size bytes in size.*  
  Note: on 68020+ systems, it is advisable to align this buffer to a 4 byte boundary for optimal performance.

- A2 - must point to a block of memory sized the maximum size of any of any plugin data entry (see D1 for more details) multiplied by mixer_total_channels from mixer.i.  
  Note: on 68020+ systems, it is advisable to align this buffer to a 4 byte boundary for optimal performance.

- D1 - must be set to the maximum size of any of the possible plugin data structures. If no custom plugins are used, this size is equal to the value of mxplg_max_data_size, found in plugins.i.  
  If custom plugins are used, this value must be either the largest data size of the custom plugins, or mxplg_max_data_size, whichever is larger.

*MixerInstallHandler(A0=VBR, D0=save_vector.w)*  
This routine sets up the mixer interrupt handler. *MixerSetup()* must have been called prior to calling this routine. The routine has two parameters:

- A0 - Set to the VBR or zero (if running on a 68000).

- D0 - Set to 0 to save the interrupt vector the handler uses for future restoring, set to 1 to not save the interrupt vector.

*MixerRemoveHandler()*  
This routine removes the mixer interrupt handler. *MixerInstallHandler()* and *MixerStop()* should be called prior to calling this routine to make sure audio DMA is stopped.

*MixerStart()*  
This routine starts mixer playback (initially playing back silence). *MixerSetup()* and *MixerInstallHandler()* must have been called prior to calling this routine.

Note: if *MIXER_CIA_TIMER* is set to 1 in mixer_config.i, this routine also starts the CIA timer to measure performance metrics.

*MixerStop()*  
This routine stops mixer playback. Both *MixerSetup()* and *MixerInstallHandler()* must have been called prior to calling this routine.

Note: if *MIXER_CIA_TIMER* is set to 1 in mixer_config.i, this routine also stops the CIA timer used to measure performance metrics. The results are of any performance measuring are found in *mixer_ticks_last*, *mixer_ticks_best* and *mixer_ticks_worst* (these variables are not available if *MIXER_CIA_TIMER* is set to 0 in mixer_config.i).

*MixerVolume(D0=volume.w)*  
This routine sets the desired hardware output volume used by the mixer (valid values are 0 to 64).

*D0=MixerPlayFX(A0=effect_structure, D0=hardware_channel)*  
This routine adds a sample to the given hardware channel, using the MXEffect structure as described earlier. The routine automatically determines the best mixer channel to play back on based on priority and age. If no applicable channel is free (for instance due to higher priority samples playing), the routine will not play the sample.

The routine has two parameters:

- A0 - Points to an instance of the *MXEffect* structure

- D0 - Hardware channel to use (DMAF_AUD0..DMAF_AUD3)

  Note: if *MIXER_SINGLE* is set to 1 in mixer_config.i, the hardware channel given is ignored.  
  Note: if *MIXER_MULTI* or *MIXER_MULTI_PAIRED* are set to 1 in mixer_confi.i and the given channel is not part of the channels set in *mixer_output_channels* the sample will not play.  
  Note: if *MIXER_MULTI_PAIRED* is set to 1 in mixer_config.i, DMAF_AUD2 and DMAF_AUD3 are paired. Add samples intended for the paired channel to DMAF_AUD2 only, samples added to DMAF_AUD3 will be ignored.

The routine has a return value:

- D0 - returns the hardware & mixer channel the sample will play on, or -1 if no free channel could be found.

*D0=MixerPlayChannelFX(A0=effect_structure, D0=mixer_channel)*  
This routine adds a sample to the given hardware/mixer channel combination, using the *MXEffect* structure as described earlier. The routine uses the selected hardware/mixer channel to play back on. It checks for priority to see if the sample can be played. If the selected channel isn't free (due to a higher priority sample playing), the routine will not play the sample.

The routine has two parameters:

- A0 - Points to an instance of the *MXEffect* structure

- D0 - Hardware/mixer channel to use (DMAF_AUD0..DMAF_AUD3 \| MIX_CH0..MIX_CH3).

  Note: The routine requires setting exactly one hardware & mixer channel in D0.  
  Note: if *MIXER_SINGLE* is set to 1 in mixer_config.i, the hardware channel given is ignored.  
  Note: if *MIXER_MULTI* or *MIXER_MULTI_PAIRED* are set to 1 in mixer_confi.i and the given channel is not part of the channels set in *mixer_output_channels* the sample will not play.  
  Note: if *MIXER_MULTI_PAIRED* is set to 1 in mixer_config.i, DMAF_AUD2 and DMAF_AUD3 are paired. Add samples intended for the paired channel to DMAF_AUD2 only, samples added to DMAF_AUD3 will be ignored.

The routine has a return value:

- D0 - returns the hardware & mixer channel the sample will play on, or -1 if no free channel could be found.

*MixerStopFX(D0=mixer_channel_mask)*  
This routine stops sample playback on the given hardware/mixer channel mask. Multiple hardware/mixer channels can be set at the same time, samples on all given channels will be stopped. This routine has one parameter:

- D0 - Hardware/mixer channel mask DMAF_AUD0..DMAF_AUD3 \| MIX_CH0..MIX_CH3).

  Note: if *MIXER_SINGLE* is set to 1 in mixer_config.i, the hardware channel given is ignored.

*D0=MixerGetBufferSize()*  
This routine returns the size of the Chip RAM buffer size that needs to be allocated and passed to *MixerSetup()*. Note that this routine merely returns the value of *mixer_buffer_size*, which is defined in mixer.i. The primary function of this routine is to offer a method for C programs to gain access to this value without needing access to mixer.i.

*D0=MixerGetSampleMinSize()*  
This routine returns the minimum sample size. This is the minimum sample size the mixer can play back correctly. Samples must always be a multiple of this value in length.

Normally this value is 4, but optimisation options in mixer_config.i can can increase this.

Note: this routine is usually not needed as the minimum sample size is implied by the mixer_config.i setup. Its primary function is to give the correct value in case *MIXER_SIZEXBUF* has been set to 1 in mixer_config.i, in which case the minimum sample size will depend on the video system selected when calling *MixerSetup()* (PAL or NTSC).  
Note: *MixerSetup()* must have been called prior to calling this routine.

*D0=MixerGetChannelStatus()*  
This routine returns whether or not the hardware/mixer channel given in D0 is in use for sample playback. If *MIXER_SINGLE* is set to 1, the hardware channel does not need to be given in D0. If the channel is not used, the routine will return *MIX_CH_FREE*. If the channel is in use, the routine will return *MIX_CH_BUSY*.

*D0=MixerGetTotalChannelCount()*  
This routine returns the total number of internal channels the mixer supports for sample playback. That is to say, the value of *mixer_sw_channels* multiplied by the number of assigned HW audio channels.

*D0=MixerGetChannelBufferSize()*  
This routine returns the value of the internal mixer buffer size. This is the size of the buffer the mixer uses per HW audio channel assigned to it. Its primary purpose is to give plugins a way to get this value without needing access to the internal mixer structure.

*MixerSetReturnVector(A0=return_function_ptr)*  
This routine sets the optional vector the mixer can call at to at the end of interrupt execution.

Note: this vector should point to a standard routine ending in RTS.

*MixerSetIRQDMACallbacks(A0=callback_structure)*  
This routine sets up the vectors used for callback routines to 
manage setting up interrupt vectors and DMA flags. This routine and
associated callbacks are only required if MIXER_EXTERNAL_IRQ_DMA is
set to 1 in mixer_config.i.

The function has a parameter:

- A0 - Points to an instance of the *MXIRQDMACallbacks* structure

Note: MixerSetup should be run before calling this routine

Note: if MIXER_C_DEFS is set to 0, all callback routines should save &
      restore all registers they use. 
      If MIXER_C_DEFS is set to 1, registers d0,d1,a0 and a1 will be
      pushed to and popped from the stack by the mixer. All callback 
      routines should save & restore all other registers they use.

Note: this routine is only available if MIXER_EXTERNAL_IRQ_DMA is set to 1.


#### The following two routines are deprecated and will no longer receive new functionality when the mixer is updated. They are still available for backwards compatibility purposes and have been updated with the new offset loop mode.

*D0=MixerPlaySample(A0=sample, D0=hardware_channel, D1=length, D2=signed_priority.w, D3=loop_indicator.w, D4=loop_offset)*  
This routine adds a sample to the given hardware channel, using values in registers passed to it. The routine automatically determines the best mixer channel to play back on based on priority and age. If no applicable channel is free (for instance due to higher priority samples playing), the routine will not play the sample.

The routine has five parameters:

- A0 - Pointer to the pre-processed sample to play

- D0 - Hardware channel to use (DMAF_AUD0..DMAF_AUD3)

- D1 - Length of the sample in bytes (signed long unless *MIXER_WORDSIZED* is set to 1 in mixer_config.i, in which case the length is an unsigned word)

- D2 - Signed priority value, higher priority samples can overwrite lower priority samples.  
  Note that looping samples (once playing) can never be overwritten.

- D3 - Either *MIX_FX_ONCE* to play back the sample once, *MIX_FX_LOOP* to play the sample on a loop, or *MIX_FX_LOOP_OFFSET* to play back the sample on a loop, restarting from the offset given in D4.

- D4 - Either 0, or the desired offset into the sample to restart looping at if D3 is set to *MIX_FX_LOOP_OFFSET*.

  Note: this routine is deprecated, use *MixerPlayFX()* instead  
  Note: if *MIXER_SINGLE* is set to 1 in mixer_config.i, the hardware channel given is ignored.  
  Note: if *MIXER_MULTI* or *MIXER_MULTI_PAIRED* are set to 1 in mixer_confi.i and the given channel is not part of the channels set in *mixer_output_channels* the sample will not play.  
  Note: if *MIXER_MULTI_PAIRED* is set to 1 in mixer_config.i, DMAF_AUD2 and DMAF_AUD3 are paired. Add samples intended for the paired channel to DMAF_AUD2 only, samples added to DMAF_AUD3 will be ignored.

The routine has a return value:

- D0 - returns the hardware & mixer channel the sample will play on, or -1 if no free channel could be found.

*D0=MixerPlayChannelSample(A0=sample, D0=mixer_channel, D1=length, D2=signed_priority.w, D3=loop_indicator.w, D4=loop_offset)*  
This routine adds a sample to the given hardware/mixer channel combination, using values in registers passed to it. The routine uses the selected hardware/mixer channel to play back on. It checks for priority to see if the sample can be played. If the selected channel isn't free (due to a higher priority sample playing), the routine will not play the sample. The routine has five parameters:

- A0 - Pointer to the pre-processed sample to play

- D0 - Hardware channel to use (DMAF_AUD0..DMAF_AUD3)

- D1 - Length of the sample in bytes (signed long unless *MIXER_WORDSIZED* is set to 1 in mixer_config.i, in which case the length is an unsigned word)

- D2 - Signed priority value, higher priority samples can overwrite lower priority samples.  
  Note that looping samples (once playing) can never be overwritten.

- D3 - Either *MIX_FX_ONCE* to play back the sample once, *MIX_FX_LOOP* to play the sample on a loop, or *MIX_FX_LOOP_OFFSET* to play back the sample on a loop, restarting from the offset given in D4.

- D4 - Either 0, or the desired offset into the sample to restart looping at if D3 is set to *MIX_FX_LOOP_OFFSET*.

  Note: this routine is deprecated, use *MixerPlayFX()* instead  
  Note: The routine requires setting exactly one hardware & mixer channel in D0.  
  Note: if *MIXER_SINGLE* is set to 1 in mixer_config.i, the hardware channel given is ignored.  
  Note: if *MIXER_MULTI* or *MIXER_MULTI_PAIRED* are set to 1 in mixer_confi.i and the given channel is not part of the channels set in *mixer_output_channels* the sample will not play. Note: if *MIXER_MULTI_PAIRED* is set to 1 in mixer_config.i, DMAF_AUD2 and DMAF_AUD3 are paired. Add samples intended for the paired channel to DMAF_AUD2 only, samples added to DMAF_AUD3 will be ignored.

The routine has a return value:

- D0 - returns the hardware & mixer channel the sample will play on, or -1 if no free channel could be found.

### Callback API

In order to support callback routines, the mixer provides several routines and a common calling convention for callback routines. Note that callback routines are only supported if *MIXER_ENABLE_CALLBACK* is set to 1.

When enabled and a callback is set using *MixerEnableCallback()*, the given callback routine is called whenever a sample ends. Samples that loop, are stopped by calling *MixerStopFX()* or by calling *MixerStop()* do not result in a callback routine being called.

#### Routine info follows:

- *MixerEnableCallback(A0=callback_function_ptr)*  
  This routine enables the callback function and sets it to the given function pointer in A0.

- *MixerDisableCallback()*  
  This routine disables the callback function.

#### Callback routine conventions follow:

- Callback functions take two parameters, the HW channel/mixer channel combination and the pointer to the start of the sample that just finished playing.

- Callback functions are not allowed to change any registers, apart from D0. They are called during the mixer interrupt and as therefore should be as frugal as possible with the amount of CPU time used.

- Callback functions can start playback of new samples using the standard mixer functions to play back samples, but only on the same mixer channel as the sample that just finished playback. If a callback function is used to start playing a new sample, the function should set its return value in D0 to 1.

  New samples played back by callback functions will start immediately after the end of the sample that just finished playback. This allows for seamless playback of one sample after the other.

#### Callback parameters/return value follow:

- A0 - Pointer to the callback function to use.

- D0 - the HW/mixer channel combination of the sample that just finished playing.

Return value:

- D0 - set to 0 if no new sample started playing, or to 1 if a new sample started playing.

### Plugin API

The plugin API is split into four parts. The first part describes the basics of the plugin system, including how it's split up into an initialisation part and a plugin part. The second part describes the plugin configurarion file, plugins_config.i. The third part describes the main API, which is dealt with directly by the mixer and thus part of mixer.asm. The last part describes the plugins themselves, which are found in plugins.asm and how to make custom plugins.

#### Plugin basics

Mixer plugins are routines that allow for several things:

- Changing sample output data for a specific mixer channel (for instance, changing the pitch of a sound)
- Communicating status with the program code outside of the mixer interrupt (for instance, setting an address in memory to 1 when a sample has finished playback)
- Starting a new sample when certain conditions occur (for instance, playing the same sample again after a short delay)

Plugin routines are called by the mixer during mixer interrupts using a specific API. They are not meant to be called outside of the mixer interrupt. They are not allowed to change sample source data, any changes in data required for the desired effect has to be written into a intermediate buffer, which is then used by the mixer for playback. Plugin routines can run in a special mode where they do not output any data to the intermediate buffer, which makes it possible to use plugins to communicate with the program code outside of the mixer interrupts at a low cost in performance.

Plugins consist of up to three routines:

- Plugin initialisation (required)  
  This routine does setup for the plugin prior to playing back the sample. These routines are called when calling the various *MixerPlayFX()* routines.

  Plugin initialisation routines also set up any data required by plugin routines and get passed initilisation data via the *MXPlugin* structure.

- Plugin routine (required)  
  This routine does the actual work of the plugin. These routines are called every mixer interrupt for samples playing using a plugin. Depending on plugin type, they either need to fill an output buffer with the audio data to play, or not.

  Note: plugin routines are not allowed to call any mixer playback function, such as *MixerPlayFX()* or *MixerPlaySample()*. Doing so can cause the mixer interrupt to crash.

- Deferred plugin routine (optional)  
  This routine is called at the end of every mixer interrupt for samples playing using a plugin. These routines are required only when playing back entirely new samples is needed for the plugin, as calling *MixerPlaySample()*/*MixerPlayFX()* type routines during the mixing loop is not supported.

Apart from deferred plugin routines (which are set up directly by plugin routines themselves), all these routines and any data they need are passed to the mixer using the MXPlugin structure, and passing this via the MXEffect structure to the playback routines. See [Mixer API](#mixer-api) for more information about MXEffect or the playback functions.

For more details on calling conventions and the like, see plugins.asm part below.

#### Plugin configuration

- Like the mixer, the plugins also have a configuration file which defines how the code gets assembled. Items configured via the configuration file can't be changed at runtime. The plugins are configured via the file plugins_config.i

  In addition, the plugins also make use of the *MIXER_C_DEFS* and *MIXER_68020* settings from mixer_config.i

  The following options exist:

  - MXPLUGIN_REPEAT  
    Set this option to 1 to enable the use of the repeat plugin, or to zero to disable it.

   ```
   MXPLUGIN_REPEAT             EQU 1
   ```

  - MXPLUGIN_SYNC  
    Set this option to 1 to enable the use of the sync plugin, or to zero to disable it.

  ```
  MXPLUGIN_SYNC               EQU 1
  ```

  - MXPLUGIN_VOLUME  
    Set this option to 1 to enable the use of the volume plugin, or to zero to disable it.

  ```
  MXPLUGIN_VOLUME             EQU 1
  ```

  - MXPLUGIN_PITCH Set this option to 1 to enable the use of the pitch plugin, or to zero to disable it.

  ```
  MXPLUGIN_PITCH              EQU 1
  ```

  - MXPLUGIN_68020_ONLY  
    If this option is set to 1 and MIXER_68020 is set to 1, the plugins use a small amount of 68020+ code to offer a tiny improvement in performance.

  ```
  MXPLUGIN_68020_ONLY         EQU 1
  ```

  - MXPLUGIN_NO_VOLUME_TABLES  
    If this option is set to 1 and MXPLUGIN_VOLUME is set to 1, the volume tables are not included, saving 3,5KB of RAM.

  ```
  MXPLUGIN_NO_VOLUME_TABLES         EQU 1
  ```

#### mixer.asm part

- The main plugin API is found in mixer.asm, as the mixer is responsible for dealing with plugins. This part of the documentation describes how to set up the *MXPlugin* structure for use in the *MXEffect* structure passed to *MixerPlayFX()* & *MixerPlayChannelFX()* and the support routines for plugins that are available.

  Note: all use of plugins requires *MIXER_ENABLE_PLUGINS* to be set to 1 and *MixerSetup()* has to have been called with the relevant parameters for plugins set correctly.

  Constant info follows:

  - MIX_PLUGIN_STD / MIX_PLUGIN_NODATA  
    These two constants are used in the filling of *MXPlugin* to indicate the type of plugin that is being configured. *MIX_PLUGIN_STD* is used to denote a standard plugin, one which outputs an altered version of the source sample into an indirect buffer to allow changes in the audio heard.

    *MIX_PLUGIN_NODATA* on the other hand denotes a plugin that does not change sample data, but is used for other purposes - such as communication with other code, synchronisation or starting new samples when certain situations occur.

  Variable info follows:

  - mixer_plugin_buffer_size  
    This variable denotes the total size in RAM needed for the indirect buffers that are used by the mixer to store the results of plugins that change the data of the input sample.

  Structure info follows:

  - MXPlugin  
    This structure defines a plugin for use with a mixer sound effect.

    The MXPlugin structure has the following members:

    - mpl_plugin_type  
      Determines the type of plugin. Either *MIX_PLUGIN_STD* for standard plugins, or *MIX_PLUGIN_NODATA* for plugins that do not alter sample buffer data.

    - mpl_init_ptr  
      Pointer to the plugin initialisation routine to use.

    - mpl_plugin_ptr  
      Pointer to the plugin routine to use.

    - mpl_init_data_ptr  
      Pointer to the plugin initialisation data to use.

  Routine info follows:

  - D0=MixerGetPluginsBufferSize()  
    This routine returns the value of *mixer_plugin_buffer_size*, the required size of the RAM buffer that needs to be allocated and passed to *MixerSetup()* if *MIXER_ENABLE_PLUGINS* is set to 1.

    Note: this routine is usually not needed as the plugin buffer size is given in mixer.i. Its primary function is to expose this value to C programs.

  - MixerSetPluginDeferredPtr(A0=deferred_function_ptr, A2=mxchannel)  
    This routine is called by a plugin whenever it needs to do a deferred (=post mixing loop) action. This is useful in case a plugin needs to start playback of a new sample, as this cannot be done during the mixing loop to prevent race conditions.

    Note: this routine should **only** be used by plugin routines and never in other situations as that will likely crash the mixer interrupt handler.

    - A0 - Pointer to the deferred plugin to use.
    - A2 - Pointer to the internal mixer channel structure, as provided by the mixer when a plugin function is called.

#### plugins.asm part

The files plugins.asm and plugins.i contain the actual plugins, as well as support routines and the requires structures for use by the plugins. Depending on plugin configuration, plugins.asm also contains lookup tables for real time volume changes.

Constant info follows:

- MXPLG_MULTIPLIER_4 / MXPLG_MULTIPLIER_32 / MXPLG_MULTIPLIER_BUFSIZE  
  These three constants are the three possible return values for the support routine *MixPluginGetMultiplier()*.

  - MXPLG_MULTIPLIER_4  
    Mixer sample size multiplier is 4 bytes
  - MXPLG_MULTIPLIER_32  
    Mixer sample size multiplier is 32 bytes
  - MXPLG_MULTIPLIER_BUFSIZE  
    Mixer sample size multiplier is equal to the internal mixer channel buffer size

- MXPLG_PITCH_STANDARD / MXPLG_PITCH_LOWQUALITY  
  These two constants determine the type of pitch change is to be used by the pitch change plugin.

  - MXPLG_PITCH_STANDARD  
    Use the standard (slower, but higher quality) pitch change mechanism
  - MXPLG_PITCH_LOWQUALITY  
    Use the faster, but lower quality pitch change mechanism

- MXPLG_PITCH_NO_PRECALC / MXPLG_PITCH_PRECALC  
  These two constants determine whether or not the pitch plugin initialisation function has to calculate the new length of the sample to have its pitch changed, or that this value has been pre-calculated.

  - MXPLG_PITCH_NO_PRECALC  
    Pitch plugin initialisation calculated the new sample length in real time
  - MXPLG_PITCH_PRECALC  
    Pitch plugin initialisation assumes new sample length has been pre-calculated

- MXPLG_VOL_TABLE / MXPLG_VOL_SHIFT  
  These two constants determine whether the volume plugin uses lookup tables, or real time shifting to change volume.

  - MXPLG_VOL_TABLE  
    The volume plugin uses lookup tables to change sample playback volume
  - MXPLG_VOL_SHIFT  
    The volume plugin uses real time shifts to change sample playback volume

- MXPLG_SYNC_DELAY / MXPLG_SYNC_DELAY_ONCE / MXPLG_SYNC_START / MXPLG_SYNC_END / MXPLG_SYNC_LOOP / MXPLG_SYNC_START_AND_LOOP  
  These six constants determine which mode the synchronisation plugin uses.

  - MXPLG_SYNC_DELAY  
    Synchronisation counts mixer interrupts until the given delay value is reached, then triggers. The counter is then reset and the process continues.
  - MXPLG_SYNC_DELAY_ONCE  
    Synchronisation counts mixer interrupts until the given delay value is reached, then triggers.
  - MXPLG_SYNC_START  
    Synchronisation triggers at the start of sample playback.
  - MXPLG_SYNC_END  
    Synchronisation triggers at the end of sample playback.
  - MXPLG_SYNC_LOOP  
    Synchronisation triggers every time sample playback loops.
  - MXPLG_SYNC_START_AND_LOOP  
    Synchronisation triggers at the start of sample playback and every time sample playback loops.

- MXPLG_SYNC_ONE / MXPLG_SYNC_INCREMENT / MXPLG_SYNC_DECREMENT / MXPLG_SYNC_DEFERRED  
  These four constants determine the type of synchronisation used by the synchronisation plugin.

  - MXPLG_SYNC_ONE  
    When synchronisation triggers, the address associated with the synchronisation plugin is set to the word value 1.
  - MXPLG_SYNC_INCREMENT  
    When synchronisation triggers, the address associated with the synchronisation plugin is increased by the word value 1.
  - MXPLG_SYNC_DECREMENT  
    When synchronisation triggers, the address associated with the synchronisation plugin is decreased by the word value 1.
  - MXPLG_SYNC_DEFERRED  
    When synchronisation triggers, the address associated with the synchronisation plugin is called as a deferred plugin routine.

Variable info follows:

- mxplg_max_idata_size  
  This variable contains the maximum size of any of the built-in plugin's initialisation data structure.

- mxplg_max_data_size  
  This variable contains the maximum size of any of the built-in plugin's data structure.

Structure info follows:

- MXPDPitchInitData  
  This structure contains the initialisation data for the pitch change plugin

  The MXPDPitchInitData structure has the following members:

  - mpid_pit_mode  
    The mode to use for the pitch plugin. Either *MXPLG_PITCH_STANDARD* or *MXPLG_PITCH_LOWQUALITY*. The latter is much faster, but also results in lower quality output.

  - mpid_pit_precalc  
    Whether or not the values in the *MXEffect* structure contain pre-calculated values for the altered pitch sample's new length and loop offset. Set using either *MXPLG_PITCH_NO_PRECALC* or *MXPLG_PITCH_PRECALC*. If set to the former, the initialisation routine will calculate the new length & loop offset for the *MXEffect* structure in real time, which costs extra CPU time. (note that the plugin routine itself is unaffected)

  - mpid_pit_ratio_fp8  
    The ratio to change the pitch by, given as a 8.8 fixed point math number. The new sample pitch will be multiplied so a ratio of 0.5 will halve the sample's pitch, while a ratio of 2.0 will double the pitch (etc).

  - mpid_pit_length  
    If *MXPLG_PITCH_PRECALC* is set, this field has to contain the original length of the sample, without pitch shift.

  - mpid_pit_loop_offset  
    If *MXPLG_PITCH_PRECALC* is set, this field has to contain the original loop offset of the sample, without pitch shift.

- MXPDVolumeInitData  
  This structure contains the initialisation data for the volume change plugin

  The MXPDVolumeInitData structure has the following members:

  - mpid_vol_mode  
    The mode to use for the volume plugin. Either *MXPLG_VOL_TABLE* or *MXPLG_VOL_SHIFT*. The former uses a lookup table (byte based) to change the volume, the latter uses shift instructions.

  - mpid_vol_volume  
    The desired volume. For table lookups, this ranges from 0 (silence) to 15 (maximum volume). In case of shifts, this ranges from 0 (maximum volume) to 8 (silence)

    Note that the shift value for silence is dependent on the mixer mode and the number of channels the mixer can mix (as set in mixer_config.i)

                       Shift value for silence
        HQ Mode/1-4 channels      8
        Normal/1 channel          8
        Normal/2 channels         7
        Normal/3 channels         7
        Normal/4 channels         6

- MXPDRepeatInitData  
  This structure contains the initialisation data for the repeat plugin

  The MXPDRepeatInitData structure has the following members:

  - mpid_rep_delay  
    The desired delay in mixer ticks. Mixer ticks occur roughly once per frame, when the mixer interrupt triggers.

- MXPDSyncInitData  
  This structure contains the initialisation data for the synchronisation plugin

  The MXPDSyncInitData structure has the following members:

  - mpid_snc_address  
    Set to the location in memory to use as output for the synchronisation plugin. This location has to be 1 word wide.

  - mpid_snc_mode  
    Set to the desired synchronisation mode. Several modes are available

    - MXPLG_SYNC_DELAY  
      Triggers every mpid_snc_delay ticks
    - MXPLG_SYNC_DELAY_ONCE  
      Triggers once, after mpid_snc_delay ticks
    - MXPLG_SYNC_START  
      Triggers once, at the start of playback
    - MXPLG_SYNC_END  
      Triggers once, at the end of playback
    - MXPLG_SYNC_LOOP  
      Triggers every time playback loops
    - MXPLG_SYNC_START_AND_LOOP  
      Triggers at the start of playback and again every time playback loops

  - mpid_snc_type  
    Set to the desired synchronisation type. Several types are available

    - MXPLG_SYNC_ONE  
      Writes the value one to the target address
    - MXPLG_SYNC_INCREMENT  
      Increments the contents of the word at the target address by one
    - MXPLG_SYNC_DECREMENT  
      Decrements the contents of the word at the target address by one
    - MXPLG_SYNC_DEFERRED  
      Instead of changing the word at *mpid_snc_address*, this mode uses the address in *mpid_snc_address* as the address of a deferred plugin function, which will be called at the end of any interrupt in which the chosen sync mode triggers.

  - mpid_snc_delay  
    The desired delay in mixer ticks. Mixer ticks occur roughly once per frame, when the mixer interrupt triggers.

Support routine info follows:

- *D0=MixerPluginGetMaxInitDataSize()* This routine returns the maximum size of any of the built in plugin initialisation data structures.

- *D0=MixerPluginGetMaxDataSize()* This routine returns the maximum size of any of the built in plugin data structures.

- *D0=MixPluginGetMultiplier()*  
  This routine returns the type of sample size multiple the mixer expects. This can be used instead of *MixerGetSampleMinSize()* if the actual value is not relevant, only whether or not it's 4x, 32x or (buffer_size)x.

  Returns either *MXPLG_MULTIPLIER_4*, *MXPLG_MULTIPLIER_32* or *MXPLG_MULTIPLIER_BUFSIZE*.

- *MixPluginRatioPrecalc(A0=effect_structure, D0=pitch_ratio, D1=shift_value)*  
  This routine can be used to pre-calculate length and loop offset values for plugins that need these values divided by a FP8.8 ratio. The routine calculates the values using a pointer to a filled *MXEffect* structure in A0, the ratio value in D0 and the shift value in D1.

  Currently this routine is only used by/for *MixPluginPitch()*.

  Note: the shift value passed to the routine is used to scale the input to create a greater range than would normally be allowed. At a shift of zero, the routine supports input & output values of up to 65535. Increasing the shift value will increase these limits by a factor of 2^shift factor, at a cost of an ever increasing inaccuracy.

Built in plugin info follows:

- Because each plugin uses both an initialisation routine and a plugin routine and the calling convention of each of these routines is always the same, the initialisation and plugin routines will be described without function prototypes and instead show the correct way to set up the *MXPlugin* structure for the mixer instead, as well as describe the functionality of the plugin, which initialisation data structure to use and how to fill it.

  - *MixPluginInitDummy()* / *MixPluginDummy()*  
    This plugin performs no function and changes no data. It can be used in place of calling an actual plugin to test plugin functionality, or as a NO-OP plugin if the code written to call *MixerPlayFX()* or *MixerPlayChannelFX()* in a specific program always wants to pass a plugin, even if this is not required for the sample to be played.

    MXPlugin setup

    - mpl_plugin_type  
      Determines the type of plugin. Either *MIX_PLUGIN_STD* or *MIX_PLUGIN_NODATA*
    - mpl_init_ptr  
      Pointer to *MixPluginInitDummy()*
    - mpl_plugin_ptr  
      Pointer to *MixPluginDummy()*
    - mpl_init_data_ptr  
      contents of this field are ignored

  - *MixPluginInitRepeat()* / *MixPluginRepeat()*  
    This plugin repeats playback of the sample specified after a given delay. It makes use of the *MXPDRepeatInitData* structure to pass its parameter.

    See the section Structures above for information how to set up this structure.

    MXPlugin setup

    - mpl_plugin_type  
      Set to *MIX_PLUGIN_NODATA*
    - mpl_init_ptr  
      Pointer to *MixPluginInitRepeat()*
    - mpl_plugin_ptr  
      Pointer to *MixPluginRepeat()*
    - mpl_init_data_ptr  
      Pointer to instance of structure *MXPDRepeatInitData*

  - *MixPluginInitSync()* / MixPluginSync()  
    This plugin is used to give synchronisation/timing information to the program playing back samples using the mixer. If offers various modes and types of this information. When the mode/type of the synchronisation plugin triggers, it either writes a value to a given address, or calls the routine at this address as a deferred plugin routine. The plugin makes use of the *MXPDSyncInitData* structure to pass its parameters.

    See the section Structures above for information how to set up this structure.

    See the section Deferred plugin routine conventions for information on how to use deferred plugin routines.

    MXPlugin setup

    - mpl_plugin_type  
      Set to *MIX_PLUGIN_NODATA*
    - mpl_init_ptr  
      Pointer to *MixPluginInitSync()*
    - mpl_plugin_ptr  
      Pointer to *MixPluginSync()*
    - mpl_init_data_ptr  
      Pointer to instance of structure *MXPDSyncInitData*

  - *MixPluginInitVolume()* / *MixPluginVolume()*

    This plugin is used to change the playback volume of the sample specified. It operates either by using a lookup table or by using shifts. In case of using lookup tables, it supports 16 volume levels: 0 = silence, 15 = maximum volume. In case of using shifts, 0 represents maximum volume and silence is represented by either 8, 7 or 6 (depending on the configured number of software channels per hardware channel). The plugin makes use of the *MXPDVolumeInitData* structure to pass its parameters.

    See the section Structures above for information how to set up this structure.

    MXPlugin setup

    - mpl_plugin_type  
      Set to *MIX_PLUGIN_STD*
    - mpl_init_ptr  
      Pointer to *MixPluginInitVolume()*
    - mpl_plugin_ptr  
      Pointer to *MixPluginVolume()*
    - mpl_init_data_ptr  
      Pointer to instance of structure *MXPDVolumeInitData*

  - *MixPluginInitPitch()* / *MixPluginPitch()*

    This plugin changes the pitch of the specified sample by a given ratio. It offers two modes (standard and low quality) and has an option to speed up the initialisation phase by using some pre-calculated values. The ratio is given as a fixed point 8.8 value and represents the value to use to multiply the original pitch value (so, 0.5 means playing back at half pitch, 2.0 means playing back at double pitch, etc). The plugin makes use of the *MXPDPitchInitData* structure to pass its parameters.

    See the section Structures above for information how to set up this structure.

    Note: using pre-calculated values for length & offset does not increase performance of the actual plugin, it only speeds up the initialisation that runs when calling *MixerPlayFX()* or *MixerPlayChannelFX()*

    MXPlugin setup:

    - mpl_plugin_type  
      Set to *MIX_PLUGIN_STD*
    - mpl_init_ptr  
      Pointer to *MixPluginInitPitch()*
    - mpl_plugin_ptr  
      Pointer to *MixPluginPitch()*
    - mpl_init_data_ptr  
      Pointer to instance of structure *MXPDPitchInitData*

Custom plugin routine conventions follow:

- Custom plugins, like regular plugins, consist of up to three routines. These are plugin initialisation routines, plugin routines and optionally deferred plugin routines. For more information on deferred plugin routines, see the section "Deferred plugin routine conventions" further down.

- Custom plugin initialisation routine conventions:

  - Initialisation routines have the following parameters:
    - A0 - Pointer to *MXEffect* structure as passed by *MixerPlayFX()* or *MixerPlayChannelFX()*

    - A1 - Pointer to plugin initialisation data structure, as passed by *MixerPlayFX()* or *MixerPlayChannelFX()*

    - A2 - Pointer to plugin data structure, as passed by *MixerPlayFX()* or *MixerPlayChannelFX()*. This block of memory is set up by the initialisation routine to contain the data the plugin requires to work

    - D0 - Hardware channel/mixer channel (f.ex. *DMAF_AUD0*\|*MIX_CH1*)
  - Depending on what the plugin itself needs, these parameters can be omitted / left blank.
  - Initialisation routines have to preserve all registers
  - Initialisation routines should limit themselves to setting up the data required for use by the plugin and any calculations (etc) to achieve this. They should not be used for other purposes.
  - Initialisation routines can have any name, though following the convention in plugins.i of naming them *MixPluginInit\<plugin name\>* is suggested.

- Custom plugin routine conventions:
  - Plugin routines have the following parameters:

    - A0 - Pointer to the output buffer to use

    - A1 - Pointer to the plugin data

    - A2 - Pointer to the *MXChannel* structure for the current channel (see note below)

    - D0 - Number of bytes to process

    - D1 - Loop indicator. Set to 1 if the sample has restarted at the loop offset (or at its start in case the loop offset is not set)

    #### Note: the structure passed in A2 is an internal mixer structure which may change between versions. Do not alter its contents with any plugin routines. It is provided solely to enable calling *MixerSetPluginDeferredPtr()*, if needed.

- Depending on what the plugin itself needs, these parameters can be omitted / left blank.

- Plugin routines have to preserve all registers

- Plugin routines are not allowed to call any mixer routine that causes a new sample to be played. If this is needed, create a separate deferred plugin routine that does call this/these routine(s). Then, in the plugin routine call *MixerSetPluginDeferredPtr()* with the function pointer for the deferred plugin routine instead.

- Plugin routines should limit themselves to actions required for the plugin and attempt to be a frugal as possible with the amount of CPU time they use, as they run during the mixer interrupt.

- Plugin routines can have any name, though following the convention in plugins.i of naming them *MixPlugin\<plugin name\>* is suggested.

Deferred plugin routine conventions follow:

- Deferred plugin routines can be used to play back new samples from plugins, without causing issues with the mixing loop. These routines are sometimes needed by custom plugins.

- Deferred plugin routine conventions
  - Deferred plugin routines have the following parameters:
    - A0 - Pointer to the output buffer in use

    - A1 - Pointer to the plugin data
  - Depending on what the plugin itself needs, these parameters can be omitted / left blank.
  - Deferred plugin routines have to preserve all registers
  - Unlike plugin routines, deferred plugin routines are allowed to call any mixer routine that causes a new sample to be played.
  - Deferred plugin routines should limit themselves to actions required to play back new samples / after mixing is done and attempt to be as frugal as possible with the amount of CPU time they use, as they run during the mixer interrupt.
  - Deferred plugin routines can have any name, though following the convention in plugins.asm of naming them *MixPlugin\<plugin name\>Deferred* is suggested.

### Converter API

The mixer provides an assembly routine to help with converting samples for use with the mixer at runtime. While this routine does use a lookup table to improve division speed, it's still relatively slow and thus not recommended for use with large amounts of sample data.

If large quantities of sample data need to be converted, consider using the SampleConverter tool provided to deal with the conversion before runtime instead.

#### Routine info follows:

- *ConvertSampleDivide(A0=source_sample,A1=destination_sample,D0=length, D1=number_of_channels)*  
  This routine converts the given sample to ensure enough headroom exists to mix the sample using the mixer. It has four parameters:

  - A0 - pointer to the start of the source sample

  - A1 - pointer to the start of the destination sample (this can be identical to the source sample if desired)

  - D0 - length of the sample in bytes (note the limitations for sample length used by the mixer apply, but are not checked for)

  - D1 - the number of channels to be mixed (this is the value of *mixer_sw_channels* from mixer_config.i)

  The conversion routine will work with anywhere from 1 to 4 channels. Note that conversion is not needed when running the mixer with *mixer_sw_channels* set to 1 (the routine will simply copy data when it's set to 1 channel).

### Performance measuring API

If *MIXER_CIA_TIMER* is set to 1 in mixer_config.i, the mixer provides several variables and a routine to measure the performance of the mixer using the CIA-A timer A of the Amiga. In order to correctly measure performance, the CIA-A timer A has to be available and no interrupts of level 5+ must run, as those will interrupt the mixer routines and skew the measured results.

Additionally, if *MIXER_COUNTER* is set to 1 in mixer_config.i, the mixer provides two new routines to measure the number of mixer interrupts that have fired since the last counter reset.

In order to measure performance, the mixer interrupt handler must be running and *MixerStart()* must have been called. This routine also starts the CIA timer when it starts the Mixer.

Once *MixerStart()* has been called, the variables for storing performance will start to get filled and the interrupt counter starts running.

#### Variable info follows:

- mixer_ticks_last  
  This variable contains the number of CIA timer ticks the last mixer interrupt took to complete. It will be filled after at least one such interrupt has occurred.

- mixer_ticks_best  
  This variable contains the lowest number of CIA timer ticks a mixer interrupt has taken to complete to date. In most cases this will represent the result of an idle interrupt (i.e. the mixer not playing any samples). It will start being updated after at least one mixer interrupt has occurred.

- mixer_ticks_worst  
  This variable contains the highest number of CIA timer ticks a mixer interrupt has taken to complete to date. This is useful to see if mixer CPU use causes performance issues. Mixer CPU use varies based on the number of samples being mixed together as well as whether or not (many) small\* samples are playing/looping. This value will start being updated after at least one mixer interrupt has occurred.

  \*) A sample is considered small when its length is (much) smaller than the size of the mixer's playback buffer (either *mixer_PAL_buffer_size* or *mixer_NTSC_buffer_size* depending on selected video system).

  This effectively means samples that last less than either 1/50th or 1/60th of a second.

- mixer_ticks_average  
  This variable initially contains no data. It can be filled with the average time the mixer interrupt took over the last 128 frames by calling the *MixerCalcTicks()* routine. Once filled, this value gives an indication of the number of cycles the mixer takes in normal use in the given program. The underlying values to be able to fill this value start being updated in a circular buffer after at least one mixer interrupt has occurred.

  Note that this value can also be useful to measure performance of playing back a certain combination of (looping) samples over time. Simply run the mixer playing back this combination for at least 128 frames, stop the mixer using *MixerStop()* and then call *MixerCalcTicks()* to see the average performance.

#### Routine info follows:

- *MixerCalcTicks()*  
  This routine calculates the average time the mixer interrupts took over the last 128 frames by using a circular buffer. It adds the results of the last 128 frames together and divides it by 128 to get the average and store this value in *mixer_ticks_average*.

- *MixerResetCounter()*  
  This routine resets the mixer interrupt counter to 0.

- *D0=MixerGetCounter()*  
  This routine gets the current value of the mixer interrupt counter. The counter is word sized.

### Using the mixer in C programs

In order to use the Mixer in C programs, several steps need to be followed:

- The mixer configuration must be set up in mixer_config.i (*MIXER_C_DEFS* must be set to 1)

- mixer.asm must be assembled into an object file

- mixer.o must be linked into the C program which is to use the mixer

- mixer.h must be included into the C program which is to use the mixer

  Note: mixer.h is designed for VBCC, Bebbo's GCC compiler and Bartman's GCC compiler. Other compilers will need a different method for calling the functions. It should be possible to make the mixer work with other compilers, but only VBCC, Bebbo and Bartman are officially supported.

If the above is done, the mixer API (as described in ["Mixer API"](#mixer-api)) becomes available to the C program. The C program will now need to follow the steps in ["Using the mixer"](#using-the-mixer) to enable mixing.

The complete function prototypes that can be used by C programs can be found in mixer.h (note that this is the same set of routines that are offered through mixer.i for assembly programs).

As pointed out above, the supplied mixer.h file is designed for use with VBCC, Bebbo and Bartman. To use the mixer using other GCC based compilers, a set of calling routines needs to be constructed. (these are not provided in this package)

#### Two examples of how to make these routines follows:

      // Assumes exec/types.h is available.
      // Example for calling MixerGetBufferSize
      inline UWORD call_MixerGetBufferSize()
      {
         register volatile UWORD _return_value __asm("d0");
         __asm__ volatile
         (
            "jsr MixerGetBufferSize\n"
            // OutputOperands
               : "=d" (_return_value)
            // InputOperands
               : /* no inputs */
            // Clobbers
               : "cc", "memory"
          );
          return _return_value;
      }

      // Assumes exec/types.h is available.
      // Example for calling MixerSetup
      inline void call_MixerSetup(void *buffer, UWORD vidsys)
      {
         register volatile void *_buffer __asm("a0") = buffer;
         register volatile UWORD _vidsys __asm("d0") = vidsys;
         __asm__ volatile
         (
            "jsr MixerSetup\n"
            // OutputOperands
               : /* no outputs */
            // InputOperands
               : "a" (_buffer), "d" (_vidsys)
            // Clobbers
               : "cc", "memory"
          );
          return ;
      }

Examples courtesy of nivrig and Jobbo over at the AmigaGameDev Discord.

Note that the examples above are provided merely as a starting point. As pointed out earlier, C integration with other compilers than VBCC or Bebbo's GCC compiler is not officially supported.

### Troubleshooting

This section of the documentation lists some possible problems when using the mixer and potential solutions to them. In many cases, it can be useful to set *MIXER_TIMING_BARS* to 1 in mixer_config.i when troubleshooting as it helps identify whether or not the interrupt is running correctly.

1.  #### Issues with startup or shutdown of the mixer or programs using it

    - Calling *MixerInstallHandler()* immediately crashes the system  
      This is usually caused by setting a non-zero VBR value on 68000/68010 based systems (in particular an odd value). Try setting the VBR to 0 if running on a 68000 or correct the VBR value if running on a 68010.

      Note that some music players do not restore all registers after calling their setup routines, which can result in the wrong VBR being passed if the *MixerInstallHandler()* routine is called directly after setting up or starting a music player.

    - Calling *MixerStart()* does not start the mixer, no interrupts fire  
      This is normally caused by setting an incorrect value of the VBR when calling *MixerInstallHandler()*. Check to make sure the correct value is passed.

      Note that some music players do not restore all registers after calling their setup routines, which can result in the wrong VBR being passed if the *MixerInstallHandler()* routine is called directly after setting up or starting a music player.

    - Calling *MixerInstallHandler()* causes many (hundreds) of interrupts per frame  
      This is usually caused by starting a music player that sets the audio registers to an initial value even on channels which remain empty. Often this is a one word loop, which can cause issues with the mixer as this will cause the audio interrupts to trigger extremely frequently.

      This can sometimes be solved by disabling the channel for music playback using features of the music player chosen. In other cases it can also be fixed by manually writing a volume of 0 and a length of several hundred bytes in the audio channel(s) used by the mixer immediately prior to calling *MixerInstallHandler()*.

      Calling *MixerStart()* can also fix this, but in some cases so many interrupts are generated that this is not possible.

    - Calling *MixerStart()* causes random audio glitches and playing samples through the mixer does not work  
      This is usually caused by a music player setting or resetting registers on channels reserved for use by the mixer. If the channel configuration for the mixer is set correctly, the music track used does not use the channel(s) reserved for the mixer and the problem persists:

      - try disabling the music channels in the player

      - if the player does not support this, it may be required to patch the music player to not touch the audio channels used by the mixer.

      - if all else fails, try using one of the two music players that have been verified to work with the mixer: Frank Wille's PTPlayer 6.3+ or Arnaud Carré's LSP.

    - Calling *MixerStart()* after interrupting the mixer using *MixerStop()* does not restart samples/loops that were playing before  
      This is a known limitation of the mixer, calling *MixerStop()* clears all mixer samples still in progress.

    - Exiting a program that uses the mixer to the OS does not stop looping / playing samples  
      This is caused by the mixer still running when the program exists. Call *MixerStop()* and *MixerRemoveHandler()* prior to exiting the program.

    - Exiting a program that uses the mixer to the OS causes a crash or unexpected behaviour when another program is used later to play back sound  
      This is caused by not resetting the previously used interrupt vector for the audio interrupt to it's original vector (i.e. the one in use prior to starting the program the uses the mixer). Normally this can be fixed by calling *MixerInstallHandler()* with D0 set to 0 to make sure interrupt vector is saved for restoring by *MixerRemoveHandler()* later.

      If having the mixer save/restore the vector in this way is not desired, it can also be fixed by manually saving/restoring the audio interrupt vector.

    - Exiting a program that uses the mixer to the OS causes the keyboard to stop working  
      This is caused by setting *MIXER_CIA_TIMER* to 1 in mixer_config.i, but not setting *MIXER_CIA_KBOARD_RES* to 1 in mixer_config.i. Alternatively, it can also be caused by setting both these values to 1 in mixer_config.i, but either not calling *MixerRemoveHandler()* or calling it too early.

      If OS keyboard restoring is desired in this case, *MixerRemoveHandler()* needs to be called as late as possible. Preferably as one of the last things prior to exiting the program and certainly within 2-3 frames before the program exits.

2.  #### Issues with sample playback

    - Playing back a sample through the mixer causes the system to crash  
      This is caused by running on a 68000/68010 based system and playing a sample stored on an odd address in memory.

    - Playing a single sample back through the mixer sounds fine, playing multiple samples through the mixer at the same time results in heavily distorted audio  
      This is caused by not properly pre-processing the samples. See ["Pre-processing samples"](#pre-processing-samples) for more information.

    - Samples played back through the mixer are very quiet  
      This can be caused by pre-processing the samples more than once, or by using samples that were quiet to begin with. Note that apparent sample playback volume using the mixer will always be lower than not using the mixer due to the way the mixer works, but it can be made worse by using samples that themselves are quiet to begin with.

      For more information on generating/choosing samples for use with the mixer in such a way that this problem is minimized, see ["Best practices for source samples"](#best-practices-for-source-samples).

    - Samples played back through the mixer are cut off prematurely or have an audible pop/tick/glitch at the end  
      The mixer plays back samples in blocks. These blocks are either 4 bytes, 32 bytes or *mixer_PAL_buffer_size* (*mixer_NTSC_buffer_size* when running on a NTSC system) in length. The length of the block is determined by how the mixer_config.i file is set up.

      The consequence of the mixer using blocks of bytes is that samples themselves must also be multiples of this block size. To fix the audio glitches, make sure that the samples are a multiple of this block size in length by padding them to the nearest multiple with bytes filled with 0.

      Note that the supplied SampleConverter tool automatically pads samples with zeroes to a multiple of 4 bytes.

    - Samples played back in a loop don't loop seamlessly or have odd repetition timing  
      The mixer plays back samples in blocks. These blocks are either 4 bytes, 32 bytes or *mixer_PAL_buffer_size* (*mixer_NTSC_buffer_size* when running on a NTSC system) in length. The length of the block is determined by how the mixer_config.i file is set up.

      The consequence of the mixer using blocks of bytes is that loops are also played back in multiples of this block size. This means that a seamless loop must be an exact multiple of the block size in length. If the samples are padded with zeroes to a multiple of the block size, those empty bytes will still get played, which can alter the timing of the loop.

    - Playing back very short samples in loops uses a lot of CPU time  
      Very short\* looping samples require the mixer to potentially run the mixing loop in smaller increments and/or more often. This increases CPU overhead. To solve this issue, either play back longer loops or set *MIXER_SIZEX32* to 1. This forces the mixer to always mix in blocks of 32 bytes, which is faster than looping smaller amounts.

      Note however that this setting does also imply that samples have to be multiples of 32 bytes in size.

      \*) for this purpose, "very short" is technically any sample that is less long than the amount of bytes played per frame by the mixer. The shorter samples get below this threshold, the more CPU time they will use to play back in a loop.

    - When playing back multiple looping samples at the same time, no other samples will play  
      The mixer will not overwrite looping samples with other samples, even if they are of higher priority. To stop a looping sample, use the *MixerStopFX()* routine with the hardware/mixer channel combination the loop is playing on.

      If all mixer channels are playing looping samples, stopping one or more of them will allow other samples to play again.

3.  #### Callback issues

    - The callback function set does not fire when samples end  
      This is usually caused by not having enabled callback functionality in mixer_config.i. To enable callback functionality, set *MIXER_ENABLE_CALLBACK* to 1 in mixer_config.i

    - The callback function does not trigger when samples loop, nor when *MixerStop()* or *MixerStopFx()* is called  
      Callbacks only trigger when a sample stops playback by reaching its end, they do not trigger when samples loop, or are ended by calling *MixerStop()* or *MixerStopFx()*.

    - The callback function does trigger, but new samples played back by it do not seamlessly follow the end of the old sample  
      This is caused by not playing back the new sample correctly. In order to get seamless playback, the callback routine has to play the new sample on the same mixer channel as the old sample just ended on. Then, it needs to set D0 to 1 as a return value prior to returning.

    - When a callback triggers, the mixer either crashes or starts behaving in a weird way  
      This is either caused by not properly saving and restoring all registers other than D0, or by setting D0 to a non-zero value prior to returning while not starting a new sample on the channel of the sample that just ended playback.

4.  #### Plugin issues

    - Plugins attached to samples do not activate  
      This is either caused by not having plugin support enabled in mixer_config.i, by setting the *mfx_plugin_ptr* to 0 (or NULL in C programs) or by not filling the MXPlugin structure correctly.

    - When a plugin is attached to a sample, the mixer plays silence for that sample  
      This is caused by setting *mpl_plugin_type* to *MIX_PLUGIN_STD* for plugins that do not output data. Set *mpl_plugin_type* to *MIX_PLUGIN_NODATA* for these type of plugins.

      Alternatively, this can also be caused by setting the plugin initialisation data to values that cause silent output, such as setting the volume plugin to table lookup with volume 0.

    - When a built-in plugin is attached to a sample, the mixer crashes, the plugin behaves weirdly or the mixer behaves weirdly  
      This is usually caused by setting up the *MXPlugin* structure incorrectly.

      Here are some possible problems:

      - the pointer set in *mfx_plugin_ptr* is not pointing to the correct location
      - the pointer(s) set in either *mpl_init_ptr*, *mpl_plugin_ptr* or *mpl_init_data_ptr* are not correct

    - When a custom plugin is attached to a sample, the mixer crashes, the plugin behaves weirdly or the mixer behaves weirdly  
      This can have various reasons, the most common ones are:

      - There are issues in the set up of the *MXPlugin* structure, such as the ones named in the problem above
      - The custom plugin attempts to play back new samples without using a a deferred plugin routine
      - The custom plugin does not correctly save and restore registers
      - The custom plugin initialisation data was not correct
      - The custom plugin inadvertently takes so much CPU time that the mixer interrupt starts to overrun the starting time of the next interrupt
      - The custom plugin routine might require a 68020 or better and is being used on a 68000

    - CPU use goes up dramatically when playing back (several) samples using the Volume or Pitch plugins  
      These plugins use a lot of CPU time, especially on a 7MHz 68000.

    - When using the Pitch plugin, the sample's pitch does not sound correct or it has odd distortions  
      The Pitch plugin resamples the sample data to a new pitch given a ratio. This is unlike module players or manually playing back samples, in which case changing pitch means changing the playback period. Resampling can introduce aliasing, which is the cause behind the incorrect pitch or odd distortions heard.

      To limit aliasing, make sure that the period of the mixer is set high enough to correctly play back the highest frequency sample post pitch change. This can be done by either limiting the ratio of pitch change applied, or by doing spectrum analysis of the sample in audio processing software and adjusting the mixer playback period based on that.

      Note that the low quality Pitch change mode is much more likely to cause these kind of distortions.

5.  #### Other issues

    - The makefile does not work / gives errors  
      The makefile was created to work on Windows based systems, on other OS's the paths need to be changed to use the correct slash type. Similarly, the makefile was created to work using VASM, VLINK and VBCC and expects them in the path. If the makefile is changed to use a different assembler, linker or compiler is chosen, the makefile might need further changes.

      Note that a makefile_unix.mak file is provided that does use the correct slashes and uses standard Unix commands for file access. Try using this file, editting it as needed.

    - Assembling the mixer generates messages and results in a non-working object file  
      This is caused by a non-valid configuration in mixer_config.i. Check the number of channels selected, the output channels selected and whether only one mixer type has been configured.

    - Assembling the mixer generates assembler errors  
      This can be caused by using a different assembler than VASM. In particular, the mixer.asm file uses the echo directive and many macro's. The use of the echo directive can be disabled in mixer_config.i, the macro's are integral to the mixer.

      In case of issues, it's recommended to use VASM & VLINK to assemble and link the mixer instead of other assemblers/linkers.

    - On a 68020+ system, performance is much lower than expected  
      This is caused by either not setting *MIXER_68020* to 1 in mixer_config.i, or by having either the mixer buffers or sample source data not aligned on 4 byte boundaries.

      For optimal performance on 68020+ systems, set *MIXER_68020* to 1 in mixer_config.i and make sure the mixer buffers and all samples used are aligned on 4 byte boundaries.

    - The mixer does not work correctly on a highly expanded system and/or causes issues on FPGA based systems / emulators  
      The mixer has been designed to enable fast mixing on low end Amiga systems. It should be compatible across a large number of configurations, but certain setups may cause issues.

      In particular, highly expanded Amiga's might contain expansions that are incompatible with disabling the OS. In this case, disable the expansions or try using a wrapper such as WHDLoad. In case of hardware CPU emulators such as the PiStorm, make sure it is set up to be as compatible as possible.

      Another possible issue can arise with emulators or FPGA systems. On such environments, it is required that the Amiga chipset and 68000 must be emulated/implemented in a compatible manner. Try setting the emulator or FPGA system used to the most compatible settings possible (for instance, the mixer will run just fine on WinUAE when it is set to cycle exact mode and does not have JIT active).

      If setting your FPGA system/emulator of choice to its most compatible settings does not solve the issue, contact the creator of the emulator / FPGA system for support.

### Performance data

The performance of the mixer depends on the chosen configuration and target system. To give an idea of what performance to expect, results for several period values and other settings have been compiled into a table, which is included below. The value given is the percentage of CPU time used per frame.

Note that performance figures for *MIXER_MULTI=1* also apply to *MIXER_MULTI_PAIRED=1* and are the results for playing back on a single hardware channel. Adding extra hardware channels basically scales linearly.

For reference, the results of the previous version of the mixer (2.0) are also included. Note that these are slightly worse than reported on the website or in the example program for mixer version 2.0. The difference is due to a new method for measuring performance. The old method incorrectly excluded part of the overhead involved in dealing with the interrupt and setting hardware registers.

#### About the used configurations & systems:

- Standard = no optimisations enabled  
- Optimised = *MIXER_SIZEXBUF*=1 and *MIXER_WORDSIZED*=1

  Note that on systems with a 68020+, optimised has MIXER_68020=1 set instead

- A500/slow = 68000@7MHz, 512KB Chip RAM / 512KB Slow RAM\*  
- A500/fast = 68000@7MHz, 512KB Chip RAM / 512KB Fast RAM  
- A1200/chip = 68020@14MHz, 2MB Chip RAM  
- A1200/fast = 68020@14MHz, 2MB Chip RAM / 8MB Fast RAM  
- A1200/030 = 68030@50MHz, 2MB Chip RAM / 16MB Fast RAM

  \*) i.e. a standard trapdoor RAM expansion

#### Results for mixer without callback or plugin support

#### 8KHz (period = 443):

| Standard           | A500/slow | A1200/chip |
|--------------------|-----------|------------|
| Single 3 chan      | 2,5%      | 1,3%       |
| Single 4 chan      | 3,0%      | 1,5%       |
| Single 3 chan (HQ) | 8,4%      | 3,6%       |
| Single 4 chan (HQ) | 9,9%      | 4,4%       |
| Multi 3 chan       | 2,6%      | 1,3%       |
| Multi 4 chan       | 3,1%      | 1,6%       |
| Multi 3 chan (HQ)  | 8,5%      | 3,7%       |
| Multi 4 chan (HQ)  | 10,0%     | 4,4%       |

| Optimised     | A500/slow | A1200/chip |
|---------------|-----------|------------|
| Single 3 chan | 2,2%      | 1,3%       |
| Single 4 chan | 2,7%      | 1,5%       |
| Multi 3 chan  | 2,3%      | 1,3%       |
| Multi 4 chan  | 2,8%      | 1,6%       |

#### 11KHz (period = 322):

| Standard           | A500/slow | A1200/chip | A500/fast | A1200/fast | A1200/030 |
|--------------------|-----------|------------|-----------|------------|-----------|
| Single 3 chan      | 3,0%      | 1,5%       | 2,9%      | 0,9%       | 0,5%      |
| Single 4 chan      | 3,7%      | 1,9%       | 3,7%      | 1,0%       | 0,5%      |
| Single 3 chan (HQ) | 11,1%     | 4,7%       | 11,1%     | 4,0%       | 1,4%      |
| Single 4 chan (HQ) | 13,1%     | 5,7%       | 3,5%      | 1,0%       | 0,5%      |
| Multi 3 chan       | 3,1%      | 1,6%       | 3,0%      | 0,9%       | 0,5%      |
| Multi 4 chan       | 3,8%      | 1,9%       | 3,7%      | 1,0%       | 0,6%      |
| Multi 3 chan (HQ)  | 11,2%     | 4,8%       | 10,9%     | 4,0%       | 1,5%      |
| Multi 4 chan (HQ)  | 13,2%     | 5,8%       | 12,9%     | 4,7%       | 1,7%      |

| Optimised     | A500/slow | A1200/chip | A500/fast | A1200/fast | A1200/030 |
|---------------|-----------|------------|-----------|------------|-----------|
| Mixer 2.0 4ch | 3,4%      | n.a.       | n.a.      | n.a.       | n.a.      |
| Single 3 chan | 2,7%      | 1,5%       | 2,7%      | 0,8%       | 0,4%      |
| Single 4 chan | 3,4%      | 1,9%       | 3,4%      | 1,0%       | 0,5%      |
| Multi 3 chan  | 2,8%      | 1,6%       | 2,7%      | 0,8%       | 0,5%      |
| Multi 4 chan  | 3,5%      | 1,9%       | 3,4%      | 0,9%       | 0,5%      |

Entries marked as n.a. were not measured (but can be configured/work).

#### 22KHz (period = 161):

| Standard           | A500/slow | A1200/chip | A500/fast | A1200/fast | A1200/030 |
|--------------------|-----------|------------|-----------|------------|-----------|
| Single 3 chan      | 4,9%      | 2,5%       | 4,9%      | 1,4%       | 0,7%      |
| Single 4 chan      | 6,2%      | 3,2%       | 6,2%      | 1,6%       | 0,8%      |
| Single 3 chan (HQ) | 20,7%     | 8,8%       | 20,8%     | 7,6%       | 2,6%      |
| Single 4 chan (HQ) | 24,8%     | 10,6%      | 24,8%     | 9,0%       | 3,6%      |
| Multi 3 chan       | 5,0%      | 2,6%       | 4,8%      | 1,5%       | 0,9%      |
| Multi 4 chan       | 6,3%      | 3,1%       | 6,1%      | 1,6%       | 0,9%      |
| Multi 3 chan (HQ)  | 20,8%     | 8,8%       | 20,3%     | 7,6%       | 2,6%      |
| Multi 4 chan (HQ)  | 25,0%     | 10,7%      | 24,3%     | 9,0%       | 3,6%      |

| Optimised     | A500/slow | A1200/chip | A500/fast | A1200/fast | A1200/030 |
|---------------|-----------|------------|-----------|------------|-----------|
| Single 3 chan | 4,7%      | 2,5%       | 4,7%      | 1,3%       | 0,7%      |
| Single 4 chan | 5,9%      | 3,2%       | 5,6%      | 1,6%       | 0,8%      |
| Multi 3 chan  | 4,8%      | 2,6%       | 4,6%      | 1,3%       | 0,7%      |
| Multi 4 chan  | 6,0%      | 3,3%       | 5,8%      | 1,6%       | 0,8%      |

#### Results for mixer with callback and/or plugin support

| Standard                 | A500/slow | A1200/chip | A500/fast | A1200/fast | A1200/030 |
|--------------------------|-----------|------------|-----------|------------|-----------|
| Callback (idle)          | 3,7%      | 2,0%       | 3,7%      | 1,0%       | 0,5%      |
| Plugin (idle)            | 4,1%      | 2,3%       | 4,0%      | 1,1%       | 0,6%      |
| Callback + plugin (idle) | 4,1%      | 2,3%       | 4,0%      | 1,1%       | 0,6%      |

Tests done @11KHz, 4 mixer channels, 1 hardware channel

#### Results for supplied plugins

| Standard            | A500/slow | A1200/chip | A500/fast | A1200/fast | A1200/030 |
|---------------------|-----------|------------|-----------|------------|-----------|
| Repeat              | 4,4%      | 2,5%       | 4,4%      | 1,2%       | 0,7%      |
| Sync                | 4,8%      | 2,8%       | 4,8%      | 1,3%       | 0,7%      |
| Volume (table)      | 24,9%     | 11,1%      | 24,8%     | 7,1%       | 2,9%      |
| Volume (shift)      | 25,4%     | 10,8%      | 25,4%     | 6,9%       | 2,7%      |
| Pitch (Low Quality) | 17,0%     | 6,1%       | 17,0%     | 3,8%       | 1,8%      |
| Pitch (Standard)    | 32,6%     | 11,1%      | 32,6%     | 6,9%       | 2,7%      |

Tests done @11KHz, 4 mixer channels, 1 hardware channel. Plugins active on all 4 channels

### Best practices for source samples

In order to get the best possible results out of the mixer, the samples used by the mixer should be chosen/designed around the way the mixer works. The primary issue when playing back sounds through the mixer is that the apparent volume of samples that are played back goes down due to the required pre- processing.

Note: running the mixer in HQ mode resolves these issues without needing to deal with special audio quality requirements for samples. This does use much more CPU time, though.

#### There are two ways to deal with this issue:

1.  lower the maximum number of samples mixed together by lowering *mixer_sw_channels* in mixer_config.i. This will allow pre-processing samples for fewer voices, which will increase the apparent volume. The obvious drawback of this approach is that the mixer will support playing back fewer samples at the same time.

2.  use audio processing software to lower the dynamic range of the samples and push them as close as possible to maximum volume. This can be done using both compressors, limiters and "loudness-normalising"\*.

    \*) Note that this is not the same as "normalising", which doesn't change perceived loudness.

Other than the above methods, the best practice is to generate/choose source samples that are "as loud as possible" and have fairly low dynamic range. This does not mean that samples can't have dynamic range, but be aware that the mixer works best with samples that do not have large swings in volume.

A second issue that is faced by samples played back by the mixer is that the signal to noise ratio will be worse due to the lower number of effective bits the mixer has available for samples, while the output hardware and it's limits have not changed. As such, it's recommended to avoid using samples that require a very low signal to noise ratio to sound well.

### Acknowledgements

The mixer examples use some code made by others and use music and samples made by others as well. In addition to that, several people have helped me during the development of the mixer. In this section, I show my appreciation for the help and free resources offered by these people.

#### Thanks for advice, help and support during my coding efforts go to:

- h0ffman at the AmigaGameDev Discord for testing an early version of the mixer and providing feedback and suggestions
- nivrig, KaiN and Jobbo at the AmigaGameDev Discord for help integrating the mixer in C programs
- agermose at the AmigaGameDev discord for providing unsigned 32 to 32 bit long division code for use in the plugins
- McGeezer for providing the AmigaGameDev Discord
- And undoubtedly others I've forgotten!

#### Thanks for resources and code I've been able to use in this project go to:

- The mixer examples use the module SneakyChick.mod, which was kindly provided to me on a freeware/non-commercial use basis by Roald Strauss @ IndieGameMusic.com. Further distribution/use of this module requires a license. Visit [IndieGameMusic.com](https://indiegamemusic.com/) to license this or one of the many other tracks they provide for use in your own productions.
- The mixer examples uses several samples provided on freesound.org under the Creative Commons CC0 license. These samples are:
  - <https://freesound.org/people/egomassive/sounds/536741/>
  - <https://freesound.org/people/Daleonfire/sounds/376694/>
  - <https://freesound.org/people/GameAudio/sounds/220173/>
  - <https://freesound.org/people/derplayer/sounds/587196/>
  - <https://freesound.org/people/Latranz/sounds/520200/>
  - <https://freesound.org/people/NovaSoundTechnology/sounds/118750/>
  - <https://freesound.org/people/aunrea/sounds/495658/>
  - <https://freesound.org/people/skymary/sounds/412017/>

  The full text of the CC0 license can be found here: <https://creativecommons.org/publicdomain/zero/1.0/legalcode>
- The mixer examples use PT Player 6.3 by Frank Wille, who has released this ProTracker player under a public domain license.
- The mixer examples use LSP 1.10 by Arnaud Carré, who has released this ProTracker converter/player under the MIT license.
- The mixer plugins use unsigned 32 to 32 bit long division code by agermose on the AmigaGameDev discord.
- The mixer examples use startup code by Henrik Erlandsson, who has released this code under the MIT license.
- The mixer examples use Joystick reading code based on a forum thread on eab.abime.net (<https://eab.abime.net/showpost.php?p=986196&postcount=2>).

Full license information for the PT Player, LSP converter/player and startup code can be found in LICENSE files included in their respective directories.

### License/Disclaimer

With exception of the items listed in the ["Acknowledgements"](#acknowledgements) section of this document, all code, documentation and other files fall under the following license:

Copyright (c) 2023-2024 Jeroen Knoester

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.