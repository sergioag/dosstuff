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

%ifndef __RAMVARS_INC__
%define __RAMVARS_INC__

struc VECTOR
	.wOffset	resb	2
	.wSegment	resb	2
endstruc

%define INT_OFFSET(a)	[(a*VECTOR_size)+VECTOR.wOffset]
%define INT_SEGMENT(a)	[(a*VECTOR_size)+VECTOR.wSegment]

struc CommandBlock
	.opCode		resb	1		; 0042h
	.driveAndHead	resb	1		; 0043h	- Contains drive number
						; in bit 5, number of heads in
						; bits 0-3
	.cylAndSector	resb	2		; 0044h
	.blockCount	resb	1		; 0046h
	.controlByte	resb	1		; 0047h
endstruc

struc StatusBlock
	.errorCode	resb	1
	.driveAndHead	resb	1
	.cylAndSector	resb	2
endstruc

HDD_VARS		equ	0042h
TIMER_TICKS		equ	006Ch
POST_RESET_FLAG		equ	0072h
LAST_STATUS		equ	0074h
NUM_FIXED_DRIVES	equ	0075h
BOOT_LOCN		equ	7C00h
BOOT_SIGNATURE		equ	7DFEh

STATUS_SUCCESS		equ	00h
STATUS_INVALID_PARAMS	equ	01h
STATUS_ADDR_MARK_NOT_FND equ	02h
STATUS_SECTOR_NOT_FND	equ	04h
STATUS_RESET_FAILED	equ	05h
STATUS_DRIVE_FAILED	equ	07h
STATUS_DMA_BOUNDARY	equ	09h
STATUS_BAD_TRACK	equ	0Bh
STATUS_UNCORRECTABLE	equ	10h
STATUS_CORRECTABLE	equ	11h
STATUS_CONTROLLER_FAIL	equ	20h
STATUS_SEEK_FAILED	equ	40h
STATUS_TIMEOUT		equ	80h
STATUS_UNDEFINED	equ	0BBh
STATUS_SENSE_OP_FAILED	equ	0FFh

CMD_TST_DRIVE_RDY	equ	00h
CMD_RECALIBRATE		equ	01h
CMD_GET_LAST_STATUS	equ	03h
CMD_FORMAT_DRIVE	equ	04h
CMD_VERIFY		equ	05h
CMD_FORMAT_TRACK	equ	06h
CMD_FORMAT_BAD_TRACK	equ	07h
CMD_READ_SECTORS	equ	08h
CMD_WRITE_SECTORS	equ	0Ah
CMD_SEEK		equ	0Bh
CMD_INIT_DRV_PARAMS	equ	0Ch
CMD_READ_ECC_BURST_LEN	equ	0Dh
CMD_READ_SECTOR_BUF	equ	0Eh
CMD_WRITE_SECTOR_BUF	equ	0Fh
CMD_SECTOR_BUF_DIAG	equ	0E0h
CMD_DRIVE_DIAG		equ	0E3h
CMD_CONTROLLER_DIAG	equ	0E4h
CMD_READ_LONG		equ	0E5h
CMD_WRITE_LONG		equ	0E6h

ERROR_NONE		equ	00h
ERROR_NO_SC		equ	02h
ERROR_WRITE_FAULT	equ	03h
ERROR_NOT_READY		equ	04h
ERROR_TRK_0_NOT_FND	equ	06h
ERROR_DRIVE_BUSY	equ	08h
ERROR_UNCORRECTABLE	equ	11h
ERROR_ADDR_MARK_NOT_FND	equ	12h
ERROR_SEEK		equ	15h
ERROR_CORRECTABLE	equ	18h
ERROR_TRACK_BAD		equ	19h
ERROR_INVALID_CMD	equ	20h
ERROR_ILLEGAL_SECTOR	equ	21h
ERROR_SECTOR_BUF	equ	30h
ERROR_CONTROLLER_ROM	equ	31h
ERROR_ECC_POLYNOMIAL	equ	32h

%endif ; ! __RAMVARS_INC__
