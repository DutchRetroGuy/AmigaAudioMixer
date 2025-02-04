; $VER: ExternalIRQMixer.asm 1.1 (04.02.25)
;
; ExternalIRQMixer.asm
; Example showing the audio mixer in MIXER_SINGLE mode.
; This example is a minimal example that shows of the steps to enable the
; mixer using external IRQ & DMA handling and play back some SFX.
;
; It does not properly disable the OS and assumes a VBR of 0.
; In 'real' programs, the VBR should be set correctly on non-68000 systems and
; the OS should be disabled.
;
; Author: Jeroen Knoester
; Version: 1.1
; Revision: 20250204
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include exec/types.i
	include	exec/exec.i
	include hardware/custom.i
	include hardware/dmabits.i
	include hardware/intbits.i
	include hardware/cia.i

	include converter.i
	include mixer.i
	include samples.i
	
	include debug.i

; Custom chips offsets
custombase			EQU	$dff000
ciaa				EQU	$bfe001
	
; Start of code
		section code,code
		
		; Main code
_main	
		; Open the DOS library to be able to print messages to the CLI
		bsr 	OSOpenDos
		
		; Print initial messages
		lea.l	txt_1(pc),a0
		bsr		PrintMessage
		lea.l	txt_2(pc),a0
		bsr		PrintMessage
		lea.l	txt_3(pc),a0
		bsr		PrintMessage
		lea.l	txt_4(pc),a0
		bsr		PrintMessage
		lea.l	txt_5(pc),a0
		bsr		PrintMessage
		lea.l	txt_6(pc),a0
		bsr		PrintMessage
		lea.l	txt_7(pc),a0
		bsr		PrintMessage
		lea.l	txt_8(pc),a0
		bsr		PrintMessage
		lea.l	txt_9(pc),a0
		bsr		PrintMessage
		lea.l	txt_10(pc),a0
		bsr		PrintMessage
		lea.l	txt_11(pc),a0
		bsr		PrintMessage
		lea.l	txt_12(pc),a0
		bsr		PrintMessage
		lea.l	txt_13(pc),a0
		bsr		PrintMessage
		
		; Pre-proces the samples
		moveq	#4,d1						; Set number of channels

		; Sample 1
		lea.l	sample1,a0					; Sample source
		lea.l	sample1,a1					; Pre-processed destination
		move.l	#sample1_size,d0			; Sample size
		bsr		ConvertSampleDivide
		
		; Sample 2
		lea.l	sample2,a0					; Sample source
		lea.l	sample2,a1					; Pre-processed destination
		move.l	#sample2_size,d0			; Sample size
		bsr		ConvertSampleDivide
		
		; Sample 3
		lea.l	sample3,a0					; Sample source
		lea.l	sample3,a1					; Pre-processed destination
		move.l	#sample3_size,d0			; Sample size
		bsr		ConvertSampleDivide
		
		; Sample 4
		lea.l	sample4,a0					; Sample source
		lea.l	sample4,a1					; Pre-processed destination
		move.l	#sample4_size,d0			; Sample size
		bsr		ConvertSampleDivide

		; Setup the mixer
		move.w	#MIX_PAL,d0					; Set video system to PAL
		lea.l	mixer_buffer,a0				; Fetch Chip RAM buffer
		bsr		MixerSetup					; Set up the mixer
		
		; Set up the external IRQ/DMA handling routines
		bsr		SetupIRQDMAStruct
		
		; Start the mixer interrupt handler
		moveq	#0,d0						; Save vector
		move.l	d0,a0						; Set VBR to 0
		bsr		MixerInstallHandler			; Install the mixer IRQ handler
		
		; Start the mixer
		bsr		MixerStart

		; Set up effect structures for all four samples
		lea.l	effect1,a0
		lea.l	sample1,a1
		move.l	#sample1_size,mfx_length(a0)
		move.l	a1,mfx_sample_ptr(a0)
		move.w	#MIX_FX_LOOP,mfx_loop(a0)
		move.w	#1,mfx_priority(a0)
		clr.l	mfx_loop_offset(a0)
		clr.l	mfx_plugin_ptr(a0)
		
		lea.l	effect2,a0
		lea.l	sample2,a1
		move.l	#sample2_size,mfx_length(a0)
		move.l	a1,mfx_sample_ptr(a0)
		move.w	#MIX_FX_LOOP,mfx_loop(a0)
		move.w	#1,mfx_priority(a0)
		clr.l	mfx_loop_offset(a0)
		clr.l	mfx_plugin_ptr(a0)
		
		lea.l	effect3,a0
		lea.l	sample3,a1
		move.l	#sample3_size,mfx_length(a0)
		move.l	a1,mfx_sample_ptr(a0)
		move.w	#MIX_FX_LOOP,mfx_loop(a0)
		move.w	#1,mfx_priority(a0)
		clr.l	mfx_loop_offset(a0)
		clr.l	mfx_plugin_ptr(a0)
		
		lea.l	effect4,a0
		lea.l	sample4,a1
		move.l	#sample4_size,mfx_length(a0)
		move.l	a1,mfx_sample_ptr(a0)
		move.w	#MIX_FX_LOOP,mfx_loop(a0)
		move.w	#1,mfx_priority(a0)
		clr.l	mfx_loop_offset(a0)
		clr.l	mfx_plugin_ptr(a0)

		; Play back all four samples
		; Sample 1
		moveq	#DMAF_AUD2,d0				; Set HW channel to play on
											; (not required for MIXER_SINGLE)
		lea.l	effect1,a0					; Sample 1
		bsr		MixerPlayFX					; Play the sample

		; Sample 2
		moveq	#DMAF_AUD2,d0				; Set HW channel to play on
											; (not required for MIXER_SINGLE)
		lea.l	effect2,a0					; Sample 2
		bsr		MixerPlayFX					; Play the sample
		
		; Sample 3
		moveq	#DMAF_AUD2,d0				; Set HW channel to play on
											; (not required for MIXER_SINGLE)
		lea.l	effect3,a0					; Sample 3
		bsr		MixerPlayFX					; Play the sample
		
		; Sample 4
		moveq	#DMAF_AUD2,d0				; Set HW channel to play on
											; (not required for MIXER_SINGLE)
		lea.l	effect4,a0					; Sample 4
		bsr		MixerPlayFX					; Play the sample
		
		; Print end messages
		lea.l	txt_14(pc),a0
		bsr		PrintMessage
		
		; Wait for left mouse button to end
		bsr		WaitLeftMouse
		
		; Stop the mixer
		bsr		MixerStop
		
		; Stop the mixer interrupt handler
		bsr		MixerRemoveHandler
		
		; Close the DOS library
		bsr		OSCloseDos
		rts
		
;------------------------------------
; External IRQ & DMA routines
;------------------------------------

		; Routine: SetupIRQDMAStruct
		; This routine sets up the MXIRQDMACallbacks structure and calls the
		; mixer routine MixerSetIRQDMACallbacks.
SetupIRQDMAStruct
		movem.l	a0/a1,-(sp)					; Stack
		
		; Set up the IRQ/DMA struct
		lea.l	irq_dma_struct(pc),a0
		lea.l	SetIRQVector(pc),a1
		move.l	a1,mxicb_set_irq_vector(a0)
		lea.l	RemoveIRQVector(pc),a1
		move.l	a1,mxicb_remove_irq_vector(a0)
		lea.l	SetIRQBits(pc),a1
		move.l	a1,mxicb_set_irq_bits(a0)
		lea.l	DisableIRQ(pc),a1
		move.l	a1,mxicb_disable_irq(a0)
		lea.l	AcknowledgeIRQ(pc),a1
		move.l	a1,mxicb_acknowledge_irq(a0)
		lea.l	SetDMACON(pc),a1
		move.l	a1,mxicb_set_dmacon(a0)
		
		; Call MixerSetIRQDMACallbacks
		bsr		MixerSetIRQDMACallbacks

		movem.l	(sp)+,a0/a1					; Stack
		rts

		; Routine: InterruptHandler
		; This routine is the external interrupt handler for the audio mixer.
		;
		; NOTE: in this example, the handler does nothing but call the 
		;       original handler and RTE. Any external handler should call
		;       the mixer's original handler.
InterruptHandler
		move.l	a0,-(sp)					; Stack

		move.l	irq_handler(pc),a0
		jsr		(a0)
		
		move.l	(sp)+,a0					; Stack
		rte

		; Routine: SetIRQVector
		; This routine sets up the audio interrupt vector
		;
		; A0 - pointer to the audio mixer interrupt handler.
		;
		; Note: this variant assumes a VBR of 0, which may not be correct on
		;       all machines!
SetIRQVector
		move.l a1,-(sp)						; Stack
		
		; Store old vector (assumes VBR of 0!)
		lea.l	old_vector(pc),a1
		move.l	$70,(a1)
		
		; Store new handler
		lea.l	irq_handler(pc),a1
		move.l	a0,(a1)
		
		; Set up new vector (assumes VBR of 0!)
		lea.l	InterruptHandler(pc),a1
		move.l	a1,$70
		
		move.l	(sp)+,a1					; Stack
		rts

		; Routine: RemoveIRQVector
		; This routine removes the IRQ vector used by the audio mixer, 
		; resetting it to it's prior value.
		;
		; Note: this variant assumes a VBR of 0, which may not be correct on
		;       all machines!
RemoveIRQVector
		; Reset vector (assumes VBR of 0!)
		move.l	old_vector(pc),$70
		rts

		; Routine: SetIRQBits
		; This routine sets the correct bits in the INTENA register
		;
		; D0 - INTENA bits to use
SetIRQBits
		move.l	a6,-(sp)					; Stack
		
		lea.l	custombase,a6
		move.w	d0,intena(a6)
		
		move.l	(sp)+,a6					; Stack
		rts

		; Routine: DisableIRQ
		; This routine disables the audio interrupt
		;
		; D0 - INTENA/INTREQ value to use
DisableIRQ
		move.l	a6,-(sp)					; Stack
		
		lea.l	custombase,a6
		move.w	d0,intena(a6)
		move.w	d0,intreq(a6)
		move.w	d0,intreq(a6)				; 2x for A4000	
		
		move.l	(sp)+,a6					; Stack
		rts

		; Routine: AcknowledgeIRQ
		; This routine acknowledges the audio interrupt 
		;
		; D0 - INTREQ value to use
AcknowledgeIRQ
		move.l	a6,-(sp)					; Stack
		
		lea.l	custombase,a6
		move.w	d0,intreq(a6)
		move.w	d0,intreq(a6)				; 2x for A4000

		move.l	(sp)+,a6					; Stack
		rts

		; Routine: SetDMACON
		; This routine sets the DMACON register to the value given
		;
		; D0 - DMACON value to set
SetDMACON
		move.l	a6,-(sp)					; Stack
		
		lea.l	custombase,a6
		move.w	d0,dmacon(a6)
		
		move.l	(sp)+,a6					; Stack
		rts
		
;------------------------------------
; Support routines
;------------------------------------
		
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
		
		; Routine: PrintMessage
		; Uses DOS to print a given message
		; A0 - pointer to message
PrintMessage
		move.l	a6,-(sp)
		move.l	a0,-(sp)
		bsr		OSOpenDos
		tst.w	d0
		bne		.no_dos
		
		move.l	dosbase(pc),a6
		jsr		_LVOOutput(a6)
		move.l	d0,d1
		move.l	(sp)+,a2
		moveq	#0,d3
		move.w	(a2)+,d3
		move.l	a2,d2
		jsr		_LVOWrite(a6)
		
		bsr		OSCloseDos
.done	move.l	(sp)+,a6
		rts
		
.no_dos	move.l	(sp)+,a0
		bra		.done
		
		; Routine: OSOpenDos
		; Opens the DOS.library if needed
		;
		; Returns
		; D0 = 0 is OK, non zero is error
OSOpenDos
		move.l	a6,-(sp)		; Stack
		
		move.l	$4.w,a6			; Execbase
		lea.l	dosname(pc),a1
		moveq	#0,d0
		jsr		_LVOOpenLibrary(a6)
		lea.l	dosbase(pc),a0
		move.l	d0,(a0)
		beq		.error
		
		moveq	#0,d0		
.done	move.l	(sp)+,a6		; Stack
		rts
		
.error	moveq	#1,d1
		bra		.done
		
		; Routine: OSCloseDos
		; Closes the DOS.library if needed
OSCloseDos
		movem.l	a1/a6,-(sp)
		
		move.l	dosbase(pc),a1
		cmp.l	#0,a1
		beq		.error
		
		move.l	$4.w,a6			; Execbase
		jsr		_LVOCloseLibrary(a6)
		moveq	#0,d0
		
.done	movem.l	(sp)+,a1/a6
		rts
		
.error	moveq	#1,d1
		bra		.done

;------------------------------------
; Data follows
;------------------------------------

irq_handler	dc.l	0
old_vector	dc.l	0

irq_dma_struct	blk.b	mxicb_SIZEOF

effect1	blk.b mfx_SIZEOF
effect2	blk.b mfx_SIZEOF
effect3	blk.b mfx_SIZEOF
effect4	blk.b mfx_SIZEOF
	
dosbase	dc.l	0
dosname dc.b	"dos.library",0,0
		cnop 0,2

txt_1	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"ExternalIRQMixer - audio mixer example using external IRQ/DMA handling",10,0,0
.txtend
		cnop	0,2
txt_2	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"----------------------------------------------------------------------",10,0,0
.txtend
		cnop	0,2
txt_3	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	10,0,0
.txtend
		cnop	0,2
txt_4	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"Note: this example is very short and does not close down the OS",10,0,0
.txtend
		cnop	0,2
txt_5	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"      properly. The Audio Mixer directly accesses custom chip",10,0,0
.txtend
		cnop	0,2
txt_6	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"      registers, closing down the OS properly prior to using the",10,0,0
.txtend
		cnop	0,2
txt_7	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"      mixer is required in real programs.",10,0,0
.txtend
		cnop	0,2
txt_8	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"Note: this program assumes a VBR of 0",10,0,0
.txtend
		cnop	0,2
txt_9	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	10,0,0
.txtend
		cnop	0,2
txt_10	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"Samples used are sourced from freesound.org. See the readme file in the data",10,0,0
.txtend
		cnop	0,2
txt_11	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"subdirectory of the mixer 'example' directory.",10,0,0
.txtend
		cnop	0,2
		
txt_12	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	10,0,0
.txtend
		cnop	0,2	
txt_13	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"Pre-processing samples...",10,0,0
.txtend
		cnop	0,2

txt_14	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"Press left mouse button to end program.",10,0,0
.txtend
		cnop	0,2


;------------------------------------
; Chip RAM buffer
;------------------------------------
		section audio,data_c
		cnop 0,4
mixer_buffer	blk.b	mixer_buffer_size

; End of File