; $VER: samples_e8x.asm 1.0 (24.06.25)
;
; samples_e8x.asm
; Additional source sample data for the E8x example.
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20250624
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include samples_e8x.i
		
		section	data,data

; 8 bit samples
		cnop	0,4
sample1_e8x				INCBIN	"Examples/Data/snap_1.raw"
		cnop	0,4
.sample1_e8x_end
sample1_e8x_size		EQU	(.sample1_e8x_end-sample1_e8x)
sample2_e8x				INCBIN	"Examples/Data/snap_2.raw"
		cnop	0,4
.sample2_e8x_end
sample2_e8x_size		EQU	(.sample2_e8x_end-sample2_e8x)

; Total sample size
sample_e8x_total_size	EQU .sample2_e8x_end-sample1_e8x

		; Pointers to premixed samples
sample1_e8x_mix	dc.l	sample1_e8x
sample2_e8x_mix	dc.l	sample2_e8x

		; Sample info lists pointers & sizes
sample_e8x_info
				dc.w	sample_e8x_count			; Sample count
si_e8x_strt		dc.l	sample1_e8x,sample1_e8x_mix	; Pointer to sample & premix buffer
				dc.l	sample1_e8x_size			; Size in bytes
				dc.l	sample1_e8x_size/2			; Loop offset in bytes
si_e8x_end		dc.l	sample2_e8x,sample2_e8x_mix	; etc.
				dc.l	sample2_e8x_size
				dc.l	sample2_e8x_size/2
si_e8x_SIZEOF	EQU		si_e8x_end-si_e8x_strt
si_e8x_END		EQU		si_e8x_SIZEOF*sample_e8x_count
si_e8x_STRT_o	EQU		si_e8x_strt-sample_e8x_info
		
; End of File