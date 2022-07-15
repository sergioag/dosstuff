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

SECOND_DISK_HANDLER:
	STI					; Interrupts enabled
	CMP	DL,80H				; Is the call for fixed disks?
	JNC	LAB_c800_02f7			; Yes, deal with hard drives

CALL_FLOPPY_HANDLER:
	INT	40H				; Call old INT 13H handler
	RETF	2				; Discard saved flags on return

LAB_c800_02f7:
	PUSH	BX				; Save registers
	PUSH	DS				; Save DS while we work on data
	PUSH	AX				; Save AX
	MOV	AX,0
	MOV	DS,AX				; DS=0000h
	MOV	BX,SECOND_DISK_AREA		; Second controller data area
	MOV	AL,[BX]				; Get our drive count
	SHR	AL,1				; Discard I/O offset in low nibble
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	ADD	AL,80H				; Set high nibble
	CMP	DL,AL				; Matches?
	POP	AX
	JNC	LAB_c800_032a			; Yes, handle it
	POP	DS				; Restore registers we didn't use
	POP	BX
	INT	47H				; Doesn't match - send it to first controller
	RETF	2				; Discard saved flags on return

DISK_HANDLER:
	STI					; Interrupts enabled
	CMP	DL,80H				; If this for hard drives?
	JC	CALL_FLOPPY_HANDLER		; No, call regular floppy handler
	PUSH	BX
	PUSH	DS				; Save DS while we work with data
	MOV	BX,0
	MOV	DS,BX
	MOV	BX,FIRST_DISK_AREA	; First controller data area

LAB_c800_032a:
	MOV	[DISK_AREA_PTR],BX		; Save disk area pointer
	POP	DS				; Restore DS
	PUSH	CX				; Save registers for return
	PUSH	DX
	PUSH	BP
	PUSH	DI
	PUSH	SI
	PUSH	DS
	PUSH	ES
	MOV	BP,SP				; Used to access saved registers later
	
	; Addresses for saved registers relative to BP:
	; BP+0		ES
	; BP+2		DS
	; BP+4		SI
	; BP+6		DI
	; BP+8		BP
	; BP+10 (0A)	DX
	; BP+12 (0C)	CX
	; BP+14 (0E)	BX
	
	PUSH	AX
	MOV	AX,0
	MOV	DS,AX				; DS=0000h
	MOV	SI,[DISK_AREA_PTR]		; Obtain disk area pointer
	MOV	AL,80H				; Start building hard disk device number
	ADD	AL,[BX+1]			; Last hard drive of this controller
	CMP	DL,AL				; Check if the drive is for us
	POP	AX
	JA	CALL_ROM_DISK_BIOS		; No, jump to saved vector
	CMP	AH,16H				; Calling greater than AH=16H?
	JA	LAB_c800_039a			; Yes, unsupported.
	CMP	AH,0				; Calling reset disk system?
	JNZ	DO_DISK_BIOS			; No, proceed only with hard drives
	INT	40H				; Call floppy disk reset
	MOV	AH,0				; Restore value of AH

DO_DISK_BIOS:
	CALL	FUN_c800_039e			; Do actual work

LAB_c800_035d:
	PUSH	AX				; Save AX during IRQ and DMA disable
	CALL	GET_MASK_REGISTER_ADDR		; Obtain mask register address in DX
	MOV	AL,0FCH				; Mask IRQ and DMA in controller
	OUT	DX,AL				; Write IRQ and DMA mask register
	MOV	AL,7				; DMA channel 3, masked
	OUT	0AH,AL				; Update 8237 DMA mask register
	CLI					; Disable interrupts
	CALL	READ_HARDWARE_CONFIG
	AND	AL,40H				; Check for IRQ bit
	IN	AL,21H				; Read OCW1 from PIC
	JNZ	MASK_IRQ5			; If set to IRQ 5, go for it
	OR	AL,4				; Mask IRQ 2
	JMP	SHORT DO_MASK_IRQ

MASK_IRQ5:
	OR	AL,20H				; Mask IRQ 5

DO_MASK_IRQ:
	OUT	21H,AL				; Update PIC OCW1
	STI					; Interrupts enabled
	CMP	AH,0F3H				; Check for non-error return
	JZ	LAB_c800_0383			; Yes, jump over
	ADD	AH,0FFH				; Force set carry to indicate error

LAB_c800_0383:
	POP	AX				; Restore AX

LAB_c800_0384:
	POP	ES
	POP	DS
	POP	SI
	POP	DI
	POP	BP
	POP	DX
	POP	CX
	POP	BX
	RETF	2				; Discard saved flags on return

CALL_ROM_DISK_BIOS:
	CMP	AH,0
	JNZ	LAB_c800_039a
	INT	40H
	MOV	AH,0
	JMP	SHORT LAB_c800_0384

LAB_c800_039a:
	MOV	AH,1
	JMP	SHORT LAB_c800_035d


FUN_c800_039e:
	MOV	[SAVED_INT13H_AL],AL		; Save AL input value
	DEC	CL
	MOV	[SAVED_INT13H_CX],CX
	PUSH	CS
	POP	CX
	CMP	CH,0C8H				; Check for C8xx
	MOV	CH,0
	JZ	LAB_c800_03b8			; First controller - go jump

	MOV	CH,[SI]				; Get drive from data area
	MOV	CL,4
	SHR	CH,CL				; Drive number in low nibble
	NEG	CH

LAB_c800_03b8:
	ADD	CH,DL
	AND	CH,1
	MOV	CL,5
	SHL	CH,CL
	MOV	BX,[SI+2]
	XCHG	BH,BL
	OR	CH,CH
	JZ	LAB_c800_0417
	TEST	BH,8
	XCHG	BH,BL
	JNZ	LAB_c800_0417
	XCHG	BH,BL
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	AND	BX,03FFH
	CALL	READ_HARDWARE_CONFIG
	NOT	AL
	AND	AL,30H
	XOR	AL,30H
	JNZ	LAB_c800_03f2
	MOV	AX,1529
	MUL	BX
	MOV	BX,1000
	DIV	BX
	MOV	BX,AX

LAB_c800_03f2:
	POP	DX
	POP	CX
	XOR	CH,CH
	MOV	AX,[SAVED_INT13H_CX]
	MOV	CL,6
	SHR	AL,CL
	XCHG	AH,AL
	ADD	AX,BX
	MOV	CL,6
	SHL	AH,CL
	XCHG	AH,AL
	XCHG	[SAVED_INT13H_CX],AX
	AND	AX,01FH
	OR	AX,[SAVED_INT13H_CX]
	MOV	[SAVED_INT13H_CX],AX
	POP	BX
	POP	AX

LAB_c800_0417:
	MOV	CL,4
	SHR	BH,CL
	AND	BH,7
	MOV	[LAB_0000_0447],BH
	AND	DH,0FH
	OR	CH,DH
	MOV	[LAB_0000_0443],CH
	CALL	FUN_c800_0a0f
	JNZ	LAB_c800_0433
	CALL	FUN_c800_0a48

LAB_c800_0433:
	MOV	AL,AH				; Function code in AL
	MOV	BX,COMMAND_TABLE
	CS XLATB				; Obtain command byte
	MOV	[LAB_0000_0442],AL		; Save it
	MOV	BL,AH				; Function code in BL
	XOR	BH,BH				; Clear BH
	SHL	BL,1				; Multiply by 2
	CS JMP	WORD [BX+FUNCTION_POINTERS]	; Call function

