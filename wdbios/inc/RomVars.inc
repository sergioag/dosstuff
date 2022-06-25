; Super-BIOS for WD1002A-WX1
; Copyright (c) 2022, Sergio Aguayo
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

struc DRVPARAMS
	.wCylinder		resb	2		; Cylinders
	.bHeads			resb	1		; Heads
	.wReducedWrite		resb	2		; Starting reduced write current cylinder
	.wWritePrecomp		resb	2		; Starting write precompensation cylinder
	.bMaxEccBurst		resb	1		; Maximum ECC burst length
	.bControlByte		resb	1		; Control byte
	.bStandardTimeout	resb	1		; Standard timeout
	.bFormattingTimeout	resb	1		; Formatting timeout
	.rgbReserved		resb	5		; Reserved (unused)
endstruc

struc ROMVARS
	.wBiosSignature		resb	2		; BIOS signature (AA55h)
	.bBiosLength		resb	1		; BIOS length in 512 btyes blocks
	.rgbBiosEntry		resb	2		; BIOS entry point
	.rgbFormatEntry		resb	3		; BIOS Format entry point
	.szCopyright		resb	48		; Copyright string
	.rgbUnknown		resb	11		; Unknown
	.driveType0Params	resb	DRVPARAMS_size	; Drive type 0 params
	.driveType1Params	resb	DRVPARAMS_size	; Drive type 1 params
	.driveType2Params	resb	DRVPARAMS_size	; Drive type 2 params
	.driveType3Params	resb	DRVPARAMS_size	; Drive type 3 params
	.rgbBiosEntryJump	resb	2		; Jump to entry point
	.driveType4Params	resb	DRVPARAMS_size	; Drive type 4 params
	.driveType5Params	resb	DRVPARAMS_size	; Drive type 5 params
	.driveType6Params	resb	DRVPARAMS_size	; Drive type 6 params
	.driveType7Params	resb	DRVPARAMS_size	; Drive type 7 params
endstruc

%endif ; !__ROMVARS_INC__
