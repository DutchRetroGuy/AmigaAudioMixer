; $VER: plugins.asm 1.1 (05.04.24)
;
; plugins.asm
; Audio mixer plugin routines
;
; For plugin API, see plugins.i and the rest of the mixer documentation.
;
; Note: all plugin configuration is done via plugins_config.i.
; 
; Author: Jeroen Knoester
; Version: 1.1
; Revision: 20240205
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include	mixer.i
	include plugins_config.i
	include	plugins.i
	
; Set constants for wrapper
MXPLUGIN_REPEAT		EQU	1
MXPLUGIN_SYNC		EQU	1
MXPLUGIN_VOLUME		EQU	1
MXPLUGIN_PITCH		EQU	1

; Start of code
		section code,code
	
	; Include 
	include plugins.asm
	
	; Base plugin configuration
MIXER_WORDSIZED				EQU 1
MIXER_SIZEX32				EQU 0
MIXER_SIZEXBUF				EQU 0
MXPLUGIN_NO_VOLUME_TABLES	EQU 0
MIXER_C_DEFS				EQU 1
MXPLUGIN_68020_ONLY			EQU 0

MIXER_68020					SET 0
	
	; Unoptimised tests
	PlgAllCode _000

	; 68020 optimised tests
MIXER_68020		SET 1

	PlgAllCode _020
	
PLPerfTest_init_routines
		; MixPluginInitRepeat
		dc.l	MixPluginInitRepeat_000
		dc.l	MixPluginInitRepeat_020
plperftest_block_end
		; MixPluginInitSync
		dc.l	MixPluginInitSync_000
		dc.l	MixPluginInitSync_020
		; MixPluginInitVolume
		dc.l	MixPluginInitVolume_000
		dc.l	MixPluginInitVolume_020
		; MixPluginInitPitch
		dc.l	MixPluginInitPitch_000
		dc.l	MixPluginInitPitch_020

PLPerfTest_routines
		; MixPluginRepeat
		dc.l	MixPluginRepeat_000
		dc.l	MixPluginRepeat_020
		; MixPluginSync
		dc.l	MixPluginSync_000
		dc.l	MixPluginSync_020
		; MixPluginVolume
		dc.l	MixPluginVolume_000
		dc.l	MixPluginVolume_020
		; MixPluginPitch
		dc.l	MixPluginPitch_000
		dc.l	MixPluginPitch_020
		
plperftest_block_size	EQU plperftest_block_end-PLPerfTest_init_routines

plrepeat				EQU	0
plsync					EQU	plperftest_block_size
plvolume				EQU	plperftest_block_size*2
plpitch					EQU	plperftest_block_size*3

	IF PLPERF_SIZE_TEST=1
pldata_size		EQU	pldata_end-pldata_start
pltest_vol_size	EQU	vol_tab_end-vol_level_1
pltest_size		EQU	pltest_end-pltest_start
		echo "Data size (excluding volume tables):"
		printv pldata_size
		echo "Data size (volume tables only):"
		printv pltest_vol_size
		echo "Code size:"
		printv pltest_size
	ENDIF
; End of File