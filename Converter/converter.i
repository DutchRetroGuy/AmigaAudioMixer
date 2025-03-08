; $VER: converter.i 2.0 (07.03.23)
;
; converter.i
; Include file for converter.asm
;
; Converter API (see mixer documentation for full information)
; ------------------------------------------------------------ 
; ConvertSampleDivide(A0=sample_ptr,A1=destination_ptr,
;                     D0=length.l,D1=number_of_channels)
;	Pre-processes a sample for use with the mixing routines.
;	Point A0 to the unmodified sample to be converted, A1 to the destination
;	location to store the converted result (this can be the same as A0 if 
;	desired). Give the length of the sample in D0 and the maximum number of
;	channels to mix together in D1.
;
;	Note: the value for number_of_channels should be equal to the value of
;	      mixer_sw_channels in mixer_config.i.
;	Note: Pre-processing samples is only needed if the value of 
;	      mixer_sw_channels in mixer_config.i is larger than 1.
;	Note: Pre-processing samples is a requirement for multi-channel mixing.
;	      However, pre-processing can be done in other ways than via this 
;	      routine.
;
;	      This routine is primarily provided as an example of how to achieve
;	      the correct result, for larger projects it's recommended to do the
;	      pre-processing ahead of time and not during run-time.
;
; Author: Jeroen Knoester
; Version: 2.0
; Revision: 20230307
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include	exec/types.i

	IFND	MIXER_CONVERTER_I
MIXER_CONVERTER_I	SET	1

; References macro
	IFND EXREF
EXREF	MACRO
		IFD BUILD_CONVERTER
			XDEF \1
		ELSE
			XREF \1
		ENDIF
		ENDM
	ENDIF

; References
	EXREF	ConvertSampleDivide
	
	ENDC	; MIXER_CONVERTER_I
; End of File