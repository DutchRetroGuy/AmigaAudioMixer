; $VER: displaybuffers.i 1.0 (07.03.19)
;
; displaybuffers.i
; 
; Include file for displaybuffer constants
;
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; References macro
	IFND EXREF
EXREF	MACRO
		IFD BUILD_DBUFFERS
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; Buffers
	EXREF	fg_buf1
	EXREF	sb_buf

; Buffer constants
display_width		EQU	288
buffer_screens		EQU	0
buffer_height		EQU	224+(32*2)
buffer_scroll_hgt	EQU buffer_height+buffer_screens
buffer_size			EQU	(display_width+(32*2))*buffer_scroll_hgt/8 ; 304x224+50 + bob space
buffer_modulo		EQU	(display_width+(32*2))/8					; Width in bytes
subbuffer_height	EQU	16
subbuffer_size		EQU	display_width*subbuffer_height/8
subbuffer_modulo	EQU	display_width/8
fg_mod				EQU	buffer_modulo*4
sb_mod	 			EQU	subbuffer_modulo*3

; Display modulos: ((width/8)*depth-1)+(width/8)-(display_width/8)-2*scroll
fg_disp_mod			EQU	(buffer_modulo*3)+(buffer_modulo-(display_width/8))-2
sb_disp_mod			EQU	subbuffer_modulo*2
; End of File