; BIOS for Plus Hardcard 20
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

struc DRVPARAMS
	.wCylinder		resb	2		; Cylinders
	.bHeads			resb	1		; Heads
	.wReducedWrite		resb	2		; Starting reduced write current cylinder
	.wWritePrecomp		resb	2		; Starting write precompensation cylinder
	.bMaxEccBurst		resb	1		; Maximum ECC burst length
	.bControlByte		resb	1		; Control byte
	.bStdTimeout		resb	1		; Standard timeout
	.bFormatTimeout		resb	1		; Formatting timeout
	.bDriveTimeout		resb	1		; Drive timeout
	.wLandingCyl		resb	2		; Landing zone cylinder
	.bSecPerTrk		resb	1		; Sectors per track
	.bReserved		resb	1		; Reserved (unused)
endstruc

struc FLOPPYPARAMS
	.bFirstSpecify		resb	1		; First specify byte
							; bits 7-4: step rate (Fh=2ms, Eh=4ms, Dh=6ms, etc)
							; bits 3-0: head unload time (0Fh=240ms)
	.bSecondSpecify		resb	1		; bits 7-1: head load time (01h = 4ms)
							; bit    0: non-DMA mode (always 0)
	.bMotorDelay		resb	1		; Delay until motor is turned on (in timer ticks)
	.bBytesPerSector	resb	1		; Bytes per sector (00h=128, 01h=256, 02h=512, 03h=1024)
	.bSectorsPerTrack	resb	1		; Sectors per track (maximum if varies per track)
	.bGapLength		resb	1		; Length of gap between sectors (2Ah for 5.25", 1Bh, for 3.5")
	.bDataLength		resb	1		; Data length (ignored if bytes per sector is non-zero)
	.bGapLengthFormat	resb	1		; Gap length when formatting (50h for 5.25", 6Ch for 3.5")
	.bFormatFiller		resb	1		; Format filler byte (default F6h)
	.bHeadSettleTime	resb	1		; Head settle time in milliseconds
	.bMotorStartTime	resb	1		; Motor start time in 1/8 seconds
endstruc

struc ROMVARS
	.wBiosSignature		resb	2		; BIOS signature (AA55h)
	.bBiosLength		resb	1		; BIOS length in 512 btyes blocks
	.rgbBiosEntry		resb	2		; BIOS entry point
	.rgbFormatEntry		resb	3		; BIOS Format entry point
	.rgbVector		resb	3		; BIOS unknown vector
	.szCopyright		resb	110		; Copyright string
endstruc

%endif ; !__ROMVARS_INC__
