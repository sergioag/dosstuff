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

	CPU	8086
	ORG	0

	%include "inc/RomVars.inc"
	%include "inc/RamVars.inc"
	%include "inc/equs.inc"
	%include "inc/biosseg.inc"

	SECTION	.text
istruc ROMVARS
	AT	ROMVARS.wBiosSignature,		dw	0AA55h
	AT	ROMVARS.bBiosLength,		db	16
	AT	ROMVARS.rgbBiosEntry,		jmp	short ROMVARS.rgbBiosEntryJump
	AT	ROMVARS.rgbFormatEntry,		jmp	LAB_c800_0b50
	AT	ROMVARS.szCopyright,		db	'07/15/86(C) Copyright 1986 Western Digital Corp.'
	AT	ROMVARS.rgbUnknown,		db	0CFh, 02h, 25h, 02h, 08h, 2Ah, 0FFh, 50h, 0F6h, 19h, 04h

	%include "inc/drvpar1.inc"
	AT	ROMVARS.rgbBiosEntryJump,	jmp	short entry
	%include "inc/drvpar2.inc"
iend

	%include "Initialize.asm"
	%include "Boot.asm"
	%include "IrqHandler.asm"
	%include "Int13h.asm"


FUNCTION_POINTERS:
	DW	RESET_DISK_SYSTEM	; (AH=0) Reset disk system
	DW	FUN_c800_07d2		; (AH=1) Get status of last operation
	DW	FUN_c800_0696		; (AH=2) Read sector(s) into memory
	DW	FUN_c800_066a		; (AH=3) Write disk sector(s)
	DW	FUN_c800_0709		; (AH=4) Verify disk sector(s)
	DW	FUN_c800_0709		; (AH=5) Format track
	DW	FUN_c800_0709		; (AH=6) Format track and set bad sector flags
	DW	FUN_c800_0709		; (AH=7) Format drive starting at given track
	DW	FUN_c800_05ef		; (AH=8) Get drive parameters
	DW	LAB_c800_04c6		; (AH=9) Initialize controller with drive parameters
	DW	FUN_c800_067d		; (AH=0A) Read long sector
	DW	FUN_c800_0688		; (AH=0B) Write long sector
	DW	FUN_c800_0709		; (AH=0C) Seek to cylinder
	DW	RESET_DISK_SYSTEM	; (AH=0D) Reset hard disks
	DW	FUN_c800_068c		; (AH=0E) Read sector buffer
	DW	FUN_c800_0692		; (AH=0F) Write sector buffer
	DW	FUN_c800_0709		; (AH=10) Check if drive ready
	DW	FUN_c800_0709		; (AH=11) Recalibrate drive
	DW	FUN_c800_0709		; (AH=12) Controller RAM diagnostic
	DW	FUN_c800_0709		; (AH=13) Drive diagnostic
	DW	FUN_c800_0709		; (AH=14) Controller internal diagnostic
	DW	FUN_c800_05ab		; (AH=15) Get disk type
	DW	FUN_c800_059f		; (AH=16) Detect disk change

COMMAND_TABLE:
	DB	0CH				; (AH=0) Initialize drive parameters
	DB	00H				; (AH=1) Test drive ready
	DB	08H				; (AH=2) Read sectors
	DB	0AH				; (AH=3) Write sectors
	DB	05H				; (AH=4) Verify sectors
	DB	06H				; (AH=5) Format track
	DB	07H				; (AH=6) Format bad track
	DB	04H				; (AH=7) Format drive
	DB	00H				; (AH=8) Test drive ready
	DB	0CH				; (AH=9) Initialize drive parameters
	DB	0E5H				; (AH=0A) Read Long
	DB	0E6H				; (AH=0B) Write Long
	DB	0BH				; (AH=0C) Seek
	DB	0CH				; (AH=0D) Initialize drive parameters
	DB	0EH				; (AH=0E) Read sector BFFR
	DB	0FH				; (AH=0F) Write sector BFFR
	DB	00H				; (AH=10) Test drive ready
	DB	01H				; (AH=11) Recalibrate
	DB	0E0H				; (AH=12) Execute sector buffer diagnostic
	DB	0E3H				; (AH=13) Execute drive diagnostic
	DB	0E4H				; (AH=14) Execute controller diagnostic
	DB	00H				; (AH=15) Test drive ready
	DB	0CH				; (AH=16) Initialize drive parameters

RESET_DISK_SYSTEM:
	CALL	GET_STATUS_ADDRESS
	OUT	DX,AL				; Reset disk controller
	MOV	CX,0584H			; Delay counter

D2:
	LOOP	D2				; Delay loop

	MOV	AH,0AH				; Retry counter
RESET_LOOP:
	INC	DX				; Point to configuration register (0322h)
	OUT	DX,AL				; Select disk controller
	DEC	DX				; Back to status register
	IN	AL,DX				; Get status register
	TEST	AL,30H				; Test for IRQ and DRQ flags
	JNZ	RESET_FAILED			; Fail if they are set
	AND	AL,0DH				; Preserve BSY, CD, and REQ flags
	XOR	AL,0DH				; Check for all of them present
	JZ	LAB_c800_04af			; Yes, continue
	LOOP	RESET_LOOP			; Try again
	DEC	AH				; One try less
	JNZ	RESET_LOOP			; Jump if still left

RESET_FAILED:
	MOV	AH,5				; Indicate error: Reset failed

RESET_RETURN:
	RET					; Return to caller

LAB_c800_04af:
	MOV	BYTE [LAB_0000_0442],1
	MOV	BYTE [LAB_0000_0443],0
	CALL	FUN_c800_0709
	JC	RESET_FAILED
	
	MOV	BYTE [LAB_0000_0443],20H
	CALL	FUN_c800_0709

LAB_c800_04c6:	
	MOV	BYTE [LAB_0000_0443],0
	CALL	LAB_c800_04d5
	JC	RESET_RETURN

	MOV	BYTE [LAB_0000_0443],20H
LAB_c800_04d5:
	CALL	FUN_c800_097d

	MOV	BYTE [LAB_0000_0442],0CH
	MOV	AL,0FCH
	CALL	FUN_c800_07df
	JNC	LAB_c800_04e7
	JMP	LAB_c800_0595

LAB_c800_04e7:
	MOV	CX,ES:[BX+0AH]
	MOV	AX,[SI+2]
	TEST	BYTE [LAB_0000_0443],20H
	JZ	LAB_c800_04fb
	TEST	AL,8
	JZ	LAB_c800_04fb
	XCHG	AH,AL

LAB_c800_04fb:
	TEST	AL,80H
	JNZ	LAB_c800_0508
	CMP	WORD ES:[BX], BYTE 0
	JZ	LAB_c800_0508
	MOV	CX,ES:[BX]

LAB_c800_0508:
	CALL	READ_HARDWARE_CONFIG
	NOT	AL
	AND	AL,30H
	XOR	AL,30H
	JNZ	LAB_c800_0527
	MOV	AX,1529
	MUL	CX
	MOV	CX,1000
	DIV	CX
	CMP	AX,0400H
	JLE	LAB_c800_0525
	MOV	AX,0400H

LAB_c800_0525:
	MOV	CX,AX

LAB_c800_0527:
	MOV	AL,CH
	CALL	FUN_c800_05da
	MOV	AL,CL
	CALL	FUN_c800_05da
	MOV	DI,8
	CALL	FUN_c800_05d7
	MOV	DI,7
	CALL	FUN_c800_05d7
	MOV	DI,6
	CALL	FUN_c800_05d7
	MOV	DI,5
	CALL	FUN_c800_05d7
	MOV	DI,4
	CALL	FUN_c800_05d7
	MOV	DI,2
	CALL	FUN_c800_05d7
	CALL	FUN_c800_0812
	JC	LAB_c800_0599
	JNZ	LAB_c800_0599
	MOV	CH,ES:[BX+3]
	MOV	CL,4
	SHL	CH,CL
	TEST	BYTE [LAB_0000_0443],20H
	JZ	LAB_c800_0578
	TEST	BYTE [SI+2],8
	JZ	LAB_c800_0595
	MOV	AX,[SI+2]
	MOV	AH,CH
	JMP	SHORT LAB_c800_0590

LAB_c800_0578:
	TEST	BYTE [SI+2],80H
	JNZ	LAB_c800_0587
	MOV	AX,ES:[BX+0AH]
	CMP	AX,ES:[BX]
	JNZ	LAB_c800_058c

LAB_c800_0587:
	XOR	AL,AL
	OR	CH,8

LAB_c800_058c:
	OR	AH,CH
	XCHG	AH,AL

LAB_c800_0590:
	OR	[SI+2],AX
	XOR	AX,AX

LAB_c800_0595:
	CALL	FUN_c800_05e6
	RET

LAB_c800_0599:
	MOV	AH,7
	CALL	FUN_c800_05e6
	RET


FUN_c800_059f:
	MOV	ES,[BP+0]
	MOV	BX,[BP+14]
	MOV	CX,04DDH
	JMP	LAB_c800_09f0

FUN_c800_05ab:
	CALL	FUN_c800_097d
	CALL	READ_HARDWARE_CONFIG
	MOV	CL,11H
	NOT	AL
	AND	AL,30H
	XOR	AL,20H
	JNZ	LAB_c800_05bd
	MOV	CL,1AH
LAB_c800_05bd:
	MOV	AL,ES:[BX+8]
	MUL	CL
	CALL	FUN_c800_062c
	DEC	CX
	MUL	CX
	MOV	[BP+10],AX			; Update saved DX
	MOV	[BP+12],DX			; Update saved CX
	MOV	AH,0F3H
	XOR	AL,AL
	CALL	FUN_c800_05e6
	RET

FUN_c800_05d7:
	MOV	AL,ES:[BX+DI]
FUN_c800_05da:
	PUSH	AX
	CALL	WAIT_FOR_REQ_SET
	POP	AX
	JC	LAB_c800_05e3
	OUT	DX,AL
	RET

LAB_c800_05e3:
	POP	AX
	JMP	SHORT LAB_c800_0599

FUN_c800_05e6:
	POP	DX
	MOV	CX,6

LAB_c800_05ea:
	POP	BX
	LOOP	LAB_c800_05ea
	PUSH	DX
	RET

FUN_c800_05ef:
	CALL	FUN_c800_097d
	CALL	FUN_c800_062c
	MOV	AX,CX
	SUB	AX,WORD 2
	MOV	CH,AL
	SHR	AX,1
	SHR	AX,1
	AND	AL,0C0H
	PUSH	AX
	CALL	READ_HARDWARE_CONFIG
	MOV	CL,11H
	NOT	AL
	AND	AL,30H
	XOR	AL,20H
	JNZ	LAB_c800_0612
	MOV	CL,1AH
LAB_c800_0612:
	POP	AX
	OR	AL,CL
	MOV	AH,CH
	MOV	[BP+12],AX			; Update saved CX
	MOV	AH,ES:[BX+8]
	DEC	AH
	MOV	AL,[SI+1]
	MOV	[BP+10],AX			; Update saved DX
	MOV	AH,0
	CALL	FUN_c800_05e6
	RET

FUN_c800_062c:
	PUSH	AX
	MOV	CX,ES:[BX+10]
	CMP	CX,ES:[BX]
	JZ	LAB_c800_0647
	CMP	WORD ES:[BX], BYTE 0
	JZ	LAB_c800_0647
	TEST	BYTE [BP+10],1			; Saved DL
	JZ	LAB_c800_0647
	NEG	CX
	ADD	CX,ES:[BX]
LAB_c800_0647:
	CALL	READ_HARDWARE_CONFIG
	NOT	AL
	AND	AL,30H
	JZ	LAB_c800_0668
	XOR	AL,20H
	JZ	LAB_c800_0668
	MOV	AX,1529
	MUL	CX
	MOV	CX,1000
	DIV	CX
	CMP	AX,400H
	JLE	LAB_c800_0666
	MOV	AX,400H
LAB_c800_0666:
	MOV	CX,AX
LAB_c800_0668:
	POP	AX
	RET

FUN_c800_066a:
	CMP	WORD [BP+12], BYTE 1	; Saved CX
	JNZ	LAB_c800_0679
	CMP	BYTE [BP+11], BYTE 0	; Saved DH
	JNZ	LAB_c800_0679
	CALL	FUN_c800_0834
LAB_c800_0679:
	MOV	AL,04BH				; Single mode
						; Increment after each transfer
						; Read from memory
						; Channel 3
	JMP	SHORT LAB_c800_0698

FUN_c800_067d:
	MOV	AL,47H				; Single mode
						; Increment after each transfer
						; Write to memory
						; Channel 3
LAB_c800_067f:
	MOV	DL,[SAVED_INT13H_AL]
	MOV	DI,0204H
	JMP	SHORT LAB_c800_069f

FUN_c800_0688:
	MOV	AL,4BH				; Single mode
						; Increment after each transfer
						; Read from memory
						; Channel 3
	JMP	SHORT LAB_c800_067f

FUN_c800_068c:
	MOV	AL,47H				; Single mode
						; Increment after each transfer
						; Write to memory
						; Channel 3
LAB_c800_068e:
	MOV	DL,1
	JMP	SHORT LAB_c800_069c

FUN_c800_0692:
	MOV	AL,4BH				; Single mode
						; Increment after each transfer
						; Read from memory
						; Channel 3
	JMP	SHORT LAB_c800_068e

FUN_c800_0696:
	MOV	AL,47H				; Single mode
						; Increment after each transfer
						; Write to memory
						; Channel 3
LAB_c800_0698:
	MOV	DL,[SAVED_INT13H_AL]
LAB_c800_069c:
	MOV	DI,200H
LAB_c800_069f:
	CLI
	OUT	0BH,AL				; Set DMA mode
	NOP
	NOP
	OUT	0CH,AL				; Clear address and counter regs
	PUSH	DX
	CALL	READ_HARDWARE_CONFIG
	MOV	BL,AL
	POP	DX
	AND	BL,80H
	JNZ	LAB_c800_06b6
	MOV	AL,0C0H
	OUT	0D6H,AL				; Set DMA mode in 2nd 8237
LAB_c800_06b6:
	MOV	AX,ES
	MOV	CL,4
	ROL	AX,CL
	MOV	CH,AL
	AND	AL,0F0H
	ADD	AX,[BP+14]
	ADC	CH,0
	OUT	06H,AL				; First 8237, current address, byte 0
	XCHG	AH,AL
	NOP
	OUT	06H,AL				; First 8237, current address, byte 1
	XCHG	AL,CH
	MOV	CL,AH
	AND	AL,0FH
	OUT	82H,AL				; DMA channel 3, address byte 2
	MOV	AX,DI
	XOR	DH,DH
	MUL	DX
	SUB	AX,1
	SBB	DL,0
	OUT	07H,AL				; DMA channel 3, word count, byte 0
	XCHG	AL,AH
	NOP
	OUT	07H,AL				; DMA channel 3, word count, byte 1
	STI
	JNZ	LAB_c800_0706
	XCHG	AH,AL
	ADD	AX,CX
	JC	LAB_c800_0706
	MOV	AL,3
	CALL	FUN_c800_07df
	JC	LAB_c800_0708
	MOV	AL,3
	OUT	0AH,AL				; Unmask DMA channel 3
	OR	BL,BL
	JNZ	LAB_c800_0710
	XOR	AL,AL
	OUT	0D4H,AL				; Unmask DMA channel 4
	JMP	SHORT LAB_c800_0710

LAB_c800_0706:
	MOV	AH,9				; Data boundary error

LAB_c800_0708:
	RET


FUN_c800_0709:
	MOV	AL,2
	CALL	FUN_c800_07df
	JC	LAB_c800_0708

LAB_c800_0710:
	CLI
	CALL	READ_HARDWARE_CONFIG
	AND	AL,40H				; Check for bit 6 set
	IN	AL,21H				; Read OCW1
	JNZ	LAB_c800_071e			; Jump if set
	AND	AL,0FBH				; Disable IRQ 2
	JMP	SHORT LAB_c800_0720

LAB_c800_071e:
	AND	AL,0DFH				; Disable IRQ 5

LAB_c800_0720:
	OUT	21H,AL				; Write PIC OCW1
	STI					; Interrupts enabled
	CALL	GET_STATUS_ADDRESS
	MOV	AH,4BH				; Retry count
	MOV	CX,0BD00H			; Retry count
LAB_c800_072b:
	IN	AL,DX				; Read status register
	TEST	AL,20H				; Check for IRQ flag
	JNZ	LAB_c800_0744			; Jump if set
	TEST	AL,8				; Test for BSY flag
	JZ	LAB_c800_072b			; Retry if not set
	LOOP	LAB_c800_072b			; Retry - inner loop
	DEC	AH				; Decrement retry counter
	JNZ	LAB_c800_072b			; Retry - outer loop
	CMP	BYTE [LAB_0000_0442],4
	JZ	LAB_c800_072b
LAB_c800_0741:
	JMP	LAB_c800_07f0

LAB_c800_0744:
	CALL	GET_MASK_REGISTER_ADDR
	MOV	AL,0FCH				; Clear IRQEN and DRQEN flags
	OUT	DX,AL				; Write to Interrupt Mask Register
	CALL	FUN_c800_0812
	JC	LAB_c800_0741
	JZ	LAB_c800_0708

FUN_c800_0751:
	MOV	BYTE [LAB_0000_0442],3
	MOV	AL,0FCH
	CALL	FUN_c800_07df
	JC	LAB_c800_07cf
	MOV	DI,LAB_0000_0442
	MOV	AX,DS
	MOV	ES,AX
	MOV	CX,4
	CLD

LAB_c800_0768:
	CALL	WAIT_FOR_REQ_SET
	JC	LAB_c800_07cf
	IN	AL,DX
	STOSB
	LOOP	LAB_c800_0768
	CALL	FUN_c800_0812
	JC	LAB_c800_07cf
	JNZ	LAB_c800_07cf
	CALL	FUN_c800_0a0f
	JNZ	LAB_c800_0780
	CALL	FUN_c800_0ab1

LAB_c800_0780:
	MOV	CH,[LAB_0000_0442]
	MOV	BL,CH
	AND	BX,WORD 0030H
	MOV	CL,3
	SHR	BL,CL
	MOV	AH,CH
	AND	AH,0FH
	CMP	AH,CS:[BX+0B26H]
	JNC	LAB_c800_07cc
	INC	BX
	MOV	BL,CS:[BX+0B26H]
	ADD	BL,AH
	MOV	AH,CS:[BX+0B26H]
	CMP	CH,98H
	JNZ	LAB_c800_07ce
	MOV	BYTE [LAB_0000_0442],0DH
	MOV	BH,AH
	MOV	AL,0FCH
	CALL	FUN_c800_07df
	JC	LAB_c800_07cf
	CALL	WAIT_FOR_REQ_SET
	JC	LAB_c800_07cf
	IN	AL,DX
	MOV	BL,AL
	CALL	FUN_c800_0812
	JC	LAB_c800_07cf
	JNZ	LAB_c800_07cf
	MOV	AX,BX
	RET

LAB_c800_07cc:
	MOV	AH,0BBH

LAB_c800_07ce:
	RET

LAB_c800_07cf:
	MOV	AH,0FFH
	RET

FUN_c800_07d2:
	CALL	FUN_c800_0751
	CMP	AH,0FFH
	JZ	LAB_c800_07ce
	MOV	AL,AH
	XOR	AH,AH
	RET

FUN_c800_07df:
	CALL	GET_MASK_REGISTER_ADDR
	OUT	DX,AL				; Write DMA and IRQ mask register
	DEC	DX				; Point to configuration register
	OUT	DX,AL				; Select controller
	DEC	DX				; Point to status register
	MOV	CX,012CH			; Timeout for BSY

LAB_c800_07e9:
	IN	AL,DX				; Read status register
	TEST	AL,8				; Check for BSY
	JNZ	LAB_c800_07f4			; Is it set? Yes - jump
	LOOP	LAB_c800_07e9			; No, try again

LAB_c800_07f0:
	MOV	AH,80H				; Set error: timeout
	STC					; Carry indicates error

LAB_c800_07f3:
	RET					; Return to caller

LAB_c800_07f4:
	MOV	DI,LAB_0000_0442
	MOV	CX,6
	CLD

LAB_c800_07fb:
	CALL	WAIT_FOR_REQ_SET		; Wait for REQ flag
	JC	LAB_c800_07f3			; If failed, return
	AND	AL,0EH				; Preserve BSY, CD, and IO flags
	XOR	AL,0CH				; Check for IO flag
	JNZ	LAB_c800_07f0			; Fail if not set
	XCHG	DI,SI
	LODSB
	XCHG	DI,SI
	OUT	DX,AL
	LOOP	LAB_c800_07fb
	MOV	AH,0				; Success
	CLC					; Clear carry - no error
	RET

FUN_c800_0812:
	CALL	WAIT_FOR_REQ_SET
	MOV	AH,0
	JC	LAB_c800_082e
	AND	AL,0EH
	CMP	AL,0EH
	JNZ	LAB_c800_082d
	IN	AL,DX
	MOV	AH,AL
	INC	DX
	MOV	CX,100
LAB_c800_0826:
	IN	AL,DX
	AND	AL,8
	JZ	LAB_c800_082f
	LOOP	LAB_c800_0826

LAB_c800_082d:
	STC					; Set error flag

LAB_c800_082e:
	RET

LAB_c800_082f:
	XCHG	AL,AH
	TEST	AL,2
	RET


FUN_c800_0834:
	MOV	AX,[BP+0]
	MOV	BX,[BP+14]
	MOV	ES,AX
	CMP	WORD ES:[BX+01FEH],0AABBH
	JZ	LAB_c800_082e
	MOV	AH,[LAB_0000_0442]
	MOV	AL,[SAVED_INT13H_AL]
	PUSH	AX
	MOV	AX,[SAVED_INT13H_CX]
	PUSH	AX
	CALL	FUN_c800_089b
	JC	LAB_c800_088e
	PUSH	AX
	MOV	AX,[BP+0]
	MOV	BX,[BP+14]
	MOV	ES,AX
	POP	AX
	MOV	ES:[BX+01BDH],AL
	POP	AX
	MOV	ES:[BX+01B6H],AX
	POP	AX
	MOV	ES:[BX+01B4H],AL
	MOV	ES:[BX+01B5H],AH
	POP	AX
	MOV	ES:[BX+01B2H],AX
	POP	AX
	MOV	ES:[BX+01B0H],AX
	POP	AX
	MOV	ES:[BX+01AFH],AL
	POP	AX
	MOV	ES:[BX+01ADH],AX

LAB_c800_088e:
	POP	AX
	MOV	[SAVED_INT13H_CX],AX
	POP	AX
	MOV	[LAB_0000_0442],AH
	MOV	[SAVED_INT13H_AL],AL
	RET


FUN_c800_089b:
	MOV	AH,8
	MOV	[LAB_0000_0442],AH
	XOR	AX,AX
	MOV	[SAVED_INT13H_CX],AX
	MOV	AH,0E0H
	AND	AH,[LAB_0000_0443]
	MOV	[LAB_0000_0443],AH
	INC	AL
	MOV	[SAVED_INT13H_AL],AL
	MOV	AL,0FCH
	CALL	FUN_c800_07df
	JC	LAB_c800_0929
	CALL	FUN_c800_0942
	POP	DI
	MOV	CX,01ADH
	CALL	FUN_c800_092a
	JC	LAB_c800_0928
	CALL	FUN_c800_0933
	JC	LAB_c800_0928
	PUSH	AX
	MOV	CX,1
	CALL	FUN_c800_092a
	JC	LAB_c800_0926
	PUSH	AX
	CALL	FUN_c800_0933
	JC	LAB_c800_0925
	PUSH	AX
	CALL	FUN_c800_0933
	JC	LAB_c800_0924
	PUSH	AX
	CALL	FUN_c800_0933
	JC	LAB_c800_0923
	PUSH	AX
	CALL	FUN_c800_0933
	JC	LAB_c800_0922
	PUSH	AX
	MOV	CX,6
	CALL	FUN_c800_092a
	JC	LAB_c800_0921
	PUSH	AX
	MOV	CX,40H
	CALL	FUN_c800_092a
	JC	LAB_c800_0920
	CALL	FUN_c800_0933
	JC	LAB_c800_0920
	PUSH	AX
	CALL	FUN_c800_0812
	JC	LAB_c800_091f
	JNZ	LAB_c800_091f
	POP	AX
	CMP	AX,0AA55H
	JZ	LAB_c800_0918
	CMP	AX,0AABBH
	JNZ	LAB_c800_0920

LAB_c800_0918:
	POP	AX
	OR	AL,AL
	JNZ	LAB_c800_0928
	PUSH	AX
	PUSH	AX

LAB_c800_091f:
	POP	AX

LAB_c800_0920:
	POP	AX

LAB_c800_0921:
	POP	AX

LAB_c800_0922:
	POP	AX

LAB_c800_0923:
	POP	AX

LAB_c800_0924:
	POP	AX

LAB_c800_0925:
	POP	AX

LAB_c800_0926:
	POP	AX
	STC

LAB_c800_0928:
	PUSH	DI

LAB_c800_0929:
	RET

FUN_c800_092a:
	CALL	WAIT_FOR_REQ_SET
	JC	LAB_c800_0932
	IN	AL,DX
	LOOP	FUN_c800_092a

LAB_c800_0932:
	RET

FUN_c800_0933:
	CALL	WAIT_FOR_REQ_SET
	JC	LAB_c800_0941
	IN	AL,DX
	MOV	AH,AL
	CALL	WAIT_FOR_REQ_SET
	IN	AL,DX
	XCHG	AH,AL

LAB_c800_0941:
	RET


FUN_c800_0942:
	XOR	CX,CX
	MOV	AH,30H
	CALL	GET_STATUS_ADDRESS

LAB_c800_0949:
	IN	AL,DX
	TEST	AL,4
	JZ	LAB_c800_0958
	TEST	AL,2
	JNZ	LAB_c800_0958
	LOOP	LAB_c800_0949
	DEC	AH
	JNZ	LAB_c800_0949

LAB_c800_0958:
	RET

;--------------------------------------------------------------------------
; This function waits for the REQ flag to be set.
;
; Input: Nothing
; Output: DX containing data register address
;	AL contains status register value
;	On error, AH contains error code and carry is set
;--------------------------------------------------------------------------
WAIT_FOR_REQ_SET:
	PUSH	CX
	MOV	CX,0FA00H			; Number of retries
	CALL	GET_STATUS_ADDRESS

LAB_c800_0960:
	IN	AL,DX				; Read status register
	TEST	AL,1				; Check for REQ flag
	JNZ	LAB_c800_096e			; Jump if set
	TEST	AL,8				; Check for BSY flag
	JZ	LAB_c800_096b			; Fail if present
	LOOP	LAB_c800_0960			; Try again if possible

LAB_c800_096b:
	STC					; Indicate error
	MOV	AH,80H				; Timeout error

LAB_c800_096e:
	DEC	DX				; Point to data register
	POP	CX
	RET					; Return to caller

;--------------------------------------------------------------------------
; This function checks S1-5 and S1-6. As per the documentation,
; they should be left open which will use the built-in pull-ups
; to read high.
;
; Input: Nothing
; Output: ZF set if both S1-5 and S1-6 are open. ZF unset otherwise.
;--------------------------------------------------------------------------
CHECK_S15_S16_OPEN:
	PUSH	AX
	PUSH	DX
	CALL	READ_HARDWARE_CONFIG
	NOT	AL				; Inverts HW register value
	AND	AL,S15 | S16			; Checks for bits 4 and 5
	POP	DX
	POP	AX
	RET

FUN_c800_097d:
	POP	BX
	CALL	FUN_c800_0a0f
	JZ	LAB_c800_09a8
	MOV	CX,[SI+2]
	TEST	BYTE [LAB_0000_0443],20H
	JZ	LAB_c800_0994
	TEST	CL,8
	JZ	LAB_c800_0994
	XCHG	CH,CL

LAB_c800_0994:
	TEST	CL,80H
	JNZ	LAB_c800_09bf
	CALL	FUN_c800_089b
	JC	LAB_c800_09a8
	MOV	CX,BX

LAB_c800_09a0:
	MOV	AX,SS
	MOV	ES,AX
	MOV	BX,SP
	PUSH	CX
	RET

LAB_c800_09a8:
	TEST	BYTE [LAB_0000_0443],20H
	JZ	LAB_c800_09bb
	TEST	BYTE [SI+2],8
	JZ	LAB_c800_09bf
	OR	BYTE [SI+3],80H
	JMP	SHORT LAB_c800_09bf

LAB_c800_09bb:
	OR	BYTE [SI+2],080H

LAB_c800_09bf:
	CALL	READ_HARDWARE_CONFIG
	TEST	BYTE [LAB_0000_0443],20H
	JZ	LAB_c800_09cd
	SHR	AL,1
	SHR	AL,1

LAB_c800_09cd:
	AND	AX,3
	MOV	CL,4
	SHL	AX,CL
	MOV	CX,BX
	PUSH	CS
	POP	BX
	CMP	BH,0C8H
	LES	BX,[INT_41H_VECTOR]
	JZ	LAB_c800_09ee
	MOV	BX,43H
	CALL	CHECK_S15_S16_OPEN
	JZ	LAB_c800_09ee
	MOV	BX,85H
	PUSH	CS
	POP	ES
LAB_c800_09ee:
	ADD	BX,AX
LAB_c800_09f0:
	MOV	AX,ES:[BX]
	PUSH	AX
	MOV	AL,ES:[BX+2]
	PUSH	AX
	MOV	AX,ES:[BX+3]
	PUSH	AX
	MOV	AX,ES:[BX+5]
	PUSH	AX
	MOV	AX,ES:[BX+7]
	PUSH	AX
	MOV	AX,ES:[BX+9]
	PUSH	AX
	JMP	SHORT LAB_c800_09a0

FUN_c800_0a0f:
	PUSH	AX
	PUSH	DX
	CALL	READ_HARDWARE_CONFIG
	NOT	AL
	AND	AL,30H
	XOR	AL,10H
	POP	DX
	POP	AX
	RET

;--------------------------------------------------------------------------
; Reads the hardware configuration address at I/O 322h or 324h
; depending on the current CS value.
;
; Input: Nothing
; Output: AL = byte from hardware configuration register
;         DX is destroyed
;--------------------------------------------------------------------------
READ_HARDWARE_CONFIG:
	PUSH	CS
	POP	DX				; DX has CS value
	CMP	DH,0C8H				; Check if CS starts with C8H
	MOV	DX,0322H			; Base I/O address
	JZ	DO_READ_HARDWARE_CONFIG		; Yes, go straight to reading from hardware
	ADD	DX,BYTE 4			; Add offset for second card

DO_READ_HARDWARE_CONFIG:
	IN	AL,DX
	RET

GET_STATUS_ADDRESS:
	PUSH	CS
	POP	DX
	CMP	DH,0C8H				; Check for C8xx
	MOV	DX,0321H			; This is status address for first controller
	JZ	RETURN_STATUS_ADDRESS		; Don't add for first controller
	ADD	DX,BYTE 4			; Add for second controller

RETURN_STATUS_ADDRESS:
	RET

GET_MASK_REGISTER_ADDR:
	PUSH	CS
	POP	DX
	CMP	DH,0C8H				; Check for C8xx
	MOV	DX,0323H			; DMA and IRQ mask register for first controller
	JZ	LAB_c800_0a47			; Don't add for first controller
	ADD	DX,BYTE 4			; Add for second controller

LAB_c800_0a47:
	RET

FUN_c800_0a48:
	PUSH	ES
	PUSH	AX
	CALL	FUN_c800_097d
	MOV	CX,[SAVED_INT13H_CX]
	PUSH	CX
	MOV	AL,CH
	MOV	AH,CL
	MOV	CL,6
	SHR	AH,CL
	MOV	CX,AX
	MOV	AL,ES:[BX+8]
	XOR	AH,AH
	MUL	CX
	MOV	DL,[LAB_0000_0443]
	AND	DX,000FH
	ADD	AX,DX
	MOV	CX,11H
	MUL	CX
	POP	CX
	AND	CX,001FH
	ADD	AX,CX
	JNC	LAB_c800_0a7d
	INC	DX
LAB_c800_0a7d:
	PUSH	AX
	MOV	AL,ES:[BX+8]
	XOR	AH,AH
	MOV	CX,AX
	MOV	BX,1AH
	POP	AX
	DIV	BX
	PUSH	DX
	XOR	DX,DX
	DIV	CX
	MOV	BX,DX
	MOV	[SAVED_INT13H_CH],AL
	MOV	CL,6
	SHL	AH,CL
	POP	DX
	OR	AH,DL
	MOV	[SAVED_INT13H_CL],AH
	MOV	AL,[LAB_0000_0443]
	AND	AL,0F0H
	OR	AL,BL
	MOV	[LAB_0000_0443],AL
	CALL	FUN_c800_05e6
	POP	AX
	POP	ES
	RET

FUN_c800_0ab1:
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	ES
	CALL	FUN_c800_097d
	MOV	DH,[LAB_0000_0443]
	AND	DH,1FH
	MOV	CL,[SAVED_INT13H_CL]
	MOV	CH,[SAVED_INT13H_CH]
	PUSH	CX
	PUSH	DX
	MOV	AL,CH
	MOV	AH,CL
	MOV	CL,6
	SHR	AH,CL
	MOV	CX,AX
	MOV	AL,ES:[BX+8]
	XOR	AH,AH
	MUL	CX
	POP	CX
	MOV	DL,CH
	ADD	AX,DX
	MOV	CX,1AH
	MUL	CX
	POP	CX
	AND	CX,WORD 001FH
	ADD	AX,CX
	JNC	LAB_c800_0af0
	INC	DX
LAB_c800_0af0:
	PUSH	AX
	MOV	AL,ES:[BX+8]
	XOR	AH,AH
	MOV	CX,AX
	MOV	BX,11H
	POP	AX
	DIV	BX
	INC	DX
	PUSH	DX
	XOR	DX,DX
	DIV	CX
	MOV	BX,DX
	MOV	[SAVED_INT13H_CH],AL
	MOV	CL,6
	SHL	AH,CL
	POP	DX
	OR	AH,DL
	MOV	[SAVED_INT13H_CL],AH
	MOV	AL,[LAB_0000_0443]
	OR	AL,BL
	MOV	[LAB_0000_0443],AL
	CALL	FUN_c800_05e6
	POP	ES
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET

LAB_c800_0b26:
	DB	9,8,10,17,2,27,3,29,0,32
	DB	64,32,128,0,32,0,64,16,16,2
	DB	0,4,64,0,0,17,11,1,2,32
	DB	32,16
	DB	10 dup(0)

LAB_c800_0b50:
	JMP	SHORT LAB_c800_0b57

LAB_c800_0b52:
	DB	0AAH,55H
	DB	1EH,07H,0DCH

LAB_c800_0b57:
	JMP	SHORT LAB_c800_0b71

LAB_c800_0b59:
	DW	LAB_c800_1973
	DW	LAB_c800_19a9
	DW	LAB_c800_19bb
	DW	LAB_c800_19d7
	DW	LAB_c800_19fc
	DW	LAB_c800_1a21
	DW	LAB_c800_1a3e
	DW	LAB_c800_1a54
	DW	LAB_c800_1a7b
	DW	LAB_c800_1a9a
	DW	LAB_c800_1abc
	DW	LAB_c800_1ae0

	%include "Formatter.asm"
