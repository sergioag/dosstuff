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

%ifndef __DRVPAR1_INC__
%define __DRVPAR1_INC__

	AT	ROMVARS.driveType0Params+DRVPARAMS.wCylinder,		dw	612
	AT	ROMVARS.driveType0Params+DRVPARAMS.bHeads,		db	4
	AT	ROMVARS.driveType0Params+DRVPARAMS.wReducedWrite,	dw	450
	AT	ROMVARS.driveType0Params+DRVPARAMS.wWritePrecomp,	dw	450
	AT	ROMVARS.driveType0Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType0Params+DRVPARAMS.bControlByte,	db	5	; 70ms step
	AT	ROMVARS.driveType0Params+DRVPARAMS.bStandardTimeout,	db	100
	AT	ROMVARS.driveType0Params+DRVPARAMS.bFormattingTimeout,	db	2
	AT	ROMVARS.driveType0Params+DRVPARAMS.rgbReserved,		db	5 dup 0

	AT	ROMVARS.driveType1Params+DRVPARAMS.wCylinder,		dw	306
	AT	ROMVARS.driveType1Params+DRVPARAMS.bHeads,		db	4
	AT	ROMVARS.driveType1Params+DRVPARAMS.wReducedWrite,	dw	153
	AT	ROMVARS.driveType1Params+DRVPARAMS.wWritePrecomp,	dw	0
	AT	ROMVARS.driveType1Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType1Params+DRVPARAMS.bControlByte,	db	5	; 70ms step
	AT	ROMVARS.driveType1Params+DRVPARAMS.bStandardTimeout,	db	50
	AT	ROMVARS.driveType1Params+DRVPARAMS.bFormattingTimeout,	db	1
	AT	ROMVARS.driveType1Params+DRVPARAMS.rgbReserved,		db	5 dup 0

	AT	ROMVARS.driveType2Params+DRVPARAMS.wCylinder,		dw	615
	AT	ROMVARS.driveType2Params+DRVPARAMS.bHeads,		db	2
	AT	ROMVARS.driveType2Params+DRVPARAMS.wReducedWrite,	dw	450
	AT	ROMVARS.driveType2Params+DRVPARAMS.wWritePrecomp,	dw	450
	AT	ROMVARS.driveType2Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType2Params+DRVPARAMS.bControlByte,	db	5	; 70ms step
	AT	ROMVARS.driveType2Params+DRVPARAMS.bStandardTimeout,	db	103
	AT	ROMVARS.driveType2Params+DRVPARAMS.bFormattingTimeout,	db	2
	AT	ROMVARS.driveType2Params+DRVPARAMS.rgbReserved,		db	5 dup 0

	AT	ROMVARS.driveType3Params+DRVPARAMS.wCylinder,		dw	615
	AT	ROMVARS.driveType3Params+DRVPARAMS.bHeads,		db	4
	AT	ROMVARS.driveType3Params+DRVPARAMS.wReducedWrite,	dw	450
	AT	ROMVARS.driveType3Params+DRVPARAMS.wWritePrecomp,	dw	450
	AT	ROMVARS.driveType3Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType3Params+DRVPARAMS.bControlByte,	db	5	; 70ms step
	AT	ROMVARS.driveType3Params+DRVPARAMS.bStandardTimeout,	db	103
	AT	ROMVARS.driveType3Params+DRVPARAMS.bFormattingTimeout,	db	2
	AT	ROMVARS.driveType3Params+DRVPARAMS.rgbReserved,		db	5 dup 0

%endif ; ! __DRVPAR1_INC__
