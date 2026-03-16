; $VER: support.asm 1.0 (16.03.23)
;
; support.asm
; Support routines for the main .asm file
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20230316
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
		include exec/types.i
		include	exec/exec.i
		include hardware/custom.i
		include hardware/cia.i

		include displaybuffers.i
		include	support.i
		include samples.i
		
; Custom chips offsets / bits
ciaa				EQU	$bfe001
potgor				EQU	$016
bit_joyb1			EQU 7
bit_joyb2			EQU 14
bit_mouseb1			EQU	6
bit_mouseb2			EQU	10
		
		section	code,code

;---------------------------------------------
; Support routines follow
;---------------------------------------------
		
		; Routine: WaitLeftMouse
		; Waits on the left mouse button being pressed.
WaitLeftMouse
.wait1
		btst    #6,ciaa						; Check left mouse button
		bne		.wait1
.wait2
		btst	#6,ciaa
		beq		.wait2						; Wait until no longer pressed
		rts
		
		; Routine: ReadInput
		; From eab.abime.net, reads joystick port 2
		; and checks left & right mouse buttons.
		;
		; Adapted slightly:
		;	- changed result table
		;	- reset potgo at end of read
		;	- conversion table renamed and moved into data section
		;	- changed registers used and cleared result register on call
		;
		; Result table:
		;	Up			-	   1
		;	Down		-	   2
		;	Left		-	   4
		;	Right		-	   8
		;	Fire 1		-	 256
		;	Fire 2		-	 512
		;	Left mouse	-	1024
		;	Right mouse	-	2048
		; Multiple directions/buttons are or'd together
		;
		; A6: custombase
		; Returns
		; D7: joystick/left mouse button value
ReadInput
		movem.l	a0/a3,-(sp)					; Stack
		lea.l	ciaa,a0
		moveq	#0,d7

		btst	#bit_joyb2&7,potgor(a6)
		seq		d7
		add.w	d7,d7

		btst	#bit_joyb1,ciapra(a0)
		seq		d7
		add.w	d7,d7

		move.w	joy1dat(a6),d6
		ror.b	#2,d6
		lsr.w	#6,d6
		and.w	#%1111,d6
		lea.l	joystick,a3
		move.b	0(a3,d6.w),d7
		
		; Read left mouse button
		btst	#bit_mouseb1,ciapra(a0)
		bne		.rmb
		
		bset	#10,d7
		
		; Read right mouse button
.rmb	btst	#bit_mouseb2,potgor(a6)
		bne		.done
		
		bset	#11,d7
			
		; Reset 2nd buttons for next call
.done	move.w	#$cc00,potgo(a6)
		movem.l	(sp)+,a0/a3					; Stack
		rts
		
		; Routine: CopyMem
		; This routine calls Exec CopyMem
		; A0 - source
		; A1 - destination
		; D0 - size
		; No registers trashed
CopyMem
		movem.l d0-d7/a0-a6,-(sp)	; Stack

		move.l	$4.w,a6
		jsr		_LVOCopyMem(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6	; Stack
		rts
		
		; Routine SetFGPtrs
		; This routine sets the foreground bitplane pointers into the
		; copperlist.
		;
		; D1 - copperlist index
		; D2 - FG buffers index
		; D3 - FG offset
SetFGPtrs
		move.l	a1,-(sp)			; Stack
		lea.l	clist_ptrs,a1
		move.l	0(a1,d1),a1			
		lea.l	bpptrs_o(a1),a1		; Get copperlist & offset
		lea.l	fg_buf1,a2
		move.l	0(a2,d2),d1			; Get foreground buffer bitmap
		add.l	d3,d1
		
		; Update copperlist foreground bitplane pointers in a loop
		move.w	d1,6(a1)
		swap	d1
		move.w	d1,2(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,14(a1)
		swap	d1
		move.w	d1,10(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,22(a1)
		swap	d1
		move.w	d1,18(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,30(a1)
		swap	d1
		move.w	d1,26(a1)
		swap	d1
		
		move.l	(sp)+,a1			; Stack
		rts
		
		; SetSBPtrs
		; This routine sets the sub buffer bitplane pointers into the
		; copperlist.
SetSBPtrs
		move.l	sb_buf,d0			; Get sub buffer bitmap
		lea.l	sbptrs,a0
		
		; Update copperlist subbuffer bitplane pointers in a loop
		moveq	#2,d7
.lp		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		add.l	#subbuffer_modulo,d0
		lea.l	8(a0),a0
		dbra	d7,.lp
		rts
		
		; Routine SetFGPal
		; This routine fills the foreground palette values into the copper list
SetFGPal
		move.l	#palette,a0
		move.l	#pal1,a1
		move.w	#color,d5
		lea.l	(a0),a0
		
		moveq	#31,d7
.pallp	move.w	d5,(a1)+
		move.w	(a0)+,(a1)+
		addq.w	#2,d5
		dbra	d7,.pallp
		rts
		
		; Routine: SetSBPal
		; This routine fills the subbuffer palette values into the copper list
SetSBPal
		move.l	#subpal,a0
		move.l	#pal2,a1
		move.w	#color+2,d5
		lea.l	2(a0),a0
		
		moveq	#6,d7
.spllp	move.w	d5,(a1)+
		move.w	(a0)+,(a1)+
		addq.w	#2,d5
		dbra	d7,.spllp
		rts
		
		; Routine PrintFG
		; This routine prints the given text to the foreground
		;
		; D4 - text mode (0=normal/1=inverted)
		; A3 - text entry to print
PrintFG
		movem.l	d3/d5/d6/a1,-(sp)				; Stack

		move.l	fg_buf1,a1
		lea.l	4(a1),a1						; Skip to starting position
		moveq	#4,d3
		move.l	#buffer_modulo*4,d5				; Note: top word must be empty
		moveq	#buffer_modulo,d6				; Note: top word must be empty
		jsr		PlotTextMultiCPU
		
		movem.l	(sp)+,d3/d5/d6/a1				; Stack
		rts
		
		; Routine PrintSubbuffer
		; This routine prints the given text to the subbuffer
		;
		; D4 - text mode (0=normal/1=inverted)
		; A3 - text entry to print
PrintSubbuffer
		movem.l	d3/d5/d6/a1,-(sp)				; Stack

		move.l	sb_buf,a1
		lea.l	(subbuffer_modulo*3)*4(a1),a1	; Offset Y by 4 pixels
		moveq	#3,d3
		moveq	#subbuffer_modulo*3,d5			; Note: top word must be empty
 		moveq	#subbuffer_modulo,d6			; Note: top word must be empty
		jsr		PlotTextMultiCPU
		
		movem.l	(sp)+,d3/d5/d6/a1				; Stack
		rts
		
		; Routine: AllocAll
		; This routine allocates all memory.
		;
		; Returns:
		; D0 = 0 - OK
		;      1 - Error
AllocAll
		lea.l	sbuffer_size,a0
		move.l	d0,(a0)						; Store sample buffer size
		
		; Allocate memory for the 1st foreground buffer
		move.l	#buffer_size*4,d0
		move.l	#MEMF_CHIP,d1
		jsr		_LVOAllocMem(a6)
		move.l	d0,fg_buf1		
		bne		.cnt

		; No memory
		moveq	#1,d0
		rts
		
		; Allocate memory for the subbuffer buffer
.cnt	move.l	#subbuffer_size*3,d0
		move.l	#MEMF_CHIP,d1
		jsr		_LVOAllocMem(a6)
		move.l	d0,sb_buf
		beq.w	error1
		
		; No errors occured
		moveq	#0,d0
		rts

		; Routine: FreeAll
		; This routine frees all allocated memory
		; Returns
		; D0 = 1
FreeAll
error2	move.l	#subbuffer_size*3,d0
		move.l	sb_buf,a1
		jsr		_LVOFreeMem(a6)
		
error1	move.l	#buffer_size*4,d0
		move.l	fg_buf1,a1
		jsr		_LVOFreeMem(a6)
		
		moveq	#1,d0
		rts
		
		; Routine PrepSamples
		; This routine sets up the samples for use in mixing. It uses either
		; the standard conversion (divide by #of channels) or conversion based
		; on limiting or compression.
		; 
		; D1 - number of channels
PrepSamples
		movem.l	d0/d7/a0-a2,-(sp)				; Stack
	
		; Fetch sample info
		lea.l	sample_info,a2
prepsamples_internal
		move.w	(a2)+,d7
		subq.w	#1,d7						; Loop counter

		; Loop over samples
.lp		move.l	(a2)+,a0					; Sample source
		move.l	(a2)+,a1
		move.l	(a1),a1						; Premix destination
		move.l	(a2)+,d0					; Sample size in bytes
		lea.l	4(a2),a2					; Skip loop size
		bsr		ConvertSampleDivide
		dbra	d7,.lp
		
.done	movem.l	(sp)+,d0/d7/a0-a2				; Stack
		rts
		
		; Routine PrepSamplesE8x
		; This routine sets up the E8x samples for use in mixing. It uses
		; either the standard conversion (divide by #of channels) or
		; conversion based on limiting or compression.
		; 
		; D1 - number of channels
		; A2 - pointer to sample info for E8x samples
PrepSamplesE8x
		movem.l	d0/d7/a0-a2,-(sp)				; Stack
	
		; Fetch sample info
		bra		prepsamples_internal
		
		; Routine: InitLFSR
		; This routine sets up the seed values for the LFSR random number
		; generator. This version is simplified because it doesn't matter
		; whether or not the same random numbers are generated between each
		; run of the PerformanceTest.
InitLFSR
		move.l	a0,-(sp)					; Stack
		
		; Initialise the seed
		; Note: replace with a more sophisticated approach for use outside of
		;       the mixer performance test.
		lea.l	lfsr32,a0
		move.l	#$abcdef10,(a0)+
		move.l	#$23456789,(a0)
		
		move.l	(sp)+,a0					; Stack
		rts
		
		; Routine: ShiftLFSR
		; This routine shifts the LFSR
		;
		; A0 - Pointer to LFSR to use
		; D0 - Polynomial mask to use
		;
		; Returns
		; D1 - Contents of the LFSR after shifting
ShiftLFSR
		movem.l	d2/a0,-(sp)					; Stack
		
		; Get current LFSR value
		move.l	(a0),d1
		move.w	d1,d2						; Save LFSR for feedback
		
		; Shift the LFSR
		lsr.l	#1,d1
		
		; Deal with feedback if applicable
		btst	#0,d2
		beq.s	.no_feedback
		
		; Apply feedback
		eor.l	d0,d1
		
.no_feedback
		; Store result
		move.l	d1,(a0)

		movem.l	(sp)+,d2/a0					; Stack
		rts
		
		; Routine: GetRandom
		; This routine uses two LFSRs to generate a 32 bit pseudo random 
		; number.
		;
		; Returns
		; D0 - a 32 bit pseudo-random number
GetRandom
		movem.l	d1/d2/a0,-(sp)				; Stack

		; Shift 32 bit LFSR twice
		lea.l	lfsr32,a0
		move.l	#PolyMask_32,d0
		bsr		ShiftLFSR
		bsr		ShiftLFSR
		move.l	d1,d2
		
		; Shift 31 bit LFSR once
		lea.l	lfsr31,a0
		move.l	#PolyMask_31,d0
		bsr		ShiftLFSR
		
		; Exclusive or result of 32 bit LFSR with the result of the 31 bit
		; LFSR
		move.l	d2,d0
		eor.l	d1,d0

		movem.l	(sp)+,d1/d2/a0				; Stack
		rts
			
;------------------------------------
; Data follows
;------------------------------------

		section	data,data
				; Joystick conversion values
joystick		dc.b    0,2,10,8,1,0,8,9,5,4,0,1,4,6,2,0
		cnop	0,2
		
seed			dc.l	0
sbuffer_size	dc.l	0
lfsr32			dc.l	0
lfsr31			dc.l	0