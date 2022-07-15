; BIOS for WD1002S-WX2
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

%ifndef __DRVPARAMS12_INC__
%define __DRVPARAMS12_INC__

	;----------- Type 0 parameters
	AT	ROMVARS.driveType0Params+DRVPARAMS.wCylinder,		dw	612
	AT	ROMVARS.driveType0Params+DRVPARAMS.bHeads,		db	4
	AT	ROMVARS.driveType0Params+DRVPARAMS.wReducedWrite,	dw	613
	AT	ROMVARS.driveType0Params+DRVPARAMS.wWritePrecomp,	dw	613
	AT	ROMVARS.driveType0Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType0Params+DRVPARAMS.bControlByte,	db	5	; 70us step
	AT	ROMVARS.driveType0Params+DRVPARAMS.rgbReserved,		db	7 dup 0

	;----------- Type 1 parameters
	AT	ROMVARS.driveType1Params+DRVPARAMS.wCylinder,		dw	612
	AT	ROMVARS.driveType1Params+DRVPARAMS.bHeads,		db	2
	AT	ROMVARS.driveType1Params+DRVPARAMS.wReducedWrite,	dw	128
	AT	ROMVARS.driveType1Params+DRVPARAMS.wWritePrecomp,	dw	128
	AT	ROMVARS.driveType1Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType1Params+DRVPARAMS.bControlByte,	db	5	; 70us step
	AT	ROMVARS.driveType1Params+DRVPARAMS.rgbReserved,		db	7 dup 0

	;----------- Type 2 parameters
	AT	ROMVARS.driveType2Params+DRVPARAMS.wCylinder,		dw	612
	AT	ROMVARS.driveType2Params+DRVPARAMS.bHeads,		db	2
	AT	ROMVARS.driveType2Params+DRVPARAMS.wReducedWrite,	dw	613
	AT	ROMVARS.driveType2Params+DRVPARAMS.wWritePrecomp,	dw	128
	AT	ROMVARS.driveType2Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType2Params+DRVPARAMS.bControlByte,	db	5	; 70us step
	AT	ROMVARS.driveType2Params+DRVPARAMS.rgbReserved,		db	7 dup 0

	;----------- Type 3 parameters
	AT	ROMVARS.driveType3Params+DRVPARAMS.wCylinder,		dw	306
	AT	ROMVARS.driveType3Params+DRVPARAMS.bHeads,		db	4
	AT	ROMVARS.driveType3Params+DRVPARAMS.wReducedWrite,	dw	306
	AT	ROMVARS.driveType3Params+DRVPARAMS.wWritePrecomp,	dw	0
	AT	ROMVARS.driveType3Params+DRVPARAMS.bMaxEccBurst,	db	11
	AT	ROMVARS.driveType3Params+DRVPARAMS.bControlByte,	db	5	; 70us step
	AT	ROMVARS.driveType3Params+DRVPARAMS.rgbReserved,		db	7 dup 0

%endif
