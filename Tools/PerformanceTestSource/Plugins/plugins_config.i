;
; IMPORTANT:
; Plugin configuration below is intended *only* for the performance test 
; program.
;
; Due to the dynamic nature of setting the various flags during performance
; testing, it is currently empty.
;
; For the plugins designed for use in non-performance tests, see the Plugins
; directory in the AudioMixer directory/archive.
;


; $VER: plugins_config.i 1.0 (04.02.24)
;
; plugins_config.i
; Configuration file for the audio mixer plugins.
;
; For plugin API, see plugins.i and the rest of the mixer documentation.
; For more information about this configuration file, see the mixer
; documentation.
; 
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20240204
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

	IFND	MIXER_PLUGINS_CONFIG_I
MIXER_PLUGINS_CONFIG_I	SET	1
; Configuration defines

;-----------------------------------------------------------------------------
; Optimisation related options
;-----------------------------------------------------------------------------
; Set define below to 1 to allow the plugins to use code that only runs on 
; 68020+ based systems.
;
; Note: if MIXER_68020 is set to 1, the code generated for plugins will be
;       optimised for 68020+ where possible, but the generated code will not
;       use 68020+ only instructions. Setting the define below to 1 changes
;       this so that the plugin code will use 68020+ only instructions as
;       well.
MXPLUGIN_68020_ONLY		EQU	1

;-----------------------------------------------------------------------------
; Performance test configuration
;-----------------------------------------------------------------------------
PLPERF_SIZE_TEST		SET 0		; Set to 1 to get a report on the various 
									; code sizes.



	; No other configuration is needed at present.

	ENDC	; MIXER_PLUGINS_CONFIG_I
; End of File