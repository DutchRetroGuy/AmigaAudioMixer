; $VER: copperlists.i 1.0 (07.03.19)
;
; copperlists.i
; Include file for copperlists.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; References macro
EXREF	MACRO
		IFD BUILD_COPPERLIST
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM

; External references
	EXREF	clist1
	EXREF	pal1
	EXREF	bpptrs
	EXREF	bpptrs_o
	EXREF	shifts
	EXREF	shifts_o
	EXREF	sbptrs
	EXREF	pal2
	
	EXREF	clist_end
	EXREF	clist_size

; End of File