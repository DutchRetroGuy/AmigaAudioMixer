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

	include exref.i

; External references
	EXREF	BUILD_COPPERLIST,clist1
	EXREF	BUILD_COPPERLIST,pal1
	EXREF	BUILD_COPPERLIST,bpptrs
	EXREF	BUILD_COPPERLIST,bpptrs_o
	EXREF	BUILD_COPPERLIST,shifts
	EXREF	BUILD_COPPERLIST,shifts_o
	EXREF	BUILD_COPPERLIST,sbptrs
	EXREF	BUILD_COPPERLIST,pal2
	
	EXREF	BUILD_COPPERLIST,clist_end
	EXREF	BUILD_COPPERLIST,clist_size

; End of File