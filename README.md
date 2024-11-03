# Audio Mixer 3.7 readme

The Audio Mixer is a configurable SFX engine designed to play back multiple 
samples at the same time on a single hardware channel. It achieves a high 
level of performance on even low end Amiga's (such as the A500) by making use
of optimised code and pre-processed samples. It is designed to be able to 
co-exist with music playback routines, as long as the music playback routine 
supports disabling access/playback to the hardware channel(s) the Audio Mixer
uses.

If desired, multiple hardware channels can be assigned to the Audio Mixer,
allowing for even more samples to be played at the same time. The Audio Mixer
supports native Amiga audio through Paula only and is designed for use in
programs that disable the OS.

Features:
   * Up to four samples can be mixed onto a single hardware channel.
   * High performance: mixing four samples onto a single channel at 11KHz 
     takes only 3.7% CPU time on a 7MHz 68000 without Fast RAM.
   * Optional high quality mode that uses much more CPU time, but plays full
     8-bit samples, rather than lower quality pre-processed ones.
   * Can be run while a music playback routine is running, as long as the 
     music routine does not access the hardware channel(s) used by the Audio
     Mixer.
   * Up to four hardware channels can be assigned to the Audio Mixer, allowing
     up to 16 samples being played back at the same time.
   * Sample playback is priority based, so that drowning out of important 
     effects can be prevented.
   * Samples can be stored anywhere in RAM, including in Fast RAM and Slow
     RAM.
   * Samples can be set to loop from either sample start, or from a given 
     offset into the sample and both looping/non-looping samples can be
     stopped on request
   * Samples can be assigned to one of the virtual channels the mixer uses (up 
     to 4 per hardware channel), allowing fine-grained control of SFX 
     playback.
   * Supports the use of optional plugins via a plugin system. These plugins
     can either be used as control/communication mechanism to other code, or
     to alter sample data in real time. There are several plugins included and
     custom plugins are also supported.

     The included plugins are:
        - MixPluginRepeat()
             - plays the sample sample again after a given delay.
        - MixPluginSync()
             - allows various ways to synchronise sample playback with the
               code that calls the mixer.
        - MixPluginVolume()
             - allows changing of the playback volume of the sample being
               played.
        - MixPluginPitch()
             - allows changing of the pitch of the sample being played.
   * Supports the use of a callback routine whenever sample playback ends, to
     allow custom code to be executed on sample end. The callback routine can
     immediately play back another sample if desired, which allows for 
     seamless sample-to-sample playback using this method.
   * Supports playback of samples of any size that will fit in RAM*.
   * Sample rate used can be configured at assembly time, using standard Paula
     period values.
   * Fully PC relative code is used to make relocation as easy as possible.

*) in practice, this is limited by the largest maximum single block of free 
   RAM that exists. A system with multiple memory expansions will be limited 
   to a much smaller maximum sample size than the total RAM size would seem to
   indicate.
   
The Audio Mixer is provided as full assembly source code with examples,
[documentation](Documentation/Documentation.md) and extra code to help integrate the mixer in C programs.

For more information about the Audio Mixer 3.7, see the included 
[documentation](Documentation/Documentation.md).

For more information about mixing audio on the Amiga, see the my website:
https://www.powerprograms.nl/amiga/audio-mixing.html

Please see the the included [LICENSE](LICENSE) file for full license information and
copyright.

The mixer examples use music by Roald Strauss, samples from freesound.org,
startup code by Henrik Erlandsson, the PT Player by Frank Wille and LSP by
Arnaud Carré.

The mixer plugins further use unsigned 32 to 32 bit long division code by
agermose on the AmigaGameDev discord.

Special thanks go to h0ffman, nivrig, KaiN, Jobbo and McGeezer over at the
AmigaGameDev Discord.
