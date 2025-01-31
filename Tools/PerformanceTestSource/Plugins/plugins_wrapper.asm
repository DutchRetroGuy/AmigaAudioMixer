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

; End of File