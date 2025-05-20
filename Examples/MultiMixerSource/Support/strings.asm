; $VER: strings.asm 1.0 (05.02.24)
;
; strings.asm
; Program text strings
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20240205
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include strings.i

		; Prepare sample text
preptxt		dc.w	1					; Count
			dc.w	9,8,14
			dc.w	.line2_end-.line2
.line2		dc.b	"Preparing samples..."
			cnop 0,2	; Realign
.line2_end

		; Title screen text
titletxt	dc.w	7					; Count
			dc.w	9,0,11
			dc.w	.line1_end-.line1
.line1		dc.b	"This example program uses startup"
			cnop 0,2	; Realign
.line1_end
			dc.w	9,0,12
			dc.w	.line2_end-.line2
.line2		dc.b	"code by Photon of Scoopex. Samples"
			cnop 0,2	; Realign
.line2_end

			dc.w	9,0,13
			dc.w	.line3_end-.line3
.line3		dc.b	"used are sourced from freesound.org."
			cnop 0,2	; Realign
.line3_end
			dc.w	9,0,15
			dc.w	.line4_end-.line4
.line4		dc.b	"See the license and readme files in"
			cnop 0,2	; Realign
.line4_end
			dc.w	9,0,16
			dc.w	.line5_end-.line5
.line5		dc.b	"the respective subdirectories of the"
			cnop 0,2	; Realign
.line5_end
			dc.w	9,0,17
			dc.w	.line6_end-.line6
.line6		dc.b	"mixer 'examples' directory for more"
			cnop 0,2	; Realign
.line6_end
			dc.w	9,0,18
			dc.w	.line7_end-.line7
.line7		dc.b	"information."
			cnop 0,2	; Realign
.line7_end

		; Main screen text
maintxt	dc.w	19					; Count
			dc.w	9,0,3
			dc.w	.line1_end-.line1
.line1		dc.b	"This example program shows the audio"
			cnop 0,2	; Realign
.line1_end
			dc.w	9,0,4
			dc.w	.line2_end-.line2
.line2		dc.b	"mixer running in MIXER_MULTI mode,"
			cnop 0,2	; Realign
.line2_end
			dc.w	9,0,5
			dc.w	.line3_end-.line3
.line3		dc.b	"mixing up to 16 samples together at"
			cnop 0,2	; Realign
.line3_end
			dc.w	9,0,6
			dc.w	.line4_end-.line4
.line4		dc.b	"the same time and outputting the"
			cnop 0,2	; Realign
.line4_end
			dc.w	9,0,7
			dc.w	.line5_end-.line5
.line5		dc.b	"result to four hardware channels."
			cnop 0,2	; Realign
.line5_end
			dc.w	9,0,9
			dc.w	.line6_end-.line6
.line6		dc.b	"The example is configured to play"
			cnop 0,2	; Realign
.line6_end
			dc.w	9,0,10
			dc.w	.line7_end-.line7
.line7		dc.b	"back at a rate of around 11KHz. This"
			cnop 0,2	; Realign
.line7_end
			dc.w	6,0,12
			dc.w	.line8_end-.line8
.line8		dc.b	"(mixing 16 samples on 1MB A500/7MHz)"
			cnop 0,2	; Realign
.line8_end
			dc.w	9,0,14
			dc.w	.line9_end-.line9
.line9		dc.b	"Time used by mixing is visualized"
			cnop 0,2	; Realign
.line9_end
			dc.w	9,0,15
			dc.w	.line10_end-.line10
.line10		dc.b	"by the on-screen raster bars."
			cnop 0,2	; Realign
.line10_end
			dc.w	12,0,17
			dc.w	.line11_end-.line11
.line11		dc.b	"Instructions:"
			cnop 0,2	; Realign
.line11_end
			dc.w	12,0,18
			dc.w	.line12_end-.line12
.line12		dc.b	"* Left mouse button exits to OS"
			cnop 0,2	; Realign
.line12_end
			dc.w	12,0,19
			dc.w	.line13_end-.line13
.line13		dc.b	"* Joystick button plays/loops/stops"
			cnop 0,2	; Realign
.line13_end
			dc.w	12,2,20
			dc.w	.line14_end-.line14
.line14		dc.b	"a sample based on selected action"
			cnop 0,2	; Realign
.line14_end
			dc.w	12,0,21
			dc.w	.line15_end-.line15
.line15		dc.b	"* Joystick 'left' or 'right' changes"
			cnop 0,2	; Realign
.line15_end
			dc.w	12,2,22
			dc.w	.line16_end-.line16
.line16		dc.b	"option selected"
			cnop 0,2	; Realign
.line16_end
			dc.w	12,0,23
			dc.w	.line17_end-.line17
.line17		dc.b	"* Joystick 'up' or 'down' changes"
			cnop 0,2	; Realign
.line17_end
			dc.w	12,2,24
			dc.w	.line18_end-.line18
.line18		dc.b	"value of the option selected"
			cnop 0,2	; Realign
.line18_end
			dc.w	11,0,26
			dc.w	.line19_end-.line19
.line19		dc.b	"More info? See mixer documentation."
			cnop 0,2	; Realign
.line19_end

		; PAL header text
palhtxt		dc.w	1					; Count
			dc.w	7,6,1				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Audio Mixing v3.7 (PAL)"
			cnop 0,2	; Realign
.line1_end
			
		; NTSC header text
ntschtxt	dc.w	1					; Count
			dc.w	7,6,1				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Audio Mixing v3.7 (NTSC)"
			cnop 0,2	; Realign
.line1_end
			
		; PAL percentage text
palpertxt	dc.w	1
			dc.w	9,0,11
			dc.w	.line1_end-.line1
.line1		dc.b	"takes ~15,2% CPU time per frame."
			cnop 0,2	; Realign
.line1_end

		; NTSC percentage text
ntscpertxt	dc.w	1
			dc.w	9,0,11
			dc.w	.line1_end-.line1
.line1		dc.b	"takes ~16,8% CPU time per frame."
			cnop 0,2	; Realign
.line1_end

		; Sample prepare text (subbuffer)
subpreptxt	dc.w	1					; Count
			dc.w	6,9,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"One moment please"
			cnop 0,2	; Realign
.line1_end

		; Subbuffer start text
substarttxt	dc.w	1					; Count
			dc.w	6,8,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Press fire to start"
			cnop 0,2	; Realign
.line1_end

		; Subbuffer text
subtxt		dc.w	1					; Count
			dc.w	6,1,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"AUDx:     Channel:     Action:    "
			cnop 0,2	; Realign
.line1_end

		; Hardware channel text
hwchantxt0	dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"AUD0"
			cnop 0,2	; Realign
.line1_end
hwchantxt1	dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"AUD1"
			cnop 0,2	; Realign
.line1_end
hwchantxt2	dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"AUD2"
			cnop 0,2	; Realign
.line1_end
hwchantxt3	dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"AUD3"
			cnop 0,2	; Realign
.line1_end

		; Mixer channel text
chantxt0	dc.w	1					; Count
			dc.w	6,19,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"auto"
			cnop 0,2	; Realign
.line1_end
chantxt1	dc.w	1					; Count
			dc.w	6,19,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"MIX0"
			cnop 0,2	; Realign
.line1_end
chantxt2	dc.w	1					; Count
			dc.w	6,19,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"MIX1"
			cnop 0,2	; Realign
.line1_end
chantxt3	dc.w	1					; Count
			dc.w	6,19,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"MIX2"
			cnop 0,2	; Realign
.line1_end
chantxt4	dc.w	1					; Count
			dc.w	6,19,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"MIX3"
			cnop 0,2	; Realign
.line1_end

		; Action text
acttxt1		dc.w	1					; Count
			dc.w	6,31,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"once"
			cnop 0,2	; Realign
.line1_end
acttxt2		dc.w	1					; Count
			dc.w	6,31,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"loop"
			cnop 0,2	; Realign
.line1_end
acttxt3		dc.w	1					; Count
			dc.w	6,31,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"stop"
			cnop 0,2	; Realign
.line1_end

hwchantxt_ptrs	dc.l	hwchantxt0,hwchantxt1,hwchantxt2,hwchantxt3
chantxt_ptrs	dc.l	chantxt0,chantxt1,chantxt2,chantxt3,chantxt4
acttxt_ptrs		dc.l	acttxt1,acttxt2,acttxt3

; End of File