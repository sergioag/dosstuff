; BIOS for Cirrus Logic CL-GD5428
; Copyright (c) 2023, Sergio Aguayo
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%ifndef __ROMVARS_INC__
%define __ROMVARS_INC__

struc ROMVARS
	.wBiosSignature		resb	2		; BIOS signature (AA55h)
	.bBiosLength		resb	1		; BIOS length in 512 btyes blocks
	.rgbBiosEntry		resb	3		; BIOS entry point
endstruc

struc VideoSavePointerTbl
	.wVideoParameterTableOff	resb	2	; Pointer to VideoParameterTbl (Offset)
	.wVideoParameterTableSeg	resb	2	; Pointer to VideoParameterTbl (Segment)
	.wVideoDynamicSaveAreaOff	resb	2	; Pointer to VideoDynamicSaveAreaTbl (Offset)
	.wVideoDynamicSaveAreaSeg	resb	2	; Pointer to VideoDynamicSaveAreaTbl (Segment)
	.wAlphaCharsetOverrideOff	resb	2	; Pointer to AlphaCharsetOverrideTbl (Offset)
	.wAlphaCharsetOverrideSeg	resb	2	; Pointer to AlphaCharsetOverrideTbl (Segment)
	.wGraphicsCharsetOverrideOff	resb	2	; Pointer to GraphicsCharsetOverrideTbl (Offset)
	.wGraphicsCharsetOverrideSeg	resb	2	; Pointer to GraphicsCharsetOverrideTbl (Segment)
	.wSecSavePointerTableOff	resb	2	; Pointer to SecSavePointerTbl (Offset)
	.wSecSavePointerTableSeg	resb	2	; Pointer to SecSavePointerTbl (Segment)
	.dwReserved1			resb	4	; Reserved
	.dwReserved2			resb	4	; Reserved
endstruc

struc SecSavePointerTbl
	.wSize				resb	2	; Length of this table in bytes, including this field
	.wDspCombinationCodeTblOff	resb	2	; Pointer to DspCombinationCodeTbl (Offset)
	.wDspCombinationCodeTblSeg	resb	2	; Pointer to DspCombinationCodeTbl (Segment)
	.wSecAlphaCharsetOverrideOff	resb	2	; Pointer to AlphaCharsetOverrideTbl (Offset)
	.wSecAlphaCharsetOverrideSeg	resb	2	; Pointer to AlphaCharsetOverrideTbl (Segment)
	.wUsrPaletteProfileTblOff	resb	2	; Pointer to UsrPaletteProfileTbl (Offset)
	.wUsrPaletteProfileTblSeg	resb	2	; Pointer to UsrPaletteProfileTbl (Segment)
	.dwReserved1			resb	4	; Reserved
	.dwReserved2			resb	4	; Reserved
	.dwReserved3			resb	4	; Reserved
endstruc

struc DspCombinationCodeTbl
	.bNumEntries			resb	1	; Number of entries
	.bVersion			resb	1	; Version number
	.bMaxCodeNumber			resb	1	; Maximum display type code that can appear in DCC table
	.bReserved			resb	1	; Reserved
	; Followed by bNumEntries times of DspCombinationEntry
endstruc

%macro DSP_COMBINATION 2
istruc DspCombinationEntry
	AT DspCombinationEntry.bType1,	db	%1
	AT DspCombinationEntry.bType2,	db	%2
iend
%endmacro

struc DspCombinationEntry
	.bType1				resb	1
	.bType2				resb	1
endstruc

; Values for DspCombinationEntry
NO_DISPLAY				equ	00h	; No display
MDA_MONO				equ	01h	; MDA with mono display
CGA_COLOR				equ	02h	; CGA with color display
; 03h is reserved
EGA_COLOR				equ	04h	; EGA with color display
EGA_MONO				equ	05h	; EGA with mono display
PGA					equ	06h	; Professional Graphics Controller
VGA_MONO				equ	07h	; VGA with mono display
VGA_COLOR				equ	08h	; VGA with color display
; 09h is reserved
MCGA_DIGITAL_COLOR			equ	0Ah	; MCGA with digital color display
MCGA_ANALOG_MONO			equ	0Bh	; MCGA with analog mono display
MCGA_ANALOG_COLOR			equ	0Ch	; MCGA with analog color display
UNRECOGNIZED				equ	0FFh	; Unrecognized video system

struc VideoParameterTbl
	.bNumColumns			resb	1	; Number of columns (44Ah)
	.bNumRowsMinusOne		resb	1	; Number of rows minus one (484h)
	.bCharHeight			resb	1	; Height of character in scan lines (485h)
	.wBufferSize			resb	2	; Size of video buffer (44Ch)
	.baSeqRegs			resb	4	; Values for Sequencer Registers 1-4
	.bMiscOutputReg			resb	1	; Value for Miscellaneous Output Register
	.baCRTCRegs			resb	25	; Values for CRTC Registers 00h-18h
	.baAttrContRegs			resb	20	; Values for Attribute Controller Registers 00h-13h
	.baGraphContRegs		resb	9	; Values for Graphics Controller Registers 00h-08h
endstruc



%endif ; !__ROMVARS_INC__
