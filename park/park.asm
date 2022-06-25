; Park
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

	SECTION	.text
	ORG	100h

_main:
	MOV	DX,msgConfirm
	CALL	_print

_keyloop:
	MOV	AH,0				; Get keystroke
	INT	16H
	CMP	AL,'a'				; Check for lower case
	JGE	_checkkey			; Directly check for lower case
	ADD	AL,20H				; Make it upper case
_checkkey:
	CMP	AL,'y'				; Is it 'y' or 'Y'?
	JZ	_driveLoopStart			; Go park drives
	MOV	DX,msgNotParked			; Print not parked message

_exit:
	CALL	_print
	INT	20h				; Exit program

_driveLoopStart:
	PUSH	ES
	XOR	CX,CX
	MOV	ES,CX
	ES MOV	CL,[0475h]			; BIOS data: number of fixed drives
	POP	ES
	TEST	CL,CL				; Is it zero?
	MOV	DX,msgNoFixedDrives		; Error message
	JZ	_exit				; No point of continuing
	MOV	DL,80h				; Starting drive

_driveLoop:
	CALL	_park				; Park the drive
	JC	_parkError			; Jump on error
	INC	DL				; Next drive
	LOOP	_driveLoop			; Loop while we have another drive

	MOV	DX,msgSafePowerOff		; Success message
	CALL	_print

_halt:
	CLI					; No interrupts
	HLT					; Halt
	JMP	SHORT _halt			; Shouldn't reach here

_parkError:
	MOV	DX,msgErrorParking		; Error message
	JMP	SHORT _exit;

;--------------------------------------------------------------------------------
; _park
;--------------------------------------------------------------------------------
; Sends a seek to the selected hard drive to the heads move to the landing zone.
;
; Input:
; DL = Fixed disk number (80h = first one, 81h = second one)
;
; Output:
; CF clear on success
; CF set on error and AH contains error code
; AL destroyed
;--------------------------------------------------------------------------------
_park:
	PUSH	BX				; Save registers
	PUSH	CX
	PUSH	DX
	PUSH	ES
	PUSH	DI

	MOV	AH,8				; Get drive parameters
	PUSH	DX
	INT	13h
	POP	DX
	JC	_parkFinish

	AND	CL,0C0h				; Clear bits 0-5
	OR	CL,1				; Set sector 1
	XOR	DH,DH				; Set head = 0
	MOV	AH,0Ch				; Seek to cylinder
	INT	13h

%ifdef DEBUG
	MOV	DX,msgParked
	CALL	_print
%endif

_parkFinish:
	POP	DI				; Restore registers
	POP	ES
	POP	DX
	POP	CX
	POP	BX
	RET

;--------------------------------------------------------------------------------
; _print
;--------------------------------------------------------------------------------
; This function prints a '$' terminated string to the standard output.
;
; Input:
; DS:DX = Pointer to the string to write
;
; Output:
; AH destroyed
;--------------------------------------------------------------------------------
_print:
	MOV	AH,9
	INT	21H
	RET

msgConfirm:
	DB	"This program will park all your hard drive's heads",13,10
	DB	'to the landing zone and then halt your computer.',13,10
	DB	'Do you want to continue? (Y/N): $'
msgNoFixedDrives:
	DB	'Your system has no fixed disk drives.',13,10,'$'
msgNotParked:
	DB	13,10,'Your hard drive has NOT been parked.',13,10,'$'
msgSafePowerOff:
	DB	13,10,'Drives parked. It is now safe to power off your computer.',13,10,'$'
msgErrorParking:
	DB	'Error parking hard drive.',13,10,'$'

%ifdef DEBUG
msgParked:
	DB	'Drive parked',13,10,'$'
%endif
