; $VER: strings.asm 1.0 (10.03.23)
;
; strings.asm
; Program text strings
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20230310
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include strings.i

		; Title screen text
titletxt	dc.w	1					; Count
			dc.w	9,4,14
			dc.w	.line1_end-.line1
.line1		dc.b	"Performance tests running..."
			cnop 0,2	; Realign
.line1_end

		; Results screen text (page 1)
resscrtxt	dc.w	75					; Count
			dc.w	13,0,1
			dc.w	.line1_end-.line1
.line1		dc.b	"Flags/type |Best |Worst|Avg. |Last"
			cnop 0,2	; Realign
.line1_end
			dc.w	13,0,2
			dc.w	.line2_end-.line2
.line2		dc.b	"-----------+-----+-----+-----+------"
			cnop 0,2	; Realign
.line2_end
			dc.w	13,0,3
			dc.w	.line3_end-.line3
.line3		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line3_end
			dc.w	15,0,4
			dc.w	.line4_end-.line4
.line4		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line4_end
			dc.w	14,0,5
			dc.w	.line5_end-.line5
.line5		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line5_end
			dc.w	13,0,6
			dc.w	.line6_end-.line6
.line6		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line6_end
			dc.w	15,0,7
			dc.w	.line7_end-.line7
.line7		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line7_end
			dc.w	14,0,8
			dc.w	.line8_end-.line8
.line8		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line8_end
			dc.w	13,0,9
			dc.w	.line9_end-.line9
.line9		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line9_end
			dc.w	15,0,10
			dc.w	.line10_end-.line10
.line10		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line10_end
			dc.w	14,0,11
			dc.w	.line11_end-.line11
.line11		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line11_end
			dc.w	13,0,12
			dc.w	.line12_end-.line12
.line12		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line12_end
			dc.w	15,0,13
			dc.w	.line13_end-.line13
.line13		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line13_end
			dc.w	14,0,14
			dc.w	.line14_end-.line14
.line14		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line14_end
			dc.w	13,0,15
			dc.w	.line15_end-.line15
.line15		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line15_end
			dc.w	15,0,16
			dc.w	.line16_end-.line16
.line16		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line16_end
			dc.w	14,0,17
			dc.w	.line17_end-.line17
.line17		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line17_end
			dc.w	13,0,18
			dc.w	.line18_end-.line18
.line18		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line18_end
			dc.w	15,0,19
			dc.w	.line19_end-.line19
.line19		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line19_end
			dc.w	14,0,20
			dc.w	.line20_end-.line20
.line20		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line20_end
			dc.w	13,0,21
			dc.w	.line21_end-.line21
.line21		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line21_end
			dc.w	15,0,22
			dc.w	.line22_end-.line22
.line22		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line22_end
			dc.w	14,0,23
			dc.w	.line23_end-.line23
.line23		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line23_end
			dc.w	13,0,24
			dc.w	.line24_end-.line24
.line24		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line24_end
			dc.w	15,0,25
			dc.w	.line25_end-.line25
.line25		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line25_end
			dc.w	14,0,26
			dc.w	.line26_end-.line26
.line26		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line26_end
			dc.w	13,0,27
			dc.w	.line27_end-.line27
.line27		dc.b	"------------------------------------"
			cnop 0,2	; Realign
.line27_end

			dc.w	9,0,3
			dc.w	.line28_end-.line28
.line28		dc.b	"Default    "
			cnop 0,2	; Realign
.line28_end
			dc.w	6,0,4
			dc.w	.line29_end-.line29
.line29		dc.b	">loop      "
			cnop 0,2	; Realign
.line29_end
			dc.w	6,0,5
			dc.w	.line30_end-.line30
.line30		dc.b	">short loop"
			cnop 0,2	; Realign
.line30_end
			dc.w	9,0,6
			dc.w	.line31_end-.line31
.line31		dc.b	"Size x32   "
			cnop 0,2	; Realign
.line31_end
			dc.w	6,0,7
			dc.w	.line32_end-.line32
.line32		dc.b	">loop      "
			cnop 0,2	; Realign
.line32_end
			dc.w	6,0,8
			dc.w	.line33_end-.line33
.line33		dc.b	">short loop"
			cnop 0,2	; Realign
.line33_end
			dc.w	9,0,9
			dc.w	.line34_end-.line34
.line34		dc.b	"Size xBufSZ"
			cnop 0,2	; Realign
.line34_end
			dc.w	6,0,10
			dc.w	.line35_end-.line35
.line35		dc.b	">loop      "
			cnop 0,2	; Realign
.line35_end
			dc.w	6,0,11
			dc.w	.line36_end-.line36
.line36		dc.b	">short loop"
			cnop 0,2	; Realign
.line36_end
			dc.w	9,0,12
			dc.w	.line37_end-.line37
.line37		dc.b	"Length=word"
			cnop 0,2	; Realign
.line37_end
			dc.w	6,0,13
			dc.w	.line38_end-.line38
.line38		dc.b	">loop"
			cnop 0,2	; Realign
.line38_end
			dc.w	6,0,14
			dc.w	.line39_end-.line39
.line39		dc.b	">short loop"
			cnop 0,2	; Realign
.line39_end
			dc.w	9,0,15
			dc.w	.line40_end-.line40
.line40		dc.b	"Word/x32   "
			cnop 0,2	; Realign
.line40_end
			dc.w	6,0,16
			dc.w	.line41_end-.line41
.line41		dc.b	">loop      "
			cnop 0,2	; Realign
.line41_end
			dc.w	6,0,17
			dc.w	.line42_end-.line42
.line42		dc.b	">short loop"
			cnop 0,2	; Realign
.line42_end
			dc.w	9,0,18
			dc.w	.line43_end-.line43
.line43		dc.b	"Word/xBufSz"
			cnop 0,2	; Realign
.line43_end
			dc.w	6,0,19
			dc.w	.line44_end-.line44
.line44		dc.b	">loop      "
			cnop 0,2	; Realign
.line44_end
			dc.w	6,0,20
			dc.w	.line45_end-.line45
.line45		dc.b	">short loop"
			cnop 0,2	; Realign
.line45_end
			dc.w	9,0,21
			dc.w	.line46_end-.line46
.line46		dc.b	"W/x32&BufSz"
			cnop 0,2	; Realign
.line46_end
			dc.w	6,0,22
			dc.w	.line47_end-.line47
.line47		dc.b	">loop      "
			cnop 0,2	; Realign
.line47_end
			dc.w	6,0,23
			dc.w	.line48_end-.line48
.line48		dc.b	">short loop"
			cnop 0,2	; Realign
.line48_end
			dc.w	9,0,24
			dc.w	.line49_end-.line49
.line49		dc.b	"68020 opt  "
			cnop 0,2	; Realign
.line49_end
			dc.w	6,0,25
			dc.w	.line50_end-.line50
.line50		dc.b	">loop      "
			cnop 0,2	; Realign
.line50_end
			dc.w	6,0,26
			dc.w	.line51_end-.line51
.line51		dc.b	">short loop"
			cnop 0,2	; Realign
.line51_end
			dc.w	13,0,3
			dc.w	.line52_end-.line52
.line52		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0		
			cnop 0,2	; Realign
.line52_end
			dc.w	13,0,4
			dc.w	.line53_end-.line53
.line53		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line53_end
			dc.w	13,0,5
			dc.w	.line54_end-.line54
.line54		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line54_end
			dc.w	13,0,6
			dc.w	.line55_end-.line55
.line55		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line55_end
			dc.w	13,0,7
			dc.w	.line56_end-.line56
.line56		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line56_end
			dc.w	13,0,8
			dc.w	.line57_end-.line57
.line57		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line57_end
			dc.w	13,0,9
			dc.w	.line58_end-.line58
.line58		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line58_end
			dc.w	13,0,10
			dc.w	.line59_end-.line59
.line59		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line59_end
			dc.w	13,0,11
			dc.w	.line60_end-.line60
.line60		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line60_end
			dc.w	13,0,12
			dc.w	.line61_end-.line61
.line61		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line61_end
			dc.w	13,0,13
			dc.w	.line62_end-.line62
.line62		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line62_end
			dc.w	13,0,14
			dc.w	.line63_end-.line63
.line63		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line63_end
			dc.w	13,0,15
			dc.w	.line64_end-.line64
.line64		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line64_end
			dc.w	13,0,16
			dc.w	.line65_end-.line65
.line65		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line65_end
			dc.w	13,0,17
			dc.w	.line66_end-.line66
.line66		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line66_end
			dc.w	13,0,18
			dc.w	.line67_end-.line67
.line67		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line67_end
			dc.w	13,0,19
			dc.w	.line68_end-.line68
.line68		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line68_end
			dc.w	13,0,20
			dc.w	.line69_end-.line69
.line69		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line69_end
			dc.w	13,0,21
			dc.w	.line70_end-.line70
.line70		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line70_end
			dc.w	13,0,22
			dc.w	.line71_end-.line71
.line71		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line71_end
			dc.w	13,0,23
			dc.w	.line72_end-.line72
.line72		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line72_end
			dc.w	13,0,24
			dc.w	.line73_end-.line73
.line73		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line73_end
			dc.w	13,0,25
			dc.w	.line74_end-.line74
.line74		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line74_end
			dc.w	13,0,26
			dc.w	.line75_end-.line75
.line75		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line75_end

		; Result numbers offset
res_offset			EQU	(.line3-resscrtxt)+12
res_line_offset		EQU .line3-.line2

		; Results screen text (page 2)
resscrtxt_2	dc.w	75					; Count
			dc.w	13,0,1
			dc.w	.line1_end-.line1
.line1		dc.b	"Flags/type |Best |Worst|Avg. |Last"
			cnop 0,2	; Realign
.line1_end
			dc.w	13,0,2
			dc.w	.line2_end-.line2
.line2		dc.b	"-----------+-----+-----+-----+------"
			cnop 0,2	; Realign
.line2_end
			dc.w	13,0,3
			dc.w	.line3_end-.line3
.line3		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line3_end
			dc.w	15,0,4
			dc.w	.line4_end-.line4
.line4		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line4_end
			dc.w	14,0,5
			dc.w	.line5_end-.line5
.line5		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line5_end
			dc.w	13,0,6
			dc.w	.line6_end-.line6
.line6		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line6_end
			dc.w	15,0,7
			dc.w	.line7_end-.line7
.line7		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line7_end
			dc.w	14,0,8
			dc.w	.line8_end-.line8
.line8		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line8_end
			dc.w	13,0,9
			dc.w	.line9_end-.line9
.line9		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line9_end
			dc.w	15,0,10
			dc.w	.line10_end-.line10
.line10		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line10_end
			dc.w	14,0,11
			dc.w	.line11_end-.line11
.line11		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line11_end
			dc.w	13,0,12
			dc.w	.line12_end-.line12
.line12		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line12_end
			dc.w	15,0,13
			dc.w	.line13_end-.line13
.line13		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line13_end
			dc.w	14,0,14
			dc.w	.line14_end-.line14
.line14		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line14_end
			dc.w	13,0,15
			dc.w	.line15_end-.line15
.line15		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line15_end
			dc.w	15,0,16
			dc.w	.line16_end-.line16
.line16		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line16_end
			dc.w	14,0,17
			dc.w	.line17_end-.line17
.line17		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line17_end
			dc.w	13,0,18
			dc.w	.line18_end-.line18
.line18		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line18_end
			dc.w	15,0,19
			dc.w	.line19_end-.line19
.line19		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line19_end
			dc.w	13,0,20
			dc.w	.line20_end-.line20
.line20		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line20_end
			dc.w	15,0,21
			dc.w	.line21_end-.line21
.line21		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line21_end
			dc.w	13,0,22
			dc.w	.line22_end-.line22
.line22		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line22_end
			dc.w	15,0,23
			dc.w	.line23_end-.line23
.line23		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line23_end
			dc.w	13,0,24
			dc.w	.line24_end-.line24
.line24		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line24_end
			dc.w	15,0,25
			dc.w	.line25_end-.line25
.line25		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line25_end
			dc.w	13,0,26
			dc.w	.line26_end-.line26
.line26		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,"     ",0
			dc.b	"     ",0,"     ",0,"      "
			cnop 0,2	; Realign
.line26_end
			dc.w	13,0,27
			dc.w	.line27_end-.line27
.line27		dc.b	"------------------------------------"
			cnop 0,2	; Realign
.line27_end

			dc.w	9,0,3
			dc.w	.line28_end-.line28
.line28		dc.b	"HQ         "
			cnop 0,2	; Realign
.line28_end
			dc.w	6,0,4
			dc.w	.line29_end-.line29
.line29		dc.b	">loop"
			cnop 0,2	; Realign
.line29_end
			dc.w	6,0,5
			dc.w	.line30_end-.line30
.line30		dc.b	">short loop"
			cnop 0,2	; Realign
.line30_end
			dc.w	9,0,6
			dc.w	.line31_end-.line31
.line31		dc.b	"HQ/68020   "
			cnop 0,2	; Realign
.line31_end
			dc.w	6,0,7
			dc.w	.line32_end-.line32
.line32		dc.b	">loop"
			cnop 0,2	; Realign
.line32_end
			dc.w	6,0,8
			dc.w	.line33_end-.line33
.line33		dc.b	">short loop"
			cnop 0,2	; Realign
.line33_end
			dc.w	9,0,9
			dc.w	.line34_end-.line34
.line34		dc.b	"Callback/I "
			cnop 0,2	; Realign
.line34_end
			dc.w	6,0,10
			dc.w	.line35_end-.line35
.line35		dc.b	">loop"
			cnop 0,2	; Realign
.line35_end
			dc.w	6,0,11
			dc.w	.line36_end-.line36
.line36		dc.b	">short loop"
			cnop 0,2	; Realign
.line36_end
			dc.w	9,0,12
			dc.w	.line37_end-.line37
.line37		dc.b	"Plugins/I  "
			cnop 0,2	; Realign
.line37_end
			dc.w	6,0,13
			dc.w	.line38_end-.line38
.line38		dc.b	">loop"
			cnop 0,2	; Realign
.line38_end
			dc.w	6,0,14
			dc.w	.line39_end-.line39
.line39		dc.b	">short loop"
			cnop 0,2	; Realign
.line39_end
			dc.w	9,0,15
			dc.w	.line40_end-.line40
.line40		dc.b	"Callb/Plg/I"
			cnop 0,2	; Realign
.line40_end
			dc.w	6,0,16
			dc.w	.line41_end-.line41
.line41		dc.b	">loop"
			cnop 0,2	; Realign
.line41_end
			dc.w	6,0,17
			dc.w	.line42_end-.line42
.line42		dc.b	">short loop"
			cnop 0,2	; Realign
.line42_end
			dc.w	9,0,18
			dc.w	.line43_end-.line43
.line43		dc.b	"PLSync     "
			cnop 0,2	; Realign
.line43_end
			dc.w	9,0,19
			dc.w	.line44_end-.line44
.line44		dc.b	"PLRepeat   "
			cnop 0,2	; Realign
.line44_end
			dc.w	9,0,20
			dc.w	.line45_end-.line45
.line45		dc.b	"PLVolume(T)"
			cnop 0,2	; Realign
.line45_end
			dc.w	9,0,21
			dc.w	.line46_end-.line46
.line46		dc.b	"PLVolume(S)"
			cnop 0,2	; Realign
.line46_end
			dc.w	9,0,22
			dc.w	.line47_end-.line47
.line47		dc.b	"PLPitch    "
			cnop 0,2	; Realign
.line47_end
			dc.w	9,0,23
			dc.w	.line48_end-.line48
.line48		dc.b	"PLPitch(LQ)"
			cnop 0,2	; Realign
.line48_end
			dc.w	9,0,24
			dc.w	.line49_end-.line49
.line49		dc.b	"PLPit (020)"
			cnop 0,2	; Realign
.line49_end
			dc.w	9,0,25
			dc.w	.line50_end-.line50
.line50		dc.b	"PLVol(T020)"
			cnop 0,2	; Realign
.line50_end
			dc.w	9,0,26
			dc.w	.line51_end-.line51
.line51		dc.b	"PLVol(S020)"
			cnop 0,2	; Realign
.line51_end
			dc.w	13,0,3
			dc.w	.line52_end-.line52
.line52		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0		
			cnop 0,2	; Realign
.line52_end
			dc.w	13,0,4
			dc.w	.line53_end-.line53
.line53		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line53_end
			dc.w	13,0,5
			dc.w	.line54_end-.line54
.line54		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line54_end
			dc.w	13,0,6
			dc.w	.line55_end-.line55
.line55		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line55_end
			dc.w	13,0,7
			dc.w	.line56_end-.line56
.line56		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line56_end
			dc.w	13,0,8
			dc.w	.line57_end-.line57
.line57		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line57_end
			dc.w	13,0,9
			dc.w	.line58_end-.line58
.line58		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line58_end
			dc.w	13,0,10
			dc.w	.line59_end-.line59
.line59		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line59_end
			dc.w	13,0,11
			dc.w	.line60_end-.line60
.line60		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line60_end
			dc.w	13,0,12
			dc.w	.line61_end-.line61
.line61		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line61_end
			dc.w	13,0,13
			dc.w	.line62_end-.line62
.line62		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line62_end
			dc.w	13,0,14
			dc.w	.line63_end-.line63
.line63		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line63_end
			dc.w	13,0,15
			dc.w	.line64_end-.line64
.line64		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line64_end
			dc.w	13,0,16
			dc.w	.line65_end-.line65
.line65		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line65_end
			dc.w	13,0,17
			dc.w	.line66_end-.line66
.line66		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line66_end
			dc.w	13,0,18
			dc.w	.line67_end-.line67
.line67		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line67_end
			dc.w	13,0,19
			dc.w	.line68_end-.line68
.line68		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line68_end
			dc.w	13,0,20
			dc.w	.line69_end-.line69
.line69		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line69_end
			dc.w	13,0,21
			dc.w	.line70_end-.line70
.line70		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line70_end
			dc.w	13,0,22
			dc.w	.line71_end-.line71
.line71		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line71_end
			dc.w	13,0,23
			dc.w	.line72_end-.line72
.line72		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line72_end
			dc.w	13,0,24
			dc.w	.line73_end-.line73
.line73		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line73_end
			dc.w	13,0,25
			dc.w	.line74_end-.line74
.line74		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line74_end
			dc.w	13,0,26
			dc.w	.line75_end-.line75
.line75		dc.b	0,0,0,0,0,0,0,0,0,0,0,"|",0,0,0,0,0,"|"
			dc.b	0,0,0,0,0,"|",0,0,0,0,0,"|",0,0,0,0,0,0
			cnop 0,2	; Realign
.line75_end

		; Result numbers offset
res_offset_2		EQU	(.line3-resscrtxt)+12
res_line_offset_2	EQU .line3-.line2

		; PAL header text
palhtxt		dc.w	1					; Count
			dc.w	7,1,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Audio Mixing v3.6 (PAL/"
			cnop 0,2	; Realign
.line1_end
			
		; NTSC header text
ntschtxt	dc.w	1					; Count
			dc.w	7,0,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Audio Mixing v3.6 (NTSC/"
			cnop 0,2	; Realign
.line1_end

singhtxt	dc.w	1					; Count
			dc.w	7,24,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"SINGLE/"
			cnop 0,2	; Realign
.line1_end

multhtxt	dc.w	1					; Count
			dc.w	7,24,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"MULTI/"
			cnop 0,2	; Realign
.line1_end

perstxt		dc.w	1					; Count
			dc.w	7,30,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"    )"
			cnop 0,2	; Realign
.line1_end

permtxt		dc.w	1					; Count
			dc.w	7,29,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"    )"
			cnop 0,2	; Realign
.line1_end

		; Subbuffer text
subtxt		dc.w	1					; Count
			dc.w	6,8,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Generating sample data"
			cnop 0,2	; Realign
.line1_end

		; Result text (subbuffer)
ressbtxt	dc.w	1					; Count
			dc.w	6,1,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"L. mouse: exit / R. mouse: display"
			cnop 0,2	; Realign               
.line1_end

		; Counter texts (subbuffer)
cntxt1		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 1 of 48"
			cnop 0,2	; Realign
.line1_end
cntxt2		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 2 of 48"
			cnop 0,2	; Realign
.line1_end
cntxt3		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 3 of 48"
			cnop 0,2	; Realign
.line1_end
cntxt4		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 4 of 48"
			cnop 0,2	; Realign
.line1_end
cntxt5		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 5 of 48"
			cnop 0,2	; Realign
.line1_end
cntxt6		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 6 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt7		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 7 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt8		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 8 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt9		dc.w	1					; Count
			dc.w	6,7,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 9 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt10		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 10 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt11		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 11 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt12		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 12 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt13		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 13 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt14		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 14 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt15		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 15 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt16		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 16 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt17		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 17 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt18		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 18 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt19		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 19 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt20		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 20 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt21		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 21 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt22		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 22 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt23		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 23 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt24		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 24 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt25		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 25 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt26		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 26 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt27		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 27 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt28		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 28 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt29		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 29 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt30		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 30 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt31		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 31 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt32		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 32 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt33		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 33 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt34		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 34 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt35		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 35 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt36		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 36 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt37		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 37 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt38		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 38 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt39		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 39 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt40		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 40 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt41		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 41 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt42		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 42 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt43		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 43 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt44		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 44 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt45		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 45 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt46		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 46 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt47		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 47 of 48"
.line1_end
			cnop 0,2	; Realign
cntxt48		dc.w	1					; Count
			dc.w	6,6,0				; Colour, X, Y
			dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"Performance test 48 of 48"
.line1_end
			cnop 0,2	; Realign			
			
		; Counter pointers
cntxt_ptrs	dc.l	cntxt1,cntxt2,cntxt3,cntxt4
			dc.l	cntxt5,cntxt6,cntxt7,cntxt8
			dc.l	cntxt9,cntxt10,cntxt11,cntxt12
			dc.l	cntxt13,cntxt14,cntxt15,cntxt16
			dc.l	cntxt17,cntxt18,cntxt19,cntxt20
			dc.l	cntxt21,cntxt22,cntxt23,cntxt24
			dc.l	cntxt25,cntxt26,cntxt27,cntxt28
			dc.l	cntxt29,cntxt30,cntxt31,cntxt32
			dc.l	cntxt33,cntxt34,cntxt35,cntxt36
			dc.l	cntxt37,cntxt38,cntxt39,cntxt40
			dc.l	cntxt41,cntxt42,cntxt43,cntxt44
			dc.l	cntxt45,cntxt46,cntxt47,cntxt48

; End of File