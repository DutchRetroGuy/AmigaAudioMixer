; $VER: plugins_wrapper.i 3.8 (04.02.24)
;
; plugins_wrapper.i
; Include file for plugins_wrapper.asm
;
;
; Author: Jeroen Knoester
; Version: 3.8
; Revision: 20250130
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
	include exref.i

; References
	EXREF	BUILD_PLUGINS_WRAPPER,PLPerfTest_init_routines
	EXREF	BUILD_PLUGINS_WRAPPER,PLPerfTest_routines
	
	EXREF	BUILD_PLUGINS_WRAPPER,plrepeat
	EXREF	BUILD_PLUGINS_WRAPPER,plsync
	EXREF	BUILD_PLUGINS_WRAPPER,plvolume
	EXREF	BUILD_PLUGINS_WRAPPER,plpitch
; End of File