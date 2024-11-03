; $VER: copperlists.asm 1.0 (07.03.19)
;
; copperlists.asm
; Copperlists for the example
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include displaybuffers.i
		include copperlists.i

		section	gfxdata,data_c
		cnop	0,2
		
		; Copperlist
clist1	dc.w	$01fc,$0000			; AGA compatibility
		dc.w	$008e,$2c92			; DIWSTRT/STOP (288x240+1 empty line)
		dc.w	$0090,$1db1
		dc.w	$0092,$0038			; DDFSTRT/STOP (304px)
		dc.w	$0094,$00c8
		dc.w	$0100,$4200			; Set 4 bitplanes standard
		dc.w	$0104,$0000			; BPLCON2 (PF2>PF1>SPR)
		dc.w	$0106,$0c60			; BPLCON3 (Lores spr/default DPL/border)
		dc.w	$010c,$0011			; BPLCON4 (Sprite colours 16-31)
		
		; Clear Sprite positions to prevent glitches
		dc.w	$0140,$0000
		dc.w	$0148,$0000
		dc.w	$0150,$0000
		dc.w	$0158,$0000
		dc.w	$0160,$0000
		dc.w	$0168,$0000
		dc.w	$0170,$0000
		dc.w	$0178,$0000
		
		dc.w	$2a01,$fffe			; Wait for line 48
pal1	blk.b	32*4				; 32 colours

bpptrs_o	EQU	bpptrs-clist1
bpptrs	dc.w	$00e0,$0000			; High pointer
		dc.w	$00e2,$0000			; Low pointer
		dc.w	$00e4,$0000
		dc.w	$00e6,$0000
		dc.w	$00e8,$0000
		dc.w	$00ea,$0000
		dc.w	$00ec,$0000
		dc.w	$00ee,$0000
		
mods	dc.w	$108,fg_disp_mod	; Modulo values
		dc.w	$10a,fg_disp_mod
		
shifts_o	EQU	shifts-clist1
shifts	dc.w	$0102,$0000			; Shift values

		; PAL wait
		dc.w	$ffdf,$fffe
		
		; Setup subbuffer
		dc.w	$0c01,$fffe	; Wait for start of line
		dc.w	$0096,$0100					; Disable bitplane DMA
		dc.w	$0cc5,$fffe					; Wait for last part of line 268
		dc.w	$0096,$8100					; Enable bitplane DMA
		dc.w	$0092,$0040					; DDFSTRT/STOP (288px)
		dc.w	$0094,$00c8

mods2	dc.w	$108,sb_disp_mod	; Modulo values
		dc.w	$10a,sb_disp_mod

		dc.w	$0100,$3200			; Set 3 bitplanes

shifts2	dc.w	$0102,$0000			; Shift values

sbptrs	dc.w	$00e0,$0000			; High pointer
		dc.w	$00e2,$0000			; Low pointer
		dc.w	$00e4,$0000
		dc.w	$00e6,$0000
		dc.w	$00e8,$0000
		dc.w	$00ea,$0000

pal2	blk.b	7*4					; 7 colours (all except 0)
		dc.w	$0104,$0000			; BPLCON2 (PF2>PF1>SPR)
		dc.w	$ffff,$fffe			; End of copperlist
clist_end
clist_size	EQU	clist_end-clist1
; End of File