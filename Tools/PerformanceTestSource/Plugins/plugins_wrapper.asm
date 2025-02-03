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
	include mixer_wrapper.i
	include plugins_config.i
	include	plugins.i
	include plugins_wrapper.i
	
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
	PlgAllCode _pl
	PlgAllCode _cbpl

	; 68020 optimised tests
MIXER_68020		SET 1

	PlgAllCode _pl020
	
PLPerfTest_init_routines
		; MixPluginInitRepeat
		dc.l	MixPluginInitRepeat_pl
		dc.l	MixPluginInitRepeat_cbpl
		dc.l	MixPluginInitRepeat_pl020
plperftest_block_end
		; MixPluginInitSync
		dc.l	MixPluginInitSync_pl
		dc.l	MixPluginInitSync_cbpl
		dc.l	MixPluginInitSync_pl020
		; MixPluginInitVolume
		dc.l	MixPluginInitVolume_pl
		dc.l	MixPluginInitVolume_cbpl
		dc.l	MixPluginInitVolume_pl020
		; MixPluginInitPitch
		dc.l	MixPluginInitPitch_pl
		dc.l	MixPluginInitPitch_cbpl
		dc.l	MixPluginInitPitch_pl020

PLPerfTest_routines
		; MixPluginRepeat
		dc.l	MixPluginRepeat_pl
		dc.l	MixPluginRepeat_cbpl
		dc.l	MixPluginRepeat_pl020
		; MixPluginSync
		dc.l	MixPluginSync_pl
		dc.l	MixPluginSync_cbpl
		dc.l	MixPluginSync_pl020
		; MixPluginVolume
		dc.l	MixPluginVolume_pl
		dc.l	MixPluginVolume_cbpl
		dc.l	MixPluginVolume_pl020
		; MixPluginPitch
		dc.l	MixPluginPitch_pl
		dc.l	MixPluginPitch_cbpl
		dc.l	MixPluginPitch_pl020
		
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