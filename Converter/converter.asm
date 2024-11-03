; $VER: converter.asm 2.0 (07.03.23)
;
; converter.asm
; Audio conversion routines. These prepare samples for fast mixing by reducing
; bit counts or forcing positive amplitude sound.
;
; Note: these routines are not fast and are to be called once per sample,
;       prior to starting any mixing.
; 
; Author: Jeroen Knoester
; Version: 2.0
; Revision: 20230307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include	converter.i

; Start of code
		section code,code
		; Routine: ConvertSampleDivide
		; This routine converts a given sample to fewer bits.
		; Makes sure enough headroom remains for longword additions.
		; 
		; Note: this is not required when running with 1 mixer channel max.
		;
		; A0 - pointer to source sample
		; A1 - pointer to destination
		; D0 - length of the sample in bytes (long)
		; D1 - number of channels to mix (1-4)
ConvertSampleDivide
		movem.l	d0-d3/a0-a2,-(sp)			; Stack
		
		; Fetch headroom value
		lea.l	headroom_values(pc),a2
		lea.l	-1(a2,d1),a2
		move.b	(a2),d3
		subq.w	#2,d1
		bpl		.do_div
		
		; Dividing by 1 is a memory copy
		asr.l	#2,d0						; Number of longwords
		
.copy_lp
		move.l	(a0)+,(a1)+
		subq.l	#1,d0
		bne		.copy_lp
		bra		.done
		
		; Set up for loop
.do_div
		asl.w	#8,d1
		lea.l	divide_values_2+128(pc),a2
		lea.l	0(a2,d1.w),a2
		moveq	#0,d2
		
		; Divide each sample by the number of channels to mix
.div_lp	move.b	(a0)+,d2
		ext.w	d2
		move.b	(a2,d2.w),d2
		
		; Deal with headroom (positive numbers only)
		tst.b	d2
		bmi		.store
		sub.b	d3,d2
		
.store	move.b	d2,(a1)+
		subq.l	#1,d0
		bne		.div_lp
		
.done
		movem.l	(sp)+,d0-d3/a0-a2			; Stack
		rts
		
		; Headroom modifier for 1,2,3 and 4 channels
		; This value needs to be subtracted from any positive sample byte
headroom_values	dc.b 0,0,1,0

		; Pre-calculated division tables to speed up the divisions.
divide_values_2	REPT 256
				dc.b (-128+REPTN)/2
				ENDR
divide_values_3 REPT 256
				dc.b (-128+REPTN)/3
				ENDR
divide_values_4 REPT 256
				dc.b (-128+REPTN)/4
				ENDR

; End of File