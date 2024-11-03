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
; Plugin selection
;-----------------------------------------------------------------------------
; Set the defines below to 1 for each plugin that is to be included. Set them
; to 0 to exclude one or more plugins. Disabling plugins this way will remove
; them from the code base, lowering the size of the generated plugins.o file.
MXPLUGIN_REPEAT				EQU	1
MXPLUGIN_SYNC				EQU	1
MXPLUGIN_VOLUME				EQU	1
MXPLUGIN_PITCH				EQU	1

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
MXPLUGIN_68020_ONLY			EQU	0

; Set define below to 1 to remove the tables for the volume plugin. This saves
; memory and disables table based volume selection in the volume plugin. Shift
; based volume selection remains available.
;
; Note: this define has no effect if MXPLUGIN_VOLUME is set to 0.
MXPLUGIN_NO_VOLUME_TABLES	EQU	0

	ENDC	; MIXER_PLUGINS_CONFIG_I
; End of File