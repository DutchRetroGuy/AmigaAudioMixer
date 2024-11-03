; $VER: font.asm 2.0 (08.05.24)
;
; font.asm
; 
; Simple font routines (8x8) for printing debug messages etc.
; Supports both standard and inverted printing.
;
; Note: uses the CC0 font "Public Pixel Font" by GGBot
;       See: https://ggbot.itch.io/public-pixel-font for more information
;       Also see "Public_Pixel_Font_1_1.zip" in the current directory for
;       the CC0 license and original true-type font files.
;
; Note: these routines are designed as a simple way to display text on the
;       screen and are quite slow. No optimisation has been done to this code.
;
; Author: Jeroen Knoester
; Version: 2.0
; Revision: 20240508
;
; Assembled using VASM in Amiga-link mode.
;

; External references

	; Includes  
	include exec/types.i
	include hardware/custom.i
	include hardware/dmabits.i
	include hardware/intbits.i

	include font.i

; Start of code
			section	code,code
; Font routines
			; Routine PlotCharCPU
			; This routine plots a single character to the given
			; bitmap at the given location.
			;
			; Note: this is not optimised, use it for non-time-critical
			;       purposes only!
			;
			; A0 - Pointer to fontdata
			; A1 - Pointer to destination bitmap
			; D0 - Character to plot
			; D1 - X location (in 8x8 cells)
			; D2 - Y location (in 8x8 cells)
			; D3 - Depth
			; D4 - Colour
			; D5 - Bitmap width in bytes
			; D6 - Bitmap plane size in bytes
PlotCharCPU	movem.l	d0-d7/a0-a2,-(sp)		; Deal with stack

			; Calculate offset for bitmap
			move.w	d2,d7
			asl.w	#3,d7
			mulu	d5,d7					; D7 = Y offset
			add.l	d1,d7					; D7 = X/Y offset
			
			; Calculate offset for character list
			asl.w	#3,d0
			
			; Loop over planes
			subq	#1,d3
			
.loop		asr.w	#1,d4						; Shift the palette colour
			bcc		.erase

			; Fetch all offsets/adresses
			move.l	d5,d2
			move.l	d7,d1
			lea.l	0(a0,d0),a2
			
			; Draw a character
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			
			add.l	d6,d7					; Update screen offset
			dbra	d3,.loop
			
			movem.l	(sp)+,d0-d7/a0-a2		; Deal with stack
			rts
			
.erase		; Fetch all offsets/adresses
			move.l	d5,d2
			move.l	d7,d1
			move.l	#0,a2
			
			; Draw a character
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			
			add.l	d6,d7					; Update screen offset
			dbra	d3,.loop

			movem.l	(sp)+,d0-d7/a0-a2		; Deal with stack
			rts
			
			; Routine: PlotInvertedCharCPU
			; As PlotCharCPU, but all one bits are displayed as zero bits
			; and vice versa.
PlotInvertedCharCPU
			movem.l	d0-d7/a0-a3,-(sp)		; Deal with stack

			; Calculate offset for bitmap
			move.w	d2,d7
			asl.w	#3,d7
			mulu	d5,d7					; D7 = Y offset
			add.l	d1,d7					; D7 = X/Y offset
			
			; Calculate offset for character list
			asl.w	#3,d0
			
			; Loop over planes
			subq	#1,d3
			
.loop		asr.w	#1,d4						; Shift the palette colour
			bcc		.erase

			; Fetch all offsets/adresses
			move.l	d5,d2
			move.l	d7,d1
			lea.l	0(a0,d0),a2
			
			; Draw a character
			move.l	d7,a3
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			move.l	a3,d7
			
			add.l	d6,d7					; Update screen offset
			dbra	d3,.loop
			
			movem.l	(sp)+,d0-d7/a0-a3		; Deal with stack
			rts
			
.erase		; Fetch all offsets/adresses
			move.l	d5,d2
			move.l	d7,d1
			
			; Draw a character
			move.b	#$0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$0,0(a1,d1.l)
			
			add.l	d6,d7					; Update screen offset
			dbra	d3,.loop

			movem.l	(sp)+,d0-d7/a0-a3		; Deal with stack
			rts
			
			; Routine PlotTextCPU
			; This routine plots a given string to the given
			; bitmap. It uses PlotCharCPU to do so. No range
			; checking is done and the Y coordinate is never
			; updated.
			;
			; Note: this is not optimised, use it for non-time-critical
			;       purposes only!
			;
			; A0 - Pointer to fontdata
			; A1 - Pointer to destination bitmap
			; A2 - List of characters to plot
			; D0 - Length of string
			; D1 - Starting X location (in 8x8 cells)
			; D2 - Y location (in 8x8 cells)
			; D3 - Depth
			; D4 - Colour
			; D5 - Bitmap width in bytes
			; D6 - Bitmap plane size in bytes
PlotTextCPU	movem.l	d0-d7/a0-a6,-(sp)		; Deal with stack

			move.w	d0,d7
			subq	#1,d7
			moveq	#0,d0
			
.loop		move.b	(a2)+,d0				; Fetch character
			sub.b	#32,d0					; Convert to ASCII
			bmi		.cnt					; Skip invalid characters
			jsr		PlotCharCPU
.cnt		addq	#1,d1
			dbra	d7,.loop

			movem.l	(sp)+,d0-d7/a0-a6		; Deal with stack
			rts
			
			; Routine: PlotInvertedTextCPU
			; As PlotTextCPU, but all one bits are treated as zero bits and
			; vice versa.
PlotInvertedTextCPU	
			movem.l	d0-d7/a0-a6,-(sp)		; Deal with stack

			move.w	d0,d7
			subq	#1,d7
			moveq	#0,d0
			
.loop		move.b	(a2)+,d0				; Fetch character
			sub.b	#32,d0					; Convert to ASCII
			bmi		.cnt					; Skip invalid characters
			jsr		PlotInvertedCharCPU
.cnt		addq	#1,d1
			dbra	d7,.loop

			movem.l	(sp)+,d0-d7/a0-a6		; Deal with stack
			rts

			; Routine PlotTextMultiCPU
			; This routine plots a set of lines of text to the given bitmap.
			; It uses PlotTextCPU to plot the actual text.
			;
			; Note: this is not optimised, use it for non-time-critical
			;       purposes only!
			;
			; A1 - Pointer to destination bitmap
			; A3 - pointer to lines of text to plot.
			; D3 - Depth
			; D4 - Text mode (0 = normal, 1 = inverted)
			; D5 - Bitmap width in bytes
			; D6 - Bitmap plane size in bytes
PlotTextMultiCPU
			movem.l	d0-d7/a0-a6,-(sp)	; Stack
			lea.l	basicfont,a0
			lea.l	PlotTextCPU(pc),a4
			tst.w	d4
			beq		.prep_lp
			
			lea.l	PlotInvertedTextCPU(pc),a4
			
.prep_lp	move.w	(a3)+,d7			; Get loop counter
			subq	#1,d7
			
			; Loop over lines of text
.lp			movem.w	(a3)+,d0-d2
			move.w	(a3)+,d4
			exg		d0,d4			; Correct order for PlotTextCPU
			move.l	a3,a2
			jsr		(a4)			; PlotTextCPU/PlotInvertedTextCPU
			lea.l	0(a3,d0),a3		; Next line
			dbra	d7,.lp
			movem.l	(sp)+,d0-d7/a0-a6	; Stack
			rts
			
			section	gfxdata,data_c
			cnop	0,2						; Is this needed?

; Basic font (8x8)
basicfont		dc.b	$00,$00,$00,$00,$00,$00,$00,$00
				dc.b	$00,$30,$78,$78,$78,$30,$00,$30
				dc.b	$00,$6c,$6c,$24,$48,$00,$00,$00
				dc.b	$00,$6c,$fe,$6c,$6c,$6c,$fe,$6c
				dc.b	$00,$10,$7e,$d0,$7c,$16,$fc,$10
				dc.b	$00,$42,$a6,$4c,$18,$34,$6a,$c4
				dc.b	$00,$70,$d8,$70,$da,$ce,$c6,$7c
				dc.b	$00,$30,$30,$10,$20,$00,$00,$00
				dc.b	$00,$1c,$30,$60,$60,$60,$30,$1c
				dc.b	$00,$70,$18,$0c,$0c,$0c,$18,$70
				dc.b	$00,$6c,$38,$6c,$00,$00,$00,$00
				dc.b	$00,$00,$00,$10,$10,$7c,$10,$10
				dc.b	$00,$00,$00,$00,$30,$30,$10,$20
				dc.b	$00,$00,$00,$00,$00,$7c,$00,$00
				dc.b	$00,$00,$00,$00,$00,$00,$30,$30
				dc.b	$00,$04,$0c,$18,$30,$60,$c0,$80
				dc.b	$00,$7c,$ce,$c6,$c6,$c6,$e6,$7c
				dc.b	$00,$78,$18,$18,$18,$18,$18,$7e
				dc.b	$00,$7c,$c6,$0c,$38,$60,$c0,$fe
				dc.b	$00,$7c,$c6,$06,$3c,$06,$c6,$7c
				dc.b	$00,$1e,$36,$66,$c6,$fe,$06,$06
				dc.b	$00,$fe,$c0,$fc,$06,$06,$c6,$7c
				dc.b	$00,$7c,$c6,$c0,$fc,$c6,$c6,$7c
				dc.b	$00,$fe,$c6,$0c,$18,$30,$60,$c0
				dc.b	$00,$7c,$c6,$c6,$7c,$c6,$c6,$7c
				dc.b	$00,$7c,$c6,$c6,$7e,$06,$c6,$7c
				dc.b	$00,$00,$00,$30,$30,$00,$30,$30
				dc.b	$00,$00,$00,$30,$30,$00,$30,$10
				dc.b	$00,$00,$00,$1c,$38,$70,$38,$1c
				dc.b	$00,$00,$00,$00,$7c,$00,$7c,$00
				dc.b	$00,$00,$00,$70,$38,$1c,$38,$70
				dc.b	$00,$7c,$c6,$06,$3c,$30,$00,$30
				dc.b	$00,$7c,$c6,$d6,$d6,$dc,$c0,$7c
				dc.b	$00,$38,$6c,$c6,$c6,$fe,$c6,$c6
				dc.b	$00,$fc,$c6,$c6,$fc,$c6,$c6,$fc
				dc.b	$00,$7c,$c6,$c0,$c0,$c0,$c6,$7c
				dc.b	$00,$f8,$cc,$c6,$c6,$c6,$cc,$f8
				dc.b	$00,$fe,$c0,$c0,$f8,$c0,$c0,$fe
				dc.b	$00,$fe,$c0,$c0,$f8,$c0,$c0,$c0
				dc.b	$00,$7e,$c0,$c0,$de,$c6,$c6,$7e
				dc.b	$00,$c6,$c6,$c6,$fe,$c6,$c6,$c6
				dc.b	$00,$7e,$18,$18,$18,$18,$18,$7e
				dc.b	$00,$1e,$06,$06,$06,$c6,$c6,$7c
				dc.b	$00,$c6,$cc,$d8,$f0,$d8,$cc,$c6
				dc.b	$00,$c0,$c0,$c0,$c0,$c0,$c0,$fe
				dc.b	$00,$c6,$ee,$fe,$d6,$c6,$c6,$c6
				dc.b	$00,$c6,$e6,$f6,$de,$ce,$c6,$c6
				dc.b	$00,$7c,$c6,$c6,$c6,$c6,$c6,$7c
				dc.b	$00,$fc,$c6,$c6,$fc,$c0,$c0,$c0
				dc.b	$00,$7c,$c6,$c6,$c6,$de,$cc,$7a
				dc.b	$00,$fc,$c6,$c6,$fc,$d8,$cc,$c6
				dc.b	$00,$7c,$c6,$c0,$7c,$06,$c6,$7c
				dc.b	$00,$7e,$18,$18,$18,$18,$18,$18
				dc.b	$00,$c6,$c6,$c6,$c6,$c6,$c6,$7c
				dc.b	$00,$c6,$c6,$c6,$c6,$6c,$38,$10
				dc.b	$00,$c6,$c6,$d6,$fe,$ee,$c6,$c6
				dc.b	$00,$c6,$ee,$7c,$38,$7c,$ee,$c6
				dc.b	$00,$66,$66,$66,$3c,$18,$18,$18
				dc.b	$00,$fe,$0e,$1c,$38,$70,$e0,$fe
				dc.b	$00,$7c,$60,$60,$60,$60,$60,$7c
				dc.b	$00,$40,$60,$30,$18,$0c,$06,$02
				dc.b	$00,$7c,$0c,$0c,$0c,$0c,$0c,$7c
				dc.b	$00,$10,$38,$6c,$c6,$00,$00,$00
				dc.b	$00,$00,$00,$00,$00,$00,$00,$fe
				dc.b	$00,$20,$10,$00,$00,$00,$00,$00
				dc.b	$00,$00,$00,$7c,$06,$7e,$c6,$7e
				dc.b	$00,$c0,$c0,$fc,$c6,$c6,$c6,$fc
				dc.b	$00,$00,$00,$7c,$c6,$c0,$c6,$7c
				dc.b	$00,$06,$06,$7e,$c6,$c6,$c6,$7e
				dc.b	$00,$00,$00,$7c,$c6,$fe,$c0,$7c
				dc.b	$00,$3c,$30,$fe,$30,$30,$30,$30
				dc.b	$00,$00,$00,$7e,$c6,$7e,$06,$7c
				dc.b	$00,$c0,$c0,$fc,$c6,$c6,$c6,$c6
				dc.b	$00,$18,$00,$78,$18,$18,$18,$fe
				dc.b	$00,$06,$00,$06,$06,$06,$c6,$7c
				dc.b	$00,$c0,$c0,$c6,$cc,$f8,$cc,$c6
				dc.b	$00,$c0,$c0,$c0,$c0,$c0,$70,$1e
				dc.b	$00,$00,$00,$fc,$d6,$d6,$d6,$d6
				dc.b	$00,$00,$00,$fc,$c6,$c6,$c6,$c6
				dc.b	$00,$00,$00,$7c,$c6,$c6,$c6,$7c
				dc.b	$00,$00,$00,$fc,$c6,$fc,$c0,$c0
				dc.b	$00,$00,$00,$7e,$c6,$7e,$06,$06
				dc.b	$00,$00,$00,$dc,$e6,$c0,$c0,$c0
				dc.b	$00,$00,$00,$7e,$c0,$fe,$06,$fc
				dc.b	$00,$30,$30,$fe,$30,$30,$30,$3e
				dc.b	$00,$00,$00,$c6,$c6,$c6,$c6,$7c
				dc.b	$00,$00,$00,$c6,$c6,$6c,$38,$10
				dc.b	$00,$00,$00,$c6,$d6,$d6,$fe,$6c
				dc.b	$00,$00,$00,$ee,$7c,$38,$7c,$ee
				dc.b	$00,$00,$00,$c6,$c6,$6c,$38,$f0
				dc.b	$00,$00,$00,$fe,$1c,$38,$70,$fe
				dc.b	$00,$1c,$30,$30,$70,$30,$30,$1c
				dc.b	$00,$30,$30,$30,$30,$30,$30,$30
				dc.b	$00,$70,$18,$18,$1c,$18,$18,$70
				dc.b	$00,$00,$00,$00,$76,$d6,$dc,$00
.basicfont_end
.basicfont_size EQU .basicfont_end-basicfont
	echo "Font size in characters:"
	printv (.basicfont_size/8)+1

; End of File