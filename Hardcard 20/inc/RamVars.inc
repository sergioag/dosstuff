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

%ifndef __RAMVARS_INC__
%define __RAMVARS_INC__

struc VECTOR
	.wOffset	resb	2
	.wSegment	resb	2
endstruc

%define INT_OFF_VAL(a)	(a*VECTOR_size)+VECTOR.wOffset
%define INT_OFFSET(a)	[INT_OFF_VAL(a)]
%define INT_SEG_VAL(a)	(a*VECTOR_size)+VECTOR.wSegment
%define INT_SEGMENT(a)	[INT_SEG_VAL(a)]

struc CTX
	.bp0AX		resb	2
	.bp2CX		resb	2
	.bp4DX		resb	2

	.bp6DI		resb	2
	.bp8ES		resb	2
	.bpASI		resb	2
	.bpCDX		resb	2
	.bpECX		resb	2
	.bp10BX		resb	2
	.bp12AX		resb	2
	.bp14DS		resb	2
	.bp16BP		resb	2

	; Bit 0: If direct video access possible
	; Bit 1: Unknown
	; Bit 2: Unknown
	; Bit 3: Unknown
	; Bit 4: Unknown
	; Bit 5: Running in PS/2
	; Bit 6: Running in AT
	; Bit 7: Unknown
	.bp18		resb	1
	.bp19		resb	1
	.bp1ARetAX	resb	2
	.bp1C		resb	2	; Return address for restore_ctx
	.bp1E		resb	1	; Number of drives
	.bp1F		resb	1
	; Bit 0: Unknown
	; Bit 1: Unknown
	; Bit 2: Unknown
	; Bit 3: Unknown
	; Bit 4: Unknown
	; Bit 5: Unknown
	; Bit 6: Running as second drive
	; Bit 7: Unknown
	.bp20		resb	2	; Some bitfield
	.bp22		resb	2
	.bp24Caller	resb	2
endstruc

HDD_VARS		equ	0442h
VIDEO_MODE		equ	0449h
TIMER_TICKS		equ	046Ch
POST_RESET_FLAG		equ	0472h
LAST_STATUS		equ	0474h
NUM_FIXED_DRIVES	equ	0475h
CONTROL_BYTE		equ	0476h
IO_PORT_OFFSET		equ	0477h
BOOT_LOCN		equ	7C00h
BOOT_SIGNATURE		equ	7DFEh

SAVED_NUM_DRIVES	equ	7E04h
SAVED_CS		equ	7E06h
SAVED_IMR		equ	7E0Bh
BIOS_SEG		equ	0F000h
MACHINE_TYPE		equ	0FFFEh
MACHINE_TYPE_AT		equ	0FCh
MACHINE_TYPE_PS2	equ	0FAh

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

PIC_PORTA		equ	20h
PIC_PORTB		equ	21h
PS2_SYS_BRD		equ	65h
%endif ; ! __RAMVARS_INC__
