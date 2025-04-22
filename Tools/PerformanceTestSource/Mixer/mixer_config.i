;
; IMPORTANT:
; Mixer configuration below is intended *only* for the performance test 
; program.
;
; It consists of a subset of the the normal mixer_config.i file, several
; settings are omitted because the mixer.asm (performance test version) has
; duplicated functions with hardcoded settings applied.
;
; For the mixer designed for use in non-performance tests, see the Mixer 
; directory in the AudioMixer directory/archive.
;


; $VER: mixer_config.i 3.7 (30.01.25)
;
; mixer_config.i
; Configuration file for the audio mixer.
;
; For mixer API, see mixer.i and the rest of the mixer documentation.
; For more information about this configuration file, see the 
; mixer documentation.
;
; Note: the audio mixer expects samples to be pre-processed such that adding
;       sample values together for all mixer channels can never exceed 8 bit
;       signed limits or overflow from positive to negative (or vice versa).
; 
; Author: Jeroen Knoester
; Version: 3.7
; Revision: 20250130
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces
	
	IFND	MIXER_CONFIG_I
MIXER_CONFIG_I	SET	1

; Configuration defines

;-----------------------------------------------------------------------------
; Performance test configuration
;-----------------------------------------------------------------------------
PERF_SIZE_TEST			SET 0		; Set to 1 to get a report on the various 
									; code sizes of each mixer option.
									;
									; Note that data size is an approximation
									; as the largest possible structure is 
									; always in use when the performance test
									; is run.

;-----------------------------------------------------------------------------
; Mixer type configuration (set only one of these)
;-----------------------------------------------------------------------------
MIXER_SINGLE			SET 1
MIXER_MULTI				SET	0		; Set to 1 for performance test of
									; either the multi mixer or multi 
									; paired mixer options.
									; The paired mode itself can't be
									; correctly tested (one of the 
									; interrupts doesn't mix at all, 
									; which skews the results).

;-----------------------------------------------------------------------------
; Mixer output configuration
;-----------------------------------------------------------------------------
mixer_sw_channels		SET	4		; Number of software channels (1-4)
mixer_period			EQU	322		; Period value (124-65535)
									; Note: display will be correct up to a
									;       period value of 999. Higher period
									;       values are supported, but will 
									;       only show the last three digits on
									;       the display.

MIXER_PER_IS_NTSC		EQU	0		; Set to 1 if the mixer period value set
									; above is given for NTSC systems, leave
									; at 0 if it is given for PAL systems.
	ENDC	; MIXER_CONFIG_I
; End of File