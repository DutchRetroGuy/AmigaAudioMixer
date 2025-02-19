; $VER: samples.asm 1.0 (01.04.19)
;
; samples.asm
; Source sample data
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20190401
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include samples.i
		
		section	data,data

; 8 bit samples
		cnop	0,4
sample1		;INCBIN	"Examples/Data/zap.raw"
			INCBIN "C:\Development\AmigaDev\Projects\amigaoutrun\sfx\15-MOTOR_MAX_SPEED_LIMITED.raw"
		cnop	0,4
.sample1_end
sample1_size		EQU	(.sample1_end-sample1)
sample2		INCBIN	"Examples/Data/laser.raw"
		cnop	0,4
.sample2_end
sample2_size		EQU	(.sample2_end-sample2)
sample3		INCBIN	"Examples/Data/power_up.raw"
		cnop	0,4
.sample3_end
sample3_size		EQU	(.sample3_end-sample3)
sample4		INCBIN	"Examples/Data/explosion.raw"
		cnop	0,4
.sample4_end
sample4_size		EQU	(.sample4_end-sample4)
sample5		INCBIN	"Examples/Data/alarm.raw"
		cnop	0,4
.sample5_end
sample5_size		EQU	(.sample5_end-sample5)
sample6		INCBIN	"Examples/Data/drums.raw"
		cnop	0,4
.sample6_end
sample6_size		EQU	(.sample6_end-sample6)
sample7		INCBIN	"Examples/Data/cat.raw"
		cnop	0,4
.sample7_end
sample7_size		EQU	(.sample7_end-sample7)
sample8		INCBIN	"Examples/Data/dog.raw"
		cnop	0,4
.sample8_end
sample8_size		EQU	(.sample8_end-sample8)

; Total sample size
sample_total_size	EQU .sample8_end-sample1

		; Pointers to premixed samples
sample1_mix		dc.l	sample1
sample2_mix		dc.l	sample2
sample3_mix		dc.l	sample3
sample4_mix		dc.l	sample4
sample5_mix		dc.l	sample5
sample6_mix		dc.l	sample6
sample7_mix		dc.l	sample7
sample8_mix		dc.l	sample8

		; Sample info lists pointers & sizes
sample_info
			dc.w	sample_count			; Sample count
si_strt		dc.l	sample1,sample1_mix		; Pointer to sample & premix buffer
			dc.l	sample1_size			; Size in bytes
			dc.l	sample1_size/2			; Loop offset in bytes
si_end		dc.l	sample2,sample2_mix		; etc.
			dc.l	sample2_size
			dc.l	sample2_size/2
			dc.l	sample3,sample3_mix
			dc.l	sample3_size
			dc.l	sample3_size/2
			dc.l	sample4,sample4_mix
			dc.l	sample4_size
			dc.l	sample4_size/2
			dc.l	sample5,sample5_mix
			dc.l	sample5_size
			dc.l	sample5_size/2
			dc.l	sample6,sample6_mix
			dc.l	sample6_size
			dc.l	sample6_size/2
			dc.l	sample7,sample7_mix
			dc.l	sample7_size
			dc.l	sample7_size/2
			dc.l	sample8,sample8_mix
			dc.l	sample8_size
			dc.l	sample8_size/2
si_SIZEOF	EQU		si_end-si_strt
si_END		EQU		si_SIZEOF*sample_count
si_STRT_o	EQU		si_strt-sample_info
		
; End of File