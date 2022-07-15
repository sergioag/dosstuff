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

;--------------------------------------------------------------------------------
; Fixed disk BIOS entry point                                                   :
;--------------------------------------------------------------------------------
; This entry point gets called by the system BIOS. Here we initialize the hard  :
; drive and set up our interrupt vectors accordingly.                           :
;--------------------------------------------------------------------------------
ENTRYPOINT:
	XOR	AX,AX
	MOV	DS,AX				; DS = 0000h
	CLI					; Interrupts disabled
	MOV	AX,CS
	MOV	AL,0				; First controller I/O offset
	CMP	AH,0C8h				; Check for CS=C800h
	JZ	INSTALL_BIOS			; Yes, setup as first controller

;--------------------------------------------------------------------------
; At this point we know that we're not running in C800h.
; This means that we may have another hard disk controller
; in the system. Thus, we need to check how many working 
; drives we really have before proceeding. We will update
; the drive count accordingly.
;--------------------------------------------------------------------------
	PUSH	AX				; Save controller info for later
	MOV	AL,[TOTAL_FIXED_DISKS]		; Get number of fixed disks from BIOS
	CMP	AL,2				; Less than 2 drives present?
	JL	SET_SECOND_CONTROLLER		; Assume working drives and configure
						; us as second controller

	XOR	AX,AX				; Counter for number of HDDs
	MOV	DX,80h				; Work with first HDDs

CHECK_DRIVE:
	PUSH	AX
	MOV	CX,1				; ???
	MOV	AL,CL				; AL=1 (???)
	MOV	AH,10h				; HDD - Check if drive ready
	INT	13H
	POP	AX				; Discard status in AH
	JC	NEXT_DRIVE			; Jump on error
	INC	AL				; We have a working HDD

NEXT_DRIVE:
	INC	DL				; Next drive
	TEST	DL,1				; Finished with second drive?
	JNZ	CHECK_DRIVE			; No, test second drive
	CMP	AL,2				; Do we have 2 working drives?
	JZ	SET_SECOND_CONTROLLER		; Yes, skip BIOS parameter update
	MOV	[TOTAL_FIXED_DISKS],AL		; Update BIOS HDD count

SET_SECOND_CONTROLLER:
	POP	AX				; Restore controller info
	MOV	AL,4				; Set as second controller

;--------------------------------------------------------------------------
; This card has 4 bytes of I/O starting at 320h or 324h.
; These I/O values come with a BIOS address of C800h:0000h
; or CA00h(?).
; Based on our CS, we have determined which offset from
; 320h to use: either 00h or 04h. This is contained in AL.
;--------------------------------------------------------------------------
INSTALL_BIOS:
	XCHG	AH,AL				; Now AH=IO offset, AL=high CS
	PUSH	AX				; Save for later, will destroy AL
	MOV	DX,322H				; I/O: Read drive configuration info
	ADD	DL,AH				; Add offset to base I/O address
	IN	AL,DX				; Read from card
	AND	AL,S17				; Check S1-7 (IRQ)
	POP	AX				; AH=I/O offset, AH=high CS
	JZ	SET_IRQ2_HANDLER		; If S1-7 is 0 (closed), use IRQ 2
	MOV	WORD [INT_0DH_IRQ5_OFFSET],IRQ_HANDLER
	MOV	[INT_0DH_IRQ5_SEGMENT],CS
	JMP	SHORT SET_DISK_VECTORS

SET_IRQ2_HANDLER:
	MOV	WORD [INT_0AH_IRQ2_OFFSET],IRQ_HANDLER
	MOV	[INT_0AH_IRQ2_SEGMENT],CS

SET_DISK_VECTORS:
	LES	BX,[INT_13H_VECTOR]		; BX=INT 13h offset, ES=INT 13h segment
	MOV	CX,[INT_40H_OFFSET]
	OR	CX,[INT_40H_SEGMENT]		; Check if INT 40h is all zeroes
	JNZ	SECOND_CONTROLLER_INIT		; Non-zero -- Don't use INT 40h
						; but use INT 47h instead

FIRST_CONTROLLER_INIT:
	MOV	[INT_40H_OFFSET],BX		; Relocate old INT 13h vector into INT 40h
	MOV	[INT_40H_SEGMENT],ES

	MOV	WORD [INT_19H_OFFSET],BOOTSTRAP_HANDLER ; Set our INT 19h handler
	MOV	[INT_19H_SEGMENT],CS

	MOV	WORD [INT_13H_OFFSET],DISK_HANDLER	; Set our INT 13h handler
	MOV	[INT_13H_SEGMENT],CS

	MOV	WORD [INT_41H_OFFSET],ROMVARS.driveType0Params
	CALL	CHECK_S15_S16_OPEN
	JZ	FIRST_INIT_41H
	MOV	WORD [INT_41H_OFFSET],ROMVARS.driveType4Params

FIRST_INIT_41H:
	MOV	[INT_41H_SEGMENT],CS		; Finish setting up INT 41h
	MOV	BX,FIRST_DISK_AREA		; Fixed disk data - first controller
	JMP	SHORT LAB_c800_019c
	NOP

SECOND_CONTROLLER_INIT:
	CMP	AL,0C8H				; Just in case, check if we're the
						; first controller
	JZ	FIRST_CONTROLLER_INIT		; We are -- go to proper init
	MOV	[INT_47H_OFFSET],BX		; Save old INT 13h vector to 2nd controller's chain
	MOV	[INT_47H_SEGMENT],ES

	MOV	WORD [INT_13H_OFFSET],SECOND_DISK_HANDLER
	MOV	[INT_13H_SEGMENT],CS

	MOV	BX,SECOND_DISK_AREA		; Fixed disk area - second controller
	IN	AL,DX				; Read hardware configuration register
	AND	AL,S18				; Check for S1-8 (XT/AT mode)
	JNZ	LAB_c800_019c			; Jump if S1-8 is open (XT mode)
	MOV	WORD [INT_46H_OFFSET],ROMVARS.driveType0Params
	MOV	[INT_46H_SEGMENT],CS
	CALL	CHECK_S15_S16_OPEN
	JZ	LAB_c800_019c			; Jump if S1-5 and S1-6 are open
	MOV	WORD [INT_46H_OFFSET],ROMVARS.driveType4Params
	
LAB_c800_019c:
	STI					; Enable interrupts
	MOV	AL,[TOTAL_FIXED_DISKS]		; Read BIOS num HDDs flags
	MOV	[BX+1],AL			; Update controller drive count
	MOV	CL,4
	SHL	AL,CL				; Move count to upper nibble
	OR	AL,AH				; I/O offset in lower nibble of AL
	MOV	[BX],AL				; Total drives - this controller only

	MOV	AX,00B2H			; Starting timer tick count
	CMP	WORD [POST_RESET_FLAG],1234H	; Warm boot?
	JZ	LAB_c800_01b8			; Yes, don't wait that much to settle
	XOR	AX,AX

LAB_c800_01b8:
	MOV	[TIMER_TICKS],AX		; Reset timer tick count
	CLI					; Disable interrupts
	IN	AL,21H				; Read PIC OCW1
	AND	AL,0FEH				; Enable timer interrupt (IRQ 0)
	OUT	21H,AL				; Set PIC OCW1
	STI					; Enable interrupts so timer starts counting
	MOV	SI,BX
	CALL	GET_STATUS_ADDRESS		; Get I/O address in DX
	OUT	DX,AL				; Reset controller (write to 0321h)
	MOV	CX,0584H

D1:
	LOOP	D1				; Delay loop
	MOV	AH,10				; Number of retries for init

WAIT_FOR_READY:
	INC	DX				; Point to 322h
	OUT	DX,AL				; Select controller
	DEC	DX				; Point to 321h
	IN	AL,DX				; Read status
	TEST	AL,30H				; Check IRQ and DRQ flags
	JNZ	CONTROLLER_FAILURE		; Fail if they're set
	AND	AL,0DH				; Preserve BUSY, IO, and REQ flags
	XOR	AL,0DH				; Check that all of those flags are set
	JZ	LAB_c800_01e4			; They are - Ready to start diagnostic
	LOOP	WAIT_FOR_READY			; Try again (0FFFFH times)
	DEC	AH				; Decrement retry counter
	JNZ	WAIT_FOR_READY

LAB_c800_01e4:
	MOV	DL,80H				; Start as first drive
	ADD	DL,[BX+1]			; DL contains number of disks in this controller
	MOV	CX,1
	MOV	DH,CH				; DH = 0
	MOV	AL,CL				; AH = 1
	MOV	AH,14H				; Controller internal diagnostic
	INT	13H				; Call it
	JC	CONTROLLER_FAILURE		; Fail if diagnostic returns error

LAB_c800_01f6:
	MOV	AH,10H				; Check if drive ready
	INT	13H
	JNC	LAB_c800_0206			; Jump if drive ready
	CMP	WORD [TIMER_TICKS],01BEH		; Enough time elapsed?
	JC	LAB_c800_01f6			; No, try again
	JMP	SHORT LAB_c800_0227

LAB_c800_0206:
	MOV	AH,0				; Reset disk system
	INT	13H
	JC	CONTROLLER_FAILURE		; Fail if reset returns error

	MOV	AH,11H				; Recalibrate drive
	INT	13H
	JC	LAB_c800_0227			; Jump if failed

;----- At this point, the current drive seems to work fine. Update counts and other flags -----

	INC	BYTE [BX+1]			; Increment drive count
	TEST	BYTE [BX+2],8
	JNZ	LAB_c800_0227
	INC	BYTE [BX+1]
	JMP	SHORT LAB_c800_0265		; Finish
	NOP

ERROR_STRING:
	DB	'1701',10,13
ERROR_STRING_LENGTH	EQU $ - ERROR_STRING

LAB_c800_0227:
	CMP	DL,80H				; Check for first drive
	JNZ	LAB_c800_023a
	CMP	WORD [POST_RESET_FLAG],1234H		; Is it warm boot?
	JZ	LAB_c800_023a			; Yes - Shorter delays
	MOV	WORD [TIMER_TICKS],0165H

LAB_c800_023a:
	INC	DL				; Next drive
	MOV	AH,DL
	CMP	BX,FIRST_DISK_AREA	; Check if first controller
	JZ	LAB_c800_0248			; Yes, skip update
	SUB	AH,[TOTAL_FIXED_DISKS]		; Decrement drive count

LAB_c800_0248:
	TEST	AH,1				; Is it already second drive?
	JNZ	LAB_c800_01f6			; No, go test again

CONTROLLER_FAILURE:
	CMP	BYTE [BX+1],0			; Check for no Total disks - this controller
	JNZ	LAB_c800_0265			; There is some disks - don't show error

	MOV	SI,ERROR_STRING
	MOV	CX,ERROR_STRING_LENGTH
	CLD

LAB_c800_025a:
	CS LODSB
	MOV	AH,0EH				; Teletype output
	INT	10H				; Output character
	LOOP	LAB_c800_025a			; Until no more characters left
	MOV	BP,0FH

LAB_c800_0265:
	MOV	CL,[BX+1]
	MOV	[TOTAL_FIXED_DISKS],CL
	RETF
