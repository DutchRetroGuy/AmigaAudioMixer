; $VER: blitter.asm 1.0 (07.03.19)
;
; blitter.asm
; 
; Contains blitter routines for the example program.
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes 
	include exec/types.i
	include hardware/custom.i
	include hardware/dmabits.i
	include hardware/intbits.i
	
	include blitter.i
	include tiles.i
	include displaybuffers.i
		
		; Blitting routines
		section code,code

		; Routine: BlitPattern
		; This routine blits a single word pattern to a given bitmap
		; D1 = word pattern to blit
		; D4 = DMOD value
		; D5 = BLTSIZE value
		; A2 = Destination bitmap
BlitPattern
		BlitWait a6
		move.l	bl_clear,bltcon0(a6)
		move.w	d4,bltdmod(a6)
		move.w	d1,bltadat(a6)
		move.l	a2,bltdpt(a6)
		move.w	d5,bltsize(a6)
		rts

		; Routine BlitCopy
		; This routine copies a given bitmap to a destination bitmap
		; D4 = ADMOD value
		; D5 = BLTSIZE value
		; A2 = Source bitmap
		; A3 = Destination bitmap
BlitCopy
		BlitWait a6
		move.l	bl_copy,bltcon0(a6)
		move.l	d4,bltamod(a6)
		move.l	a2,bltapt(a6)
		move.l	a3,bltdpt(a6)
		move.w	d5,bltsize(a6)
		rts
		
		; Routine: BlitClearScreen
		; This routine clears a given buffer
		; A0 = Pointer to buffer
		; D0 = blitsize
BlitClearScreen
		; Wait on Blitter
		BlitWait a6
		
		; Clear the buffer
		move.l	#$ffffffff,bltafwm(a6)
		move.l	bl_clear,bltcon0(a6)
		move.w	#$0000,bltdmod(a6)
		move.w	#$0000,bltadat(a6)
		move.l	a0,bltdpt(a6)
			
		; Start blit
		move.w	d0,bltsize(a6)
		rts
		
		; Routine: DrawSubBuffer
		; This routine draws the Sub Buffer tiles
DrawSubBuffer
		; Fetch the tilemap, tiles and subbuffer
		lea.l	sb_tile_map,a0
		lea.l	sb_tiles,a1
		move.l	sb_buf,a3
		
		; Set up registers for BlitCopy
		move.l	#subbuffer_modulo-2,d4
		move.w	#sb_tbsize,d5
		
		; Loop over tiles
		moveq	#(display_width/16)-1,d7
.lp		move.w	(a0)+,d1		; Fetch tile
		mulu	#sb_tsize,d1
		lea.l	0(a1,d1),a2		; Source
		bsr		BlitCopy
		lea.l	2(a3),a3		; Move to next spot in destination
		dbra	d7,.lp
		rts
		
		section data,data
		cnop	0,2

		; Bltcon tables for bob minterms/shifts (base tables)
bl_bob		dc.l	$0fca0000,$1fca1000,$2fca2000,$3fca3000
			dc.l	$4fca4000,$5fca5000,$6fca6000,$7fca7000
			dc.l	$8fca8000,$9fca9000,$afcaa000,$bfcab000
			dc.l	$cfcac000,$dfcad000,$efcae000,$ffcaf000
bl_copy		dc.l	$09f00000,$19f01000,$29f02000,$39f03000
			dc.l	$49f04000,$59f05000,$69f06000,$79f07000
			dc.l	$89f08000,$99f09000,$a9f0a000,$b9f0b000
			dc.l	$c9f0c000,$d9f0d000,$e9f0e000,$f9f0f000
bl_clear	dc.l	$01f00000,$11f01000,$21f02000,$31f03000
			dc.l	$41f04000,$51f05000,$61f06000,$71f07000
			dc.l	$81f08000,$91f09000,$a1f0a000,$b1f0b000
			dc.l	$c1f0c000,$d1f0d000,$e1f0e000,$f1f0f000
			
		; 18x1 tiles for subbuffer
sb_tile_map		dc.w	$0,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$3	; Line 1
; End of File