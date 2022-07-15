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

%ifndef __DRVPAR2_INC__
%define __DRVPAR2_INC__

	AT	ROMVARS.driveType4Params+DRVPARAMS.wCylinder,		dw	981
	AT	ROMVARS.driveType4Params+DRVPARAMS.bHeads,		db	5
	AT	ROMVARS.driveType4Params+DRVPARAMS.wReducedWrite,	dw	982
	AT	ROMVARS.driveType4Params+DRVPARAMS.wWritePrecomp,	dw	982
	AT	ROMVARS.driveType4Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType4Params+DRVPARAMS.bControlByte,	db	7	; 3ms step
	AT	ROMVARS.driveType4Params+DRVPARAMS.bStandardTimeout,	db	213
	AT	ROMVARS.driveType4Params+DRVPARAMS.bFormattingTimeout,	db	3
	AT	ROMVARS.driveType4Params+DRVPARAMS.rgbReserved,		db	5 dup 0

	AT	ROMVARS.driveType5Params+DRVPARAMS.wCylinder,		dw	987
	AT	ROMVARS.driveType5Params+DRVPARAMS.bHeads,		db	7
	AT	ROMVARS.driveType5Params+DRVPARAMS.wReducedWrite,	dw	988
	AT	ROMVARS.driveType5Params+DRVPARAMS.wWritePrecomp,	dw	988
	AT	ROMVARS.driveType5Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType5Params+DRVPARAMS.bControlByte,	db	7	; 3ms step
	AT	ROMVARS.driveType5Params+DRVPARAMS.bStandardTimeout,	db	219
	AT	ROMVARS.driveType5Params+DRVPARAMS.bFormattingTimeout,	db	3
	AT	ROMVARS.driveType5Params+DRVPARAMS.rgbReserved,		db	5 dup 0

	AT	ROMVARS.driveType6Params+DRVPARAMS.wCylinder,		dw	612
	AT	ROMVARS.driveType6Params+DRVPARAMS.bHeads,		db	4
	AT	ROMVARS.driveType6Params+DRVPARAMS.wReducedWrite,	dw	613
	AT	ROMVARS.driveType6Params+DRVPARAMS.wWritePrecomp,	dw	613
	AT	ROMVARS.driveType6Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType6Params+DRVPARAMS.bControlByte,	db	7	; 3ms step
	AT	ROMVARS.driveType6Params+DRVPARAMS.bStandardTimeout,	db	100
	AT	ROMVARS.driveType6Params+DRVPARAMS.bFormattingTimeout,	db	2
	AT	ROMVARS.driveType6Params+DRVPARAMS.rgbReserved,		db	5 dup 0

	AT	ROMVARS.driveType7Params+DRVPARAMS.wCylinder,		dw	615
	AT	ROMVARS.driveType7Params+DRVPARAMS.bHeads,		db	4
	AT	ROMVARS.driveType7Params+DRVPARAMS.wReducedWrite,	dw	616
	AT	ROMVARS.driveType7Params+DRVPARAMS.wWritePrecomp,	dw	616
	AT	ROMVARS.driveType7Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType7Params+DRVPARAMS.bControlByte,	db	7	; 3ms step
	AT	ROMVARS.driveType7Params+DRVPARAMS.bStandardTimeout,	db	103
	AT	ROMVARS.driveType7Params+DRVPARAMS.bFormattingTimeout,	db	2
	AT	ROMVARS.driveType7Params+DRVPARAMS.rgbReserved,		db	5 dup 0

%endif ; ! __DRVPAR2_INC__
