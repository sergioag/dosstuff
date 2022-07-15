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

	%include "inc/RomVars.inc"
	%include "inc/RamVars.inc"

	ORG 0
	SECTION .text

istruc ROMVARS
	AT	ROMVARS.wBiosSignature,		dw	0AA55h		; BIOS signature (AA55h)
	AT	ROMVARS.bBiosLength,		db	16		; BIOS length in 512 btyes blocks
	AT	ROMVARS.rgbBiosEntry,		JMP	SHORT entry	; BIOS entry point
	AT	ROMVARS.rgbFormatEntry,		JMP	formatter	; BIOS Format entry point
	AT	ROMVARS.szCopyright,		DB	'(C) Copyright 1984 Western Digital Corporation'
	
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bFirstSpecify,	db	0CFh	; 8ms step rate, 240ms unload time
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bSecondSpecify,	db	02h	; 4ms load time
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bMotorDelay,		db	25h	; 1sec until motor is turned on
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bBytesPerSector,	db	02h	; Bytes per sector (512)
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bSectorsPerTrack,	db	08h	; Sectors per track (8)
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bGapLength,		db	2Ah	; Length of gap between sectors (5.25")
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bDataLength,		db	0FFh	; Data length (ignored if bytes per sector is non-zero)
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bGapLengthFormat,	db	50h	; Gap length when formatting (5.25")
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bFormatFiller,	db	0F6h	; Format filler byte (default F6h)
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bHeadSettleTime,	db	19h	; Head settle time (25ms)
	AT	ROMVARS.floppyParams+FLOPPYPARAMS.bMotorStartTime,	db	04h	; Motor start time (0.5sec)

%ifdef TYPE11
	%Include "inc/drvparams11.inc"
%endif
%ifdef TYPE12
	%include "inc/drvparams12.inc"
%endif
%ifdef TYPE13
	%include "inc/drvparams13.inc"
%endif
%ifdef TYPECUSTOM
	%include "inc/drvparamscustom.inc"
%endif

iend

entry:
	xor	ax,ax
	mov	ds,ax
	cli
	les	ax,INT_OFFSET(13h)		; Get existing int 13h vector
	mov	INT_OFFSET(40h),ax		; Save it to int 40h
	mov	INT_SEGMENT(40h),es

	; Set our int 13h handler
	mov	INT_OFFSET(13h),WORD disk_handler
	mov	INT_SEGMENT(13h),cs

	; Set our int 19h handler
	mov	INT_OFFSET(19h),WORD bootstrap_handler
	mov	INT_SEGMENT(19h),cs

	; Set our int 0Dh handler (IRQ 5)
	mov	INT_OFFSET(0Dh),WORD irq_handler
	mov	INT_SEGMENT(0Dh),cs

	; Set int 41h to our parameter table
	mov	INT_OFFSET(41h),WORD ROMVARS.driveType0Params
	mov	INT_SEGMENT(41h),cs

	sti
	mov	ax,40h				; Address BIOS data segment
	mov	ds,ax

	mov	[NUM_FIXED_DRIVES], BYTE 0	; Set drive count to zero

	mov	ax,19Ah				; Starting timer tick count
	cmp	[POST_RESET_FLAG],WORD 1234h	; Check for keyboard reset
	jz	EN1				; Yes, jump
	xor	ax,ax				; Longer tick count

EN1:
	mov	[TIMER_TICKS],ax		; Initialize our tick count
	cli					; No interrupts
	in	al,21h				; Read OCW1 from PIC
	and	al,0FEh				; Enable IRQ 0 (timer interrupt)
	out	21h,al				; Set OCW1
	sti					; Interrupts back on
	mov	dl,80h				; Starting drive number

EN2:
%ifndef TYPE11
	mov	cx,1
	mov	dh,ch
	mov	al,cl
%endif
	mov	ah,0				; Reset disk system
	int	13h				; Do it
	jc	EN4				; Jump on error
	mov	ah,14h				; Controller internal diagnostic
	int	13h				; Do it
	jc	EN4				; Jump on error

EN3:
	mov	ah,10h				; Check if drive ready
	int	13h				; Do it
	jnc	EN5				; Jump if successful
	cmp	[TIMER_TICKS],WORD 01BEh	; Still have time left?
	jc	EN3				; Yes, check again
	jmp	short EN6			; No, try next drive

EN4:
	inc	dl
	jmp	short EN6

err_msg:
	db	'1701',10,13
err_msg_length	equ	$-err_msg

EN5:
	mov	ah,11h				; Recalibrate drive
	int	13h				; Do it
	jc	EN6				; On error, go for next drive

	inc	BYTE [NUM_FIXED_DRIVES]		; We have a working drive
	cmp	dl,80h				; Is this the first drive?
	jnz	EN6				; No, skip resetting tick count
	
	cmp	[POST_RESET_FLAG],WORD 1234h	; Are we under keyboard reset?
	jz	EN6				; Yes, don't reset tick count
	mov	[TIMER_TICKS],WORD 0165h	; Reset tick count to give about
						; 5 secs to next drive

EN6:
	inc	dl				; Next drive number
	test	dl,1				; Wait on each other drive
	jnz	EN3				; Go wait
	cmp	dl,88h				; Any more possible drives?
	jc	EN2				; Yes, proceed with next one

	cmp	[NUM_FIXED_DRIVES],BYTE 0	; Do we have any working drives?
	jnz	EN8				; Yes, finish successfully

	mov	si,err_msg			; Error message
	cld					; Move forward
	mov	cx,err_msg_length		; Length

EN7:
	cs lodsb				; Get next byte
	mov	ah,0eh				; Teletype output
	int	10h				; Put character
	loop	EN7				; Next character
	mov	bp,0fh				; Signal failure

EN8:
	retf					; Return to system BIOS

;------------------------------------------------
; Int 19h handler - Bootstrap			:
;------------------------------------------------
bootstrap_handler:
	xor	ax,ax
	mov	ds,ax				; Set addressing
	mov	es,ax
	cli					; No interrupts allowed

	; Setup floppy parameter table
	mov	INT_OFFSET(1Eh),WORD ROMVARS.floppyParams
	mov	INT_SEGMENT(1Eh),cs

	; Setup fixed disk parameter table
	mov	INT_OFFSET(41h),WORD ROMVARS.driveType0Params
	mov	INT_SEGMENT(41h),cs

	sti					; Interrupts back on
	mov	cx,3				; Retry count
	xor	dx,dx				; Drive 0

BH1:
	mov	ax,0				; Reset floppy
	int	40h				; Call floppy interrupt
	jc	BH2				; Jump on error

	mov	bx,BOOT_LOCN			; Bootsector location
	mov	ax,0201h			; Read 1 sector into memory
	push	cx				; Save retry counter
	mov	cx,1				; Head 0, sector 1
	int	40h				; Call floppy interrupt
	pop	cx				; Restore retry counter
	jnc	BH6				; Jump on success

BH2:
	cmp	ah,80h				; Is error timeout?
	jz	BH3				; Yes, ignore go straight for hdd
	loop	BH1				; Try again, if possible

BH3:
	mov	ax,0				; Reset disk system
	int	40h				; Call floppy interrupt
	mov	dl,80h				; First fixed disk
	mov	cx,8				; Drive counter

BH4:
	mov	ah,0				; Reset disk system
	int	13h				; Call disk interrupt
	jc	BH5				; Jump on error
	mov	bx,BOOT_LOCN			; Bootsector location
	mov	ax,0201h			; Read 1 sector into memory
	push	cx				; Save drive counter
	mov	cx,1				; Head 0, sector 1
	int	13h				; Call disk interrupt
	pop	cx				; Restore drive counter
	jc	BH5				; Jump on error

	cmp	[BOOT_SIGNATURE],WORD 0AA55h	; Check if signature present
	jz	BH6				; Yes, jump to it

BH5:
	inc	dl				; Next drive
	loop	BH4				; Loop if possible
	int	18h				; Bootstrap failure - go basic

BH6:
	jmp	0:BOOT_LOCN			; Jump to bootsector

;------------------------------------------------
; Int 0Dh Handler - IRQ 5			:
;------------------------------------------------
irq_handler:
	push	ax				; Save register
	mov	al,20h				; Non-specific EOI
	out	20h,al				; Set ICW2
	mov	al,7				; Mask DMA channel 3
	out	0ah,al				; Set DMA mask register
	in	al,21h				; Read OCW1
	or	al,20h				; Mask IRQ 5
	out	21h,al				; Set OCW1
	pop	ax				; Restore register
	iret					; Return from interrupt

;------------------------------------------------
; Int 13h Handler - Disk interrupt		:
;------------------------------------------------
disk_handler:
	sti					; Interrupts enabled
	cmp	dl,80h				; Is it for hard drive?
	jnc	DH2				; Yes, go for it
	int	40h				; No, call floppy handler
DH1:
	retf	2				; Discard saved flags

DH2:
	cmp	ah,0				; Is it AH=0?
	jnz	DH3				; No, call normally
	int	40h				; For AH=0, we must call floppy as well
	mov	ah,0				; Reset to AH=0, discard floppy result
%ifdef TYPE13 OR TYPECUSTOM
	cmp	dl,88h				; Check for allowed range
	ja	DH1				; Return if outside range
%endif

DH3:
	push	bx				; Save registers
	push	cx
	push	dx
	push	bp
	push	di
	push	si
	push	ds
	push	es
	mov	bp,sp
	push	ax
	mov	ax,40h
	mov	ds,ax				; Address BIOS data area segment
	pop	ax
	cmp	ah,14h				; Is function code within allowed range?
	ja	DH4				; No, return error
	cmp	dl,88h				; Is drive number within allowed range?
	jc	DH5				; Yes, proceed with call

DH4:
	mov	ah,STATUS_INVALID_PARAMS	; Set error code
	jmp	short DH6			; Go to return code

DH5:
	call	hdd_proc			; Do the actual disk call

DH6:
	push	ax
	mov	[LAST_STATUS],ah

	; Disable IRQ and DMA from controller
	call	get_port3
	mov	al,0FCh				; Disable IRQ and DMA
	out	dx,al				; Set mask register

	; Disable DMA 3
	mov	al,7				; Mask DMA channel 3
	out	0Ah,al				; Update mask register

	; Disable IRQ 5
	cli					; Interrupts not allowed
	in	al,21h				; Read OCW1
	or	al,20h				; Disable IRQ 5
	out	21h,al				; Update OCW1
	sti					; Interrupts back on

	add	ah,0ffh				; Carry set if non-zero result (error)
	pop	ax				; Restore registers
	pop	es
	pop	ds
	pop	si
	pop	di
	pop	bp
	pop	dx
	pop	cx
	pop	bx
	retf	2				; Discard saved flags

hdd_proc:
	mov	[HDD_VARS+CommandBlock.blockCount],al	; Save number of sectors

	dec	cl					; Make sector number zero-based
	mov	[HDD_VARS+CommandBlock.cylAndSector],cx	; Save cylinder and sector numbers

	mov	ch,dl					; Drive number in CH (80h, etc)
	and	ch,1					; Keep the drive bit only (0 or 1)
	mov	cl,5					; Shift count
	shl	ch,cl					; Move the drive bit to bit 5
%ifndef TYPE11
	and	dh,0fh					; Restrict head number to 0-15
%endif
	or	ch,dh					; Combine drive and head number
	mov	[HDD_VARS+CommandBlock.driveAndHead],ch	; Save it

	sub	dl,80h					; Make drive number zero-based (80h -> 00h)
	and	dx,0FEh					; Drop head number and drive bit
	shl	dl,1					; Multiply by 2
	mov	si,dx					; DX will always be 0 for valid drives

	push	ax					; Saves regs used by get_drive_table
	push	es
	call	get_drive_table				; Obtain active drive table
	ES mov	al,[bx+DRVPARAMS.bControlByte]		; Get control byte
	mov	[HDD_VARS+CommandBlock.controlByte],al	; Save it
	pop	es					; Restore regs
	pop	ax

	mov	al,ah
	mov	bx,command_table
	cs xlatb					; Obtain command byte
	mov	[HDD_VARS+CommandBlock.opCode],al	; Save command byte

	mov	bl,ah					; Function code to BL
	xor	bh,bh					; Zero high part of BX
	shl	bl,1					; Multiply by 2 so it's an index
	cs jmp	word [bx+function_table]		; Jump to the appropriate routine

function_table:
	dw	init_disk_system		; AH = 00h (Reset disk system)
	dw	get_last_status			; AH = 01h (Get status of last operation)
	dw	read_sector			; AH = 02h (Read sector into memory)
	dw	write_sector			; AH = 03h (Write sector from memory)
	dw	exec_cmd_nodma			; AH = 04h (Verify disk sector)
	dw	exec_cmd_nodma			; AH = 05h (Format track)
	dw	exec_cmd_nodma			; AH = 06h (Format bad track)
	dw	exec_cmd_nodma			; AH = 07h (Format drive)
	dw	get_drive_params		; AH = 08h (Get drive parameters)
	dw	init_drives			; AH = 09h (Initialize controller)
	dw	read_long			; AH = 0Ah (Read long sector)
	dw	write_long			; AH = 0Bh (Write long sector)
	dw	exec_cmd_nodma			; AH = 0Ch (Seek)
	dw	init_disk_system		; AH = 0Dh (Reset hard disk)
	dw	read_sector_buffer		; AH = 0Eh (Read sector buffer)
	dw	write_sector_buffer		; AH = 0Fh (Write sector buffer)
	dw	exec_cmd_nodma			; AH = 10h (Check if drive ready)
	dw	exec_cmd_nodma			; AH = 11h (Recalibrate)
	dw	exec_cmd_nodma			; AH = 12h (Controller RAM diagnostic)
	dw	exec_cmd_nodma			; AH = 13h (Drive diagnostic)
	dw	exec_cmd_nodma			; AH = 14h (Controller internal diagnostic)

command_table:
	db	CMD_INIT_DRV_PARAMS		; AH = 00h (Reset disk system)
	db	00h				; AH = 01h (Get status of last operation)
	db	CMD_READ_SECTORS		; AH = 02h (Read sector into memory)
	db	CMD_WRITE_SECTORS		; AH = 03h (Write sector from memory)
	db	CMD_VERIFY			; AH = 04h (Verify disk sector)
	db	CMD_FORMAT_TRACK		; AH = 05h (Format track)
	db	CMD_FORMAT_BAD_TRACK		; AH = 06h (Format bad track)
	db	CMD_FORMAT_DRIVE		; AH = 07h (Format drive)
	db	00h				; AH = 08h (Get drive parameters)
	db	CMD_INIT_DRV_PARAMS		; AH = 09h (Initialize controller)
	db	CMD_READ_LONG			; AH = 0Ah (Read long sector)
	db	CMD_WRITE_LONG			; AH = 0Bh (Write long sector)
	db	CMD_SEEK			; AH = 0Ch (Seek)
	db	CMD_INIT_DRV_PARAMS		; AH = 0Dh (Reset hard disk)
	db	CMD_READ_SECTOR_BUF		; AH = 0Eh (Read sector buffer)
	db	CMD_WRITE_SECTOR_BUF		; AH = 0Fh (Write sector buffer)
	db	CMD_TST_DRIVE_RDY		; AH = 10h (Check if drive ready)
	db	CMD_RECALIBRATE			; AH = 11h (Recalibrate)
	db	CMD_SECTOR_BUF_DIAG		; AH = 12h (Controller RAM diagnostic)
	db	CMD_DRIVE_DIAG			; AH = 13h (Drive diagnostic)
	db	CMD_CONTROLLER_DIAG		; AH = 14h (Controller internal diagnostic)

init_disk_system:
	call	get_port1
	out	dx,al				; Perform controller reset
%ifndef TYPE11
	mov	cx,0584h			; Delay loop count

IDS1:
	LOOP	IDS1				; Delay loop
%endif

	MOV	AH,0Ah				; Retry counter
IDS2:
	inc	dx				; Point to port 2
	out	dx,al				; Select controller
	dec	dx				; Back to port 1
	in	al,dx				; Read hardware status
	test	al,30h				; Check for IRQ and DRQ flags
	jnz	IDS3				; Fail if either present

	and	al,0Dh				; Preserve BSY, C/D and REQ flags
	xor	al,0Dh				; Check if all of them are present
	jz	init_drives			; Yes, continue init
	loop	IDS2				; Inner loop
	dec	ah				; Decrement retry counter
	jnz	IDS2				; Outer loop

IDS3:
	mov	ah,STATUS_RESET_FAILED		; Error status

IDS4:
	ret

init_drives:
	; Set to drive 0
	mov	[HDD_VARS+CommandBlock.driveAndHead],BYTE 0
	call	init_drive
	jc	IDS4				; Jump on error
	; Set to drive 1
	mov	[HDD_VARS+CommandBlock.driveAndHead],BYTE 20h

init_drive:
	mov	al,0FCh				; IRQ and DMA disabled
	call	write_command_dma		; Set DMA/IRQ and write command
	jc	IDS4				; Jump on error
	call	get_drive_table			; Get active drive table in DI
	mov	di,1				; Max cylinders, MSB
	call	write_byte
	mov	di,0				; Max cylinders, LSB
	call	write_byte
	mov	di,2				; Max heads
	call	write_byte
	mov	di,4				; Starting Reduced write current, MSB
	call	write_byte
	mov	di,3				; Starting Reduced write current, LSB
	call	write_byte
	mov	di,6				; Starting write precomp, MSB
	call	write_byte
	mov	di,5				; Starting write precomp, LSB
	call	write_byte
	mov	di,7				; Max ECC data burst length
	call	write_byte
	call	get_completion_code		; Read command result
	jc	ID1
	jz	ID2

ID1:
	mov	ah,STATUS_DRIVE_FAILED
ID2:
	ret

;------------------------------------------------
; write_byte					:
;------------------------------------------------
; Writes a byte to the controller. This is done :
; by waiting for the REQ flag to be asserted	:
; before writing the byte.			:
;						:
; Input:					:
;  ES:[BX+DI] contains the byte to write	:
;						:
; Output:					:
;  On success, nothing.				:
;  On error, AH is set to error code, last	:
;   stack frame is dropped and control is	:
;   returned to the previous one.		:
;  AL,DL destroyed.				:
;------------------------------------------------
write_byte:
	call	wait_for_req			; Wait for the controller to ask for byte
	jc	WB1				; Jump on error
	es mov	al,[bx+di]			; Get byte
	out	dx,al				; Write to controller
	ret
WB1:
	pop	ax				; Drop stack frame
	jmp	short ID1			; Error return

;------------------------------------------------
; get_drive_params				:
;------------------------------------------------
; Obtains the disk parameters. This is called	:
; when Int 13h with AH=08 is invoked.		:
;						:
; Input:					:
;  Drive number in CmdBlock.driveAndHead	:
;						:
; Output:					:
;  AH = 0					:
;  AL,CX,DX destroyed				:
;  Saved registers updated			:
;------------------------------------------------
get_drive_params:
	call	get_drive_table			; Obtain active drive table
	es mov	ax,[bx]				; Get Number of cylinders
	sub	ax,2				; Reserve the last 2 for controller
	mov	ch,al				; Low part in CH
	shr	ax,1				; Shift high part 2 bits right
	shr	ax,1
	and	al,0C0h				; Clear all except high 2 bits
	or	al,17				; Add sectors per track
	mov	ah,ch				; Set high part
	mov	[bp+0Ch],ax			; Set to saved CX
	es mov	ah,[bx+2]			; Get number of heads
	dec	ah				; Make it zero-based
	mov	al,[NUM_FIXED_DRIVES]		; Number of fixed drives
	mov	[bp+0Ah],ax			; Set to saved DX
GDP1:
	mov	ah,STATUS_SUCCESS		; Successful return
	ret

;------------------------------------------------
; get_last_status				:
;------------------------------------------------
; Obtains the status of the last disk operation	:
; This is called when Int 13h with AH=01 is	:
; invoked.					:
;						:
; Input:					:
;  Nothing					:
;						:
; Output:					:
;  AL = status of last operation		:
;------------------------------------------------
get_last_status:
	mov	al,[LAST_STATUS]
	jmp	short GDP1

write_sector:
	mov	al,4Bh				; DMA Channel 3, read from
						; memory, increment after
						; each transfer, single
	jmp	short RS1

read_long:
	mov	al,47h				; DMA Channel 3, write to
						; memory, increment after
						; each transfer, single
RL1:
	mov	dl,[HDD_VARS+CommandBlock.blockCount]
	mov	di,0204h
	jmp	short RS3

write_long:
	mov	al,4Bh				; DMA Channel 3, read from
						; memory, increment after
						; each transfer, single
	jmp	short RL1

read_sector_buffer:
	mov	al,47h				; DMA Channel 3, write to
						; memory, increment after
						; each transfer, single
RSB1:
	mov	dl,1
	jmp	short RS2

write_sector_buffer:
	mov	al,4Bh
	jmp	short RSB1

read_sector:
	mov	al,47h

RS1:
	mov	dl,[HDD_VARS+CommandBlock.blockCount]
RS2:
	mov	di,0200h
RS3:
	cli					; Interrupts disabled
	out	0Bh,al				; Set DMA mode register
	out	0Ch,al				; Clear address and counter regs
	mov	ax,es
	mov	cl,4				; Rotate count
	rol	ax,cl				; Now high nibble of ES is in low nibble of AL
	mov	ch,al				; Save for later
	and	al,0F0h				; Clear low nibble 
	add	ax,[bp+0Eh]			; Add saved BX (offset of data buffer)
	adc	ch,0				; Add carry to saved part
	out	06h,al				; Write base addr, byte 0
	xchg	al,ah				; Next byte
	out	06h,al				; Write base addr, byte 1
	xchg	ch,al				; Saved part in AL
	mov	cl,ah
	and	al,0Fh				; Clear high nibble of AL
	out	82h,al				; Write DMA channel 3, address byte 2
	mov	ax,di				; Block size
	xor	dh,dh
	mul	dx				; Block size * block count
	sub	ax,1
	sbb	dl,0
	out	07h,al				; Write channel 3, word count, byte 0
	xchg	ah,al
	out	07h,al				; Write channel 3, word count, byte 1
	sti					; Interrupts enabled
	jnz	RS4				; Jump if > 64K
	xchg	al,ah				; Back to normal order
	add	ax,cx
	jc	RS4				; Jump if > 64K
	mov	al,3				; IRQ and DMA enabled
	call	write_command_dma		; Set DMA/IRQ and send command
	jc	RS5				; Error
	mov	al,3				; Unmask DMA channel 3
	out	0Ah,al				; Write it
	jmp	short ECN1
RS4:
	mov	ah,STATUS_DMA_BOUNDARY
RS5:
	ret

exec_cmd_nodma:
	mov	al,2				; Enable IRQ, disable DMA
	call	write_command_dma		; Set IRQ/DMA and send command
	jc	RS5				; Error
ECN1:
	cli					; No interrupts allowed
	in	al,21h				; Read OCW1
	and	al,0DFh				; Enable IRQ 5
	out	21h,al				; Write OCW1
	sti					; Interrupts back on
	call	get_port1
ECN2:
	in	al,dx				; Read hardware status
	test	al,20h				; Check for IRQ flag
	jnz	read_last_status		; Jump if set
	test	al,8				; Test for DMA flag
	jnz	ECN2				; If set, try again

ECN3:
	jmp	WCD2				; Error return (timeout)

;------------------------------------------------
; read_last_status				:
;------------------------------------------------
; Read the last operation status from the	:
; controller. If the error is a correctable ECC	:
; error, then also obtain the burst length.	:
;						:
; Input:					:
;  Nothing					:
;						:
; Output:					:
;  AH=Error status				:
;  If AH=STATUS_CORRECTABLE, AL contains burst	:
;  length.					:
;  All other registers destroyed.		:
;------------------------------------------------
read_last_status:
	call	get_port3
	mov	al,0FCh				; Disable DMA and IRQ
	out	dx,al				; Update mask register
	call	get_completion_code
	jc	ECN3				; On error
	jz	RS5				; On error
	; Next command to get status info
	mov	[HDD_VARS+CommandBlock.opCode],BYTE CMD_GET_LAST_STATUS
	mov	al,0FCh				; DMA and IRQ disabled
	call	write_command_dma		; Set DMA config and write command
	jc	RLS4				; Jump on error
	mov	di,HDD_VARS			; Write to our var stg
	mov	ax,ds
	mov	es,ax
	mov	cx,4				; Number of bytes
	cld
RLS1:
	call	wait_for_req			; Wait for byte to be ready
	jc	RLS4				; Jump on error
	in	al,dx				; Read byte
	stosb					; Store it
	loop	RLS1				; Loop until done

	call	get_completion_code		; Get completion code
	jc	RLS4				; Jump on error
	jnz	RLS4				; Completion code is error - shouldn't happen
	mov	ch,[HDD_VARS+StatusBlock.errorCode]
	; At this point, BH is assumed to be 0 as set in hdd_proc
	mov	bl,ch				; BL contains error code
	and	bx,30h				; Preserve bits 4-5 of error code
	mov	cl,3				; Shift count
	shr	bl,cl				; Bits 4-5 of error code now at 1-2 of BL
	mov	ah,ch				; Full error code in AH
	and	ah,0Fh				; Clear high nibble of error code
	cs cmp	ah,[bx+ERROR_TABLE]		; Does it fit in the range for the class?
	jnc	RLS2				; No, set as undefined error
	inc	bx				; Point to start index
	cs mov	bl,[bx+ERROR_TABLE]		; BL has index relative to start of table
	add	bl,ah				; Add in low nibble
	cs mov	ah,[bx+ERROR_TABLE]		; Get the status code
	cmp	ch,ERROR_CORRECTABLE		; Is it a correctable ECC error?
	jnz	RLS3				; No, finish
	mov	bh,ah				; Save for later
	mov	[HDD_VARS+CommandBlock.opCode],BYTE CMD_READ_ECC_BURST_LEN
	mov	al,0FCh				; Disable IRQ and DMA
	call	write_command_dma		; Send new command
	jc	RLS4				; Jump on error
	call	wait_for_req			; Wait for incoming byte
	jc	RLS4				; Jump on error
	in	al,dx				; Read response byte
	mov	bl,al				; Save it
	call	get_completion_code		; Read completion code to finish
	jc	RLS4				; Jump on error
	jnz	RLS4				; Code contains error - shouldn't happen
	mov	ax,bx				; Set return value (AH=ERROR_CORRECTABLE,
						; AL=ECC burst length)
	ret					; Successful return

RLS2:
	mov	ah,STATUS_UNDEFINED
RLS3:
	ret
RLS4:
	mov	ah,STATUS_SENSE_OP_FAILED
	ret

;------------------------------------------------
; write_command_dma				:
;------------------------------------------------
; Sets the DMA and IRQ mask, then writes the    :
; command to the controller.			:
;						:
; Input:					:
;  AL = Value for the mask register		:
;  Command block in HDD_VARS			:
;						:
; Output:					:
;  On error, CF set, AH contains status code.	:
;  AL,CX,DI destroyed				:
;-----------------------------------------------
write_command_dma:
	call	get_port3
	out	dx,al				; Write mask register
	dec	dx				; Port 2
	out	dx,al				; Select controller
	dec	dx				; Port 1
	mov	cx,300				; Retry count
WCD1:
	in	al,dx				; Read hardware status
	test	al,8				; Check for BSY flag
	jnz	write_command			; Yes, go write command
	loop	WCD1				; Loop until set or timeout

WCD2:
	mov	ah,STATUS_TIMEOUT		; Error status
	stc					; Error return

WCD3:
	ret

;------------------------------------------------
; write_command					:
;------------------------------------------------
; Writes the command block in HDD_VARS to the	:
; controller.					:
;						:
; Input:					:
;  Command block in HDD_VARS			:
;						:
; Output:					:
;  On error: CF set				:
;						:
;  AL,CX,DI destroyed				:
;  DX = Port 0					:
;------------------------------------------------
write_command:
	mov	di,HDD_VARS			; Command block to transfer
	mov	cx,6				; Length
	cld					; Forward direction
write_loop:
	call	wait_for_req			; Wait for REQ before reading
	jc	WCD3				; Jump on error
	and	al,0Eh				; Preserve BSY, C/D and I/O flags
	xor	al,0Ch				; Check for BSY and C/D set, I/O unset
	jnz	WCD2				; Jump if not so
	xchg	si,di
	lodsb					; Get next byte
	xchg	si,di
	out	dx,al				; Write it
	loop	write_loop			; Loop until done
	jmp	GDP1				; Successful return

;-----------------------------------------------;
; get_completion_code				:
;------------------------------------------------
; Obtains the completion code at the end of the :
; execution of a command.			:
;						:
; Input:					:
;  Nothing					:
;						:
; Output:					:
;  On error, CF set, AH contains error status.	:
;  On success, CF clear, AL contains completion :
;  code, ZF set according to bit 1 of AL.	:
;  AH,DX Destroyed				:
;-----------------------------------------------:
get_completion_code:
	call	wait_for_req			; Wait for REQ before reading
	mov	ah,0
	jc	GCC3				; Jump on error
	and	al,0Eh				; Preserve BSY, C/D and I/O flags
	cmp	al,0Eh				; Are they all set?
	jnz	GCC2				; Yes, error out
	in	al,dx				; Read data byte
	mov	ah,al				; Save read data byte
	inc	dx				; Port 1
GCC1:
	in	al,dx				; Read hardware status
	and	al,8				; Check for BSY flag
	jnz	GCC1				; Loop until set
	xchg	ah,al
	test	al,2				; Test for error
	ret
GCC2:
	stc					; Indicate error
GCC3:
	ret

;------------------------------------------------
; wait_for_req					:
;------------------------------------------------
; Waits for the REQ status bit to be set. It	:
; will wait if BSY is set, but fail otherwise.	:
;						:
; Input:					:
;  Nothing					:
;						:
; Output:					:
;  On error, CF set, AH=STATUS_TIMEOUT		:
;  On success, CF clear				:
;  DX = Port 0					:
;  AL = Hardware status				:
;------------------------------------------------
wait_for_req:
	call	get_port1
WFR1:
	in	al,dx				; Read hardware status
	test	al,1				; Check for REQ flag
	jnz	WFR2				; Go if set
	test	al,8				; Check for BSY flag
	jnz	WFR1				; Try again if still set
	stc					; Error return
	mov	ah,STATUS_TIMEOUT		; Error status
WFR2:
	dec	dx				; Point to port 0
	ret

;------------------------------------------------
; get_drive_table				:
;------------------------------------------------
; Returns a pointer to the drive table entry	:
; used by the selected drive.			:
;						:
; Input:					:
;  Drive number in CommandBlock.driveAndHead	:
;						:
; Output:					:
;  ES:BX points to the active drive table entry	:
;  AX,CL,DX destroyed				:
;------------------------------------------------
get_drive_table:
	xor	ax,ax
	mov	es,ax
	es les	bx,INT_OFFSET(41h)		; Get pointer to start of table
	call	get_port2
	in	al,dx				; Read drive configuration register
	test	[HDD_VARS+CommandBlock.driveAndHead],BYTE 20h ; Is it second drive?
	jnz	GDT1				; Yes, don't shift bits
	shr	al,1				; Discard drive 1 bits
	shr	al,1				; And move drive 0 bits in 0 & 1
GDT1:
	and	ax,3				; Preserve only bits 0-1
	mov	cl,4
	shl	ax,cl				; Multiply by 16 (size of DRVPARAMS)
	add	bx,ax				; Add to start of table
						; After which BX points to active entry
	ret

get_port2:
	lea	dx,[si+322h]
	ret
get_port1:
	lea	dx,[si+321h]
	ret
get_port3:
	lea	dx,[si+323h]
	ret

ERROR_TABLE:
	db	09h,CLASS_0-ERROR_TABLE
	db	0Ah,CLASS_1-ERROR_TABLE
	db	02h,CLASS_2-ERROR_TABLE
	db	03h,CLASS_3-ERROR_TABLE

CLASS_0:
		;00h-08h
	db	STATUS_SUCCESS			; 00h
	db	STATUS_CONTROLLER_FAIL		; 01h (UNUSED)
	db	STATUS_SEEK_FAILED		; 02h
	db	STATUS_CONTROLLER_FAIL		; 03h
	db	STATUS_TIMEOUT			; 04h
	db	STATUS_SUCCESS			; 05h (UNUSED)
	db	STATUS_CONTROLLER_FAIL		; 06h
	db	STATUS_SUCCESS			; 07h (UNUSED)
	db	STATUS_SEEK_FAILED		; 08h
CLASS_1:
		;11h-19h
	db	STATUS_UNCORRECTABLE		; 10h (UNUSED)
	db	STATUS_UNCORRECTABLE		; 11h
	db	STATUS_ADDR_MARK_NOT_FND	; 12h
	db	STATUS_SUCCESS			; 13h (UNUSED)
	db	STATUS_SECTOR_NOT_FND		; 14h (UNUSED)
	db	STATUS_SEEK_FAILED		; 15h
	db	STATUS_SUCCESS			; 16h (UNUSED)
	db	STATUS_SUCCESS			; 17h (UNUSED)
	db	STATUS_CORRECTABLE		; 18h
	db	STATUS_BAD_TRACK		; 19h
CLASS_2:
		;20h-21h
	db	STATUS_INVALID_PARAMS		; 20h
%ifdef TYPE12 OR TYPECUSTOM
	db	STATUS_INVALID_PARAMS		; 21h
%endif
%ifdef TYPE13 OR TYPE11
	db	STATUS_ADDR_MARK_NOT_FND	; 21h
%endif
CLASS_3:
		;30h-32h
	db	STATUS_CONTROLLER_FAIL		; 30h
	db	STATUS_CONTROLLER_FAIL		; 31h
	db	STATUS_UNCORRECTABLE		; 32h

%ifdef TYPE11
	db	00h,00h,00h,00h,00h
%endif
%ifdef TYPE12
	db	00h,00h,00h,00h,00h,00h
%endif
%ifdef TYPE13 OR TYPECUSTOM
	db	00h
%endif

formatter:
	push	ax				; Save register
	mov	ax,cs				; Setup segment addressing
	mov	ds,ax

	mov	dx,banner_msg			; Welcome banner
	mov	ah,9				; Output string
	int	21h				; Print it

	pop	ax				; Restore register

	or	al,al				; Check if non-zero
	jnz	F1				; Yes, skip default

	mov	al,3				; Default interleave

F1:
	and	ah,7				; Limit drive to 0-7
	push	ax				; Save register
	add	ah,'C'				; Make drive from C to J
	mov	dl,ah				; To expected reg for output
	mov	ah,2				; Output character
	int	21h				; Do it
	mov	dx,interleave_msg		; Interleave message
	mov	ah,9				; Output string
	int	21h				; Print it
	pop	ax				; Restore regs
	push	ax				; Save again
	call	print_number			; Print interleave
	mov	ah,1				; Read character with echo
	int	21h				; Get it
	cmp	al,'y'				; Is it 'y'?
	jz	F2				; Yes, proceed with format
	cmp	al,'Y'				; Is it 'Y'?
	jz	F2				; Yes, proceed with format
	pop	ax				; Restore register
	mov	dx,exit_msg			; Exit message
	sub	bh,bh				; Page 0
	jmp	short F3			; Print and exit

F2:
	pop	ax				; Restore register
	mov	dl,ah				; Drive number
	or	dl,80h				; Make it as Int 13h expects it
	mov	ah,dl				; Have a copy in AH
	push	ax				; Save register
	mov	ah,12h				; Controller RAM diagnostic
	int	13h				; Go for it
	mov	bh,ah				; Save status code for printing
	jc	format_error			; Jump if diagnostic failed
	pop	ax				; Restore register
	push	ax				; Save again

	; Now setup formatting
	sub	dh,dh				; Starting head 0
	mov	cx,1				; Sector 1, cylinder 0
	mov	ah,7				; Format drive
	int	13h				; Do it
	mov	bh,ah				; Save status code for printing
	jc	format_error			; Jump if formatting failed
	mov	cx,1
	mov	ah,11h				; Recalibrate drive
	int	13h				; Do it
	mov	bh,ah				; Save status code for printing
	jnc	format_success			; Jump if successful

format_error:
	pop	ax				; Restore register
	mov	dx,failed_msg			; Failure message
	mov	ah,9				; Output string
	int	21h				; Print it
	mov	al,bh				; Put the status code for printing
	call	print_number			; Print it
	jmp	short format_exit		; Get out of here

format_success:
	mov	dx,success_msg			; Success message
F3:
	mov	ah,9				; Output String
	int	21h
format_exit:
	mov	al,bh				; Status code as return value
	mov	ah,4Ch				; Terminate
	int	21h
	; Doesn't return

print_number:
	push	ax				; Save register
	mov	cl,4				; Shift count
	shr	al,cl				; Move high nibble into low
	call	PN1				; Print it
	pop	ax				; Restore register
	jmp	short PN1			; Now print low nibble
	nop

PN1:
	and	al,0Fh				; Only use lo nibble
	add	al,90h
	daa
	adc	al,40h
	daa
	mov	dl,al				; Move to the expected reg
	mov	ah,2				; Output character
	int	21h
	ret

banner_msg:
%ifdef TYPE12 OR TYPE11
	db	'WX2 Format Revision 6.0 (C) Copyright Western Digital Corp. 1985',13,10
%endif
%ifdef TYPE13 OR TYPECUSTOM
	db	'WX2 Format Revision 7.0 (C) Copyright Western Digital Corp. 1985',13,10
%endif
	db	'   (AH) = Relative drive number (0 - 7)',13,10
	db	'   (AL) = Interleave factor (3 is standard)',13,10
	db	'Press "y" to begin formatting drive $'

interleave_msg:
	db	' with interleave $'
success_msg:
	db	13,10,'Format Successful$'
failed_msg:
	db	13,10,'Error---completion code $'
exit_msg:
	db	13,10,'Nothing Done Exit$'

%ifdef TYPE12 OR TYPE11
	db	'85/01/29'
%endif
%ifdef TYPE13 OR TYPECUSTOM
	db	'  Formatter as of 02/07/85  '
%endif
