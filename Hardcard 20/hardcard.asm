
	%include	"inc/RomVars.inc"
	%include	"inc/RamVars.inc"

	ORG 0
	SECTION .text

istruc ROMVARS
	AT	ROMVARS.wBiosSignature,		dw	0AA55h		; BIOS signature (AA55h)
	AT	ROMVARS.bBiosLength,		db	16		; BIOS length in 512 btyes blocks
	AT	ROMVARS.rgbBiosEntry,		JMP	SHORT entry	; BIOS entry point
	AT	ROMVARS.rgbFormatEntry,		db	0,0,0		; BIOS Format entry point (unused)
	AT	ROMVARS.rgbVector,		JMP	LAB_1c4d	; BIOS Unknown entry point
	AT	ROMVARS.szCopyright,		DB	'COPYRIGHT 1985,1986,1987 PLUS Development Corporation --  ALL RIGHTS RESERVED.  Version  6.20  by Claude Camp '

;0079
entry:
	CALL	save_ctx			; Initialize calling context
	MOV	BYTE [7E0Ah],0

LAB_0081:
	MOV	BYTE [BP+CTX.bp18],0
	MOV	BYTE [BP+CTX.bp18+1],0
	MOV	BYTE [BP+CTX.bp1E+1],0
	MOV	BYTE [BP+CTX.bp20],0
	MOV	BYTE [7E04h],0
	MOV	[SAVED_CS],CS

LAB_009a:
	MOV	AX,[SAVED_CS]			; Get prev segment
	ADD	AH,2				; Point to next one
	TEST	AH,6				; Are we done?
	JZ	LAB_00b3			; Yes, go away
	MOV	[SAVED_CS],AX			; Update prev segment
	CALL	get_plus_version		; Check version
	CMP	AX,614h				; Is it version 6.14 or above?
	JC	LAB_009a			; No, go for next segment
	JMP	LAB_047f			; Skip our installation
						; We trust other BIOS will do for us

LAB_00b3:
	MOV	AH,8				; Get disk parameters
	MOV	DL,80h				; First fixed drive
	INT	13h				; Call disk BIOS
	PUSHF
	POP	AX				; AX contains saved flags
	CLI
	PUSH	WORD INT_OFFSET(40h)
	PUSH	WORD INT_SEGMENT(40h)
	PUSH	WORD INT_OFFSET(19h)
	PUSH	WORD INT_SEGMENT(19h)
	PUSH	WORD INT_OFFSET(41h)
	PUSH	WORD INT_SEGMENT(41h)
	PUSH	WORD INT_OFFSET(46h)
	PUSH	WORD INT_SEGMENT(46h)
	PUSH	WORD [LAST_STATUS]		; Last op status & num of disks
	PUSH	WORD [CONTROL_BYTE]		; Control byte & I/O offset
	PUSH	WORD INT_OFFSET(13h)
	PUSH	WORD INT_SEGMENT(13h)

	PUSH	AX				; Save flags

	IN	AL,PIC_PORTB			; Read IMR
	MOV	[SAVED_IMR],AL
	OR	AL,20h				; Enable IRQ 5 (fixed disk)
	AND	AL,0FEh				; Disable IRQ 0 (timer)
	OUT	PIC_PORTB,AL			; Update IMR
	STI

	PUSH	DS				; Save data segment
	MOV	AX,BIOS_SEG			; Point to BIOS segment
	MOV	DS,AX				; Set addressing
	MOV	AL,BYTE [MACHINE_TYPE]		; Read machine type code
	POP	DS				; Restore data segment

	CMP	AL,MACHINE_TYPE_AT		; Is it AT?
	JNZ	LAB_010d			; No, branch
	OR	BYTE [BP+CTX.bp18],40h		; Set AT flag
	JMP	SHORT LAB_011d

LAB_010d:
	CMP	AL,MACHINE_TYPE_PS2		; Is it PS/2?
	JNZ	LAB_011d			; No, branch
	OR	BYTE [BP+CTX.bp18],20h		; Set PS/2 flag
	CLI
	IN	AL,PS2_SYS_BRD			; Read system board control reg
	AND	AL,0FEh				; Disable fixed disk CS
	OUT	PS2_SYS_BRD,AL			; Update system board control reg
	STI

LAB_011d:
	CALL	check_video
	JC	LAB_0126			; Jump if direct access not possible
	OR	BYTE [BP+CTX.bp18],1		; Set direct access flag

LAB_0126:
	XOR	AX,AX				; Will write 0 to the controller port
	MOV	CX,4				; # of controllers to write
	MOV	DX,323h				; XT HDC 0 DMA and INT mask register

LAB_012e:
	OUT	DX,AL				; Write port
	ADD	DX,BYTE 4			; Point to next controller
	LOOP	LAB_012e			; Repeat for next controller
	POPF					; Restore saved flags
	JC	LAB_0143			; Jump if BIOS returned error
	CMP	BYTE [NUM_FIXED_DRIVES],0	; Does BIOS report any fixed drives?
	JA	LAB_0163			; Yes, branch
	CALL	detect_relocated_bios		; Check if the disk BIOS was relocated
	JNC	LAB_0150			; Jump if relocated

	; Relocate Int 13h to Int 40h
LAB_0143:
	CLI					; Disable interrupts
	MOV	DI,INT_OFF_VAL(40h)		; Write to Int 40h
	MOV	SI,INT_OFF_VAL(13h)		; Read from Int 13h
	MOV	CX,VECTOR_size/2		; One vector (2 words)
	REP MOVSW				; Move it
	STI					; Interrupts back on

LAB_0150:
	MOV	BYTE [BP+CTX.bp1E],0
	MOV	WORD [LAST_STATUS],STATUS_SUCCESS
	MOV	WORD [CONTROL_BYTE],0
	JMP	SHORT LAB_01c1

	nop

LAB_0163:
	mov	ax,INT_SEGMENT(13h)
	call	get_plus_version
	mov	bl,[NUM_FIXED_DRIVES]
	mov	[bp+CTX.bp1E],bl
	jz	LAB_0189			; Branch if no Plus detected
	mov	[SAVED_NUM_DRIVES],bl
	jmp	SHORT LAB_01c1

	DB	14 dup(0)

bootstrap_int:
	JMP	LAB_1ac6

LAB_0189:
	mov	ah,10h				; Check if drive ready
	mov	dl,80h				; First fixed drive
	int	13h				; Do it
	jc	LAB_0150			; Jump if nothing there
	mov	ax,cs
	test	ah,6
	jz	LAB_01bc
	mov	byte [bp+CTX.bp1E],1		; Update number of drives
	cmp	bl,1				; Do we have already 1 drive?
	jz	LAB_01b1			; Yes, branch
	mov	ah,10h				; Check if drive ready
	mov	dl,81h				; Second fixed drive
	int	13h				; Do it
	jc	LAB_01b1			; Branch if nothing there
	mov	byte [bp+CTX.bp1E],2		; Two drives
	or	byte [bp+20h],40h
LAB_01b1:
	mov	byte [SAVED_NUM_DRIVES],1
	or	byte [bp+CTX.bp18],80h
	jmp	SHORT LAB_01cf			; Skip setting up bootstrap

LAB_01bc:
	mov	bh,'A'
	jmp	LAB_0321

LAB_01c1:
	cli					; Interrupts disabled
	mov	word INT_OFFSET(19h),bootstrap_int	; Set bootstrap vector
	mov	word INT_SEGMENT(19h),cs
	call	init_drv_params
LAB_01cf:
	cli					; Interrupts disabled
	mov	word INT_OFFSET(13h),disk_int	; Set disk vector
	mov	word INT_SEGMENT(13h),cs
	sti					; Interrupts back on

	cmp	word [POST_RESET_FLAG],1234h	; Are we in warm boot?
	jz	LAB_020c			; Yes, skip spinup delay
	mov	cx,24h				; Number of timer ticks to wait
	call	timer_delay			; Delay
	jmp	SHORT LAB_020c			; Continue there

	db	22 dup(0)

LAB_0201:
	istruc	FLOPPYPARAMS
		AT FLOPPYPARAMS.bFirstSpecify,	DB	0CFh	; Step rate = 8ms
								; Head unload time = 240ms
		AT FLOPPYPARAMS.bSecondSpecify,	DB	02h	; Head load time = 4ms
		AT FLOPPYPARAMS.bMotorDelay,	DB	25h	; Motor off delay (ticks)
		AT FLOPPYPARAMS.bBytesPerSector,DB	02h	; 512 bytes
		AT FLOPPYPARAMS.bSectorsPerTrack,DB	08h	; 8 sectors per track
		AT FLOPPYPARAMS.bGapLength,	DB	2Ah
		AT FLOPPYPARAMS.bDataLength,	DB	0FFh	; Ignored
		AT FLOPPYPARAMS.bGapLengthFormat,DB	50h
		AT FLOPPYPARAMS.bFormatFiller,	DB	0F6h
		AT FLOPPYPARAMS.bHeadSettleTime,DB	19h	; milliseconds
		AT FLOPPYPARAMS.bMotorStartTime,DB	04h	; half second

LAB_020c:
	push	word [bp+CTX.bp18]
	push	word [bp+CTX.bp1E]
	push	word [bp+CTX.bp20]
	mov	al,0
	lea	di,[bp+CTX.bp18]
	mov	bx,1F0Eh
	call	send_command
	jnc	LAB_022e
	pop	word [bp+CTX.bp20]
	pop	word [bp+CTX.bp1E]
	pop	word [bp+CTX.bp18]
	jmp	LAB_0314

LAB_022e:
	call	get_checksum
	cmp	ah,0DBh
	jnz	LAB_0259
	or	byte [7E0Ah],1
	test	byte [bp+1Fh],1
	jz	LAB_0259
	test	byte [bp+1Fh],2
	jnz	LAB_0259
	mov	byte [bp+19h],0
	jmp	LAB_035d

	db	8 dup(0)

disk_int:
	jmp	LAB_04bc

LAB_0259:
	pop	word [bp+20h]
	pop	word [bp+1Eh]
	pop	word [bp+18h]
	mov	byte [7E05h],9
	mov	bl,[7E04h]
	shl	bl,1
	mov	ax,cs
	and	ah,0F9h
	or	ah,bl

LAB_0274:
	mov	[SAVED_CS],ax
	call	get_plus_version
	jz	LAB_028b
	mov	bx,cs
	cmp	[SAVED_CS],bx
	jnc	LAB_029a
	cmp	ah,5
	jnc	LAB_029a
	jmp	SHORT LAB_02a4

LAB_028b:
	jnc	LAB_02a4
	test	byte [7E07h],6
	jnz	LAB_02a4
	test	byte [bp+18h],60h
	jnz	LAB_02a4

LAB_029a:
	mov	[7E08h],ax
	call	LAB_18d7
	jc	LAB_0314
	jz	LAB_02af

LAB_02a4:
	mov	cl,[7E04h]
	mov	al,80h
	shr	al,cl
	or	[bp+1Fh],al

LAB_02af:
	mov	ax,[SAVED_CS]
	add	ah,2
	test	ah,6
	jz	LAB_02c0
	inc	byte [7E04h]
	jmp	SHORT LAB_0274

LAB_02c0:
	mov	cl,[bp+1Eh]
	cmp	cl,2
	jc	LAB_02f4
	mov	cl,2
	mov	ax,80C0h
LAB_02cd:
	test	[bp+1Fh],ah
	jz	LAB_02da
	shr	ah,1
	shr	al,cl
	jnc	LAB_02cd
	jmp	SHORT LAB_02f1

LAB_02da:
	test	[bp+20h],al
	jnz	LAB_02f1

LAB_02df:
	shr	ah,1
	shr	al,cl
	jc	LAB_02f1
	test	[bp+1Fh],ah
	jnz	LAB_02df
	test	[bp+20h],al
	jz	LAB_02f1
	mov	cl,1
LAB_02f1:
	mov	[bp+1Eh],cl
LAB_02f4:
	mov	[NUM_FIXED_DRIVES],cl
	pop	ax
	pop	bx
	push	bx
	push	ax
	mov	[bp+1Ah],bx
	mov	[bp+1Ch],ax
	mov	al,9
	lea	di,[bp+21h]
	mov	bx,1F05h
	call	send_command
	jc	LAB_0314
	call	LAB_14d8
	jnc	LAB_0379
LAB_0314:
	mov	ax,cs
	and	ah,6
	shr	ah,1
	mov	bh,'B'
LAB_031d:
	mov	[SAVED_NUM_DRIVES],ah
LAB_0321:
	call	print_init_error
	cli
	pop	word [4Eh]
	pop	word [4Ch]
	pop	word [476h]
	pop	word [474h]
	pop	word [11Ah]
	pop	word [118h]
	pop	word [106h]
	pop	word [104h]
	pop	word [66h]
	pop	word [64h]
	pop	word [102h]
	pop	word [100h]
	mov	al,[SAVED_IMR]
	out	21h,al
	sti
	jmp	SHORT LAB_0395

LAB_035d:
	add	sp, byte 6
	mov	byte [NUM_FIXED_DRIVES],1
	mov	ah,9
	mov	dl,80h
	call	LAB_1309
	jnc	LAB_0379
	mov	ah,[bp+4]
	shr	ah,1
	shr	ah,1
	mov	bh,43h
	jmp	SHORT LAB_031d

LAB_0379:
	test	byte [bp+18h],60h
	jnz	LAB_0395
	test	byte [7E0Ah],2
	jnz	LAB_0395
	mov	ah,[SAVED_IMR]
	and	ah,1
	cli
	in	al,21h
	or	al,ah
	out	21h,al
	sti
LAB_0395:
	test	byte [7E0Ah],2
	jnz	LAB_03d1
	mov	[SAVED_CS],cs
LAB_03a0:
	mov	ax,[SAVED_CS]
	add	ah,2
	test	ah,6
	jz	LAB_03d1
	mov	[SAVED_CS],ax
	call	get_plus_version
	jz	LAB_03a0
	mov	ax,LAB_1c00
	mov	bx,cs
	cli
	xchg	INT_OFFSET(01h),ax
	xchg	INT_SEGMENT(01h),bx
	mov	[7E00h],ax
	mov	[7E02h],bx
	sti
	mov	word [bp+1Ch],LAB_0467	; Set return address
	jmp	restore_ctx

LAB_03d1:
	jmp	LAB_047f

	db	19 dup(0)

LAB_03e7:
	istruc DRVPARAMS
		AT DRVPARAMS.wCylinder,			dw	612
		AT DRVPARAMS.bHeads,			db	8
		AT DRVPARAMS.wReducedWrite,		dw	612
		AT DRVPARAMS.wWritePrecomp,		dw	0
		AT DRVPARAMS.bMaxEccBurst,		db	11
		AT DRVPARAMS.bControlByte,		db	5
		AT DRVPARAMS.bStdTimeout,		db	12
		AT DRVPARAMS.bFormatTimeout,		db	180
		AT DRVPARAMS.bDriveTimeout,		db	0
		AT DRVPARAMS.wLandingCyl,		dw	0
		AT DRVPARAMS.bSecPerTrk,		db	0
		AT DRVPARAMS.bReserved,			db	0
LAB_03f7:
	istruc DRVPARAMS
		AT DRVPARAMS.wCylinder,			dw	615
		AT DRVPARAMS.bHeads,			db	4
		AT DRVPARAMS.wReducedWrite,		dw	615
		AT DRVPARAMS.wWritePrecomp,		dw	0
		AT DRVPARAMS.bMaxEccBurst,		db	11
		AT DRVPARAMS.bControlByte,		db	5
		AT DRVPARAMS.bStdTimeout,		db	12
		AT DRVPARAMS.bFormatTimeout,		db	180
		AT DRVPARAMS.bDriveTimeout,		db	40
		AT DRVPARAMS.wLandingCyl,		dw	0
		AT DRVPARAMS.bSecPerTrk,		db	0
		AT DRVPARAMS.bReserved,			db	0
LAB_0407:
	istruc DRVPARAMS
		AT DRVPARAMS.wCylinder,			dw	612
		AT DRVPARAMS.bHeads,			db	8
		AT DRVPARAMS.wReducedWrite,		dw	612
		AT DRVPARAMS.wWritePrecomp,		dw	0
		AT DRVPARAMS.bMaxEccBurst,		db	11
		AT DRVPARAMS.bControlByte,		db	5
		AT DRVPARAMS.bStdTimeout,		db	12
		AT DRVPARAMS.bFormatTimeout,		db	180
		AT DRVPARAMS.bDriveTimeout,		db	0
		AT DRVPARAMS.wLandingCyl,		dw	0
		AT DRVPARAMS.bSecPerTrk,		db	0
		AT DRVPARAMS.bReserved,			db	0
LAB_0417:
	istruc DRVPARAMS
		AT DRVPARAMS.wCylinder,			dw	306
		AT DRVPARAMS.bHeads,			db	4
		AT DRVPARAMS.wReducedWrite,		dw	306
		AT DRVPARAMS.wWritePrecomp,		dw	0
		AT DRVPARAMS.bMaxEccBurst,		db	11
		AT DRVPARAMS.bControlByte,		db	5
		AT DRVPARAMS.bStdTimeout,		db	12
		AT DRVPARAMS.bFormatTimeout,		db	180
		AT DRVPARAMS.bDriveTimeout,		db	40
		AT DRVPARAMS.wLandingCyl,		dw	0
		AT DRVPARAMS.bSecPerTrk,		db	0
		AT DRVPARAMS.bReserved,			db	0
LAB_0427:
	istruc DRVPARAMS
		AT DRVPARAMS.wCylinder,			dw	612
		AT DRVPARAMS.bHeads,			db	8
		AT DRVPARAMS.wReducedWrite,		dw	612
		AT DRVPARAMS.wWritePrecomp,		dw	0
		AT DRVPARAMS.bMaxEccBurst,		db	11
		AT DRVPARAMS.bControlByte,		db	5
		AT DRVPARAMS.bStdTimeout,		db	12
		AT DRVPARAMS.bFormatTimeout,		db	180
		AT DRVPARAMS.bDriveTimeout,		db	0
		AT DRVPARAMS.wLandingCyl,		dw	0
		AT DRVPARAMS.bSecPerTrk,		db	17
		AT DRVPARAMS.bReserved,			db	0
LAB_0437:
	istruc DRVPARAMS
		AT DRVPARAMS.wCylinder,			dw	615
		AT DRVPARAMS.bHeads,			db	4
		AT DRVPARAMS.wReducedWrite,		dw	615
		AT DRVPARAMS.wWritePrecomp,		dw	0
		AT DRVPARAMS.bMaxEccBurst,		db	11
		AT DRVPARAMS.bControlByte,		db	5
		AT DRVPARAMS.bStdTimeout,		db	12
		AT DRVPARAMS.bFormatTimeout,		db	180
		AT DRVPARAMS.bDriveTimeout,		db	40
		AT DRVPARAMS.wLandingCyl,		dw	615
		AT DRVPARAMS.bSecPerTrk,		db	17
		AT DRVPARAMS.bReserved,			db	0
LAB_0447:
	istruc DRVPARAMS
		AT DRVPARAMS.wCylinder,			dw	612
		AT DRVPARAMS.bHeads,			db	8
		AT DRVPARAMS.wReducedWrite,		dw	612
		AT DRVPARAMS.wWritePrecomp,		dw	0
		AT DRVPARAMS.bMaxEccBurst,		db	11
		AT DRVPARAMS.bControlByte,		db	5
		AT DRVPARAMS.bStdTimeout,		db	12
		AT DRVPARAMS.bFormatTimeout,		db	180
		AT DRVPARAMS.bDriveTimeout,		db	0
		AT DRVPARAMS.wLandingCyl,		dw	0
		AT DRVPARAMS.bSecPerTrk,		db	17
		AT DRVPARAMS.bReserved,			db	0
LAB_0457:
	istruc DRVPARAMS
		AT DRVPARAMS.wCylinder,			dw	306
		AT DRVPARAMS.bHeads,			db	4
		AT DRVPARAMS.wReducedWrite,		dw	306
		AT DRVPARAMS.wWritePrecomp,		dw	0
		AT DRVPARAMS.bMaxEccBurst,		db	11
		AT DRVPARAMS.bControlByte,		db	5
		AT DRVPARAMS.bStdTimeout,		db	12
		AT DRVPARAMS.bFormatTimeout,		db	180
		AT DRVPARAMS.bDriveTimeout,		db	40
		AT DRVPARAMS.wLandingCyl,		dw	306
		AT DRVPARAMS.bSecPerTrk,		db	17
		AT DRVPARAMS.bReserved,			db	0

LAB_0467:
	push	ax
	push	ax
	push	bp
	mov	bp,sp
	pushf
	pop	ax			; AX has flags
	xchg	[bp+8],ax		; AX has CS
	xchg	[bp+6],ax		; AX has IP
	mov	[bp+4],ax
	or	word [bp+8],100h	; Set trap flag
	pop	bp
	pop	ax
	iret

LAB_047f:
	mov	word [bp+1Ch],LAB_0487	; Set return address
	jmp	restore_ctx

LAB_0487:
	retf				; Return to system BIOS

LAB_0488:
	dw	00FFh
	dw	00FFh
	dw	0FA08h
	dw	0F80Ah
	dw	7A05h
	dw	3806h
	dw	3807h
	dw	3804h
	dw	00FFh
	dw	000Ch
	dw	0FEE5h
	dw	0FCE6h
	dw	300Bh
	dw	00FFh
	dw	830Eh
	dw	810Fh
	dw	0000h
	dw	0001h
	dw	00E0h
	dw	00E3h
	dw	00E4h
	dw	00FFh
	dw	00FFh
	dw	00FFh
	dw	00FFh
	dw	00FFh

LAB_04bc:
	sti				; Interrupts disabled
	test	dl,80h			; Is it for fixed disk?
	jnz	LAB_04c7		; Yes, branch
	int	40h			; Call relocated disk handler
LAB_04c4:
	retf	2			; Return to caller, dropping flags

LAB_04c7:
	or	ah,ah			; Is it non-zero?
	jnz	LAB_04e1		; Yes, branch

	; Handle calling reset to diskette
	int	40h			; Call relocated disk handler
	mov	ax,0			; Clear value
	push	ds
	mov	ds,ax			; Setup addressing
	mov	al,[NUM_FIXED_DRIVES]	; Read number of drivers
	or	al,80h			; Make it a fixed disk number
	cmp	dl,al			; Is request out of range?
	mov	al,0			; Clear
	pop	ds			; Restore addressing
	jnc	LAB_04c4		; Out of range, return to caller
	mov	ah,0Dh			; Reset hard disk
LAB_04e1:
	push	bp
	mov	bp,sp
	xchg	[bp+2],ax		; Set caller IP to 0D00h
	xchg	[bp+4],ax		; Set caller CS to caller IP
	mov	[bp+6],ax		; Set caller flags to CS
	pop	bp
	push	ds
	mov	ax,BIOS_SEG
	mov	ds,ax
	cmp	byte [MACHINE_TYPE],MACHINE_TYPE_PS2
	pop	ds
	jnz	LAB_0504		; Jump if not PS/2

	;---> Begin of PS/2 specific code <---
	cli				; Interrupts disabled
	in	al,PS2_SYS_BRD		; Read PS/2 System board control reg
	and	al,0FEh			; Disable fixed disk CS
	out	65h,al			; Update PS/2 system baord control reg
	sti				; Interrupt enabled
	;---> End of PS/2 specific code <---

LAB_0504:
	pop	ax			; Restore to caller AX
	call	save_ctx		; Save calling context
	mov	al,0
	lea	di,[bp+18h]		;  
	mov	bx,1F0Eh		; 1F = Read data, length = 14 bytes
	call	send_command		; Send command
	jc	LAB_0524		; Branch if error
	call	get_checksum		; Calculate sum
	cmp	ah,0DBh			; Is it correct?
	jnz	LAB_0524		; No, error out
	mov	byte [bp+CTX.bp19],0	; Reset value
	jmp	SHORT LAB_054c
	
	nop
	
LAB_0524:
	mov	ax,0BB00h		; Undefined error
	jmp	SHORT LAB_057f		; Error return
	nop
LAB_052A:
	dw	1234h			; Magic CX value
	dw	7F80h			; Magic DX value
	dw	5678h			; Magic DI value
	dw	9ABCh			; Magic ES value
	dw	0DEF0h			; Magic SI value

LAB_0534:
	dw	LAB_10fa		; AL = FEh
	dw	LAB_10f0		; AL = FDh
	dw	LAB_1197		; AL = FCh
	dw	LAB_123b		; AL = FBh
	dw	LAB_1110		; AL = FAh
	dw	LAB_111f		; AL = F9h
	dw	LAB_1340		; AL = F8h
	dw	LAB_13c5		; AL = F7h
	dw	LAB_1157		; AL = F6h
	dw	LAB_1277		; AL = F5h
	dw	LAB_12cd		; AL = F4h
	dw	LAB_12c7		; Not reached?

LAB_054c:
	mov	ax,[bp+CTX.bp12AX]	; Get input AX
	cmp	ah,14h			; Is it controller internal diagnostic?
	jnz	LAB_058e		; No, branch
	cmp	al,0F4h			; Magic value?
	jc	LAB_058e		; No, branch

	push	ds			; Save register [1]

	push	cs
	pop	ds
	mov	si,LAB_052A		; Magic value table

	push	es			; Save register [2]

	push	ss			; Setup addressing
	pop	es

	lea	di,[bp+CTX.bp2CX]	; Starting offet
	mov	cx,5			; Count 5 words
	repe cmpsw			; Compare it

	pop	es			; Restore register [2]
	pop	ds			; Restore register [1]

	jnz	LAB_058e		; Branch if no match

	neg	al			; Complement of value
	dec	al			; Make it zero-based
	cbw				; Extend to 16 bits
	shl	ax,1			; Make it an index to words
	mov	bx,ax			; Put in appropriate register
	cs call	[bx+LAB_0534]		; Call diagnostics handler
	jc	LAB_057f		; Jump if error
	xor	ax,ax			; Success return

LAB_057f:
	mov	[bp+CTX.bp12AX],ax	; Return value
	mov	[LAST_STATUS],ah	; Set BIOS last status
	pushf				; Save flags
	call	check_not_ready		; Update drive status
	popf				; Restore flags
	jmp	LAB_06a5		; Go exit

LAB_058e:
	cmp	ah,0Dh			; Calling reset hard disks?
	jz	LAB_059e		; Yes, branch
	cmp	ah,9			; Calling initialize with params?
	jnz	LAB_05b1		; No, branch

	; ----------> AH = 9: Initialize controller with drive params <------------

	test	byte [bp+CTX.bp18],60h	; Is it AT or PS/2?
	jnz	LAB_05b1		; No, branch

	; AT or PS/2 branch

LAB_059e:
	mov	al,[bp+CTX.bpCDX]	; Saved DL (drive number)
	and	al,7Fh			; Discard fixed drive indicator (80h)
	cmp	al,[bp+CTX.bp1E]	; Is it out of range?
	jnc	LAB_05b1		; Yes, branch
	mov	byte [bp+CTX.bpCDX],80h	; Reset controller number
	or	al,0C0h			; 4 drives per controller
	or	[bp+19h],al		; Set CDB

LAB_05b1:
	test	byte [bp+CTX.bp18],80h	; Is it a fixed drive number?
	jz	LAB_05c7		; No
	mov	al,[bp+20h]
	rol	al,1
	rol	al,1			; 2 high bits now in lower 2 bits
	and	al,3			; Preserve only these bits
	or	al,80h			; Make it a fixed disk number
	cmp	[bp+CTX.bpCDX],al	; 
	jbe	LAB_05ca		
LAB_05c7:
	jmp	LAB_0678

LAB_05ca:
	add	al,81h			; Make it a count
	mov	[NUM_FIXED_DRIVES],al	; Save it
	mov	al,[bp+CTX.bp19]
	cmp	ah,9
	jnz	LAB_05d9
	or	al,20h

LAB_05d9:
	cmp	ah,8
	jnz	LAB_05e0
	or	al,10h

LAB_05e0:
	mov	ah,[bp+1eh]
	mov	[bp+24h],ax
	pushf
	pop	ax
	mov	[bp+22h],ax
	mov	[bp+20h],cs
	mov	word [bp+1Eh],LAB_0603
	lea	sp,[bp+6]
	pop	di
	pop	es
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	ds
	pop	bp
	add	sp,byte 2
	retf

LAB_0603:
	push	ds
	push	bp
	mov	bp,0
	mov	ds,bp
	mov	bp,sp
	xchg	[bp+4],ax
	mov	[NUM_FIXED_DRIVES],ah
	jc	LAB_0621
	pushf
	test	al,40h
	jnz	LAB_0628
	test	al,10h
	jz	LAB_0620
	mov	dl,ah
LAB_0620:
	popf
LAB_0621:
	pop	bp
	pop	ds
	pop	ax
	retf

LAB_0625:
	jmp	LAB_0524

LAB_0628:
	mov	ah,0Dh
	test	al,20h
	jz	LAB_0632
	AND	al,0DFh
	mov	ah,9
LAB_0632:
	popf
	pop	bp
	pop	ds
	add	sp,byte 2
	call	save_ctx
	mov	al,0
	lea	di,[bp+18h]
	mov	bx,1F0Eh
	call	send_command
	jc	LAB_0625
	call	get_checksum
	cmp	ah,0DBh
	jnz	LAB_0625
	mov	al,[bp+12h]
	mov	[bp+19h],al
LAB_0656:
	mov	al,[bp+0Ch]
	and	al,7Fh
	call	LAB_107c
	jc	LAB_066f
	inc	bh
	add	[bp+0Ch],bh
	mov	al,[bp+0Ch]
	and	al,7Fh
	cmp	al,[bp+1Eh]
	jc	LAB_0678
LAB_066f:
	and	byte [bp+19h],0BFh
	xor	ax,ax
	jmp	SHORT LAB_069b

	nop

LAB_0678:
	call	LAB_06ae
	jc	LAB_069b
LAB_067d:
	test	byte [bp+18h],60h
	jnz	LAB_068b
	cs call	word [bx+1B8Ch]
	jmp	SHORT LAB_0690

	nop

LAB_068b:
	cs call	word [bx+1BB6h]
LAB_0690:
	test	byte [bp+19h],40h
	jz	LAB_069b
	cmp	ah,0
	jz	LAB_0656
LAB_069b:
	mov	[bp+12h],ax
LAB_069e:
	mov	[474h],ah
	call	LAB_0e86
LAB_06a5:
	mov	word [bp+1Ch],LAB_06ad	; Set return pointer
	jmp	restore_ctx		; Get out
LAB_06ad:
	retf				; Finally get out of interrupt

LAB_06ae:
	mov	ah,[bp+13h]
	test	byte [bp+18h],40h
	jnz	LAB_06c7
	test	byte [bp+18h],20h
	jnz	LAB_06c2
	cmp	ah,15h
	jmp	SHORT LAB_06ca

LAB_06c2:
	cmp	ah,1Ah
	jmp	SHORT LAB_06ca

LAB_06c7:
	cmp	ah,16h
LAB_06ca:
	jc	LAB_06cf
	jmp	SHORT LAB_0711

	nop

LAB_06cf:
	cmp	ah,1
	jz	LAB_0741
	mov	al,[bp+0Ch]
	and	al,7Fh
	cmp	al,[bp+1Eh]
	jnc	LAB_0711
	call	LAB_107c
	jc	LAB_0716
	and	bh,bh
	jz	LAB_072d
	and	dl,dl
	jz	LAB_073c
	test	byte [bp+18h],80h
	jz	LAB_06fb
	test	byte [bp+20h],0C0h
	jz	LAB_06fb
	dec	dl
	jz	LAB_073c
LAB_06fb:
	mov	al,5
	mul	dl
	add	al,9
	mov	bx,1F05h
	lea	di,[bp+21h]
	call	send_command
	jnc	LAB_073c
	mov	ax,0BB00h
	jmp	SHORT LAB_0726

LAB_0711:
	mov	ax,100h
	jmp	SHORT LAB_0719

LAB_0716:
	mov	ax,8000h
LAB_0719:
	cmp	byte [bp+13h],8
	jz	LAB_0727
	cmp	byte [bp+13h],15h
	jz	LAB_072a
LAB_0725:
	stc
LAB_0726:
	ret
LAB_0727:
	jmp	LAB_0847

LAB_072a:
	jmp	LAB_1624

LAB_072d:
	push	ds
	call	LAB_0a93
	lodsw
	pop	ds
	ror	ah,1
	ror	ah,1
	xchg	ah,al
	mov	[bp+21h],ax
LAB_073c:
	call	LAB_10af
	jc	LAB_0716
LAB_0741:
	mov	bl,[bp+13h]
	mov	bh,0
	shl	bx,1
	cs mov	ax,[bx+488h]
	test	ah,10h
	jnz	LAB_0763
	jmp	SHORT LAB_07bc

	nop

LAB_0755:
	db	11 dup(0)

LAB_0760:
	jmp	SHORT LAB_07c1
	nop

LAB_0763:
	push	bx
	push	ax
	mov	ax,[bp+2]
	xchg	ah,al
	rol	ah,1
	rol	ah,1
	and	ah,3
	add	ax,cx
	cmp	ax,dx
	jc	LAB_077e
	pop	ax
	pop	ax
	mov	ax,200h
	jmp	SHORT LAB_0725

LAB_077e:
	ror	ah,1
	ror	ah,1
	xchg	ah,al
	mov	cl,[bp+2]
	and	cl,3Fh
	or	al,cl
	mov	[bp+2],ax
	pop	ax
	test	ah,8
	jz	LAB_07bb
	push	ax
	push	dx
	push	ds
	call	LAB_0a93
	mov	bl,[si+2]
	pop	ds
	pop	cx
	xor	dx,dx
	call	LAB_0a05
	jc	LAB_07ba
	mov	bl,[bp+12h]
	and	bx,0FFh
	jz	LAB_07b4
	cmp	bx,ax
	jbe	LAB_07ba
LAB_07b4:
	mov	[bp+12h],al
	mov	[bp+0],al
LAB_07ba:
	pop	ax
LAB_07bb:
	pop	bx
LAB_07bc:
	and	byte [bp+1],0
	ret

LAB_07c1:
	push	ax
	in	al,21h
	jmp	SHORT LAB_07c6

LAB_07c6:
	or	al,20h
	out	21h,al
	jmp	SHORT LAB_07cc

LAB_07cc:
	mov	al,7
	out	0Ah,al
	jmp	SHORT LAB_07d2

LAB_07d2:
	mov	al,20h
	out	20h,al
	push	ds
	mov	ax,0F000h
	mov	ds,ax
	mov	al,[0FFFEh]
	pop	ds
	cmp	al,0FCh
	jz	LAB_07e8
	cmp	al,0FAh
	jnz	LAB_07ee
LAB_07e8:
	sti
	mov	ax,9100h
	int	15h

LAB_07ee:
	pop	ax
	iret

LAB_07f0:
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,321h
	out	dx,al
	xor	cx,cx
LAB_07fd:
	loop	LAB_07fd
	call	check_not_ready
	jc	LAB_0809
	call	LAB_1052
	jnc	LAB_0810
LAB_0809:
	call	LAB_158c
	mov	ax,500h
	ret

LAB_0810:
	mov	ax,0Ch
	jmp	SHORT LAB_0852

	nop

LAB_0816:
	xor	ah,ah
	mov	al,[474h]
	ret

LAB_081c:
	call	check_not_ready
	jc	LAB_0847
	call	LAB_10af
	sub	dx,cx
	dec	dx
	dec	dx
	xchg	dh,dl
	ror	dl,1
	ror	dl,1
	or	dl,11h
	mov	[bp+0Eh],dx
	push	ds
	call	LAB_0a93
	mov	ah,[si+2]
	pop	ds
	dec	ah
	mov	al,[bp+1Eh]
	mov	[bp+0Ch],ax
LAB_0844:
	xor	ax,ax
	ret

LAB_0847:
	xor	ax,ax
	mov	[bp+0Eh],ax
	mov	[bp+0Ch],ax
	jmp	SHORT LAB_0866

	nop

LAB_0852:
	call	LAB_08a9
	jc	LAB_0866
	call	LAB_086e
	jc	LAB_0866
	call	LAB_0bd4
	jc	LAB_0866
	jnz	LAB_0866
	xor	ax,ax
	ret

LAB_0866:
	call	LAB_158c
	mov	ax,700h
	stc
	ret

LAB_086e:
	push	ds
	mov	cx,5
	mov	bl,0Dh
	call	LAB_0a93
	dec	dx

LAB_0878:
	lodsb
	shr	bl,1
	jnc	LAB_0887
	xchg	ah,al
	lodsb
	call	LAB_089c
	jc	LAB_089b
	xchg	ah,al
LAB_0887:
	call	LAB_089c
	jc	LAB_089b
	loop	LAB_0878
	lodsb
	and	al,0C0h
	pop	ds
	and	byte [476h],3Fh
	or	[476h],al
LAB_089b:
	ret

LAB_089c:
	push	ax
	mov	ah,9
	call	LAB_09f5
	pop	ax
	jc	LAB_08a8
	dec	dx
	out	dx,al
	inc	dx
LAB_08a8:
	ret

LAB_08a9:
	and	byte [bp+18h],0EFh
	jmp	SHORT LAB_08b4
	nop

LAB_08b0:
	or	byte [bp+18h],10h
LAB_08b4:
	push	ax
	mov	bh,ah
	mov	di,442h
	stosb
	mov	al,[bp+5]
	and	al,1Fh
	test	bh,20h
	jnz	LAB_08c7
	xor	al,al
LAB_08c7:
	stosb
	mov	ax,[bp+2]
	dec	al
	test	bh,10h
	jnz	LAB_08d5
	and	ax,3Fh
LAB_08d5:
	test	bh,40h
	jnz	LAB_08dc
	and	al,0C0h
LAB_08dc:
	stosw
	mov	al,[bp+0]
	test	bh,8
	jnz	LAB_08ee
	xor	al,al
	test	bh,1
	jz	LAB_08ee
	mov	al,1
LAB_08ee:
	stosb
	mov	al,[476h]
	and	al,0C0h
	or	al,5
	stosb
	call	check_not_ready
	jnc	LAB_08ff
	jmp	LAB_09e9
LAB_08ff:
	test	byte [bp+18h],10h
	jz	LAB_095a
	test	byte [bp+19h],10h
	jnz	LAB_0956
	test	byte [bp+18h],60h
	jz	LAB_0937
	in	al,21h
	test	al,20h
	jz	LAB_095a
	cmp	word [408h],278h
	jz	LAB_092f
	cmp	word [40Ah],278h
	jz	LAB_092f
	cmp	word [40Ch],278h
	jnz	LAB_0937
LAB_092f:
	mov	dx,27Ah
	in	al,dx
	test	al,10h
	jnz	LAB_095a
LAB_0937:
	test	byte [bp+19h],40h
	jnz	LAB_095a
	cli
	mov	ax,760h
	xchg	[34h],ax
	mov	[bp+1Ah],ax
	mov	ax,cs
	xchg	[36h],ax
	mov	[bp+1Ch],ax
	sti
	or	byte [bp+19h],10h
LAB_0956:
	mov	al,2
	jmp	SHORT LAB_095c
LAB_095a:
	mov	al,0
LAB_095c:
	test	byte [bp+19h],20h
	jnz	LAB_0969
	test	bh,80h
	jz	LAB_0969
	or	al,1
LAB_0969:
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,323h
	out	dx,al
	mov	bl,2
LAB_0976:
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,322h
	out	dx,al
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,321h
	mov	ah,0Dh
	mov	cx,10h
LAB_0990:
	call	LAB_09f5
	jnc	LAB_09a2
	loop	LAB_0990
	dec	bl
	jz	LAB_09e9
	mov	cx,1000h
LAB_099e:
	loop	LAB_099e
	jmp	SHORT LAB_0976
LAB_09a2:
	call	LAB_0c47
	jc	LAB_09e9
	mov	cx,6
	mov	si,442h
LAB_09ad:
	call	LAB_09f5
	jc	LAB_09e9
	lodsb
	dec	dx
	out	dx,al
	inc	dx
	loop	LAB_09ad
	test	byte [bp+19h],20h
	jnz	LAB_09c7
	test	bh,80h
	jz	LAB_09c7
	mov	al,3
	out	0Ah,al
LAB_09c7:
	test	byte [bp+19h],10h
	jz	LAB_09e9
	test	byte [bp+18h],10h
	jz	LAB_09e9
	cli
	in	al,21h
	jmp	SHORT LAB_09d8
LAB_09d8:
	and	al,0DFh
	out	21h,al
	sti
	test	byte [bp+18h],60h
	jz	LAB_09e9
	clc
	mov	ax,9000h
	int	15h
LAB_09e9:
	pop	ax
	ret

LAB_09eb:
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,321h
LAB_09f5:
	push	cx
	mov	cx,4000h
LAB_09f9:
	in	al,dx
	and	al,0Fh
	cmp	ah,al
	jz	LAB_0a03
	loop	LAB_09f9
	stc
LAB_0a03:
	pop	cx
	ret

LAB_0a05:
	inc	dx
	push	dx
	push	cx
	mov	dh,[bp+5]
	mov	cx,[bp+2]
	call	LAB_0c37
	pop	ax
	sub	ax,cx
	pop	cx
	neg	ah
	jc	LAB_0a35
	mul	bl
	jc	LAB_0a35
	add	al,ch
	jc	LAB_0a35
	sub	al,dh
	jc	LAB_0a35
	mov	dh,11h
	mul	dh
	xor	ch,ch
	add	ax,cx
	xor	dh,dh
	sub	ax,dx
	cmp	ax,101h
	cmc
LAB_0a35:
	ret

LAB_0a36:
	push	ax
	call	LAB_189f
	push	dx
	mov	al,47h
	test	ah,2
	jnz	LAB_0a44
	mov	al,4Bh
LAB_0a44:
	push	ax
	mov	al,[bp+0]
	test	ah,1
	jz	LAB_0a4f
	mov	al,1
LAB_0a4f:
	xor	ah,ah
	mul	cx
	sub	ax,1
	sbb	dx,byte 0
	add	dl,byte -1
	jnc	LAB_0a62
LAB_0a5e:
	pop	ax
	pop	ax
	pop	ax
	ret

LAB_0a62:
	push	bx
	add	bx,ax
	pop	bx
	jc	LAB_0a5e
	mov	cx,ax
	pop	ax
	cli
	out	0Bh,al
	jmp	SHORT LAB_0a70
LAB_0a70:
	out	0Ch,al
	jmp	SHORT LAB_0a74
LAB_0a74:
	mov	ax,bx
	out	6,al
	jmp	SHORT LAB_0a7a
LAB_0a7a:
	xchg	ah,al
	out	6,al
	jmp	SHORT LAB_0a80
LAB_0a80:
	pop	ax
	out	82h,al
	jmp	SHORT LAB_0a85
LAB_0a85:
	mov	ax,cx
	out	7,al
	jmp	SHORT LAB_0a8b
LAB_0a8b:
	xchg	ah,al
	out	7,al
	sti
	clc
	pop	ax
	ret

LAB_0a93:
	push	ax
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,322h
	in	al,dx
	and	al,3
	shl	al,1
	shl	al,1
	shl	al,1
	shl	al,1
	cbw
	mov	si,3E7h
	test	byte [bp+18h],60h
	jz	LAB_0ab6
	mov	si,427h
LAB_0ab6:
	add	si,ax
	push	cs
	pop	ds
	pop	ax
	ret

LAB_0abc:
	db	00h
	db	01h
	db	02h
	db	03h
	db	04h
	db	06h
	db	08h
	db	10h
	db	11h
	db	12h
	db	14h
	db	15h
	db	18h
	db	19h
	db	20h
	db	21h
	db	30h
	db	31h
	db	32h

LAB_0acf:
	db	00h
	db	0BBh
	db	20h
	db	40h
	db	20h
	db	40h
	db	20h
	db	40h
	db	10h
	db	10h
	db	02h
	db	04h
	db	40h
	db	11h
	db	0Bh
	db	01h
	db	02h
	db	20h
	db	20h
	db	10h

LAB_0ae3:
	db	0BBh
	db	0E0h
	db	20h
	db	40h
	db	0CCh
	db	0AAh
	db	20h
	db	40h
	db	10h
	db	10h
	db	02h
	db	04h
	db	40h
	db	11h
	db	0Ah
	db	01h
	db	02h
	db	20h
	db	20h
	db 	10h
	db	0BBh

LAB_0af8:
	mov	bh,byte 0
	test	byte [bp+18h],1
	jz	LAB_0b62
	mov	si,9Eh
	add	si,[44Eh]
	mov	cx,0B000h
	mov	al,[449h]
	cmp	al,7
	jz	LAB_0b1f
	or	bh,2
	mov	ch,0B8h
	cmp	al,4
	jc	LAB_0b1f
	or	bh,1
	jmp	SHORT LAB_0b62

LAB_0b1f:
	mov	dx,[463h]
	add	dx,byte 6
	mov	ds,cx
	mov	es,cx
	mov	cx,0F2Bh
	mov	di,si
	test	bh,2
	jnz	LAB_0b38
	xchg	[si],cx
	jmp	SHORT LAB_0b5a

LAB_0b38:
	in	al,dx
	test	al,1
	jnz	LAB_0b38
	cli
LAB_0b3e:
	in	al,dx
	test	al,1
	jz	LAB_0b3e
	lodsw
	sti
	xchg	ax,cx
	mov	bl,al
LAB_0b48:
	in	al,dx
	test	al,1
	jnz	LAB_0b48
	cli
LAB_0b4e:
	in	al,dx
	test	al,1
	jz	LAB_0b4e
	mov	al,bl
	stosw
	sti
	sub	di,byte 2
LAB_0b5a:
	mov	si,cx
	xor	cx,cx
	mov	ds,cx
	mov	es,cx
LAB_0b62:
	test	byte [bp+18h],2
	jz	LAB_0b81
	mov	al,0B6h
	out	43h,al
	jmp	SHORT LAB_0b6e
LAB_0b6e:
	mov	ax,0FFFFh
	out	42h,al
	jmp	SHORT LAB_0b75
LAB_0b75:
	xchg	ah,al
	out	42h,al
	in	al,61h
	mov	bl,al
	or	al,3
	out	61h,al
LAB_0b81:
	mov	al,[442h]
	call	LAB_0c5e
	mov	cx,ax
	call	LAB_0bdb
	pushf
	test	byte [bp+18h],2
	jz	LAB_0b97
	mov	al,bl
	out	61h,al
LAB_0b97:
	test	byte [bp+18h],1
	jz	LAB_0bd2
	test	bh,1
	jnz	LAB_0bd2
	mov	cx,0B000h
	test	bh,2
	jz	LAB_0bac
	mov	ch,0B8h
LAB_0bac:
	mov	es,cx
	mov	dx,[463h]
	add	dx,byte 6
	test	bh,2
	jnz	LAB_0bbf
	es mov	[di],si
	jmp	SHORT LAB_0bce
LAB_0bbf:
	in	al,dx
	test	al,1
	jnz	LAB_0bbf
	cli
LAB_0bc5:
	in	al,dx
	test	al,1
	jz	LAB_0bc5
	mov	ax,si
	stosw
	sti
LAB_0bce:
	xor	cx,cx
	mov	es,cx
LAB_0bd2:
	popf
	ret

LAB_0bd4:
	push	cx
	mov	cx,50h
	jmp	SHORT LAB_0bdc

	nop

LAB_0bdb:
	push	cx
LAB_0bdc:
	push	cx
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,321h
	mov	ah,0Fh
	test	byte [bp+19h],20h
	jnz	LAB_0c0a
	test	byte [bp+18h],10h
	jz	LAB_0c0a
	test	byte [bp+19h],10h
	jz	LAB_0c0a
	in	al,21h
	test	al,1
	jnz	LAB_0c0a
LAB_0c01:
	call	LAB_0c14
	jnc	LAB_0c11
	loop	LAB_0c01
	pop	cx
	push	cx
LAB_0c0a:
	call	LAB_0c2d
	jnc	LAB_0c11
	loop	LAB_0c0a
LAB_0c11:
	pop	cx
	pop	cx
	ret

LAB_0c14:
	in	al,dx
	and	al,ah
	cmp	al,ah
	jz	LAB_0c32
	hlt

LAB_0c1c:
	in	al,dx
	and	al,ah
	cmp	al,ah
	jz	LAB_0c32
	hlt

LAB_0c24:
	in	al,dx
	and	al,ah
	cmp	al,ah
	jz	LAB_0c32
	stc
	ret

LAB_0c2d:
	call	LAB_09f5
	jc	LAB_0c36
LAB_0c32:
	dec	dx
	in	al,dx
	test	al,2
LAB_0c36:
	ret

LAB_0c37:
	mov	dl,cl
	and	dx,1F3Fh
	xchg	cl,ch
	rol	ch,1
	rol	ch,1
	and	ch,3
	ret

LAB_0c47:
	push	ax
	in	al,dx
	nop
	and	al,0Fh
	cmp	al,ah
	jnz	LAB_0c5b
	not	al
	in	al,dx
	push	es
	pop	es
	and	al,0Fh
	cmp	al,ah
	jz	LAB_0c5c
LAB_0c5b:
	stc
LAB_0c5c:
	pop	ax
	ret

LAB_0c5e:
	cmp	al,0E3h
	jnz	LAB_0c67
	mov	ax,3Ch
	jmp	SHORT LAB_0c72

LAB_0c67:
	cmp	al,4
	jz	LAB_0c6f
	mov	ax,50h
	ret

LAB_0c6f:
	mov	ax,12Ch
LAB_0c72:
	push	dx
	push	ax
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,322h
	in	al,dx
	pop	dx
	and	al,3
	jz	LAB_0c8a
	xor	al,3
	jz	LAB_0c8a
	shl	dx,1
LAB_0c8a:
	shl	dx,1
	shl	dx,1
	mov	ax,dx
	pop	dx
	ret

LAB_0c92:
	call	LAB_0a36
	jnc	LAB_0ce6
	call	LAB_1889
	jcxz	LAB_0cc1
	mov	[bp+0],cl
	push	ax
	call	LAB_0c92
LAB_0ca3:
	pop	bx
	or	ax,ax
	jnz	LAB_0cc0
	mov	ax,[bp+0]
	add	ah,al
	mov	al,[bp+12h]
	sub	al,ah
	jz	LAB_0cbe
	push	bx
	call	LAB_183b
	mov	[bp+0],ax
	pop	ax
	jmp	SHORT LAB_0c92
LAB_0cbe:
	xor	ax,ax
LAB_0cc0:
	ret

LAB_0cc1:
	mov	byte [bp+0],1
	or	byte [bp+19h],20h
	call	LAB_08a9
	jc	LAB_0ceb
	push	ax
	call	LAB_17c0
	mov	ax,0
	mov	ds,ax
	mov	es,ax
	pop	ax
	jc	LAB_0ceb
LAB_0cdc:
	push	ax
	call	LAB_0cf2
	and	byte [bp+19h],0DFh
	jmp	SHORT LAB_0ca3

LAB_0ce6:
	call	LAB_08b0
	jnc	LAB_0cf2
LAB_0ceb:
	call	LAB_158c
	mov	ax,0BB00h
	ret

LAB_0cf2:
	test	byte [bp+19h],40h
	jz	LAB_0cfb
	call	LAB_11c3
LAB_0cfb:
	call	LAB_0af8
	jc	LAB_0ceb
	jnz	LAB_0d05
LAB_0d02:
	xor	ax,ax
	ret

LAB_0d05:
	mov	ax,3
	call	LAB_08a9
	jc	LAB_0d40
	mov	ah,0Bh
	mov	cx,4
	mov	di,442h

LAB_0d15:
	mov	bx,100h
LAB_0d18:
	call	LAB_09eb
	jnc	LAB_0d22
	dec	bx
	jnz	LAB_0d18
	jmp	SHORT LAB_0d40

LAB_0d22:
	dec	dx
	in	al,dx
	stosb
	inc	dx
	loop	LAB_0d15
	call	LAB_0bd4
	jc	LAB_0d40
	jnz	LAB_0d40
	mov	byte [447h],0FFh
	mov	al,[442h]
	and	al,7Fh
	cmp	al,4
	jnz	LAB_0d47
	call	LAB_1052
LAB_0d40:
	call	LAB_158c
	mov	ax,0FF00h
	ret

LAB_0d47:
	push	es
	push	cs
	pop	es
	mov	di,0ABCh
	mov	cx,14h
	repne scasb
	pop	es
	add	di,byte 13h
	test	byte [bp+18h],60h		; Running on AT or PS/2?
	jz	LAB_0d5f			; No, branch
	add	di,byte 14h
LAB_0d5f:
	cs mov	ah,[di]
	mov	al,0
	cmp	ah,11h
	jz	LAB_0d6c
	jmp	LAB_0e0c

LAB_0d6c:
	test	byte [bp+18h],4
	jz	LAB_0d98
LAB_0d72:
	mov	ax,0Dh
	call	LAB_08a9
	jc	LAB_0d91
	mov	ah,0Bh
	call	LAB_09eb
	jc	LAB_0d91
	dec	dx
	in	al,dx
	mov	bl,al
	call	LAB_0bd4
	jc	LAB_0d91
	jnz	LAB_0d91
	mov	ah,11h
	mov	al,bl
	ret

LAB_0d91:
	call	LAB_158c
	mov	ax,0BB00h
	ret

LAB_0d98:
	mov	di,443h
	push	ds
	call	LAB_0a93
	mov	bl,[si+2]
	pop	ds
	mov	dx,0FA08h
	mov	al,[bp+13h]
	cmp	al,2
	jz	LAB_0db4
	mov	dx,7A05h
	cmp	al,4
	jnz	LAB_0d72
LAB_0db4:
	push	dx
	mov	dh,[di]
	mov	cx,[di+1]
	call	LAB_0c37
	call	LAB_0a05
	jnc	LAB_0dc5
	pop	ax
	jmp	SHORT LAB_0d72

LAB_0dc5:
	inc	ax
	mov	ah,al
	sub	al,[bp+0]
	jnz	LAB_0dd1
	pop	ax
	jmp	LAB_0d02

LAB_0dd1:
	neg	al
	add	[bp+1],ah
	mov	[bp+0],al
	mov	ax,[di+1]
	mov	dl,al
	and	dl,3Fh
	mov	dh,[di]
	and	dh,1Fh
	inc	dx
	cmp	dl,11h
	jc	LAB_0dfd
	xor	dl,dl
	inc	dh
	cmp	dh,bl
	jc	LAB_0dfd
	xor	dh,dh
	add	ah,1
	jnc	LAB_0dfd
	add	al,40h
LAB_0dfd:
	inc	dx
	and	al,0C0h
	or	al,dl
	mov	[bp+2],ax
	mov	[bp+5],dh
	pop	ax
	jmp	LAB_0ce6

LAB_0e0c:
	cmp	ah,0BBh
	jz	LAB_0e2c
	cmp	BYTE [442h],90h
	jnz	LAB_0e2c
	push	ax
	mov	ax,1
	call	LAB_08b0
	jnc	LAB_0e26
LAB_0e21:
	call	LAB_158c
	jmp	SHORT LAB_0e2b
LAB_0e26:
	call	LAB_0af8
	jc	LAB_0e21
LAB_0e2b:
	pop	ax
LAB_0e2c:
	ret

;-------------------------------------------------------------------------------
; timer_delay
;-------------------------------------------------------------------------------
; Waits for the specified number of timer ticks to occur.
;-------------------------------------------------------------------------------
; Input:
;  CX = Number of timer ticks to wait fro
; Output:
;  Nothing
;  CX destroyed
;-------------------------------------------------------------------------------
timer_delay:
	push	bx			; Save register
	xor	bx,bx			; Starting count
	cli				; No interrupts while we setup
	add	cx,[TIMER_TICKS]	; Add current low count to expected count
	adc	bx,[TIMER_TICKS+2]	; Get current high count + carry
	sti				; Interrupts back on
LAB_0e3a:
	call	timer_check		; Check if we're there yet
	ja	LAB_0e3a		; No, check again
	pop	bx			; Restore register
	ret				; Return to caller

;-------------------------------------------------------------------------------
; timer_check
;-------------------------------------------------------------------------------
; Checks if the specified timer tick number has elapsed
;-------------------------------------------------------------------------------
; Input:
;  BX = High byte of expected timer tick
;  CX = Low byte of expected timer tick
; Output:
;  AF,ZF,CF set accordingly
;-------------------------------------------------------------------------------
timer_check:
	cli				; Interrupts disabled
	cmp	bx,[TIMER_TICKS+2]	; Check high byte
	jnz	LAB_0e4c		; If no match, no need to keep checking
	cmp	cx,[TIMER_TICKS]	; Check low byte
LAB_0e4c:
	sti				; Interrupts back on
	ret				; Return to caller

LAB_0e4e:
	xor	bx,bx
	mov	cx,21Ch
	cli
	add	cx,[46Ch]
	adc	bx,[46Eh]
	sti
LAB_0e5d:
	push	bx
	push	cx
	mov	ah,10h
	call	LAB_1309
	pop	cx
	pop	bx
	jnc	LAB_0e85
	call	timer_check
	jc	LAB_0e85
	push	cx
	mov	cx,12h
	call	timer_delay
	pop	cx
	cmp	ah,80h
	jc	LAB_0e5d
	mov	ah,0Dh
	call	LAB_1309
	xor	cx,cx
	xor	bx,bx
	jmp	SHORT LAB_0e5d
LAB_0e85:
	ret

LAB_0e86:
	push	ax
	test	byte [bp+19h],10h
	jz	LAB_0ea3
	cli
	in	al,21h
	jmp	SHORT LAB_0e92
LAB_0e92:
	or	al,20h
	out	21h,al
	mov	ax,[bp+1Ah]
	mov	[34h],ax
	mov	ax,[bp+1Ch]
	mov	[36h],ax
	sti
LAB_0ea3:
	mov	al,7
	out	0Ah,al
	mov	dx,323h
	mov	cx,4
	mov	al,0
LAB_0eaf:
	out	dx,al
	jmp	SHORT LAB_0eb2
LAB_0eb2:
	add	dx, byte 4
	loop	LAB_0eaf
	call	check_not_ready
	cmp	byte [447h],0FFh
	jnz	LAB_0f21
	test	byte [442h],80h
	jz	LAB_0f21
	mov	dx,[444h]
	rol	dl,1
	rol	dl,1
	and	dl,3
	xchg	dh,dl
	mov	cx,4
	xor	di,di
	mov	bh,[bp+21h]
	push	ds
	push	ss
	pop	ds
	lea	si,[bp+22h]
LAB_0ee3:
	rol	bh,1
	rol	bh,1
	mov	ah,bh
	and	ah,3
	lodsb
	cmp	ax,dx
	ja	LAB_0ef8
	mov	di,ax
	loop	LAB_0ee3
	pop	ds
	jmp	SHORT LAB_0f21

LAB_0ef8:
	pop	ds
	sub	dx,di
	xchg	dh,dl
	ror	dl,1
	ror	dl,1
	and	WORD [444h],BYTE 3Fh
	or	[444h],dx
	test	byte [bp+1Fh],1
	jnz	LAB_0f21
	mov	ch,4
	sub	ch,cl
	mov	cl,5
	shl	ch,cl
	and	byte [443h],1Fh
	or	[443h],ch
LAB_0f21:
	and	byte [bp+19h],8Fh
	pop	ax
	neg	ah
	neg	ah
	ret

;-------------------------------------------------------------------------------
; check_not_ready / check_drive_not_ready
;-------------------------------------------------------------------------------
; Checks that the drive is not ready and not selected. For check_drive_not_ready
; the drive is selected by specifying its status register value in DX. FOr
; check_not_ready, this is selected based on the value of DL in the context
;-------------------------------------------------------------------------------
; Input:
;  BP = Request context (only check_not_ready)
;  DX = Status register for drive (only used by check_drive_not_ready)
; Output:
;  DX = Status register for drive (unchanged in check_drive_not_ready)
;  On success:
;   CF cleared
;  On error:
;   CF set
; AL destroyed
;-------------------------------------------------------------------------------
check_not_ready:
	mov	dl,[bp+CTX.bp4DX]	; Get saved DL value
	and	dx,byte 0Ch		; Each 4 drives = 1 controller
	add	dx,321h			; Add 1st cntlr status reg value
check_drive_not_ready:
	push	cx			; Save register
	mov	cx,4000h		; Retry counter
LAB_0f39:
	in	al,dx			; Read status register
	test	al,9			; Check for READY or SEL
	jz	LAB_0f4a		; None set, branch
	and	al,0Fh			; Zero high nibble
	cmp	al,0Fh			; Check for SEL, COM/DATA,
					; IN/OUT, and READY
	jnz	LAB_0f47		; Branch if some set
	dec	dx			; Data register
	in	al,dx			; Read from data register
	inc	dx			; Back to status register
LAB_0f47:
	loop	LAB_0f39		; Try again, if able
	stc				; Error return
LAB_0f4a:
	pop	cx			; Restore register
	ret				; Return to caller

print_init_error:
	push	ds
	push	cs
	pop	ds
	mov	si,init_err_msg		; First message
	call	print_string		; Print it
	mov	al,bh			; Print first character of error code
	mov	ah,0Eh			; Teletype output
	int	10h			; Print it
	mov	si,init_err_msg2	; Second message
	call	print_string		; Print it
	es mov	al,[SAVED_NUM_DRIVES]	; Get drive number
	add	al,30h			; Make it an ascii character
	mov	ah,0Eh			; Teletype output
	int	10h			; Output character
	mov	si,error_msg		; Third message
	call	print_string		; Print it
	pop	ds
	mov	word [bp+CTX.bp16BP],0Fh
	ret				; Return to caller

init_err_msg:
	db	'1701(',0
init_err_msg2:
	db	') -- Controller #',0
error_msg:
	db	' Error',13,10,0
LAB_0f99:
	db	13,10,'Error reading',0
LAB_0fa9:
	db	13,10,'Invalid',0
boot_retry_msg:
	db	' fixed disk boot block.',13,10
	db	'Please insert a bootable diskette into',13,10
	db	'drive A: and press ENTER key when ready ...',0

;-------------------------------------------------------------------------------
; boot_err
;-------------------------------------------------------------------------------
; Writes the boot failure messages and waits for ENTER key.
;-------------------------------------------------------------------------------
; Input:
;  CS:SI = First message to print
; Output:
; AX,BL,SI destroyed
;-------------------------------------------------------------------------------
boot_err:
	call	clear_screen		; Clear the screen
	push	ds			; Save value
	push	cs
	pop	ds			; DS = CS
	call	print_string		; Print caller-provided string
	mov	si,boot_retry_msg	; Next part of the message
	call	print_string		; Print it
	pop	ds			; Restore DS
LAB_1030:
	xor	ah,ah			; Get keystroke
	int	16h			; Do it (waiting)
	cmp	al,0Dh			; Is it ENTER?
	jnz	LAB_1030		; No, get another one.
	call	clear_screen		; Clean up screen
	ret				; Return to caller

;-------------------------------------------------------------------------------
; clear_screen
;-------------------------------------------------------------------------------
; Clear the screen maintaining the current video mode.
;-------------------------------------------------------------------------------
; Input:
;  Nothing
; Output:
;  AX destroyed
;-------------------------------------------------------------------------------
clear_screen:
	xor	ah,ah			; Set video mode
	mov	al,[VIDEO_MODE]		; to current video mode?
	int	10h			; Do it
	ret				; Return to caller

;-------------------------------------------------------------------------------
; print_string
;-------------------------------------------------------------------------------
; Prints a NULL-terminated string to the screen.
;-------------------------------------------------------------------------------
; Input:
;  DS:SI = The NULL-terminated string to print
; Output:
;  DS:SI = next character after end of string.
;  AX = 0E00h
;  BL = 0
;-------------------------------------------------------------------------------
print_string:
	mov	bl,0			; Set foreground color????
LAB_1046:
	lodsb				; Get next character
	or	al,al			; Is it zero?
	jz	LAB_1051		; Yes, finish it
	mov	ah,0Eh			; Teletype output
	int	10h			; Do it
	jmp	SHORT LAB_1046		; Repeat for next character
LAB_1051:
	ret

LAB_1052:
	mov	cx,0Ah
LAB_1055:
	push	cx
	mov	ax,0
	call	LAB_08b0
	jc	LAB_106f
	mov	cx,10h
LAB_1061:
	push	cx
	call	LAB_0af8
	jnc	LAB_106c
	pop	cx
	loop	LAB_1061
	jmp	SHORT LAB_107a

LAB_106c:
	pop	cx
	jz	LAB_107a
LAB_106f:
	xor	cx,cx
LAB_1071:
	loop	LAB_1071
LAB_1073:
	loop	LAB_1073
	pop	cx
	loop	LAB_1055
	stc
	push	cx
LAB_107a:
	pop	cx
	ret

LAB_107c:
	mov	ah,0
	mov	ch,[bp+1Fh]
	and	ch,0F0h
	mov	cl,4
	mov	bl,[bp+20h]
	mov	dl,0
LAB_108b:
	mov	bh,0
	shl	bx,1
	shl	bx,1
	shl	ch,1
	jc	LAB_10a2
	cmp	al,bh
	jbe	LAB_10a9
	sub	al,bh
	dec	al
	neg	bh
	adc	dl,0
LAB_10a2:
	add	ah,4
	loop	LAB_108b
	stc
	ret
LAB_10a9:
	add	al,ah
	mov	[bp+4],al
	ret

LAB_10af:
	mov	bl,[bp+4]
	and	bl,3
	mov	bh,0
LAB_10b7:
	mov	si,bx
	mov	dx,[bp+si+21h]
	mov	ch,[bp+21h]
	jz	LAB_10ce
	mov	cl,bl
	add	cl,bl
	rol	ch,cl
	mov	bh,ch
	and	bh,3
	mov	bl,dl
LAB_10ce:
	mov	dl,dh
	rol	ch,1
	rol	ch,1
	mov	dh,ch
	and	dx,3FFh
	jz	LAB_10df
	mov	cx,bx
	ret
LAB_10df:
	and	si,si
	jnz	LAB_10e9
	test	byte [bp+1Fh],1
	jnz	LAB_10eb
LAB_10e9:
	stc
	ret

LAB_10eb:
	add	bl,3
	jmp	SHORT LAB_10b7

LAB_10f0:
	mov	ax,[bp+18h]
	and	ax,0Fh
	mov	[bp+10h],ax
	ret

LAB_10fa:
	mov	ax,[bp+10h]
	and	ax,0Fh
	and	word [bp+18h],BYTE -16
	or	[bp+18h],ax
	call	LAB_14d8
	jnc	LAB_110f
	mov	ax,0BB00h
LAB_110f:
	ret

LAB_1110:
	mov	al,[bp+10h]
	call	LAB_107c
	mov	[bp+10h],al
	jnc	LAB_111e
	mov	ax,8000h
LAB_111e:
	ret

LAB_111f:
	push	ds
	push	es
	mov	es,[bp+14h]
	mov	di,[bp+10h]
	mov	byte [bp+4],0
	mov	cx,cs
	and	ch,0F9h
LAB_1130:
	push	cx
	push	di
	mov	ax,cx
	call	get_plus_version
	pop	di
	pop	cx
	jz	LAB_1145
	call	LAB_0a93
	mov	ax,si
	stosw
	mov	ax,ds
	jmp	SHORT LAB_1146
LAB_1145:
	stosw
LAB_1146:
	stosw
	add	byte [bp+4],4
	add	ch,2
	test	ch,6
	jnz	LAB_1130
	pop	es
	pop	ds
	clc
	ret

LAB_1157:
	pop	ax
	call	LAB_116d
	mov	byte [bp+1],0
	mov	bl,ah
	mov	bh,0
	shl	bx,1
	cs mov	ax,[bx+488h]
	jmp	LAB_067d

LAB_116d:
	mov	si,[bp+10h]
	mov	ds,[bp+14h]
LAB_1173:
	lea	di,[bp+8]
	push	ss
	pop	es
	mov	cx,6
	rep movsw
	mov	di,0
	mov	ds,di
	mov	es,di
	mov	ax,[bp+12h]
	mov	[bp+0],ax
	mov	cx,[bp+0Eh]
	mov	[bp+2],cx
	mov	dx,[bp+0Ch]
	mov	[bp+4],dx
	ret

LAB_1197:
	pop	ax
	mov	si,[bp+10h]
	mov	ds,[bp+14h]
	mov	[bp+6],si
	mov	word [si+0Ch],0
	mov	word [si+0Eh],0
	call	LAB_1173
	call	LAB_06ae
	jc	LAB_11c0
	or	byte [bp+19h],40h
	cs call	[bx+1B8Ch]
	and	byte [bp+19h],0BFh
LAB_11c0:
	jmp	LAB_069b

LAB_11c3:
	mov	si,sp
	push	ss
	pop	ds
	mov	di,[bp+6]
	mov	es,[bp+14h]
	es mov	word [di+0Ch],11FEh
	es mov	[di+0Eh],cs
	add	di,byte 10h
	stosw
	mov	ax,bx
	stosw
	mov	ax,cx
	stosw
	mov	ax,dx
	stosw
	lea	ax,[bp+26h]
	sub	ax,si
	stosw
	mov	cx,ax
	rep movsb
	xor	ax,ax
	mov	ds,ax
	mov	es,ax
	mov	[bp+12h],ax
	mov	[474h],ah
	jmp	LAB_06a5

LAB_11fe:
	call	save_ctx
	lea	si,[bx+18h]
	mov	ds,[bp+14h]
	lodsw
	mov	cx,ax
	lea	di,[bp+26h]
	sub	di,ax
	mov	sp,di
	push	ss
	pop	es
	rep movsb
	mov	[bp+6],bx
	mov	[bp+14h],ds
	mov	word [bx+0Ch],0
	mov	word [bx+0Eh],0
	lea	si,[bx+10h]
	lodsw
	mov	dx,ax
	lodsw
	mov	bx,ax
	lodsw
	mov	cx,ax
	lodsw
	xchg	ax,dx
	mov	di,0
	mov	ds,di
	mov	es,di
	ret

LAB_123b:
	test	byte [bp+1Fh],1
	jz	LAB_1246
	mov	bx,0FFFFh
	jmp	SHORT LAB_1272

LAB_1246:
	mov	al,[bp+20h]
	mov	bx,0
	mov	ch,[bp+1Fh]
	and	ch,0F0h
	mov	cl,4
LAB_1254:
	mov	ah,0
	shl	ax,1
	shl	ax,1
	shl	ch,1
	jc	LAB_1262
	inc	ah
	add	bl,ah
LAB_1262:
	loop	LAB_1254
	mov	bh,bl
	xchg	[475h],bh
	mov	[bp+1Eh],bl
	push	bx
	call	LAB_14d8
	pop	bx
LAB_1272:
	mov	[bp+0Eh],bx
	clc
	ret

LAB_1277:
	push	ds
	mov	si,[bp+10h]
	mov	ds,[bp+14h]
	lodsb
	mov	cl,al
	mov	al,7Fh
	ror	al,cl
	and	al,0F0h
	mov	ah,[bp+1Fh]
	and	ah,0Fh
	or	ah,1
	or	al,ah
	mov	[bp+1Fh],al
	mov	byte [bp+20h],0FFh
	lodsw
	mov	bx,ax
	lodsw
	shl	bh,1
	shl	bh,1
	or	ah,bh
	mov	bh,al
	mov	[bp+21h],ah
	mov	word [bp+22h],0
	mov	[bp+24h],bx
	and	byte [bp+18h],7Fh
	pop	ds
	mov	byte [475h],1
	mov	byte [bp+1Eh],1
LAB_12be:
	call	LAB_14d8
	jnc	LAB_12c6
	mov	ax,0BB00h
LAB_12c6:
	ret

LAB_12c7:
	or	byte [bp+1Fh],2
	jmp	SHORT LAB_12be

LAB_12cd:
	push	es
	mov	di,[bp+10h]
	mov	es,[bp+14h]
	mov	ah,[bp+1Fh]
	test	ah,1
	jz	LAB_1303
	mov	al,0
LAB_12de:
	shl	ah,1
	jnc	LAB_12e6
	inc	al
	jmp	SHORT LAB_12de

LAB_12e6:
	stosb
	mov	al,[bp+21h]
	mov	ah,al
	and	ah,0Ch
	shr	ah,1
	shr	ah,1
	and	al,3
	mov	bx,[bp+24h]
	xchg	al,bl
	xchg	bh,bl
	stosw
	mov	ax,bx
	stosw
LAB_1300:
	pop	es
	clc
	ret

LAB_1303:
	es mov	byte [di],0FFh
	jmp	SHORT LAB_1300

LAB_1309:
	push	word [bp+12h]
	push	word [bp+0Eh]
	push	word [bp+0Ch]
	mov	[bp+12h],ax
	mov	[bp+0],ax
	mov	[bp+0Eh],cx
	mov	[bp+2],cx
	mov	dh,0
	mov	[bp+0Ch],dx
	mov	[bp+4],dx
	call	LAB_06ae
	jc	LAB_1333
	cs call	[bx+LAB_1b8c]
	call	LAB_0e86
LAB_1333:
	mov	dx,[bp+0Ch]
	pop	word [bp+0Ch]
	pop	word [bp+0Eh]
	pop	word [bp+12h]
	ret

LAB_1340:
	call	LAB_1403
	xor	bx,bx
	mov	cx,21Ch
	cli
	add	cx,[46Ch]
	adc	bx,[46Eh]
	sti
	xor	ax,ax
	xor	dx,dx
LAB_1356:
	push	ax
	push	dx
	push	bx
	push	cx
	mov	bx,4
	call	LAB_1446
	jc	LAB_13a7
	call	LAB_1459
	cmp	word [si+1FCh],4C50h
	jnz	LAB_13a6
	cmp	word [si+1FEh],5355h
	jnz	LAB_13a6
	call	LAB_1463
	cmp	ah,0DBh
	jnz	LAB_13a6
	pop	di
	pop	cx
	pop	bx
	pop	dx
	pop	ax
	cmp	[si-5],al
	jz	LAB_1397
	xchg	ax,dx
	cmp	[si-5],al
	jz	LAB_1397
	cmp	ah,dh
	jbe	LAB_1392
	xchg	ax,dx
LAB_1392:
	mov	al,[si-5]
	mov	ah,0
LAB_1397:
	mov	ds,di
	inc	ah
	cmp	ah,9
	jc	LAB_13ab
	xor	ax,ax
LAB_13a2:
	call	LAB_1428
	ret

LAB_13a6:
	pop	ds
LAB_13a7:
	pop	cx
	pop	bx
	pop	dx
	pop	ax
LAB_13ab:
	call	timer_check
	jc	LAB_13bb
	cmp	byte [bp+2],0D1h
	jnc	LAB_13c0
	inc	byte [bp+2]
	jmp	SHORT LAB_1356

LAB_13bb:
	mov	ax,8000h
	jmp	SHORT LAB_13a2

LAB_13c0:
	mov	ax,0BB00h
	jmp	SHORT LAB_13a2

LAB_13c5:
	call	LAB_1403
	call	LAB_1459
	mov	word [si+1FCh],4C50h
	mov	word [si+1FEh],5355h
	mov	byte [si+1FBh],25h
	call	LAB_1463
	neg	ah
	mov	[si-5],ah
	pop	ds
	mov	ax,0BB00h
	push	ax
LAB_13e9:
	mov	bx,6
	call	LAB_1446
	jc	LAB_13f3
	pop	bx
	push	ax
LAB_13f3:
	cmp	byte [bp+2],0D1h
	jnc	LAB_13fe
	inc	byte [bp+2]
	jmp	SHORT LAB_13e9
LAB_13fe:
	pop	ax
	call	LAB_1428
	ret

LAB_1403:
	push	ds
	mov	ds,[bp+14h]
	mov	bx,[bp+10h]
	mov	dl,[bx]
	pop	ds
	shl	dl,1
	shl	dl,1
	mov	ax,[bp+8]
	xchg	[bp+14h],ax
	mov	[bp+8],ax
	inc	word [bp+10h]
	mov	word [bp+2],0FFC1h
	mov	dh,0
	mov	[bp+4],dx
	ret

LAB_1428:
	push	ax
	mov	word [bp+2],1
	mov	bx,18h
	call	LAB_1446
	dec	word [bp+10h]
	mov	bx,[bp+14h]
	xchg	[bp+8],bx
	mov	[bp+14h],bx
	pop	ax
	neg	ah
	neg	ah
	ret

LAB_1446:
	mov	word [bp+0],1
	cs mov	ax,[bx+488h]
	cs call	[bx+1B8Ch]
	call	LAB_0e86
	ret

LAB_1459:
	pop	ax
	push	ds
	mov	ds,[bp+8]
	mov	si,[bp+10h]
	jmp	ax

LAB_1463:
	mov	cx,200h
	mov	ah,0
LAB_1468:
	lodsb
	add	ah,al
	loop	LAB_1468
	ret

;-------------------------------------------------------------------------------
; get_plus_version
;-------------------------------------------------------------------------------
; Input:
;  AX = Segment to check
; Output:
;  If PLUS version is detected:
;    CF clear
;    AH = Major version
;    AL = Minor version
;    Note: for major version < 5, low nibble of AL is always zero.
;  If PLUS version is not detected:
;    CF set
;    AX = 0
;  BX,CX,DX,DI are destroyed
;-------------------------------------------------------------------------------
get_plus_version:
	push	ds
	push	es
	mov	ds,ax		; Address target segment
	mov	es,ax		; Address target segment
	mov	di,0		; Start of segment
	mov	ax,[di]		; Read first word
	push	bx
	pop	bx
	cmp	ax,0AA55h	; Is option BIOS signature present?
	jz	LAB_1485	; Yes, branch

	xor	ax,ax		; No version
	stc			; Error return
	jmp	SHORT LAB_14d5	; Exit

LAB_1485:
	mov	cx,96h		; Max bytes to check
	mov	al,'P'		; Initial character to check
LAB_148a:
	jcxz	LAB_14d3	; Branch if done
	repne scasb		; Search for string
	jnz	LAB_14d3	; Branch if not found
	cmp	word [di],'LU'	; Do next bytes match?
	jnz	LAB_148a	; No, look for next string
	cmp	byte [di+2],'S'	; Does it match next byte?
	jnz	LAB_148a	; No, look for next string
	mov	al,'V'		; Next character to check
LAB_149e:
	jcxz	LAB_14d3	; Branch if done
	repne scasb		; Search for string
	jnz	LAB_14d3	; Branch if not found
	cmp	word [di],'er'	; Do next byes match?
	jnz	LAB_149e	; No, branch
	mov	al,'.'		; Does it match next byte?
	jcxz	LAB_14d3	; Branch if done
	repne scasb		; Search for next string
	jnz	LAB_14d3	; Branch if not found

	mov	al,[di]		; Minor version
	mov	ah,[di-2]	; Major version
	sub	ax,3030h	; Convert to numbers

	cmp	ah,5		; Is it major version 5 or greater?
	jc	LAB_14cf	; No, just return
	mov	ch,ah		; Major version in CH

	mov	cl,10
	mul	cl		; AX = minor * 10

	mov	ah,[di+1]	; Get next digit of minor version
	sub	ah,30h		; Convert to number
	add	al,ah		; Add it to minor version
	mov	ah,ch		; Put major version in AH
LAB_14cf:
	and	ax,ax		; Set ZF and CF
	jmp	SHORT LAB_14d5	; Successful exit

LAB_14d3:
	xor	ax,ax		; No version detected
LAB_14d5:
	pop	es
	pop	ds
	ret			; Return to caller


LAB_14d8:
	push	word [bp+18h]
	mov	byte [bp+19h],25h
	call	get_checksum
	neg	ah
	mov	[bp+19h],ah
	mov	al,0
	lea	si,[bp+18h]
	mov	bx,1E0Eh
	call	send_command
	pop	word [bp+18h]
	ret

;-------------------------------------------------------------------------------
; get_checksum
;-------------------------------------------------------------------------------
; Gets the sum of the CDB
;-------------------------------------------------------------------------------
; Input:
;  SS:BP = context base
; Output:
;  AH = Calculated checksum
; AL, CX, SI destroyed
;-------------------------------------------------------------------------------
get_checksum:
	push	ds		; Save segment
	push	ss		; Address SS...
	pop	ds		; ... as DS
	lea	si,[bp+18h]	; Will read from SS:BP+18h
	mov	cx,0Eh		; 14 bytes
	mov	ah,0		; Start counter
LAB_1501:
	lodsb			; Load byte
	add	ah,al		; Add it
	loop	LAB_1501	; Loop until done
	pop	ds		; Restore segment
	ret			; Return to caller

;-------------------------------------------------------------------------------
; send_command
;-------------------------------------------------------------------------------
; Send a command to the controller.
;-------------------------------------------------------------------------------
; Input:
;  AL = LUN + Head? (opcode?)
;  BH = Class & Opcode? (operation type? 1Fh = read, else = write)
;  BL = Data length
;  SS:SI = Data to write (when BH != 1Fh)
;  SS:DI = Data to read (when BH = 1Fh)
; Output:
;  On success:
;   CF clear
;   If BH = 1F: SS:DI contains read data
;  On error:
;   CF set
;  BX,CX,DX,SI,DI destroyed
;-------------------------------------------------------------------------------
send_command:
	mov	dx,321h			; Base I/O port
	mov	cx,cs			; Code segment
	and	ch,2			; Preserve lower 2 bits
					; of high part of CS
	shl	ch,1			; Multiply by 2
	add	dl,ch			; Add to I/O port address
	mov	ah,2			; Retry counter
LAB_1516:
	push	ax
	call	check_drive_not_ready	; Ensure not selected
	jc	LAB_1530		; Branch on error
	inc	dx			; Point to config register
	out	dx,al			; Select controller
	jmp	SHORT LAB_1520		; Delay
LAB_1520:
	dec	dx			; Point to status register
	xor	cx,cx			; Retry counter
	mov	ah,4			; Secondary retry counter
LAB_1525:
	in	al,dx			; Read status register
	cmp	al,0CDh			; Ready to receive command?
	jz	LAB_1532		; Yes, branch
	loop	LAB_1525		; Retry
	dec	ah			; Decrement secondary retry
	jnz	LAB_1525		; Retry
LAB_1530:
	jmp	SHORT LAB_157f		; Jump failure

LAB_1532:
	dec	dx			; Point to data register
	mov	al,bh
	out	dx,al			; (B0) Opcode
	jmp	SHORT LAB_1538
LAB_1538:
	pop	ax			; Peek next byte
	push	ax
	out	dx,al			; (B1) LUN + Head
	jmp	SHORT LAB_153d
LAB_153d:
	mov	al,bl			; TODO: Data length?????
	mov	cx,4			; Transfer 4 bytes
LAB_1542:
	out	dx,al			; (B2-5)
	loop	LAB_1542		; Continue loop
	inc	dx			; Point to status register
	xor	cx,cx			; Zero counter
	cmp	bh,1Fh			; Is this opcode?
	jz	LAB_1566		; Yes, skip sending data
LAB_154d:
	in	al,dx			; Read status
	cmp	al,0C9h			; Controller ready to receive data?
	jz	LAB_1556		; Yes, branch
	loop	LAB_154d		; Try again
	jmp	SHORT LAB_157f		; Error return
LAB_1556:
	dec	dx			; Point to data register
	mov	cl,bl			; Number of bytes to send
	mov	ch,0			; Zero high part
	push	ds			; Save segment register
	push	ss			; Use SS...
	pop	ds			; ... as DS
LAB_155e:
	lodsb				; Load data byte
	out	dx,al			; Write data byte
	loop	LAB_155e		; Loop until done with data bytes
	pop	ds			; Restore segment
	jmp	SHORT LAB_157c		; Finish up

	nop

LAB_1566:
	in	al,dx			; Read status register
	cmp	al,0CBh			; Controller ready to send data?
	jz	LAB_156f		; Yes, branch
	loop	LAB_1566		; Try again
	jmp	SHORT LAB_157f		; Error return
LAB_156f:
	dec	dx			; Point to data register
	mov	cl,bl			; Number of bytes to read
	mov	ch,0			; Zero high part
	push	es			; Save segment
	push	ss			; Use SS...
	pop	es			; ... as ES
LAB_1577:
	in	al,dx			; Read data byte
	stosb				; Store it
	loop	LAB_1577		; Loop until no more bytes to read
	pop	es			; Restore segment
LAB_157c:
	inc	dx			; Point to status register
LAB_157d:
	pop	ax			; Restore register
LAB_157e:
	ret				; Return to caller

LAB_157f:
	call	LAB_1596		; Reset drive
	jc	LAB_157d		; Branch if error
	pop	ax
	dec	ah			; Decrement retry
	stc				; Error return
	jz	LAB_157e		; Exit if retries exhausted
	jmp	SHORT LAB_1516		; Otherwise continue (ignore carry)

LAB_158c:
	mov	dl,[bp+4]
	and	dx,byte 0Ch
	add	dx,321h
LAB_1596:
	push	bx			; Save registers
	push	si
	xor	bx,bx			; Zero count
	mov	cx,36h			; Delay timer tick count
	cli				; Interrupts disabled
	add	cx,[TIMER_TICKS]	; Add currrent timer count
	adc	bx,[TIMER_TICKS+2]	; Add high part and carry
	sti				; Interrupts back on
	push	cx			; Save register
	mov	si,0
	jmp	SHORT LAB_15f1

LAB_15ad:
	pop	cx			; Restore register
	call	timer_check		; Check if we're there yet
	ja	LAB_15bb		; Yes, exit loop
	out	dx,al			; Reset controller
	xor	cx,cx			; Delay
LAB_15b6:
	loop	LAB_15b6		; Delay loop
	stc				; Error return
	jmp	SHORT LAB_15f9		; Return to caller

LAB_15bb:
	in	al,dx
	push	ax
	and	al,0F9h
	cmp	al,0C0h
	pop	ax
	jz	LAB_15f8
	push	cx
	cmp	al,0CFh
	jnz	LAB_15ce
	dec	dx
	in	al,dx
	inc	dx
	jmp	short LAB_15ad

LAB_15ce:
	cmp	al,0CDh
	jnz	LAB_15e5
	mov	al,0
	mov	cx,6
	dec	dx
LAB_15d8:
	out	dx,al
	jmp	SHORT LAB_15db
LAB_15db:
	loop	LAB_15d8
	inc	dx
	mov	cx,4000h
LAB_15e1:
	loop	LAB_15e1
	jmp	SHORT LAB_15ad

LAB_15e5:
	inc	si
	test	si,1
	jnz	LAB_15f1
	inc	dx
	out	dx,al
	dec	dx
	jmp	SHORT LAB_15ad

LAB_15f1:
	out	dx,al			; Reset controller
	xor	cx,cx			; Delay counter
LAB_15f4:
	loop	LAB_15f4		; Delay
	jmp	SHORT LAB_15ad		; Continue

LAB_15f8:
	clc
LAB_15f9:
	pop	si			; Restore registers
	pop	bx
	ret				; Return to caller

LAB_15fc:
	call	LAB_10af
	sub	dx,cx
	dec	dx
	mov	ax,11h
	mul	dx
	push	ds
	call	LAB_0a93
	mov	dl,[si+2]
	pop	ds
	mov	dh,0
	mul	dx
	mov	[bp+0Eh],dx
	mov	[bp+0Ch],ax
	mov	word [bp+12h],300h
	pop	ax
	xor	ax,ax
	jmp	LAB_069e

LAB_1624:
	xor	ax,ax
	mov	[bp+0Eh],ax
	mov	[bp+0Ch],ax
	mov	[bp+12h],ax
	stc
	ret

LAB_1631:
	test	byte [bp+18h],20h
	jz	LAB_163a
	jmp	LAB_0c92
LAB_163a:
	mov	ax,100h
	ret

LAB_163e:
	db	'*** Fixed Disk BIOS Error ***',0
LAB_165c:
	db	13,13,'A low-level format operation has been attempted that would result in the loss'
	db	13,'of media defect information recorded at the factory.  This operation has been'
	db	13,'interrupted so no data or media defect information would be lost.'
	db	13,13,'Please press CTRL-ALT-DEL to reboot your system.',0

LAB_176e:
	test	byte [bp+18h],8
	jz	LAB_1777
	xor	ax,ax
	ret
LAB_1777:
	mov	ax,2
	int	10h
	mov	ah,1
	mov	cx,2000h
	int	10h
	mov	dx,918h
	mov	si,LAB_163e
	mov	bl,0Fh
	call	LAB_1798
	mov	si,LAB_165c
	mov	bl,7
	call	LAB_1798
LAB_1796:
	jmp	SHORT LAB_1796

LAB_1798:
	mov	bh,0
	push	ds
	push	cs
	pop	ds
	mov	cx,1
LAB_17a0:
	mov	ah,2
	int	10h
	lodsb
	cmp	al,0
	jz	LAB_17be
	cmp	al,0Dh
	jz	LAB_17b8
	mov	ah,9
	int	10h
	inc	dl
	cmp	dl,50h
	jc	LAB_17a0
LAB_17b8:
	inc	dh
	mov	dl,0
	jmp	SHORT LAB_17a0
LAB_17be:
	pop	ds
	ret

LAB_17c0:
	call	LAB_189f
	push	dx
	mov	dl,[bp+4]
	and	dx,BYTE 0Ch
	add	dx,321h
	mov	si,bx
	and	si,BYTE 0Fh
	and	bx,BYTE -16
	pop	cx
	or	bl,cl
	mov	cl,4
	ror	bx,cl
	mov	ds,bx
	mov	bh,9
	test	ah,2
	jz	LAB_17ed
	or	bh,2
	push	ds
	pop	es
	mov	di,si
LAB_17ed:
	mov	cx,200h
	test	ah,4
	jz	LAB_17f8
	mov	cx,204h
LAB_17f8:
	push	cx
	mov	cx,14h
LAB_17fc:
	push	cx
	xor	cx,cx
LAB_17ff:
	in	al,dx
	and	al,0Fh
	cmp	al,bh
	jz	LAB_1818
	cmp	al,0Fh
	jz	LAB_1815
	or	al,al
	jz	LAB_1814
	loop	LAB_17ff
	pop	cx
	loop	LAB_17fc
	push	cx
LAB_1814:
	stc
LAB_1815:
	pop	cx
LAB_1816:
	pop	cx
	ret

LAB_1818:
	pop	cx
	pop	cx
	push	cx
	test	bh,2
	jz	LAB_182d
LAB_1820:
	in	al,dx
	test	al,1
	jz	LAB_1820
	dec	dx
	in	al,dx
	stosb
	inc	dx
	loop	LAB_1820
	jmp	SHORT LAB_1838

LAB_182d:
	in	al,dx
	test	al,1
	jz	LAB_182d
	dec	dx
	lodsb
	out	dx,al
	inc	dx
	loop	LAB_182d
LAB_1838:
	clc
	jmp	SHORT LAB_1816

LAB_183b:
	push	ax
	mov	al,[bp+0]
	xor	ah,ah
	mov	bl,11h
	div	bl
	mov	bl,[bp+2]
	add	bl,ah
	mov	bh,bl
	and	bh,3Fh
	cmp	bh,11h
	jbe	LAB_185f
	sub	bh,11h
	and	bl,0C0h
	or	bl,bh
	inc	byte [bp+5]
LAB_185f:
	mov	[bp+2],bl
	push	ds
	call	LAB_0a93
	mov	bh,[si+2]
	pop	ds
	xor	ah,ah
	div	bh
	mov	bl,[bp+5]
	add	bl,ah
	cmp	bl,bh
	jc	LAB_187b
	sub	bl,bh
	inc	al
LAB_187b:
	add	[bp+3],al
	jnc	LAB_1884
	add	byte [bp+2],40h
LAB_1884:
	mov	[bp+5],bl
	pop	ax
	ret

LAB_1889:
	push	ax
	call	LAB_189f
	mov	ax,bx
	not	ax
	xor	dx,dx
	add	ax,1
	adc	dx,BYTE 0
	div	cx
	mov	cx,ax
	pop	ax
	ret

LAB_189f:
	push	ax
	mov	bh,ah
	mov	ax,[bp+8]
	mov	cx,10h
	mul	cx
	add	ax,[bp+10h]
	adc	dx,BYTE 0
	mov	cx,200h
	test	bh,4
	jz	LAB_18bb
	or	cl,4
LAB_18bb:
	mov	bl,[bp+1]
	or	bl,bl
	jz	LAB_18d3
	push	dx
	push	ax
	mov	al,bl
	xor	ah,ah
	mul	cx
	pop	bx
	add	ax,bx
	adc	dx,BYTE 0
	pop	bx
	add	dx,bx
LAB_18d3:
	mov	bx,ax
	pop	ax
	ret

LAB_18d7:
	mov	dl,[bp+1Eh]
	push	dx
	or	dl,80h
	inc	byte [bp+1Eh]
	test	byte [7E0Ah],1
	jnz	LAB_18ed
	call	LAB_0e4e
	jnc	LAB_1905
LAB_18ed:
	mov	cx,2
	push	cx
LAB_18f1:
	mov	ah,0Dh
	call	LAB_1309
	pop	cx
	jnc	LAB_1905
	dec	cx
	jcxz	LAB_1933
	push	cx
	mov	cx,36h
	call	timer_delay
	jmp	SHORT LAB_18f1

LAB_1905:
	mov	ah,14h
	call	LAB_1309
	jc	LAB_1933
	test	byte [bp+18h],60h
	jnz	LAB_1920
	mov	ah,12h
	call	LAB_1309
	jc	LAB_1933
	mov	ah,0Fh
	call	LAB_1309
	jc	LAB_1933
LAB_1920:
	mov	ah,9
	call	LAB_1309
	jc	LAB_1933
	mov	ah,11h
	call	LAB_1309
	jc	LAB_1933
	call	LAB_19d8
	jnc	LAB_1945
LAB_1933:
	mov	bh,43h
LAB_1935:
	call	print_init_error
	pop	ax
	mov	[bp+1Eh],al
	or	bp,bp
	jmp	LAB_19d7

LAB_1941:
	mov	bh,44h
	jmp	SHORT LAB_1935

LAB_1945:
	test	byte [7E0Ah],2
	jz	LAB_194f
	jmp	LAB_19d4

LAB_194f:
	cmp	word [7E08h],BYTE 0
	jz	LAB_19d4
	mov	dl,[bp+4]
	and	dx,BYTE 0Ch
	add	dx,322h
	in	al,dx
	cmp	al,0F0h
	jnz	LAB_19d4
	mov	al,5

LAB_1967:
	push	ax
	push	word [bp+14h]
	push	word [bp+10h]
	mov	[bp+14h],ds
	mov	word [bp+10h],7BFFh
	mov	al,[7E04h]
	mov	[7BFFh],al
	call	LAB_1340
	pop	word [bp+10h]
	pop	word [bp+14h]
	pop	ax
	jnc	LAB_1999
	dec	al
	jz	LAB_1996
	pop	dx
	push	dx
	or	dl,80h
	call	LAB_19d8
	jnc	LAB_1967
LAB_1996:
	stc
	jmp	SHORT LAB_1941

LAB_1999:
	mov	si,7C00h
	lodsw
	or	al,al
	jz	LAB_19d4
	mov	bl,al
	mov	[bp+21h],ah
	lodsw
	mov	[bp+22h],ax
	lodsw
	mov	[bp+24h],ax
	and	bl,3
	add	[bp+1Eh],bl
	mov	cl,[7E04h]
	inc	cl
	shl	cl,1
	ror	bl,cl
	or	[bp+20h],bl
	mov	al,[7E05h]
	add	byte [7E05h],5
	lea	si,[bp+21h]
	mov	bx,1E05h
	call	send_command
	jc	LAB_19d7
LAB_19d4:
	pop	ax
	xor	ax,ax
LAB_19d7:
	ret

LAB_19d8:
	push	ax
	push	cx
	push	dx
	mov	cx,14h
	xor	dh,dh
LAB_19e0:
	push	cx
	mov	ah,0Ch
	mov	cx,6381h
	call	LAB_1309
	jc	LAB_1a09
	mov	ah,0Ch
	mov	cx,1
	call	LAB_1309
	jc	LAB_1a09
	pop	cx
	loop	LAB_19e0
	mov	cx,14h
LAB_19fb:
	push	cx
	mov	ah,10h
	call	LAB_1309
	pop	cx
	jnc	LAB_1a0a
	loop	LAB_19fb
	stc
	jmp	SHORT LAB_1a0a
LAB_1a09:
	pop	cx
LAB_1a0a:
	pop	dx
	pop	cx
	pop	ax
	ret

;-------------------------------------------------------------------------------
; check_video
;-------------------------------------------------------------------------------
; Checks the current video settings to see if directly accessing the video
; memory is an option.
;-------------------------------------------------------------------------------
; Input:
;  Nothing
; Output:
;  CF set if direct access is not possible, cleared if possible.
;  AX, BX, DX destroyed.
;-------------------------------------------------------------------------------
check_video:
	push	ds
	cmp	word INT_SEGMENT(10h),0F000h	; Is video BIOS part of system BIOS?
	jnz	LAB_1a42			; No, return error
	cmp	byte [VIDEO_MODE],7		; Is it 80x25 mono (MDA only)?
	jz	LAB_1a3f			; Yes, branch
	mov	bx,9Eh
	mov	ax,0B800h			; Address CGA buffer
	mov	ds,ax				; Set addressing
	mov	ax,72Bh				; Test value
	mov	dx,ax				; Save a copy
	xchg	[bx],ax				; Write it to CGA memory
	jmp	SHORT LAB_1a2f			; Delay
LAB_1a2f:
	jmp	SHORT LAB_1a31			; Delay
LAB_1a31:
	cmp	[bx],dx				; Compare with saved value
	jnz	LAB_1a42			; Doesn't match - return error
	mov	[bx],ax				; Restore previous value
	jmp	SHORT LAB_1a39
LAB_1a39:
	jmp	SHORT LAB_1a3b
LAB_1a3b:
	cmp	[bx],ax				; Check again
	jnz	LAB_1a42			; Doesn't match - return error
LAB_1a3f:
	clc					; Successful return
LAB_1a40:
	pop	ds
	ret					; Return to caller
LAB_1a42:
	stc					; Error return
	jmp	SHORT LAB_1a40


;-------------------------------------------------------------------------------
; detect_relocated_bios
;-------------------------------------------------------------------------------
; Tries to find a disk BIOS relocated to Int 40h. This is done by checking
; if the vector matches IBM BIOS' Int 13h vector. That would mean the BIOS
; has been relocated. If there isn't a match, we compare Int 40h's vector
; with with all interrupt vectors. If we have at least 3 matches, we
; assume it's not a relocated BIOS.
;-------------------------------------------------------------------------------
; Input:
;  None
; Output:
;  CF clear if relocated BIOS is detected.
;  CF set otherwise.
;   AX, BX, CX, DX, SI, DI destroyed
;-------------------------------------------------------------------------------
detect_relocated_bios:
	mov	si,0EC59h			; Diskette handler in IBM BIOS
	mov	di,0Fh				; Diskette handler in IBM BIOS
	mov	bx,INT_OFF_VAL(40h)		; Check Int 40h
	call	compare_vector			; Check it
	jz	LAB_1a6d			; Jump if a match
	mov	si,ax				; Now check for the vector we
	mov	di,dx				; Got in Int 40h
	xor	ch,ch				; Zero counter
	mov	bx,INT_OFF_VAL(0FFh)		; Check Int FFh
LAB_1a5c:
	call	compare_vector			; Check vector
	jnz	LAB_1a68			; Branch if no match
	inc	ch				; Increment counter
	cmp	ch,3				; Enough matches?
	jnc	LAB_1a70			; Yes, assume not relocated and
						; just no-op handler
LAB_1a68:
	sub	bx,BYTE VECTOR_size		; Move to the next vector
	jnc	LAB_1a5c			; Jump if not wrapped
LAB_1a6d:
	clc					; Relocated BIOS detected
	jmp	SHORT LAB_1a71
LAB_1a70:
	stc					; Relocated BIOS NOT detected
LAB_1a71:
	ret					; Return to caller

;-------------------------------------------------------------------------------
; compare_vector
;-------------------------------------------------------------------------------
; Compares the vector of the requested interrupt to the provided linear addr.
;-------------------------------------------------------------------------------
; Input:
;  BX = Address of the interrupt vector to check
;  DI = high 4 bits of the linear address
;  SI = low 16 bits of the linear address
; Output:
;  Flags set as result of comparison
;  AX = low 16 bits of linear address of interrupt vector
;  DX = high 4 bits of linear address of interrupt vector
;  CL destroyed
;-------------------------------------------------------------------------------
compare_vector:
	mov	ax,[bx+VECTOR.wSegment]		; Get segment address
	mov	cl,4
	rol	ax,cl				; High nibble goes to low nibble
	mov	dx,ax				; DX contains high 4 bits, AX low 12 bits
	and	dx,BYTE 0Fh			; We only care about low 4 bits
	and	ax,0FFF0h			; We only care about high 12 bits
	add	ax,[bx+VECTOR.wOffset]		; Add in the offset
	adc	dx,BYTE 0			; Carry to high value
	cmp	dx,di				; Compare low value
	jnz	LAB_1a8c			; Branch it no match
	cmp	ax,si				; Compare to high value
LAB_1a8c:
	ret					; Return to caller

init_drv_params:
	cli					; Interrupts disabled
	test	BYTE [bp+CTX.bp18],60h		; Running on PS/2 or AT?
	jz	LAB_1aba			; No, branch

	mov	al,0
	call	LAB_107c
	jc	LAB_1ac4
	push	ds
	call	LAB_0a93
	pop	ds
	mov	INT_OFFSET(41h),si
	mov	al,1
	call	LAB_107c
	jc	LAB_1ac0
	push	ds
	call	LAB_0a93
	pop	ds
	mov	INT_OFFSET(46h),si
	mov	INT_SEGMENT(46h),cs
	jmp	SHORT LAB_1ac0

LAB_1aba:
	mov	word INT_OFFSET(41h),LAB_03e7	; PC/XT drive table
LAB_1ac0:
	mov	INT_SEGMENT(41h),cs
LAB_1ac4:
	sti
	ret

;-------------------------------------------------------------------------------
; INT 19h (Bootstrap) vector
;-------------------------------------------------------------------------------
LAB_1ac6:
	sti					; Interrupts enabled
	call	save_ctx			; Setup call context
	mov	al,0				; Opcode?
	lea	di,[bp+CTX.bp18]		; Destination address for read
	mov	bx,1F0Eh			; Read 14 bytes
	call	send_command			; Do it
	jc	LAB_1b00			; Branch on error
	call	get_checksum			; Calculate checksum
	cmp	ah,0DBh				; Is checksum correct?
	jnz	LAB_1b00			; No, branch away
	mov	bx,LAB_1bea			; AT floppy params
	test	byte [bp+18h],40h		; Running on AT?
	jnz	LAB_1af4			; Yes, skip rest
	mov	bx,LAB_1bf5			; PS/2 floppy params
	test	byte [bp+18h],20h		; Running on PS/2?
	jnz	LAB_1af4			; Yes, skip rest
	mov	bx,LAB_0201			; PC/XT floppy params
LAB_1af4:
	cli					; Interrupts disabled
	mov	INT_OFFSET(1Eh),bx		; Set floppy parameters
	mov	INT_SEGMENT(1Eh),cs
	call	init_drv_params			; Set hard drive parameters
LAB_1b00:
	mov	word [bp+1Ch],LAB_1b08		; Set next routine
	jmp	SHORT restore_ctx

	nop

LAB_1b08:
	xor	dx,dx				; Double as first floppy and seg = 0
	mov	ds,dx
	call	read_boot			; Read boot sector
	jnc	LAB_1b2c			; Branch is successful read
	mov	dl,80h				; Now try with hard drive
	call	read_boot			; Read boot sector
	jnc	LAB_1b20			; Branch if successful read
	mov	si,LAB_0f99			; 'Error reading' message
LAB_1b1b:
	call	boot_err
	jmp	SHORT LAB_1ac6

LAB_1b20:
	es cmp	word [bx+1FEh],0AA55h		; Is bootable magic present?
	mov	si,0FA9h			; Non-bootable disk message
	jnz	LAB_1b1b			; No, branch to error
LAB_1b2c:
	jmp	0:7C00h				; Transfer control to boot sector

;-------------------------------------------------------------------------------
; read_boot
;-------------------------------------------------------------------------------
; Reads the boot sector of the specified device to memory where it's expected
; to be for booting.
;-------------------------------------------------------------------------------
; Input:
;  DH = Head number
;  DL = Drive number (as per Int 13h)
; Output:
;  On success:
;   CF clear
;   0:7C00h contains the boot sector's contents
;  On failure:
;   CF set
;  AX,CX destroyed
;  BX set to 7C00h
;  ES set to zero
;-------------------------------------------------------------------------------
read_boot:
	mov	cx,5				; Retry count
LAB_1b34:
	push	cx				; Save retry counter
	xor	ax,ax				; Reset disk system
	int	13h				; Call disk BIOS
	mov	ax,201h				; Read 1 sector
	mov	bx,7C00h			; To 7C00h
	xor	cx,cx				; 
	mov	es,cx				; Will read from Seg = 0
	inc	cx				; Read cyl 0, sec 1
	int	13h				; Do it
	pop	cx				; Restore counter
	jc	LAB_1b4a			; Branch on error
	ret					; Successful return
LAB_1b4a:					; Error handling
	cmp	ah,80h				; Is drive not ready?
	jz	LAB_1b51			; Yes, just error out
	loop	LAB_1b34			; No, loop while retries last
LAB_1b51:
	stc					; Error return
	ret					; Return to caller

;-------------------------------------------------------------------------------
; save_ctx
;-------------------------------------------------------------------------------
; Establishes the context structure expected by most of the BIOS code
;-------------------------------------------------------------------------------
; Input:
;  Calling context
; Output:
;  BP set pointing to context
;  DS and ES set to 0
;  DF cleared
;-------------------------------------------------------------------------------
save_ctx:
	sub	sp,BYTE 0Ch
	push	bp
	push	ds
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	es
	push	di
	push	dx
	push	cx
	push	ax
	mov	bp,0
	mov	ds,bp
	mov	es,bp
	mov	bp,sp
	cld
	jmp	word [bp+CTX.bp24Caller]

;-------------------------------------------------------------------------------
; restore_ctx
;-------------------------------------------------------------------------------
; Tears down the calling context, restoring registers.
;-------------------------------------------------------------------------------
; Input:
;  BP = Calling context
; Output:
;  All registers and flags as needed to return
;-------------------------------------------------------------------------------
restore_ctx:
	lea	sp,[bp+CTX.bp6DI]; Discard temporary values
	pop	di
	pop	es
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	mov	[bp+1Ah],ax	; Save AX temporarily
	pop	ds
	pop	bp
	pop	ax		; 
	pushf			; Save flags temporarily
	and	ah,8Fh
	jz	LAB_1b87
	mov	dl,ah
LAB_1b87:
	popf			; Restore flags
	pop	ax		; Restore AX
	ret	8		; Return to [BP+1Ch]
				; Discard rest of stack frame

LAB_1b8c:
	dw	LAB_07f0
	dw	LAB_0816
	dw	LAB_0c92
	dw	LAB_0c92
	dw	LAB_0ce6
	dw	LAB_176e
	dw	LAB_176e
	dw	LAB_176e
	dw	LAB_081c
	dw	LAB_0852
	dw	LAB_0c92
	dw	LAB_0c92
	dw	LAB_0ce6
	dw	LAB_07f0
	dw	LAB_0c92
	dw	LAB_0c92
	dw	LAB_0ce6
	dw	LAB_0ce6
	dw	LAB_0ce6
	dw	LAB_0ce6
	dw	LAB_0ce6
	dw	LAB_07f0
	dw	LAB_0816
	dw	LAB_0c92
	dw	LAB_0c92
	dw	LAB_0ce6
	dw	LAB_176e
	dw	LAB_163a
	dw	LAB_163a
	dw	LAB_081c
	dw	LAB_0852
	dw	LAB_0c92
	dw	LAB_0c92
	dw	LAB_0ce6
	dw	LAB_07f0
	dw	LAB_1631
	dw	LAB_1631
	dw	LAB_0ce6
	dw	LAB_0ce6
	dw	LAB_163a
	dw	LAB_163a
	dw	LAB_0ce6
	dw	LAB_15fc
	dw	LAB_163a
	dw	LAB_163a
	dw	LAB_163a
	dw	LAB_0844

LAB_1bea:
	istruc	FLOPPYPARAMS
		AT	FLOPPYPARAMS.bFirstSpecify,	db	0DFh	; Step rate = 6ms
									; Head unload time = 240ms
		AT	FLOPPYPARAMS.bSecondSpecify,	db	02h	; Head load time = 4ms
		AT	FLOPPYPARAMS.bMotorDelay,	db	25h	; Delay until motor off, 25 ticks
		AT	FLOPPYPARAMS.bBytesPerSector,	db	02h	; 512 bytes
		AT	FLOPPYPARAMS.bSectorsPerTrack,	db	0Fh	; 15 sectors per track
		AT	FLOPPYPARAMS.bGapLength,	db	1Bh	; 3.5"
		AT	FLOPPYPARAMS.bDataLength,	db	0FFh	; Ignored
		AT	FLOPPYPARAMS.bGapLengthFormat,	db	54h	; Gap length???
		AT	FLOPPYPARAMS.bFormatFiller,	db	0F6h
		AT	FLOPPYPARAMS.bHeadSettleTime,	db	0Fh	; 15ms
		AT	FLOPPYPARAMS.bMotorStartTime,	db	08h	; 1s start time
LAB_1bf5:
	istruc	FLOPPYPARAMS
		AT	FLOPPYPARAMS.bFirstSpecify,	db	0AFh	; Step rate = 12ms
									; Head unload time = 240ms
		AT	FLOPPYPARAMS.bSecondSpecify,	db	02h	; Head load time = 4ms
		AT	FLOPPYPARAMS.bMotorDelay,	db	25h	; Delay until motor off, 25 ticks
		AT	FLOPPYPARAMS.bBytesPerSector,	db	02h	; 512 bytes
		AT	FLOPPYPARAMS.bSectorsPerTrack,	db	12h	; 18 sectors per track
		AT	FLOPPYPARAMS.bGapLength,	db	1Bh	; 3.5"
		AT	FLOPPYPARAMS.bDataLength,	db	0FFh	; Ignored
		AT	FLOPPYPARAMS.bGapLengthFormat,	db	6Ch	; Gap length for 3.5"
		AT	FLOPPYPARAMS.bFormatFiller,	db	0F6h
		AT	FLOPPYPARAMS.bHeadSettleTime,	db	01h	; 1ms
		AT	FLOPPYPARAMS.bMotorStartTime,	db	04h	; 0.5s start time

LAB_1c00:
	sti
	push	bp
	mov	bp,sp
	push	ax
	push	ds
	mov	ax,0
	mov	ds,ax
LAB_1c0b:
	test	word [bp+6],100h
	jnz	LAB_1c17
	add	bp,BYTE 6
	jmp	SHORT LAB_1c0b
LAB_1c17:
	mov	ax,[7E06h]
	cmp	ax,[bp+4]
	jnz	LAB_1c2d
	mov	ax,LAB_1c31
	mov	[bp+2],ax
	mov	[bp+4],cs
	and	word [bp+6],0FEFFh
LAB_1c2d:
	pop	ds
	pop	ax
	pop	bp
	iret

LAB_1c31:
	call	save_ctx
	mov	byte [bp+18h],0
	mov	byte [bp+19h],0
	cli
	mov	ax,[7E00h]
	mov	[4],ax
	mov	ax,[7E02h]
	mov	[6],ax
	sti
	jmp	LAB_03a0

LAB_1c4d:
	sub	sp,BYTE 0Ch
	push	cs
	call	LAB_1c79
	call	save_ctx
	mov	byte [bp+18h],0
	mov	byte [bp+19h],0
	mov	di,7E00h
	lea	si,[bp+26h]
	push	ss
	pop	ds
	mov	cx,6
	cld
	rep movsw
	mov	word [bp+1Ch],LAB_1c75
	jmp	restore_ctx

LAB_1c75:
	add	sp,BYTE 0Ch
	retf

LAB_1c79:
	call	save_ctx
	mov	si,7E00h
	lea	di,[bp+2Ah]
	push	ss
	pop	es
	mov	cx,6
	cld
	rep movsw
	push	ds
	pop	es
	mov	byte [7E0Ah],2
	jmp	LAB_0081
