
	%include "inc/config.inc"
	%include "inc/macros.inc"
	%include "inc/RamVars.inc"
	%include "inc/RomVars.inc"
	%include "inc/Ports.inc"
	%include "inc/BiosSeg.inc"

%ifdef V20
	CPU 186
%else
	CPU 8086
%endif

	ORG 0
	SECTION .text


istruc ROMVARS
	AT	ROMVARS.wBiosSignature,		dw	0AA55h		; BIOS signature (AA55h)
	AT	ROMVARS.bBiosLength,		db	64		; BIOS length in 512 btyes blocks
	AT	ROMVARS.rgbBiosEntry,		JMP	NEAR entry	; BIOS entry point
iend

LAB_0006:
	db	'VR9',0,0,0
	db	77h,0CCh

	db	'VIDEO ',0
	db	73h,4Fh,0B2h,07h,3Dh,29h,0E9h,1Eh,29h
	db	'IBM VGA Compatible'
	db	0F7h,0C8h,30h,0DFh,53h,2Eh,20h,0

LAB_0038:
	db	80h

LAB_0039:
	db	'CL-GD5429 VGA BIOS Version 1.00a    ',13,10
	db	'Copyright 1992-1994 Cirrus Logic, Inc. All Rights Reserved.',13,10
	db	'Copyright 1987-1990 Quadtel Corp. All Rights Reserved.',13,10
	db	0,0,0,0,0
	db	'STB Syste'
LAB_00e2:
	db	'ms, Inc.',13,10
	db	70 dup(0)
LAB_0132:
	db	1,0
LAB_0134:
	db	0

LAB_0135:
	push	cx
	mov	cx,0Ah
	mov	al,ah
	or	al,33h
LAB_013d:
	SHL	bx,1
	jnc	LAB_0143
	or	al,8
LAB_0143:
	call	LAB_020d
	or	al,4
	call	LAB_020d
	and	al,0F3h
	loop	LAB_013d
	pop	cx
	ret

LAB_0151:
	cs test	[1036h],BYTE 80h
	jnz	LAB_016a
	push	bx
	mov	bx,434Ch
	mov	ax,5000h
	call	LAB_01d7
	pop	bx
	mov	ax,5040h
	call	LAB_01d7
LAB_016a:
	ret

LAB_016b:
	push	cx
	mov	cx,10h
LAB_016f:
	and	al,0F3h
	rcl	bx,1
	jnc	LAB_0177
	or	al,8
LAB_0177:
	call	LAB_020d
	or	al,4
	call	LAB_020d
	in	al,dx
	loop	LAB_016f
	pop	cx
	ret

LAB_0184:
	cs test	[1036h],BYTE 80h
	jnz	LAB_01d1
	call	LAB_0233
	mov	bx,6000h
	call	LAB_0135
	call	LAB_0216
	push	bx
	call	LAB_024d
	call	LAB_0233
	mov	bx,6040h
	call	LAB_0135
	call	LAB_0216
	push	bx
	call	LAB_024d
	pop	bx
	pop	ax
	cmp	ax,434Ch
	jnz	LAB_01d1
	mov	dx,3C4h
	mov	al,9
	call	ReadIndirectRegister
	and	bl,0FCh
	and	ah,3
	or	ah,bl
	out	dx,ax
	inc	ax
	call	ReadIndirectRegister
	and	ah,0BFh
	and	bh,40h
	or	ah,bh
	out	dx,ax
LAB_01d1:
	mov	ax,448Eh
	int	15h
	ret

LAB_01d7:
	push	cx
	push	bx
	push	ax
	call	LAB_0233
	mov	bx,4C00h
	call	LAB_0135
	call	LAB_01fd
	pop	bx
	call	LAB_0135
	pop	bx
	call	LAB_016b
	call	LAB_01fd
	xor	cx,cx
LAB_01f3:
	in	al,dx
	test	al,80h
	loopz	LAB_01f3
	call	LAB_024d
	pop	cx
	ret

LAB_01fd:
	and	al,0F3h
	call	LAB_020d
	and	al,0FEh
	call	LAB_020d
	or	al,1
	call	LAB_020d
	ret

LAB_020d:
	push	cx
	mov	cx,10h
LAB_0211:
	out	dx,al
	loop	LAB_0211
	pop	cx
	ret

LAB_0216:
	push	cx
	mov	cx,10h
LAB_021a:
	mov	al,ah
	and	al,40h
	or	al,33h
	call	LAB_020d
	or	al,4
	call	LAB_020d
	in	al,dx
	rcl	al,1
	rcl	bx,1
	SHR	al,1
	loop	LAB_021a
	pop	cx
	ret

LAB_0233:
	mov	dx,3C4h
	mov	al,8
	out	dx,al
	inc	dx
	in	al,dx
	mov	ah,al
	or	al,20h
	call	LAB_020d
	or	al,12h
	call	LAB_020d
	or	al,1
	call	LAB_020d
	ret

LAB_024d:
	mov	al,ah
	and	al,40h
	or	al,33h
	call	LAB_020d
	and	al,0FEh
	call	LAB_020d
	call	LAB_020d
	and	al,0EDh
	call	LAB_020d
	and	al,0DFh
	call	LAB_020d
	mov	al,ah
	out	dx,al
	ret

LAB_026c:
	mov	al,17h				; Read SR17 register
	call	ReadSequencerRegister		; Read it
	and	ah,38h				; Preserve system bus select bits
	cmp	ah,38h				; Something there?
	jnz	.1				; Yes, branch
	mov	al,1
	call	LAB_0cba			; Set EEPROM configuration
.1:
	ret

EnableHardware:
	pushf
	cli					; Interrupts disabled

	cs test	[LAB_1036],BYTE 8		; This is always 0
	jz	.1				; Always jumps
	mov	dx,SLEEP_REG
	mov	al,1
	out	dx,al
	jmp	SHORT .2

.1:
	mov	bx,SLEEP_REG			; Sleep register
	mov	dx,bx
	mov	ax,16h				; Setup mode
	out	dx,ax				; Hardware in setup mode

	mov	dx,POS102			; Subsystem enable register
	mov	al,1				; Enable video subsustem
	out	dx,ax				; Enable hardware

	mov	al,0Eh				; No setup, subsystem enabled
	mov	dx,bx				; Sleep register
	out	dx,ax				; Enable hardware

	xor	al,al				; 8514: Disable adapter
	mov	dx,4AE8h			; 8514: CRT Control
	out	dx,ax				; Disable 8514
.2:
	popf
	ret

LAB_02ad:
	call	LAB_4bad
	call	LAB_284e
	pushf
	cmp	bl,1
	jnz	.1
	or	[VIDEO_MODE_CONTROL],BYTE 6	; Enable monochrome
.1:
	popf
	ret

LAB_02c0:
	push	es
	mov	di,[CURR_PAGE_START]
	mov	si,[NUM_COLUMNS]
	mov	dx,si
	SHL	si,1
	add	si,di
	mov	al,[ROWS_MINUS_ONE]
	mov	ah,[NUM_COLUMNS]
	mul	ah
	mov	cx,ax
	mov	ax,0B800h
	cmp	[CURR_VIDEO_MODE],BYTE 7
	jnz	LAB_02e6
	mov	ah,0B0h
LAB_02e6:
	mov	es,ax
	mov	ds,ax
	rep movsw
	mov	cx,dx
	mov	al,20h
	mov	ah,bh
	rep stosw
	pop	es
	ret

LAB_02f6:
	call	LAB_0d45
	jz	LAB_02c0
	mov	dx,SEQ_INDEX
	mov	al,4
	call	ReadIndirectRegister
	push	ax
	mov	si,[NUM_COLUMNS]
	test	ah,8
	jz	LAB_0319
	cmp	[CURR_VIDEO_MODE],BYTE 13h
	jnz	LAB_0319
	SHL	si,3
	jmp	SHORT LAB_034e
LAB_0319:
	and	ah,0F7h
	out	dx,ax
	mov	dl,0CEh
	mov	al,5
	call	ReadIndirectRegister
	push	ax
	and	ah,0FCh
	or	ah,1
	out	dx,ax
	mov	ch,ah
	mov	dx,INDEX_REG
	mov	al,9
	call	ReadIndirectRegister
	push	ax
	xor	ah,ah
	out	dx,ax
	mov	al,0Bh
	call	ReadIndirectRegister
	push	ax
	test	ch,40h
	jz	LAB_0348
	mov	ah,0Eh
	out	dx,ax
LAB_0348:
	mov	dl,0C4h
	mov	ax,0FF02h
	out	dx,ax
LAB_034e:
	mov	di,[CURR_PAGE_START]
	mov	ax,si
	mul	WORD [CHAR_HEIGHT]
	mov	si,ax
	push	si
	add	si,di
	mov	cl,[ROWS_MINUS_ONE]
	xor	ch,ch
	mul	cx
	mov	bp,ax
	mov	bl,dl
	xor	ah,ah
	mov	dx,INDEX_REG
	mov	cx,0A000h
	mov	es,cx
	mov	ds,cx
LAB_0375:
	mov	cx,si
	neg	cx
	or	bl,bl
	jnz	LAB_0383
	cmp	cx,bp
	jbe	LAB_0383
	mov	cx,bp
LAB_0383:
	sub	bp,cx
	sbb	bl,0
	rep movsb
	or	bl,bl
	jnz	LAB_0392
	or	bp,bp
	jz	LAB_03a9
LAB_0392:
	add	ah,0Fh
	call	LAB_066b
	jz	LAB_039d
	sub	ah,0Ch
LAB_039d:
	mov	al,9
	out	dx,ax
	mov	si,1000h
	and	di,0FFFh
	jmp	SHORT LAB_0375
LAB_03a9:
	pop	cx
	mov	bx,di
	add	bx,cx
	jnc	LAB_03b9
	inc	ah
	mov	al,9
	out	dx,ax
	sub	di,1000h
LAB_03b9:
	mov	dx,INDEX_REG
	mov	al,5
	call	ReadIndirectRegister
	and	ah,0FCh
	out	dx,ax
	xor	ax,ax
	mov	ds,ax
	rep stosb
	cmp	[CURR_VIDEO_MODE],BYTE 13h
	jz	LAB_03dc
	mov	dl,0CEh
	pop	ax
	out	dx,ax
	pop	ax
	out	dx,ax
	mov	dl,0CEh
	pop	ax
	out	dx,ax
LAB_03dc:
	mov	dl,0C4h
	pop	ax
	out	dx,ax
	ret

LAB_03e1:
	test	bl,4
	jnz	LAB_03e9
	jmp	LAB_31bf
LAB_03e9:
	jmp	LAB_31c2

LAB_03ec:
	test	bl,4
	jnz	LAB_03f4
	jmp	LAB_320c
LAB_03f4:
	jmp	LAB_342c

LAB_03f7:
	mov	ah,0Dh
	pop	ds
	iret

LAB_03fb:
	mov	ah,0Ch
	pop	ds
	iret

LAB_03ff:
	xchg	ah,al
	call	LAB_10cd
	xchg	ah,al
	test	ah,1
	jnz	LAB_03fb
	test	ah,4
	jnz	LAB_048a
	push	bx
	push	cx
	push	dx
	xchg	cx,bx
	mov	cl,bl
	SHR	bx,3
	or	ch,ch
	jnz	LAB_046f
LAB_041e:
	mov	ch,al
	mov	ax,[NUM_COLUMNS]
	mul	dx
	add	bx,ax
	adc	dl,0
	call	LAB_0d14
	mov	dx,SEQ_INDEX
	mov	al,2
	call	ReadIndirectRegister
	or	ah,0Fh
	out	dx,ax
	mov	dx,INDEX_REG
	xor	ax,ax
	out	dx,ax
	mov	ax,0F01h
	out	dx,ax
	and	cl,7
	mov	ax,8008h
	shr	ah,cl
	out	dx,ax
	mov	ax,0A000h
	mov	ds,ax
	or	ch,ch
	js	LAB_0479
	or	[bx],al
	mov	ah,ch
	out	dx,ax
	or	[bx],al
LAB_045c:
	mov	ax,0FF08h
	out	dx,ax
	xor	ax,ax
	out	dx,ax
	inc	al
	out	dx,ax
	mov	al,ch
	mov	ah,0Ch
	pop	dx
	pop	cx
	pop	bx
	pop	ds
	iret

LAB_046f:
	add	bx,[PAGE_SIZE]
	dec	ch
	jnz	LAB_046f
	jmp	SHORT LAB_041e
LAB_0479:
	mov	ax,1803h
	out	dx,ax
	mov	ah,ch
	xor	al,al
	out	dx,ax
	or	[bx],al
	mov	ax,3
	out	dx,ax
	jmp	SHORT LAB_045c
LAB_048a:
	push	es
	push	di
	push	ax
	push	dx
	mov	di,ax
	mov	ax,0A000h
	mov	es,ax
	mov	ax,[NUM_COLUMNS]
	SHL	ax,3
	mul	dx
	add	ax,cx
	adc	dl,0
	call	LAB_0d14
	xchg	ax,di
	es mov	[di],al
	pop	dx
	pop	ax
	pop	di
	pop	es
	pop	ds
	iret

LAB_04af:
	xchg	ah,al
	call	LAB_10cd
	xchg	ah,al
	test	ah,1
	jz	LAB_04c3
	mov	ah,3
	jmp	LAB_390f

LAB_04c0:
	JMP	LAB_3909

LAB_04c3:
	test	ah,4
	jz	LAB_04cb
	jmp	LAB_0559
LAB_04cb:
	mov	si,ax
	mov	bp,cx
	mov	ax,0A000h
	cs mov	es,[LAB_2555]
	mov	al,bh
	xor	ah,ah
	SHL	ax,1
	mov	di,ax
	mov	ax,[di+CURSOR_POSN]
	mov	di,ax
	and	di,0FFh
	mov	al,[NUM_COLUMNS]
	mul	ah
	mul	WORD [CHAR_HEIGHT]
	add	di,ax
	adc	dl,0
	push	dx
	mov	dl,bl
	mov	cx,[CHAR_HEIGHT]
	mov	bx,[NUM_COLUMNS]
	dec	bx
	mov	ax,si
	mul	BYTE [CHAR_HEIGHT]
	lds	si,[INT_OFF_VAL(43h)]
	add	si,ax
	mov	ah,dl
	xor	al,al
	mov	dx,INDEX_REG
	out	dx,ax
	inc	al
	not	ah
	out	dx,ax
	mov	dx,SEQ_INDEX
	mov	ax,0F02h
	out	dx,ax
	pop	dx
LAB_0524:
	call	LAB_0d14
	push	si
	push	di
	mov	ax,cx
	movsb
	dec	cx
LAB_052d:
	cmp	di,BYTE 0
	jnz	LAB_0535
	call	LAB_0d2c
LAB_0535:
	add	di,bx
	jnc	LAB_053c
	call	LAB_0d2c
LAB_053c:
	movsb
	loop	LAB_052d
	mov	cx,ax
	pop	di
	pop	si
	inc	di
	dec	bp
	jnz	LAB_0524
	mov	ax,3
	mov	dx,INDEX_REG
	out	dx,ax
	xor	ax,ax
	out	dx,ax
	inc	ax
	out	dx,ax
	cs mov	ds,[LAB_2553]
	ret
LAB_0559:
	push	bx
	xor	bh,bh
	mov	bp,cx
	mov	cx,ax
	mov	ax,0A000h
	mov	es,ax
	mov	ax,[CURSOR_POSN]
	mov	di,ax
	and	di,0FFh
	mov	al,[NUM_COLUMNS]
	mul	ah
	mul	WORD [CHAR_HEIGHT]
	jnc	LAB_057e
	mov	bh,dl
	SHL	bh,3
LAB_057e:
	add	di,ax
	mov	ax,8
	mov	dx,di
	mul	dx
	add	dl,bh
	mov	di,ax
	pop	bx
	push	dx
	mov	ax,[CHAR_HEIGHT]
	mov	dx,ax
	mul	cl
	cs mov	ds,[LAB_2553]
	lds	si,[INT_OFF_VAL(43h)]
	add	si,ax
	pop	ax
LAB_05a0:
	push	di
	push	dx
	push	dx
	mov	dx,ax
	call	LAB_0d14
	pop	dx
	push	ax
LAB_05aa:
	mov	cx,8
	mov	ah,[si]
	inc	si
LAB_05b0:
	rcl	ah,1
	mov	al,bl
	jc	LAB_05b8
	mov	al,bh
LAB_05b8:
	stosb
	loop	LAB_05b0
	or	di,di
	jnz	LAB_05c2
	call	LAB_0d2c
LAB_05c2:
	push	ds
	push	ax
	xor	ax,ax
	mov	ds,ax
	mov	ax,[NUM_COLUMNS]
	dec	ax
	SHL	ax,3
	add	di,ax
	pop	ax
	pop	ds
	jnc	LAB_05dd
	cmp	dx,BYTE 1
	jz	LAB_05dd
	call	LAB_0d2c
LAB_05dd:
	dec	dx
	jnz	LAB_05aa
	pop	ax
	pop	dx
	pop	di
	sub	si,dx
	add	di,BYTE 8
	dec	bp
	jnz	LAB_05a0
	cs mov	ds,[LAB_2553]
	ret

LAB_05f1:
	xchg	ah,al
	call	LAB_10cd
	xchg	ah,al
	test	ah,1
	jz	LAB_0605
	mov	ah,3
	jmp	LAB_38b3

LAB_0602:
	jmp	LAB_389f

LAB_0605:
	test	ah,4
	jz	LAB_060c
	jmp	SHORT LAB_060f
LAB_060c:
	jmp	LAB_04cb
LAB_060f:
	jmp	LAB_0559

LAB_0612:
	call	LAB_1427
	test	bl,4
	jnz	LAB_061d
	SHR	al,2
LAB_061d:
	mov	bx,0A000h
	mov	es,bx
	xor	di,di
	mov	bl,al
	xor	bh,bh
	mov	cl,10h
	call	LAB_066b
	jz	LAB_0631
	mov	cl,4
LAB_0631:
	mov	dx,INDEX_REG
	mov	al,9
	call	ReadIndirectRegister
	push	ax
LAB_063a:
	mov	al,9
	mov	ah,bh
	out	dx,ax
	push	cx
	xor	ax,ax
	mov	cx,8000h
	rep stosw
	pop	cx
	add	bh,cl
	sub	bl,1
	jnc	LAB_063a
	pop	ax
	out	dx,ax
	jmp	LAB_305c
LAB_0654:
	ret
LAB_0655:
	push	bx
	mov	bh,ah
	and	bh,18h
	SHR	bh,2
	mov	al,0Ah
	call	ReadIndirectRegister
	and	ah,0F9h
	or	ah,bh
	out	dx,ax
	pop	bx
	ret

LAB_066b:
	push	ax
	push	dx
	mov	dx,INDEX_REG
	mov	al,0Bh
	call	ReadIndirectRegister
	test	ah,20h
	pop	dx
	pop	ax
	ret

LAB_067b:
	mov	bh,10h					; SRF[4:3]: 32 bits of memory, 1Mbyte total

	mov	dx,SEQ_INDEX				; Sequencer Index Register
	mov	al,0Fh					; Read DRAM control register
	call	ReadIndirectRegister			; Read it

	and	ah,0E7h					; Clear data bus width bits
	or	ah,bh					; Set the data bus width
.testBank:
	mov	dl,0C4h					; Point to Sequencer Index Register
	out	dx,ax					; Write the DRAM control register

	push	ax
	push	cx
	xor	cx,cx
.delay1:
	loop	.delay1

	mov	si,8000h				; Bank size in bytes
	call	TestMemoryBank				; Test and clear it

	pop	cx
	pop	ax

	jz	LAB_06a7				; Jump if test successful

	test	ah,18h					; Are we in 256K yet?
	jz	LAB_06a7				; Yes, bail out

	sub	ah,8					; Bump down one size
	jmp	SHORT .testBank				; Try again

LAB_06a7:
	and	ah,18h
	cmp	ah,8
	jz	LAB_06b7
	call	LAB_06d9
	jnz	LAB_06b7
	or	ah,18h
LAB_06b7:
	mov	ch,ah
	and	ch,18h
	push	ax
	mov	al,0Ah
	call	ReadSequencerRegister
	and	ah,0E7h
	or	ah,ch
	call	WriteSequencerRegister
	pop	ax
	mov	bh,ah
	SHR	bh,2
	or	bh,bh
	jz	LAB_06d6
	dec	bh
LAB_06d6:
	xor	al,al
	ret

LAB_06d9:
	push	ax
	push	bx
	push	dx
	push	di
	push	es

	mov	dx,SEQ_INDEX

	mov	al,0Ah				; SRA: Scratch pad 1 register
	call	ReadIndirectRegister		; Read it
	or	ah,18h				; Set memory to 2Mbyte
	out	dx,ax				; Update it

	mov	al,9				; SR9: Scratch pad 0 register
	call	ReadIndirectRegister		; Read it

	push	dx
	push	ax

	or	ah,0Ch				; 1024x768 frequency
	out	dx,ax				; Update it

	mov	al,6Dh
	call	LAB_1064
	mov	di,0
	jnz	LAB_0727
	mov	al,6Dh
	call	LAB_073e
	mov	dl,0CEh
	mov	ax,4009h
	out	dx,ax
	mov	bl,1
	call	LAB_0cd2
	mov	ax,0A800h
	mov	es,ax
	es mov	[di],ax
	call	LAB_0cd2
	xor	ax,ax
	es	mov [di+4000h],ax
	call	LAB_0cd2
	es mov	di,[di]
LAB_0727:
	xor	ah,ah
	mov	al,[CURR_VIDEO_MODE]
	push	di
	call	LAB_29cb
	pop	di
	pop	ax
	pop	dx
	out	dx,ax
	cmp	di,0A800h
	pop	es
	pop	di
	pop	dx
	pop	bx
	pop	ax
	ret

LAB_073e:
	push	di
	push	ax
	call	LAB_4bc3
	pop	ax
	call	LAB_13e1
	call	LAB_1283
	add	di,BYTE 16h
	mov	si,81Ch
	push	ds
	push	cs
	pop	ds
LAB_0753:
	lodsw
	cmp	al,0C6h
	jz	LAB_0769
	mov	dx,ax
	lodsw
	mov	bh,ah
	call	ReadIndirectRegister
	and	ah,bh
	es or	ah,[di]
	inc	di
	out	dx,ax
	jmp	SHORT LAB_0753

LAB_0769:
	pop	ds
	pop	di
	ret

LAB_076c:
	cmp	ah,4Fh
	jnz	LAB_0774
	jmp	LAB_1fc2

LAB_0774:
	or	al,0FFh
	ret

LAB_0777:
	push	dx
	mov	dx,SEQ_INDEX
	and	bl,bh
	call	ReadSequencerRegister
	not	bh
	and	ah,bh
	or	ah,bl
	call	WriteSequencerRegister
	pop	dx
	ret

LAB_078b:
	push	ax
	push	bx
	push	cx
	mov	bl,al
	mov	al,ah
	call	LAB_0777
	call	LAB_079c
	pop	cx
	pop	bx
	pop	ax
	ret

LAB_079c:
	push	bx
	push	dx
	mov	al,9
	call	ReadSequencerRegister
	mov	bl,ah
	mov	al,0Ah
	call	ReadSequencerRegister
	mov	bh,ah
	call	LAB_0151
	pop	dx
	pop	bx
	ret

LAB_07b2:
	db	'XMODE',0
	db	'3',16h,'%',1Ch,08h,'B',14h,08h,'HW',0
	db	11h,0,01h,0E3h,07h,11h,08h
	db	'XCLR',0
	db	81h,0,03h,'n',12h,'w',12h
	db	'FREQ',0
	db	'I',0
	
	db	11h,96h,11h,0A2h,11h,0

LAB_07e3:
		; Register	Value		Description
	dw	SEQ_INDEX,	0BF08h		; GR8: Clear bit 6
	dw	SEQ_INDEX,	000Bh		; SRB: VCLK0 numerator = 0
	dw	SEQ_INDEX,	001Bh		; SR1B: VCLK0 D and PS = 0
	dw	SEQ_INDEX,	000Ch		; SRC: VCLK1 numerator = 0
	dw	SEQ_INDEX,	001Ch		; SR1C: VCLK1 D and PS = 0
	dw	SEQ_INDEX,	000Dh		; SRD: VCLK2 numerator = 0
	dw	SEQ_INDEX,	001Dh		; SR1D: VCLK2 D and PS = 0
	dw	SEQ_INDEX,	000Fh		; SRF: DRAM control:
						;  DRAM Bank select: four 512Kx8 DRAMs
						;  CRT FIFO Fast-Page Detection Mode: Enabled
						;  CRT FIFO Depth Control: 8 levels
						;  DRAM Data Bus width: 8 bit
						;  RAS timing: 3 MCLK (high), 4 MCLK (low), extended RAS
	dw	SEQ_INDEX,	0016h		; SR16: Performance tuning:
						;  RDY delay for I/O: 1
						;  RDY delay for Memory Write: 1 CPU1X
						;  FIFO Demand Threshold: 0
	dw	SEQ_INDEX,	001Fh		; SR1F: MCLK slect: MCLK = VCLK
	dw	SEQ_INDEX,	0FE17h		; SR17: Extended control reg:
						;  Enable MMIO
						;  Turn off palette memory
						;  Don't shadow DAC writes
	dw	0				; END OF TABLE

LAB_0811:
	db	00h				; GR8: Don't set anything
	db	4Ah				; SRB: Numerator = 74
	db	2Bh				; SR1B: No post scalar, denominator = 22
	db	5Bh				; SRC: Numerator = 91
	db	2Fh				; SR1C: Post scalar, denominator = 23
	db	42h				; SRD: Numerator = 66
	db	1Fh				; SR1D: Post scalar, denominator = 15
	db	00h				; SRF: Don't set anything
	db	0D8h				; SR16:
						;  RDY delay for I/O: 2
						;  RDY delay for Memory Write: 3 CPU1X
						;  FIFO Demand Threshold: 0
	db	1Ch				; SR1F: MCLK = VCLK, frequency = 50.114MHz
	db	01h				; SR17: Enable shadow DAC writes

LAB_081c:
		; Register	Value		Description
	dw	SEQ_INDEX,	0807h		; SR7: All clear, except reserved bit
	dw	SEQ_INDEX,	1B0Fh		; SRF: Clear DRAM bank select, FIFO fast page,
						;  FIFO depth control, and RAS timing.
	dw	SEQ_INDEX,	000Eh		; SRE: VCLK3 numerator = 0
	dw	SEQ_INDEX,	001Eh		; SR1R: VCLK3 No post scalar, denominator = 0
	dw	INDEX_REG,	0C00Bh		; GRB: All clear except eight byte latches, extended write mode
	dw	COLOR_CRTC_INDEX, 0019h		; CR19: Clear interlace end
	dw	COLOR_CRTC_INDEX, 001Ah		; CR1A: All clear
	dw	COLOR_CRTC_INDEX, 001Bh		; CR1B: All clear
	dw	DAC_MASK_REG,	00FFh		; HDR: All clear
	dw	SEQ_INDEX,	0F016h		; SR16: All clear
	dw	SEQ_INDEX,	0F016h		; SR16: All clear (again?)
	dw	0				; END OF TABLE

LAB_084a:
	mov	si,LAB_081c				; Register table to use
	call	WriteRegisterTable			; Write it
	ret

;-------------------------------------------------------------------------------
; InitializeHardware
;-------------------------------------------------------------------------------
; Loads the initial values to initialize the hardware. Skips some of them
; if we're on a warm boot, as they would've been already loaded in the cold boot.
;
; Input:
;  Nothing
;
; Output:
;  AX,CX,SI,DI,ES destroyed
;-------------------------------------------------------------------------------
InitializeHardware:
	cmp	[RESET_FLAG],WORD 1234h				; Is this a warm boot?
	jz	.warm1						; Yes, skip init

	push	cs
	pop	es
	mov	si,LAB_07e3					; Table of register/value pairs
	mov	di,LAB_0811					; Table of values for hidden DAC register
	call	WriteRegisterTable

	push	ds						; Save DS

	push	cs						; DS = CS
	pop	ds

	mov	ax,9						; Address Scratchpad 0 seq register
	mov	cx,2						; Number of entries
	mov	si,LAB_1037					; Starting offset

.readLoop:
	mov	ah,[si]						; Get register value
	call	WriteSequencerRegister					; Write it
	inc	ax						; Next sequencer register
	inc	si						; Next value
	loop	.readLoop					; Loop while bytes left

	jmp	SHORT .lateInit					; Go to last part

.warm1:
	push	ds						; Save register (dummy)
.lateInit:
	pop	ds						; Restore saved register
	cmp	[RESET_FLAG],WORD 1234h				; Is this a warm boot?
	jz	.warm2						; Yes, skip init

	xor	di,di						; No bytes to set bits
	call	LAB_084a					; Call late init

.warm2:
	ret

	; 088b
;-------------------------------------------------------------------------------
; WriteRegisterTable
;-------------------------------------------------------------------------------
; Sets the registers as specified in the table, taking into account a few
; special cases:
; - 3C4h: writes to SRE or SR1E will be skipped if current video mode is 13h
;   or below.
; - 3C6h is always assumed to be the hidden DAC register. Pixel mask is always
;   left fully enabled after this.
; - 3D4h is the color CRTC index register. If the card is in monochrome operation,
;   it will be updated to 3B4h automatically. Same values will otherwise be used.
;
; Input:
; - CS:SI points to a pair of I/O port and value (in this order), each being 16
;   bits wide. The bitmask will be AND'd with the current value, except for 3C6h
;   where this value is ignored. The end of the table is indicated by a 0 in the
;   port number.
; - ES:DI points to an array of bytes. Each of these bytes corresponds to an
;   entry in the table above. This value will be used to set bits in the register,
;   except for 3C6h, where this is the actual value that will be set. DI can be
;   set to 0 if this functionality is not desired. In this case, no bits will be
;   set in the registers.
;
; Output:
;  Registers DX, SI, DI are destroyed.
;-------------------------------------------------------------------------------
WriteRegisterTable:
	push	ax						; Save registers
	push	bx
	push	ds
	push	cs						; Make DS=CS
	pop	ds

.readLoop:
	lodsw							; Read port number
	or	ax,ax						; Is it zero?
	jz	.endLoop					; Yes, end of table
	mov	dx,ax						; Move to proper register

	lodsw							; Read port value

	cmp	dl,0D4h						; Is it CRTC index register?
	jnz	.processEntry					; No, skip fixup

	call	GetCRTCIndex					; Obtain proper CRTC index register
	jmp	SHORT .writeEntry

.endLoop:
	pop	ds						; Registers
	pop	bx
	pop	ax
	ret

.processEntry:
	cmp	dl,0C6h						; Is it DAC mask register?
	jnz	.writeEntry					; No, skip special case

	xor	al,al						; Clear pixel mask register
	out	dx,al						; Clear it

	call	ActivateHiddenDAC				; Enable hidden DAC register

	xor	al,al						; Clear value (default)

	or	di,di						; Is there a list of values available?
	jz	.noDACValues					; No, skip reading

	es mov	al,[di]						; Obtain Hidden DAC value list
	inc	di						; Point to next value

.noDACValues:
	out	dx,al						; Write hidden DAC register
	mov	al,0FFh						; Enable pixel mask in all pixels
	out	dx,al						; Set Pixel Mask
	jmp	SHORT .readLoop					; Go to next register entry

.writeEntry:
	mov	bh,ah						; Save the register value
	call	ReadIndirectRegister					; Read current value
	and	ah,bh						; Apply bits to clear
	or	di,di						; Are there bits to set?
	jz	.specialSRECase					; No, skip it
	es or	ah,[di]						; Apply bits to set
	inc	di						; Point to next value
	jmp	SHORT .write2					; Jump to update value

.specialSRECase:
	cmp	dx,SEQ_INDEX					; Is it sequence index register?
	jnz	.write2						; No, regular write

	cmp	al,0Eh						; Is it SRE?
	jz	.writeSpecialSRE				; Yes, handle special case
	cmp	al,1Eh						; Is it SR1E?
	jnz	.write1						; No, handle regular case

	; Handle SRE and SR1E writes
.writeSpecialSRE:
	call	LAB_08ec					; Check current video mode
	jbe	.goNextEntry					; Jump if 13h or below
	jmp	SHORT .write2					; Go write register

.write1:
	jmp	SHORT .write2					; I/O Delay
.write2:
	out	dx,ax						; Write value
.goNextEntry:
	jmp	SHORT .readLoop					; Next byte

LAB_08ec:
	push	ds						; Save register
%ifdef V20
	push	BYTE 0						; Address BIOS data segment
	pop	ds						; Set it
%else
	push	ax
	xor	ax,ax
	mov	ds,ax
	pop	ax
%endif
	cmp	[CURR_VIDEO_MODE],BYTE 13h			; Is it 40x25/320x200 color?
	pop	ds						; Restore register
	ret							; Return to caller

;-------------------------------------------------------------------------------
; ActivateHiddenDAC
;-------------------------------------------------------------------------------
; Activates the hidden DAC register by performing 4 successive reads to the
; Pixel Mask register.
;
; Input:
; DX = 3C6h
;
; Output:
; AL destroyed
;-------------------------------------------------------------------------------
ActivateHiddenDAC:
	in	al,dx
	jmp	SHORT .1
.1:
	in	al,dx
	jmp	SHORT .2
.2:
	in	al,dx
	jmp	SHORT .3
.3:
	in	al,dx
	jmp	SHORT .4
.4:
	ret

LAB_0904:
	db	80h
	dw	LAB_0bfc
	db	81h
	dw	LAB_0c07
	db	82h
	dw	LAB_0c0d
	db	85h
	dw	LAB_0c9e
	db	9Ah
	dw	LAB_0c25
	db	0A0h
	dw	LAB_096d
	db	0A1h
	dw	LAB_0b4a
	db	0A2h
	dw	LAB_0b71
	db	0A3h
	dw	LAB_0be0
	db	0A4h
	dw	LAB_0b90
	db	0A5h
	dw	LAB_0ca4
	db	0ADh
	dw	LAB_094f
	db	00h				; End of table

LAB_0929:
	call	LAB_0f91
	jz	LAB_0931
	jmp	LAB_0cd0
LAB_0931:
	mov	si,LAB_0904
	push	bx
LAB_0935:
	cs mov	bh,[si]
	add	si,BYTE 3
	or	bh,bh
	jnz	LAB_0943
	pop	bx
	jmp	LAB_0cd0
LAB_0943:
	cmp	bh,bl
	jnz	LAB_0935
	pop	bx
	cs jmp	WORD [si-2]

LAB_094c:
	jmp	LAB_0cd0

LAB_094f:
	or	bh,bh
	jz	LAB_095c
	SHL	al,1
	mov	ah,0Ah
	mov	bh,6
	call	LAB_078b
LAB_095c:
	mov	al,0Ah
	call	ReadSequencerRegister
	SHR	ah,1
	and	ah,3
	xchg	al,ah
	mov	ah,12h
	jmp	LAB_0cce

LAB_096d:
	mov	si,0FFFFh
	mov	[bp+0],si
	mov	[bp+8],si
	mov	[bp+2],si
	mov	[bp+6],si
	mov	cl,1
	push	ds
	push	ax
	cmp	al,8
	jc	LAB_0988
	cmp	al,0Ch
	jbe	LAB_09ab
LAB_0988:
	mov	bx,dx
	call	LAB_0d9a
	call	LAB_0dd6
	cmp	si,BYTE -1
	jz	LAB_09ab
	mov	[bp+0],ds
	mov	[bp+8],si
	cmp	di,BYTE -1
	jz	LAB_09ab
	mov	[bp+2],es
	mov	[bp+6],di
	mov	[bp+0Eh],WORD 1283h
LAB_09ab:
	pop	ax
	pop	ds
	cmp	si,BYTE -1
	jz	LAB_09b8
	cmp	al,13h
	jbe	LAB_09bb
	jmp	SHORT LAB_09bb
LAB_09b8:
	and	cl,0FEh
LAB_09bb:
	mov	ah,cl
LAB_09bd:
	jmp	LAB_0cce

LAB_09c0:
	add	sp,BYTE 2
	lodsw
	mov	si,[si+3]
	mov	ds,ax
	jmp	SHORT LAB_09ed

LAB_09cb:
	cs mov	al,[LAB_0ca3]
	or	al,al
	jz	LAB_09bd
	mov	al,[CURR_VIDEO_MODE]
	push	ds
	mov	bx,dx
	call	LAB_0d9a
	call	LAB_0dd6
	pop	ds
	lds	si,[VIDEO_SAVE_PTR]
	lds	si,[si-18h]
	mov	ax,ds
	or	ax,si
	jz	LAB_0a04
LAB_09ed:
	lodsw
	or	ax,ax
	jz	LAB_0a04
	push	si
	inc	ax
	jz	LAB_0a15
	dec	ax
	cmp	ax,0FFFDh
	jz	LAB_09c0
	cmp	ax,0FFFEh
	jnz	LAB_0a07
	jmp	LAB_0b00
LAB_0a04:
	jmp	LAB_0cce
LAB_0a07:
	cmp	di,BYTE -1
	jnz	LAB_0a0f
	jmp	LAB_0af9
LAB_0a0f:
	es cmp	ax,[di+3]
	jnz	LAB_0a6d
LAB_0a15:
	lodsw
	inc	ax
	jz	LAB_0a20
	dec	ax
	es cmp	ax,[di+5]
	jnz	LAB_0a6d
LAB_0a20:
	lodsb
	inc	al
	jz	LAB_0a2d
	dec	al
	es cmp	al,[di+7]
	jnz	LAB_0a6d
LAB_0a2d:
	lodsb
	inc	al
	jz	LAB_0a63
	dec	al
	push	ax
	es cmp	[di+3],WORD 280h
	jnz	LAB_0a5c
	es cmp	[di+5],WORD 1E0h
	jnz	LAB_0a5c
	mov	dx,SEQ_INDEX
	mov	al,7
	call	ReadIndirectRegister
	test	ah,4
	jnz	LAB_0a5c
	call	LAB_0b34
	pop	ax
	cmp	al,bl
	jz	LAB_0a63
	jmp	SHORT LAB_0a6d
LAB_0a5c:
	pop	ax
	es cmp	al,[di+15h]
	jnz	LAB_0a6d
LAB_0a63:
	lodsb
	inc	al
	jz	LAB_0a72
	dec	al
	es cmp	al,[di]
LAB_0a6d:
	jz	LAB_0a72
	jmp	LAB_0af9
LAB_0a72:
	lodsw
	lodsb
	mov	cl,al
	xor	ch,ch

LAB_0a78:
	lodsb
	mov	dl,al
	mov	dh,3
	cmp	dl,0C9h
	jz	LAB_0aa7
	cmp	dl,0C7h
	jz	LAB_0add
	cmp	dl,0C6h
	jz	LAB_0ae4
	cmp	dl,0C0h
	jz	LAB_0ab3
	cmp	dl,0C2h
	jz	LAB_0ae8
	lodsb
	out	dx,al
	lodsb
	mov	ah,al
	inc	dx
	in	al,dx
	and	ah,al
	lodsb
	or	al,ah
	out	dx,al
LAB_0aa3:
	loop	LAB_0a78
	jmp	SHORT LAB_0af9
LAB_0aa7:
	dec	dx
	lodsb
	out	dx,al
	inc	dx
	lodsb
	out	dx,al
	lodsb
	out	dx,al
	lodsb
	out	dx,al
	jmp	SHORT LAB_0aa3

LAB_0ab3:
	in	al,dx
	push	ax
	lodsb
	push	ax
	mov	ah,al
	call	LAB_1f86
	xchg	al,ah
	lodsb
	and	ah,al
	lodsb
	or	ah,al
	mov	bh,ah
	call	GetCRTCIndex
	add	dl,6
	in	al,dx
	pop	ax
	push	dx
	mov	dl,0C0h
	out	dx,al
	mov	al,bh
	out	dx,al
	pop	dx
	in	al,dx
	mov	dl,0C0h
	pop	ax
	out	dx,al
	jmp	SHORT LAB_0aa3

LAB_0add:
	xor	al,al
	out	dx,al
	dec	dx
	call	ActivateHiddenDAC
LAB_0ae4:
	lodsb
	out	dx,al
	jmp	SHORT LAB_0aa3

LAB_0ae8:
	lodsb
	mov	ah,al
	push	dx
	mov	dx,MISC_OUTPUT_READ
	in	al,dx
	and	ah,al
	lodsb
	or	al,ah
	pop	dx
	out	dx,al
	jmp	SHORT LAB_0aa3

LAB_0af9:
	pop	si
	mov	si,[si+5]
	jmp	LAB_09ed

LAB_0b00:
	lodsw
	lodsb
	lodsb
	push	ds
	xor	bx,bx
	mov	ds,bx
	cmp	al,[CURR_VIDEO_MODE]
	jnz	LAB_0b31
	call	LAB_0d9a
	pop	ds
	lodsb
	inc	al
	jz	LAB_0b1d
	dec	al
	cmp	ah,al
	jnz	LAB_0af9
LAB_0b1d:
	mov	ah,[si-3]
	inc	ah
	jz	LAB_0b2e
	dec	ah
	call	LAB_0b34
	cmp	bl,[si-3]
	jnz	LAB_0af9
LAB_0b2e:
	jmp	LAB_0a72
LAB_0b31:
	pop	ds
	jmp	SHORT LAB_0af9

LAB_0b34:
	mov	al,0Ah
	call	ReadSequencerRegister
	mov	bl,3Ch
	and	ah,41h
	jz	LAB_0b49
	mov	bl,48h
	cmp	ah,40h
	jz	LAB_0b49
	mov	bl,4Bh
LAB_0b49:
	ret

LAB_0b4a:
	call	LAB_284e
	mov	bh,0Ah
	or	bl,bl
	jz	LAB_0b5b
	mov	bh,0Eh
	dec	bl
	jz	LAB_0b5b
	mov	bh,0Fh
LAB_0b5b:
	mov	[bp+0Eh],bx
	jmp	LAB_0cce

LAB_0b61:
	db	00h,00h,02h,03h,01h,00h,02h,00h,02h,01h,03h,12h
	db	03h,22h,03h,32h

LAB_0b71:
	mov	si,LAB_0b61
	SHL	al,1
	xor	ah,ah
	add	si,ax
	cs lodsb
	push	ax
	mov	al,0Ah
	call	ReadSequencerRegister
	SHR	ah,2
	mov	cl,ah
	and	cl,10h
	pop	ax
	or	al,cl
	cs mov	bh,[si]
LAB_0b90:
	mov	ch,bh
	and	ch,0F0h
	cmp	ch,40h
	jbe	LAB_0ba0
	and	bh,0Fh
	or	bh,40h
LAB_0ba0:
	push	ax
	push	bx
	SHL	al,2
	test	al,80h
	jz	LAB_0bab
	or	al,41h
LAB_0bab:
	and	al,7Fh
	test	bh,40h
	jz	LAB_0bb4
	or	al,80h
LAB_0bb4:
	mov	ah,0Ah
	mov	bh,0C1h
	call	LAB_078b
	pop	bx
	pop	ax
	mov	cl,2
	and	al,3
	shl	al,cl
	mov	ah,bh
	mov	cl,4
	shl	ah,cl
	and	ah,30h
	or	al,ah
	SHL	bh,2
	and	bh,0C0h
	or	al,bh
	mov	bh,0FFh
	mov	ah,9
	call	LAB_078b
	jmp	LAB_0cce

LAB_0be0:
	mov	bh,al
	mov	al,41h
	cmp	bh,2
	jnc	LAB_0bf2
	mov	al,40h
	cmp	bh,1
	jz	LAB_0bf2
	xor	al,al
LAB_0bf2:
	mov	bh,41h
	mov	ah,0Ah
	call	LAB_078b
	jmp	LAB_0cce

LAB_0bfc:
	mov	ax,19h
	mov	bl,0
	mov	[bp+0Eh],bx
	jmp	LAB_0cce

LAB_0c07:
	mov	ax,100h
	jmp	LAB_0cce

LAB_0c0d:
	call	GetCRTCIndex
	mov	al,27h
	call	ReadIndirectRegister
	and	ah,3
	mov	al,ah
	jmp	LAB_0cce

LAB_0c1d:
	db	00h,1Ch,02h,04h,0Ch,36h,56h,76h

LAB_0c25:
	call	LAB_0c8d
	push	ax
	push	ax
	pop	bx
	mov	ch,al
	and	ch,0F0h
	SHR	ch,1
	test	bh,80h
	jz	LAB_0c3a
	or	ch,80h
LAB_0c3a:
	xor	cl,cl
	mov	[bp+0Ch],cx
	mov	cx,8
	mov	si,LAB_0c1d
	and	al,0FCh
	SHR	al,1
	test	bh,80h
	jz	LAB_0c50
	or	al,80h
LAB_0c50:
	cs cmp	al,[si]
	jz	LAB_0c58
	inc	si
	loop	LAB_0c50
LAB_0c58:
	sub	si,LAB_0c1d
	mov	bx,si
	and	bl,7
	mov	cl,2
	shl	bl,cl
	SHL	al,1
	and	al,0Ch
	inc	cx
	shl	al,cl
	or	al,bl
	pop	bx
	and	bh,41h
	xor	bl,bl
	or	bh,bh
	jz	LAB_0c81
	mov	bl,10h
	cmp	bh,40h
	jz	LAB_0c81
	mov	bl,20h
LAB_0c81:
	xor	bh,bh
	xchg	bl,bh
	mov	[bp+0Eh],bx
	and	ah,0FEh
	jmp	SHORT LAB_0cce

LAB_0c8d:
	mov	al,9
	call	ReadSequencerRegister
	mov	cl,ah
	mov	al,0Ah
	call	ReadSequencerRegister
	mov	ch,ah
	mov	ax,cx
	ret

LAB_0c9e:
	call	LAB_1427
	jmp	SHORT LAB_0cce

LAB_0ca3:
	db	0FFh

LAB_0ca4:
	or	al,al
	jnz	LAB_0cb5
	cs mov	ah,[LAB_0ca3]
	or	ah,ah
	jz	LAB_0cce
	mov	ah,1
	jmp	SHORT LAB_0cce
LAB_0cb5:
	call	LAB_09cb
	jmp	SHORT LAB_0cce

LAB_0cba:
	mov	ah,0
	xor	al,1
	mov	bl,al
	xor	bl,1
	ror	bl,1
	ror	bl,1
	mov	bh,40h
	mov	al,8					; SR8: EEPROM Control Register
	call	LAB_0777				; Update register
LAB_0cce:
	clc
	ret

LAB_0cd0:
	stc
	ret

LAB_0cd2:
	push	ax
	push	cx
	push	dx
	call	GetCRTCIndex
	add	dl,6
	xor	bh,bh
LAB_0cdd:
	xor	cx,cx
LAB_0cdf:
	in	al,dx
	test	al,8
	loopnz	LAB_0cdf
	xor	cx,cx
LAB_0ce6:
	in	al,dx
	test	al,8
	loopz	LAB_0ce6
	inc	bh
	cmp	bh,bl
	jnz	LAB_0cdd
	pop	dx
	pop	cx
	pop	ax
	ret

;-------------------------------------------------------------------------------
; ReadIndirectRegister
;-------------------------------------------------------------------------------
; Reads an indirect register by writing to the index register and then
; reading the corresponding data register (next register).
;
; Input:
;  DX = Index register base address (data register is assumed to be +1)
;  AL = Register index
;
; Output:
;  AH = Read value
;-------------------------------------------------------------------------------
ReadIndirectRegister:
	out	dx,al				; Write register index
	inc	dx				; Point to register data
	mov	ah,al				; Save index in ah
	in	al,dx				; Read register data
	dec	dx				; Point back to register index
	xchg	ah,al				; Index in AL, Value in AH
	ret					; Return to caller

;-------------------------------------------------------------------------------
; ReadSequencerRegister
;-------------------------------------------------------------------------------
; Reads the specified sequencer register
;
; Input:
;  AL = Sequencer Register Index
;
; Output:
; AH = Value read from register
; DX set to SEQ_INDEX (3C4)
;-------------------------------------------------------------------------------
ReadSequencerRegister:
	mov	dx,SEQ_INDEX			; Sequencer index reg (3C4)
	call	LAB_0f91			; Always sets ZF
	jnz	.1				; Never branches
	call	ReadIndirectRegister			; Read register
.1:
	ret

;-------------------------------------------------------------------------------
; WriteSequencerRegister
;-------------------------------------------------------------------------------
; Writes a sequencer register
;
; Input:
; AL = Sequencer register index
; AH = Sequencer register value
;
; Output:
;  Nothing
;-------------------------------------------------------------------------------
WriteSequencerRegister:
	call	LAB_0f91			; Always sets ZF
	jnz	.1				; Never branches
	mov	dx,SEQ_INDEX			; Address sequence index register
	out	dx,ax				; Write value
.1:
	ret

LAB_0d14:
	push	ax
	push	dx
	mov	ah,dl
	SHL	ah,2
	call	LAB_066b
	jnz	LAB_0d23
	SHL	ah,2
LAB_0d23:
	mov	al,9
	mov	dx,INDEX_REG
	out	dx,ax
	pop	dx
	pop	ax
	ret

LAB_0d2c:
	push	ax
	push	dx
	mov	al,9
	mov	dx,INDEX_REG
	call	ReadIndirectRegister
	add	ah,10h
	call	LAB_066b
	jz	LAB_0d41
	sub	ah,0Ch
LAB_0d41:
	out	dx,ax
	pop	dx
	pop	ax
	ret

LAB_0d45:
	push	ds
	xor	ax,ax
	mov	ds,ax
	cmp	[CURR_VIDEO_MODE],BYTE 4
	jc	LAB_0d66
	cmp	[CURR_VIDEO_MODE],BYTE 7
	jz	LAB_0d66
	cmp	[CURR_VIDEO_MODE],BYTE 14h
	jc	LAB_0d6c
	cmp	[CURR_VIDEO_MODE],BYTE 55h
	ja	LAB_0d6c
LAB_0d66:
	xor	al,al
	or	al,al
	pop	ds
	ret

LAB_0d6c:
	or	al,1
	pop	ds
	ret

;-------------------------------------------------------------------------------
; GetCRTCIndex
;-------------------------------------------------------------------------------
; Obtains the correct value of the CRTC Index register depending on wether
; we're in color or monochrome mode.
;
; Input:
; Nothing
;
; Output:
; DX = CRTC index register for current mode of operation:
;	Monochrome: 3B4h
;	Color: 3D4h
;-------------------------------------------------------------------------------
GetCRTCIndex:
	push	ax
	mov	dx,MISC_OUTPUT_READ
	in	al,dx
	mov	dl,0D4h
	test	al,1
	jnz	.1
	mov	dl,0B4h
.1:
	pop	ax
	ret

LAB_0d7f:
	push	ds
	push	si
	push	ax
	call	LAB_0d9a
	mov	al,ch
	push	bx
	call	LAB_0dd6
	pop	bx
	or	bh,bh
	jnz	LAB_0d96
	mov	di,ds
	mov	es,di
	mov	di,si
LAB_0d96:
	pop	ax
	pop	si
	pop	ds
	ret

LAB_0d9a:
	push	bx
	xor	ah,ah
	xor	bh,bh
	mov	bl,[CURR_VIDEO_MODE]
	cmp	bl,13h
	ja	LAB_0dd4
	SHL	bx,1
	cs mov	bx,[bx+LAB_0f69]
	mov	ah,bh
	cmp	ah,0FFh
	jnz	LAB_0dd4
	mov	ah,2
	test	[VIDEO_MODE_CONTROL],BYTE 10h		; Is it 400 lines?
	jnz	LAB_0dd4				; Yes, jump
	dec	ah
	mov	bl,[VIDEO_SWITCHES]
	and	bl,0Fh
	cmp	bl,0Eh
	jz	LAB_0dd2
	cmp	bl,8
	jnz	LAB_0dd4
LAB_0dd2:
	dec	ah
LAB_0dd4:
	pop	bx
	ret

LAB_0dd6:
	push	dx
	push	cx
	push	bx
	push	ax
	cmp	al,13h
	ja	LAB_0e2c
	xor	bx,bx
	mov	bl,al
	SHL	bx,1
	cs mov	bx,[bx+LAB_0f69]
	cmp	bh,0FFh
	jc	LAB_0e14
	cmp	al,7
	jz	LAB_0e0c
	cmp	ah,1
	jc	LAB_0e14
	add	bl,13h
	cmp	ah,1
	jz	LAB_0e14
	mov	bh,al
	sub	bl,bh
	SHR	bh,1
	add	bl,4
	add	bl,bh
	jmp	SHORT LAB_0e14
LAB_0e0c:
	cmp	ah,1
	jbe	LAB_0e14
	add	bl,12h
LAB_0e14:
	xor	si,si
	mov	ds,si
	lds	si,[VIDEO_SAVE_PTR]
	lds	si,[si]
	mov	al,40h
	mul	bl
	add	si,ax
	mov	di,0FFFFh
	mov	es,di
	jmp	LAB_0f32
LAB_0e2c:
	xor	si,si
	mov	ds,si
	lds	si,[VIDEO_SAVE_PTR]
LAB_0e34:
	cmp	[si-2],WORD 5256h
	jnz	LAB_0eb7
	push	ds
	push	si
	mov	dx,[si-0Eh]
	mov	cx,[si-4]
	les	di,[si-0Ch]
	lds	si,[si-8]
	jcxz	LAB_0e93
LAB_0e4b:
	test	al,80h
	jnz	LAB_0e60
	cmp	al,58h
	jnz	LAB_0e59
	es cmp	[di],BYTE 6Ah
	jz	LAB_0eca
LAB_0e59:
	es cmp	al,[di]
	jz	LAB_0eca
	jmp	SHORT LAB_0e66
LAB_0e60:
	es cmp	bx,[di+1]
	jz	LAB_0eca
LAB_0e66:
	add	si,BYTE 40h
	add	di,dx
	call	LAB_118a
	jnz	LAB_0e91
	push	ax
	es mov	al,[di+0Ch]
	and	al,0Fh
	mov	si,LAB_56eb
	jz	LAB_0e90
	cmp	al,2
	jnc	LAB_0e85
	add	si,BYTE 40h
	jmp	SHORT LAB_0e90
LAB_0e85:
	mov	si,LAB_1907
	sub	al,2
	mov	ah,40h
	mul	ah
	add	si,ax
LAB_0e90:
	pop	ax
LAB_0e91:
	loop	LAB_0e4b
LAB_0e93:
	pop	si
	pop	ds
	mov	dx,ds
	mov	cx,cs
	cmp	dx,cx
	jz	LAB_0eac
	cmp	WORD [si-10h],BYTE 4
	jc	LAB_0eb7
	lds	si,[si-14h]
	mov	dx,ds
	or	dx,si
	jnz	LAB_0e34
LAB_0eac:
	mov	si,0FFFFh
	mov	di,si
	mov	es,di
	mov	ds,si
	jmp	SHORT LAB_0f32
LAB_0eb7:
	mov	dx,cs
	mov	ds,dx
	mov	si,LAB_4f73
	cmp	dx,0E000h
	jnz	LAB_0ec7
	mov	si,LAB_4fa7
LAB_0ec7:
	jmp	LAB_0e34

LAB_0eca:
	push	ax
	call	LAB_1427
	es cmp	al,[di+10h]
	jc	LAB_0f2e
	call	LAB_0f99
	jc	LAB_0f2e
	push	cx
	call	LAB_0f96
	mov	ax,1
	shl	ax,cl
	pop	cx
	es test	[di+0Eh],ax
	jz	LAB_0f2e
	cs test	[LAB_1035],BYTE 20h
	jnz	LAB_0efe
	pop	ax
	push	ax
	mov	ah,0C3h
	int	15h
	xchg	ah,al
	cmp	ah,0C3h
	jz	LAB_0f19
LAB_0efe:
	push	dx
	mov	al,9
	call	ReadSequencerRegister
	mov	al,ah
	SHR	al,1
	push	ax
	mov	al,0Ah
	call	ReadSequencerRegister
	test	ah,80h
	pop	ax
	jz	LAB_0f16
	or	al,80h
LAB_0f16:
	pop	dx
	jmp	SHORT LAB_0f23

LAB_0f19:
	mov	si,0C1Dh
	xor	ah,ah
	add	si,ax
	cs mov	al,[si]
LAB_0f23:
	call	LAB_0f37
	jc	LAB_0f2e
	pop	ax
	add	sp,BYTE 4
	jmp	SHORT LAB_0f32

LAB_0f2e:
	pop	ax
	jmp	LAB_0e66

LAB_0f32:
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	ret

LAB_0f37:
	es mov	ah,[di+14h]
	push	ax
	and	ax,606h
	cmp	ah,al
	pop	ax
	ja	LAB_0f64
	es cmp	[di+3],WORD 320h
	jz	LAB_0f5d
	es cmp	[di+3],WORD 400h
	jnz	LAB_0f67
	and	ax,0E0E0h
	cmp	ah,al
	ja	LAB_0f64
	jmp	SHORT LAB_0f67
LAB_0f5d:
	and	ax,1818h
	cmp	ah,al
	jbe	LAB_0f67
LAB_0f64:
	stc
	jmp	SHORT LAB_0f68
LAB_0f67:
	clc
LAB_0f68:
	ret

LAB_0f69:
	db	00h,0FFh
	db	01h,0FFh
	db	02h,0FFh
	db	03h,0FFh
	db	04h,00h
	db	05h,00h
	db	06h,00h
	db	07h,0FFh
	db	08h,00h
	db	09h,00h
	db	0Ah,00h
	db	0Bh,00h
	db	0Ch,00h
	db	0Dh,00h
	db	0Eh,00h
	db	11h,01h
	db	12h,01h
	db	1Ah,03h
	db	1Bh,03h
	db	1Ch,00h

LAB_0f91:
	push	ax
	xor	al,al
	pop	ax
	ret

LAB_0f96:
	mov	cl,8
	ret

LAB_0f99:
	push	dx
	push	cx
	push	ax
	push	di
	mov	al,1Fh
	call	ReadSequencerRegister
	and	ah,3Fh
	mov	ch,ah
	mov	al,0Ah
	call	ReadIndirectRegister
	add	di,BYTE 11h
	and	ah,38h
	cmp	ah,8
	jz	LAB_0fbe
	inc	di
	cmp	ah,10h
	jz	LAB_0fbe
	inc	di
LAB_0fbe:
	es mov	al,[di]
	or	al,al
	jz	LAB_0fc9
	cmp	ch,al
	jc	LAB_0fcc
LAB_0fc9:
	clc
	jmp	SHORT LAB_0fcd
LAB_0fcc:
	stc
LAB_0fcd:
	pop	di
	pop	ax
	pop	cx
	pop	dx
	ret

LAB_0fd2:
	db	6Bh,5Fh,00h,0C0h
	db	6Bh,57h,00h,0C0h
	db	6Bh,5Bh,00h,0C0h
	db	6Bh,6Dh,00h,0C0h
	db	9Bh,6Eh,00h,0C0h
	db	9Bh,7Eh,00h,0C0h
	db	12 dup (0FFh)
	db	13h,00h,01h,00h

	db	'VRGD5429'

	db	00h,00h,08h,0D2h
	db	0Fh,00h,39h,00h
	db	0FCh,0Fh,01h,35h
	db	10h,02h,00h,02h
	db	37h,10h,00h,00h
	db	03h,3Fh,10h,06h
	db	00h,04h,3Fh,10h
	db	00h,00h,05h,37h
	db	10h,06h,00h,06h
	db	37h,10h,00h,00h
	db	07h,3Dh,10h,02h
	db	00h,08h,0E2h,00h
	db	0A0h,00h,0FFh
LAB_1035:
	db	0A0h
LAB_1036:
	db	00h
LAB_1037:
	db	08h,00h
	db	00h,00h,00h,00h
LAB_103d:
	db	00h
LAB_103e:
	db	00h
	db	00h,05h
	db	0FFh,0FFh,0FFh,0FFh
LAB_1045:
	db	'09/02/94'
	db	20h,20h,20h,20h
	db	20h,20h,20h,20h
	db	20h,0Dh,0Ah,00

;-------------------------------------------------------------------------------
; UnlockAndInitialize
;-------------------------------------------------------------------------------
; Unlocks the hardware for initializing
;
; Input:
;  Nothing
;
; Output:
;  AX,CX,DX,SI,DI,ES destroyed
;-------------------------------------------------------------------------------
UnlockAndInitialize:
	mov	dx,SEQ_INDEX				; Sequencer Index
	mov	ax,1206h				; (06) = Index 6
							; (12) = Unlock extension registers
	out	dx,ax					; Do unlock

	call	InitializeHardware
	ret

LAB_1064:
	push	ax
	call	LAB_1411
	mov	si,di
	pop	ax
	ret

LAB_106c:
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	push	di
	push	si
	call	LAB_1064
	jnz	LAB_10c1
	xor	al,al
	es test	[di+3Dh],BYTE 1
	jnz	LAB_1083
	or	al,1
LAB_1083:
	es test	[di+9],BYTE 1
	jz	LAB_108c
	or	al,2
LAB_108c:
	call	LAB_118a
	jnz	LAB_10a0
	push	ax
	mov	dx,SEQ_INDEX
	mov	al,4
	call	ReadIndirectRegister
	test	ah,8
	pop	ax
	jmp	SHORT LAB_10a5
LAB_10a0:
	es test	[di+8],BYTE 8
LAB_10a5:
	jz	LAB_10a9
	or	al,4
LAB_10a9:
	es cmp	[di+2],BYTE 8
	jz	LAB_10bd
	es cmp	[di+2],BYTE 0Eh
	jnz	LAB_10bb
	or	al,10h
	jmp	SHORT LAB_10bd
LAB_10bb:
	or	al,30h
LAB_10bd:
	cmp	al,al
	jmp	SHORT LAB_10c5
LAB_10c1:
	push	ax
	or	al,0FFh
	pop	ax
LAB_10c5:
	pop	si
	pop	di
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	ret

LAB_10cd:
	push	dx
	push	cx
	push	bx
	mov	bh,ah
	xor	bl,bl
	mov	dx,INDEX_REG
	in	al,dx
	mov	ch,al
	mov	al,6
	call	ReadIndirectRegister
	mov	al,ch
	out	dx,al
	test	ah,1
	jnz	LAB_10ea
	or	bl,1
LAB_10ea:
	mov	dl,0CCh
	in	al,dx
	test	al,1
	jz	LAB_10f4
	or	bl,2
LAB_10f4:
	mov	dl,0C4h
	in	al,dx
	mov	ch,al
	mov	al,4
	call	ReadIndirectRegister
	mov	al,ch
	out	dx,al
	test	ah,8
	jz	LAB_1109
	or	bl,4
LAB_1109:
	mov	ax,bx
	pop	bx
	pop	cx
	pop	dx
	ret

LAB_110f:
	call	LAB_0f91
	jz	LAB_1116
	jmp	SHORT LAB_117b
LAB_1116:
	xor	di,di
	cmp	al,13h
	push	ax
	jbe	LAB_1126
	call	LAB_13e1
	call	LAB_1283
	add	di,BYTE 16h
LAB_1126:
	call	LAB_117c
	push	bx
	push	ax
	call	GetCRTCIndex
	mov	al,27h
	call	ReadIndirectRegister
	and	ah,0FCh
	cmp	ah,98h
	pop	ax
	jnz	LAB_114e
	mov	bl,al
	mov	al,17h
	call	ReadSequencerRegister
	and	ah,0FEh
	and	bl,1
	or	ah,bl
	call	WriteSequencerRegister
LAB_114e:
	pop	bx
	call	LAB_084a
	pop	ax
	push	cx
	call	LAB_0f96
	cmp	cl,5
	jnz	LAB_1174
	mov	ax,31h
	mov	dx,INDEX_REG
	out	dx,ax
	mov	cx,0FFFFh
LAB_1166:
	dec	cx
	cmp	cx,BYTE 0
	jz	LAB_1174
	call	ReadIndirectRegister
	test	ah,1
	jnz	LAB_1166
LAB_1174:
	pop	cx
	call	LAB_1337
	call	LAB_1355
LAB_117b:
	ret

LAB_117c:
	push	di
	mov	di,LAB_0811
	cs mov	ah,[di+8]
	cs mov	al,[di+0Ah]
	pop	di
	ret

LAB_118a:
	push	ax
	push	bx
	mov	ax,cs
	mov	bx,es
	cmp	ax,bx
	pop	bx
	pop	ax
	ret

LAB_1195:
	db	0Ch
LAB_1196:
	db	00h,03h,04h,05h,06h,07h,09h,10h,12h,15h,16h,11h
LAB_11a2:
	db	7Fh,82h,6Bh
	db	1Bh,72h,0F0h,60h,58h,57h,58h,72h,8Ch,63h,86h,54h,99h,06h,3Eh,40h
	db	0E8h,0DFh,0E7h,0FFh,8Bh,0A3h,86h,85h,96h,24h,0FDh,60h,02h,0FFh,00h,24h
	db	88h,0A1h,84h,85h,96h,24h,0FDh,60h,02h,0FFh,00h,24h,88h,0A1h,84h,84h
	db	92h,2Ah,0FDh,60h,12h,0FFh,00h,2Ah,89h,63h,86h,55h,9Ah,06h,3Eh,40h
	db	0E8h,0DFh,0E7h,0FFh,8Bh,7Fh,82h,6Ah,1Ah,72h,0F0h,60h,58h,57h,58h,72h
	db	8Ch,7Bh,9Eh,68h,91h,6Fh,0F0h,60h,58h,57h,58h,6Fh,8Ah,7Dh,80h,6Dh
	db	1Ch,98h,0F0h,60h,7Ch,57h,5Fh,91h,82h,5Fh,82h,53h,9Fh,0Bh,3Eh,40h
	db	0EAh,0DFh,0E7h,04h,8Ch,0A1h,84h,85h,93h,2Ah,0FDh,60h,12h,0FFh,00h,2Ah
	db	89h,99h,9Ch,84h,1Ah,96h,1Fh,40h,80h,7Fh,80h,96h,84h,0BDh,80h,0A5h
	db	1Ah,2Ah,0B2h,60h,0Bh,0FFh,00h,2Ah,80h,9Fh,82h,84h,90h,1Eh,0F5h,60h
	db	00h,0FFh,0FFh,1Eh,93h,7Fh,82h,68h,12h,6Fh,0F0h,60h,58h,57h,57h,6Fh
	db	8Bh,64h,88h,53h,9Bh,0F2h,1Fh,40h,0E0h,0DFh,0DFh,0F3h,83h,64h,87h,54h
	db	9Ch,0F2h,1Fh,40h,0E1h,0DFh,0E7h,0EBh,84h
LAB_126e:
	db	0C4h,04h,0CEh,05h,0CEh,06h,0D4h,13h,00h
LAB_1277:
	db	0Eh,40h,05h,01h,0Eh,40h,05h,02h,0Eh,00h,05h,08h

LAB_1283:
	push	ax
	push	cx
	push	dx
	push	si
	call	LAB_118a
	jnz	LAB_12fd
	mov	dh,3
	es mov	al,[di+7]
	cmp	al,4
	jbe	LAB_12ce
	push	di
	mov	si,LAB_126e
	mov	di,LAB_1277
	mov	cx,2
	cmp	al,18h
	jz	LAB_12aa
	dec	cx
	cmp	al,8
	ja	LAB_12aa
	dec	cx
LAB_12aa:
	mov	al,4
	mul	cl
	add	di,ax
	mov	cx,3
LAB_12b3:
	cs lodsb
	mov	dl,al
	cs mov	ah,[di]
	inc	di
	cs lodsb
	out	dx,ax
	loop	LAB_12b3
	cs mov	cl,[di]
	mov	dl,0D4h
	mov	al,13h
	call	ReadIndirectRegister
	shl	ah,cl
	out	dx,ax
	pop	di
LAB_12ce:
	es mov	al,[di+0Ch]
	and	al,0F0h
	cmp	al,0F0h
	jz	LAB_12db
	call	LAB_1302
LAB_12db:
	mov	dl,0C2h
	es mov	al,[di+0Dh]
	out	dx,al
	es cmp	[di+7],BYTE 4
	jbe	LAB_12fd
	mov	dl,0DAh
	in	al,dx
	mov	cl,0Ah
	mov	al,6
	mov	dl,0C0h
LAB_12f2:
	out	dx,al
	out	dx,al
	inc	ax
	loop	LAB_12f2
	mov	al,10h
	out	dx,al
	mov	al,41h
	out	dx,al
LAB_12fd:
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret

LAB_1302:
	push	cx
	mov	ah,al
	mov	cl,4
	shr	al,cl
	and	al,0Fh
	test	ah,1
	jz	LAB_1312
	add	al,0Fh
LAB_1312:
	push	di
	mov	dl,0D4h
	mov	si,LAB_1196
	mov	di,LAB_11a2
	mov	cx,0Ch
	mul	cl
	add	di,ax
	mov	al,11h
	call	ReadIndirectRegister
	and	ah,7Fh
	out	dx,ax
LAB_132b:
	cs mov	ah,[di]
	inc	di
	cs lodsb
	out	dx,ax
	loop	LAB_132b
	pop	di
	pop	cx
	ret

LAB_1337:
	push	ax
	push	cx
	push	dx
	mov	dx,SEQ_INDEX
	mov	ax,10h
	mov	cx,4
LAB_1343:
	out	dx,ax
	inc	ax
	loop	LAB_1343
	mov	cl,2
	mov	dl,0CEh
	mov	al,9
LAB_134d:
	out	dx,ax
	inc	ax
	loop	LAB_134d
	pop	dx
	pop	cx
	pop	ax
	ret

LAB_1355:
	call	LAB_13c3
	jnz	LAB_13b2
	mov	al,0AH
	call	ReadSequencerRegister
	and	ah,40h
	jz	LAB_13b2
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,71h
	jz	LAB_13b2
	mov	al,1
	call	LAB_13b3
	jnz	LAB_1374
	mov	al,10h
LAB_1374:
	cmp	[CURR_VIDEO_MODE],BYTE 64h
	jz	LAB_138b
	cmp	[CURR_VIDEO_MODE],BYTE 66h
	jz	LAB_138b
	mov	al,11h
	call	LAB_13b3
	jnz	LAB_138b
	mov	al,50h
LAB_138b:
	call	LAB_1302
	call	LAB_13b3
	jz	LAB_1397
	mov	ax,221Bh
	out	dx,ax
LAB_1397:
	mov	dl,0CCh
	in	al,dx
	or	al,0Ch
	mov	dl,0C2h
	out	dx,al
	mov	dl,0C4h
	mov	ax,420Eh
	out	dx,ax
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,64h
	mov	ax,1F1Eh
	jnz	LAB_13b1
	mov	ah,1Eh
LAB_13b1:
	out	dx,ax
LAB_13b2:
	ret

LAB_13b3:
	push	dx
	push	ax
	mov	al,0Ah
	mov	dx,SEQ_INDEX
	call	ReadIndirectRegister
	and	ah,1
	pop	ax
	pop	dx
	ret

LAB_13c3:
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,13h
	jbe	LAB_13dd
	call	LAB_13e1
	es cmp	[di+3],WORD 280h
	jnz	LAB_13df
	es cmp	[di+5],WORD 1E0h
	jmp	SHORT LAB_13df
LAB_13dd:
	cmp	al,12h
LAB_13df:
	ret
LAB_13e0:
	ret

LAB_13e1:
	push	cx
	push	dx
	mov	cl,al
	and	cl,7Fh
	cmp	cl,13h
	jbe	LAB_1401
	mov	ah,12h
	mov	al,cl
	push	bx
	mov	bl,0A0h
	push	ds
	pushf
	push	cs
	call	LAB_293d
	pop	ds
	pop	bx
	test	ah,1
	jz	LAB_1408
LAB_1401:
	mov	al,0
	cmp	di,BYTE -1
	jnz	LAB_140a
LAB_1408:
	or	al,0FFh
LAB_140a:
	mov	ah,0
	or	al,al
	pop	dx
	pop	cx
	ret

LAB_1411:
	push	ax
	call	LAB_13e1
	pop	ax
	jnz	LAB_1425
	push	cx
	push	bx
	mov	ch,al
	mov	bh,0
	call	LAB_0d7f
	pop	bx
	pop	cx
	cmp	al,al
LAB_1425:
	ret

LAB_1426:
	ret

LAB_1427:
	push	dx
	push	cx
	mov	ch,ah
	mov	al,0Ah
	call	ReadSequencerRegister
	and	ah,18h
	mov	cl,3
	shr	ah,cl
	mov	cl,ah
	mov	al,4
	shl	al,cl
	mov	ah,ch
	pop	cx
	pop	dx
	ret

LAB_1442:
	db	14h, 00h, 00h, 20h, 04h, 90h, 01h, 04h, 08h, 10h, 00h, 0Eh, 0F2h, 6Fh, 0FFh, 01h
	db	04h, 00h, 00h, 00h, 00h, 46h, 00h, 00h, 5Ah, 3Eh, 00h, 00h, 00h, 00h, 00h, 08h
	db	08h, 54h, 0Ah, 01h, 20h, 04h, 5Eh, 01h, 04h, 08h, 08h, 00h, 0Eh, 0F3h, 0AFh, 0FFh
	db	01h, 04h, 00h, 00h, 00h, 00h, 46h, 00h, 00h, 5Ah, 3Eh, 00h, 00h, 00h, 00h, 00h
	db	08h, 08h, 55h, 09h, 01h, 20h, 04h, 5Eh, 01h, 04h, 08h, 0Eh, 00h, 0Eh, 0F4h, 0AFh
	db	0FFh, 01h, 04h, 00h, 00h, 00h, 00h, 46h, 00h, 00h, 5Ah, 3Eh, 00h, 00h, 00h, 00h
	db	00h, 08h, 08h, 5Ch, 03h, 01h, 20h, 03h, 58h, 02h, 08h, 08h, 10h, 04h, 1Eh, 0E5h
	db	2Fh, 00h, 01h, 04h, 22h, 1Ch, 1Ch, 1Ah, 4Bh, 01h, 20h, 53h, 30h, 00h, 00h, 00h
	db	22h, 00h, 01h, 01h, 5Ch, 03h, 01h, 20h, 03h, 58h, 02h, 08h, 08h, 10h, 04h, 1Eh
	db	85h, 2Fh, 0FFh, 01h, 04h, 22h, 1Ch, 1Ch, 12h, 48h, 01h, 20h, 64h, 3Ah, 00h, 00h
	db	00h, 22h, 00h, 08h, 08h, 5Ch, 03h, 01h, 20h, 03h, 58h, 02h, 08h, 08h, 10h, 04h
	db	1Eh, 05h, 2Fh, 0FFh, 01h, 04h, 1Ch, 1Ch, 1Ch, 0Ah, 3Ch, 01h, 20h, 51h, 3Ah, 00h
	db	00h, 00h, 22h, 00h, 08h, 08h, 5Ch, 03h, 01h, 20h, 03h, 58h, 02h, 08h, 08h, 10h
	db	04h, 1Eh, 0F5h, 0EFh, 0FEh, 01h, 04h, 19h, 19h, 19h, 02h, 38h, 01h, 20h, 7Eh, 33h
	db	00h, 00h, 00h, 22h, 00h, 08h, 08h, 5Dh, 04h, 01h, 00h, 04h, 00h, 03h, 04h, 08h
	db	10h, 03h, 1Eh, 0D6h, 0EFh, 00h, 01h, 04h, 19h, 19h, 19h, 84h, 4Bh, 00h, 00h, 2Ch
	db	10h, 00h, 4Ah, 00h, 22h, 00h, 01h, 01h, 5Dh, 04h, 01h, 00h, 04h, 00h, 03h, 04h
	db	08h, 10h, 03h, 1Eh, 46h, 0EFh, 30h, 01h, 04h, 19h, 19h, 19h, 64h, 48h, 00h, 00h
	db	61h, 24h, 00h, 4Ah, 00h, 22h, 00h, 08h, 38h, 5Dh, 04h, 01h, 00h, 04h, 00h, 03h
	db	04h, 08h, 10h, 03h, 1Eh, 36h, 0EFh, 0F8h, 01h, 04h, 19h, 19h, 19h, 44h, 46h, 00h
	db	00h, 6Eh, 2Ah, 00h, 4Ah, 00h, 22h, 00h, 08h, 38h, 5Dh, 04h, 01h, 00h, 04h, 00h
	db	03h, 04h, 08h, 10h, 03h, 1Eh, 26h, 0EFh, 0FEh, 01h, 04h, 19h, 19h, 19h, 24h, 3Ch
	db	00h, 00h, 3Bh, 1Ah, 00h, 4Ah, 00h, 22h, 00h, 08h, 38h, 5Dh, 04h, 01h, 00h, 04h
	db	00h, 03h, 04h, 08h, 10h, 03h, 1Eh, 0F6h, 2Fh, 0FEh, 01h, 04h, 19h, 19h, 19h, 04h
	db	00h, 00h, 00h, 55h, 36h, 00h, 4Ah, 01h, 22h, 00h, 08h, 38h, 5Eh, 00h, 01h, 80h
	db	02h, 90h, 01h, 08h, 08h, 10h, 04h, 1Eh, 0F9h, 0E3h, 0FEh, 01h, 04h, 00h, 00h, 00h
	db	00h, 3Ch, 01h, 20h, 7Eh, 33h, 00h, 00h, 00h, 22h, 00h, 01h, 01h, 5Fh, 01h, 01h
	db	80h, 02h, 0E0h, 01h, 08h, 08h, 10h, 04h, 1Eh, 0F0h, 0E3h, 0FEh, 01h, 04h, 00h, 00h
	db	00h, 00h, 3Ch, 01h, 20h, 7Eh, 33h, 00h, 00h, 00h, 22h, 00h, 08h, 08h, 60h, 05h
	db	01h, 00h, 04h, 00h, 03h, 08h, 08h, 10h, 04h, 1Eh, 0D6h, 0EFh, 00h, 01h, 10h, 00h
	db	19h, 19h, 84h, 4Bh, 01h, 20h, 2Ch, 10h, 00h, 4Ah, 00h, 22h, 00h, 01h, 01h, 60h
	db	05h, 01h, 00h, 04h, 00h, 03h, 08h, 08h, 10h, 04h, 1Eh, 0A6h, 0EFh, 30h, 01h, 10h
	db	00h, 19h, 19h, 64h, 48h, 01h, 20h, 61h, 24h, 00h, 4Ah, 00h, 22h, 00h, 0Ch, 0Bh
	db	60h, 05h, 01h, 00h, 04h, 00h, 03h, 08h, 08h, 10h, 04h, 1Eh, 36h, 0EFh, 38h, 01h
	db	10h, 00h, 19h, 19h, 44h, 46h, 01h, 20h, 6Eh, 2Ah, 00h, 4Ah, 00h, 22h, 00h, 0Bh
	db	0Ah, 60h, 05h, 01h, 00h, 04h, 00h, 03h, 08h, 08h, 10h, 04h, 1Eh, 26h, 0EFh, 38h
	db	01h, 10h, 00h, 19h, 19h, 24h, 3Ch, 01h, 20h, 3Bh, 1Ah, 00h, 4Ah, 00h, 22h, 00h
	db	08h, 08h, 60h, 05h, 01h, 00h, 04h, 00h, 03h, 08h, 08h, 10h, 04h, 1Eh, 0F6h, 2Fh
	db	7Ch, 01h, 10h, 00h, 19h, 19h, 04h, 00h, 01h, 20h, 55h, 36h, 00h, 4Ah, 01h, 22h
	db	00h, 08h, 08h, 64h, 11h, 01h, 80h, 02h, 0E0h, 01h, 10h, 08h, 10h, 06h, 1Ah, 90h
	db	0EFh, 38h, 01h, 10h, 00h, 19h, 19h, 00h, 3Ch, 03h, 20h, 65h, 3Ah, 00h, 00h, 00h
	db	22h, 0E1h, 08h, 08h, 65h, 14h, 01h, 20h, 03h, 58h, 02h, 10h, 08h, 10h, 06h, 1Ah
	db	85h, 2Fh, 00h, 01h, 10h, 00h, 22h, 22h, 12h, 48h, 03h, 20h, 2Ah, 0Ch, 00h, 00h
	db	00h, 22h, 0E1h, 01h, 01h, 65h, 14h, 01h, 20h, 03h, 58h, 02h, 10h, 08h, 10h, 06h
	db	1Ah, 65h, 2Fh, 38h, 01h, 10h, 00h, 1Ch, 1Ch, 0Ah, 3Ch, 03h, 20h, 5Fh, 22h, 00h
	db	00h, 00h, 22h, 0E1h, 0Ch, 0Ch, 65h, 14h, 01h, 20h, 03h, 58h, 02h, 10h, 08h, 10h
	db	06h, 1Ah, 75h, 0EFh, 38h, 01h, 10h, 00h, 19h, 19h, 02h, 38h, 03h, 20h, 7Eh, 32h
	db	00h, 00h, 00h, 22h, 0E1h, 0Bh, 0Bh, 66h, 10h, 01h, 80h, 02h, 0E0h, 01h, 0Fh, 08h
	db	10h, 06h, 1Ah, 0F0h, 0EFh, 38h, 01h, 10h, 00h, 19h, 19h, 00h, 3Ch, 07h, 20h, 65h
	db	3Ah, 00h, 00h, 00h, 22h, 0F0h, 08h, 08h, 67h, 13h, 01h, 20h, 03h, 58h, 02h, 0Fh
	db	08h, 10h, 06h, 1Ah, 85h, 2Fh, 00h, 01h, 10h, 00h, 22h, 22h, 12h, 48h, 07h, 20h
	db	65h, 3Ah, 00h, 00h, 00h, 22h, 0F0h, 01h, 01h, 67h, 13h, 01h, 20h, 03h, 58h, 02h
	db	0Fh, 08h, 10h, 06h, 1Ah, 65h, 2Fh, 00h, 01h, 10h, 00h, 1Ch, 1Ch, 0Ah, 3Ch, 07h
	db	20h, 51h, 3Ah, 00h, 00h, 00h, 22h, 0F0h, 01h, 01h, 67h, 13h, 01h, 20h, 03h, 58h
	db	02h, 0Fh, 08h, 10h, 06h, 1Ah, 0F5h, 0EFh, 38h, 01h, 10h, 00h, 19h, 19h, 02h, 38h
	db	07h, 20h, 7Eh, 33h, 00h, 00h, 00h, 22h, 0F0h, 08h, 08h, 68h, 16h, 01h, 00h, 04h
	db	00h, 03h, 0Fh, 08h, 10h, 06h, 1Ah, 0F6h, 2Fh, 00h, 01h, 20h, 00h, 00h, 1Ch, 04h
	db	00h, 07h, 0A0h, 55h, 36h, 20h, 4Ah, 01h, 32h, 0F0h, 0Ah, 0Ah, 6Ah, 02h, 01h, 20h
	db	03h, 58h, 02h, 04h, 08h, 10h, 03h, 1Eh, 0E5h, 2Fh, 00h, 01h, 04h, 00h, 00h, 00h
	db	1Ah, 4Bh, 00h, 00h, 53h, 30h, 00h, 00h, 00h, 22h, 00h, 01h, 01h, 6Ah, 02h, 01h
	db	20h, 03h, 58h, 02h, 04h, 08h, 10h, 03h, 1Eh, 85h, 2Fh, 0FFh, 01h, 04h, 00h, 00h
	db	00h, 12h, 48h, 00h, 00h, 65h, 3Ah, 00h, 00h, 00h, 22h, 00h, 08h, 38h, 6Ah, 02h
	db	01h, 20h, 03h, 58h, 02h, 04h, 08h, 10h, 03h, 1Eh, 05h, 2Fh, 0FFh, 01h, 04h, 00h
	db	00h, 00h, 0Ah, 3Ch, 00h, 00h, 51h, 3Ah, 00h, 00h, 00h, 22h, 00h, 08h, 38h, 6Ah
	db	02h, 01h, 20h, 03h, 58h, 02h, 04h, 08h, 10h, 03h, 1Eh, 0F5h, 0EFh, 0FFh, 01h, 04h
	db	00h, 00h, 00h, 02h, 38h, 00h, 00h, 7Eh, 33h, 00h, 00h, 00h, 22h, 00h, 08h, 38h
	db	6Ch, 06h, 01h, 00h, 05h, 00h, 04h, 04h, 08h, 10h, 03h, 1Eh, 0F7h, 0EFh, 38h, 01h
	db	10h, 00h, 19h, 19h, 06h, 00h, 00h, 00h, 6Eh, 2Ah, 00h, 60h, 01h, 22h, 00h, 08h
	db	38h, 6Dh, 07h, 01h, 00h, 05h, 00h, 04h, 08h, 08h, 10h, 04h, 1Eh, 0C7h, 0EFh, 20h
	db	01h, 14h, 00h, 00h, 19h, 06h, 00h, 01h, 0A0h, 6Eh, 2Ah, 20h, 60h, 01h, 22h, 00h
	db	0Dh, 0Ah, 71h, 12h, 01h, 80h, 02h, 0E0h, 01h, 18h, 08h, 10h, 06h, 1Ah, 90h, 0EFh
	db	38h, 01h, 10h, 00h, 19h, 19h, 00h, 3Ch, 05h, 20h, 3Ah, 16h, 00h, 00h, 00h, 32h
	db	0E5h, 08h, 08h, 74h, 17h, 01h, 00h, 04h, 00h, 03h, 10h, 08h, 10h, 06h, 1Ah, 0B6h
	db	2Fh, 20h, 01h, 18h, 00h, 00h, 1Ch, 04h, 00h, 07h, 0A0h, 55h, 36h, 20h, 4Ah, 01h
	db	32h, 0E1h, 0Eh, 0Eh, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	db	00h, 00h, 00h, 00h, 00h
LAB_1907:
	db	84h, 18h, 10h, 00h, 20h, 01h, 03h, 00h, 02h, 6Bh, 0A0h
	db	83h, 84h, 83h, 8Ah, 9Eh, 0BFh, 1Fh, 00h, 4Fh, 0Dh, 0Eh, 00h, 00h, 00h, 00h, 9Ch
	db	8Eh, 8Fh, 42h, 1Fh, 95h, 0BAh, 0A3h, 0FFh, 00h, 01h, 02h, 03h, 04h, 05h, 14h, 07h
	db	38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh, 08h, 00h, 0Fh, 00h, 00h, 00h, 00h, 00h
	db	00h, 10h, 0Eh, 00h, 0FFh, 84h, 2Ah, 08h, 00h, 30h, 01h, 03h, 00h, 02h, 0ABh, 0A0h
	db	83h, 84h, 83h, 8Ah, 9Eh, 0BFh, 1Fh, 00h, 47h, 05h, 06h, 00h, 00h, 00h, 00h, 83h
	db	85h, 57h, 42h, 1Fh, 63h, 0BAh, 0A3h, 0FFh, 00h, 01h, 02h, 03h, 04h, 05h, 14h, 07h
	db	38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh, 08h, 00h, 0Fh, 00h, 00h, 00h, 00h, 00h
	db	00h, 10h, 0Eh, 00h, 0FFh, 84h, 18h, 0Eh, 00h, 20h, 01h, 03h, 00h, 02h, 0ABh, 0A0h
	db	83h, 84h, 83h, 8Ah, 9Eh, 0BFh, 1Fh, 00h, 4Dh, 0Bh, 0Ch, 00h, 00h, 00h, 00h, 83h
	db	85h, 5Dh, 42h, 1Fh, 63h, 0BAh, 0A3h, 0FFh, 00h, 01h, 02h, 03h, 04h, 05h, 14h, 07h
	db	38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh, 08h, 00h, 0Fh, 00h, 00h, 00h, 00h, 00h
	db	00h, 10h, 0Eh, 00h, 0FFh, 64h, 24h, 10h, 00h, 0F0h, 01h, 0Fh, 00h, 06h, 2Fh, 7Bh
	db	63h, 64h, 9Eh, 69h, 92h, 6Fh, 0F0h, 00h, 60h, 00h, 00h, 00h, 00h, 00h, 00h, 58h
	db	8Ah, 57h, 32h, 00h, 58h, 6Fh, 0E3h, 0FFh, 00h, 01h, 02h, 03h, 04h, 05h, 14h, 07h
	db	38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh, 01h, 00h, 0Fh, 00h, 00h, 00h, 00h, 00h
	db	00h, 00h, 05h, 0Fh, 0FFh, 80h, 2Fh, 10h, 00h, 0C0h, 01h, 0Fh, 00h, 06h, 2Fh, 99h
	db	7Fh, 80h, 9Ch, 83h, 19h, 96h, 1Fh, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 80h
	db	84h, 7Fh, 40h, 00h, 80h, 96h, 0E3h, 0FFh, 00h, 01h, 02h, 03h, 04h, 05h, 14h, 07h
	db	38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh, 01h, 00h, 0Fh, 00h, 00h, 00h, 00h, 00h
	db	00h, 00h, 05h, 0Fh, 0FFh, 0A0h, 3Fh, 10h, 00h, 80h, 01h, 0Fh, 00h, 06h, 0EFh, 0BDh
	db	9Fh, 0A0h, 80h, 0A4h, 19h, 2Ah, 0B2h, 00h, 60h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh
	db	80h, 0FFh, 50h, 00h, 00h, 2Ah, 0E3h, 0FFh, 00h, 01h, 02h, 03h, 04h, 05h, 14h, 07h
	db	38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh, 01h, 00h, 0Fh, 00h, 00h, 00h, 00h, 00h
	db	00h, 00h, 05h, 0Fh, 0FFh, 28h, 18h, 08h, 00h, 20h, 01h, 0Fh, 00h, 0Eh, 6Fh, 2Dh
	db	27h, 27h, 91h, 2Ah, 90h, 0BFh, 1Fh, 00h, 0C0h, 00h, 00h, 00h, 00h, 00h, 00h, 9Ch
	db	8Eh, 8Fh, 00h, 00h, 97h, 0B8h, 0E3h, 0FFh, 00h, 01h, 02h, 03h, 04h, 05h, 06h, 07h
	db	08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 0Fh, 41h, 00h, 0Fh, 00h, 00h, 00h, 00h, 00h
	db	00h, 00h, 05h, 0Fh, 0FFh, 50h, 18h, 10h, 00h, 80h, 01h, 0Fh, 00h, 06h, 63h, 60h
	db	4Fh, 50h, 82h, 54h, 80h, 0BFh, 1Fh, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 9Ch
	db	0AEh, 8Fh, 28h, 00h, 97h, 0B8h, 0E3h, 0FFh, 00h, 01h, 02h, 03h, 04h, 05h, 06h, 07h
	db	08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 0Fh, 01h, 00h, 0Fh, 00h, 00h, 00h, 00h, 00h
	db	00h, 00h, 05h, 0Fh, 0FFh

LAB_1b07:
	db	38h, 28h, 2Dh, 0Ah, 1Fh, 06h, 19h, 1Ch, 02h, 07h, 06h, 07h, 00h, 00h, 00h, 00h			; 6845 register values for modes 00h and 01h
	db	71h, 50h, 5Ah, 0Ah, 1Fh, 06h, 19h, 1Ch, 02h, 07h, 06h, 07h, 00h, 00h, 00h, 00h			; 6845 register values for modes 02h and 03h
	db	38h, 28h, 2Dh, 0Ah, 7Fh, 06h, 64h, 70h, 02h, 01h, 06h, 07h, 00h, 00h, 00h, 00h			; 6845 register values for modes 04h and 05h
	db	61h, 50h, 52h, 0Fh, 19h, 06h, 19h, 19h, 02h, 0Dh, 0Bh, 0Ch, 00h, 00h, 00h, 00h			; 6845 register values for modes 06h and 07h
	dw	800h												; bytes in video buffer for modes 00h and 01h
	dw	1000h												; bytes in video buffer for modes 02h and 03h
	dw	4000h												; bytes in video buffer for modes 04h and 05h
	dw	4000h												; bytes in video buffer for mode 06h
LAB_1b4f:
	db	2Ch, 28h, 2Dh, 29h, 2Ah, 2Eh, 1Eh, 29h								; columns on screen for each of modes 00h through 07h
	db	00h, 0BAh, 0C4h, 03h, 0ECh, 8Ah, 0E8h, 8Ah							; CRT controller mode bytes for each of modes 00h through 07h

	db	46h, 10h, 0F6h
	db	06h, 87h, 04h, 08h, 74h, 03h, 0E9h, 0C1h, 03h, 0Ah, 0C0h, 75h, 2Fh, 0C6h, 46h, 10h
	db	1Ch, 33h, 0DBh, 0D0h, 0E9h, 73h, 03h, 83h, 0C3h, 63h, 0D0h, 0E9h, 73h, 03h, 83h, 0C3h
	db	3Ah, 0D0h, 0E9h, 73h, 04h, 81h, 0C3h, 0Dh, 03h, 0Bh, 0DBh, 74h, 06h, 83h, 0C3h, 20h
	db	83h, 0C3h, 3Fh, 0C1h, 0EBh, 06h, 89h, 5Eh, 0Eh, 0E9h, 8Eh, 03h, 8Bh, 7Eh, 0Eh, 0FEh
	db	4Eh, 10h, 74h, 03h, 0E9h, 94h, 01h, 83h, 0C7h, 20h, 50h, 51h, 57h, 8Bh, 7Eh, 0Eh
	db	0B9h, 10h, 00h, 33h, 0C0h, 0F3h, 0ABh, 5Fh, 59h, 58h, 0F6h, 46h, 0Ch, 01h, 75h, 03h
	db	0E9h, 0C0h, 00h, 8Bh, 0F7h, 26h, 89h, 3Fh, 26h, 0C7h, 47h, 10h, 20h, 00h, 0B2h, 0CAh
	db	0ECh, 0AAh, 8Ah, 0C5h, 0AAh, 0E8h, 96h, 0F1h, 52h, 0ECh, 0AAh, 0B2h, 0CEh, 0ECh, 0AAh, 0B2h
	db	0C4h, 0B3h, 01h, 0B9h, 04h, 00h, 0E8h, 8Eh, 03h, 0B0h, 02h, 0EEh, 0B2h, 0CCh, 0ECh, 0AAh
	db	5Ah, 32h, 0DBh, 0B9h, 19h, 00h, 0E8h, 7Eh, 03h, 0B9h, 14h, 00h, 32h, 0E4h, 0E8h, 83h
	db	03h, 0AAh, 0E2h, 0FAh, 0B2h, 0CEh, 32h, 0DBh, 0B9h, 09h, 00h, 0E8h, 69h, 03h, 0B4h, 14h
	db	0E8h, 71h, 03h, 0AAh, 0E8h, 0Ch, 2Fh, 0E8h, 75h, 0F3h, 75h, 3Ah, 0BAh, 0C4h, 03h, 0B3h
	db	06h, 0B9h, 0Eh, 00h, 0E8h, 50h, 03h, 0B3h, 16h, 0B1h, 01h, 0E8h, 49h, 03h, 0B3h, 18h
	db	0B1h, 07h, 0E8h, 42h, 03h, 0B2h, 0CEh, 0B3h, 09h, 0B1h, 03h, 0E8h, 39h, 03h, 0B3h, 10h
	db	0B1h, 02h, 0E8h, 32h, 03h, 0E8h, 26h, 0F1h, 0B3h, 19h, 0B1h, 03h, 0E8h, 28h, 03h, 0B2h
	db	0C6h, 0E8h, 0A1h, 0ECh, 0ECh, 0AAh, 0BAh, 0CEh, 03h, 0B0h, 04h, 0E8h, 95h, 0F0h, 50h, 52h
	db	80h, 0E4h, 0FCh, 0EFh, 8Bh, 0DAh, 43h, 0E8h, 04h, 0F1h, 0B0h, 22h, 0EEh, 42h, 0B9h, 04h
	db	00h, 32h, 0C0h, 52h, 8Bh, 0D3h, 0EEh, 5Ah, 50h, 0ECh, 0AAh, 58h, 0FEh, 0C0h, 0E2h, 0F3h
	db	5Ah, 58h, 0EFh, 0F6h, 46h, 0Ch, 02h, 74h, 14h, 53h, 8Bh, 5Eh, 0Eh, 57h, 2Bh, 0FBh
	db	26h, 89h, 7Fh, 12h, 5Fh, 26h, 89h, 7Fh, 02h, 5Bh, 0E8h, 0B1h, 2Ch, 0F6h, 46h, 0Ch
	db	04h, 74h, 65h, 53h, 8Bh, 5Eh, 0Eh, 57h, 2Bh, 0FBh, 26h, 89h, 7Fh, 14h, 5Fh, 26h
	db	89h, 7Fh, 04h, 5Bh, 0B2h, 0C6h, 0ECh, 0AAh, 42h, 0ECh, 0AAh, 8Ah, 0E8h, 42h, 0ECh, 8Ah
	db	0C8h, 0Ah, 0EDh, 74h, 01h, 48h, 0AAh, 26h, 0C6h, 05h, 03h, 26h, 0FEh, 0Dh, 74h, 0Fh
	db	42h, 0Ah, 0EDh, 74h, 03h, 0ECh, 0EBh, 01h, 0EEh, 4Ah, 0ECh, 3Ah, 0C1h, 74h, 0ECh, 47h
	db	32h, 0C0h, 0B9h, 00h, 03h, 0E8h, 27h, 00h, 0E8h, 30h, 00h, 32h, 0C0h, 0B9h, 03h, 00h
	db	0E8h, 1Ch, 00h, 0B8h, 0Fh, 00h, 0B9h, 03h, 00h, 0E8h, 13h, 00h, 0B8h, 02h, 00h, 0B9h
	db	03h, 00h, 0E8h, 0Ah, 00h, 0E8h, 25h, 00h, 0C6h, 46h, 10h, 1Ch, 0E9h, 1Bh, 02h, 0B2h
	db	0C7h, 0EEh, 0EBh, 00h, 0B2h, 0C9h, 0ECh, 0AAh, 0E2h, 0FCh, 0C3h, 0B2h, 0C4h, 0ECh, 8Ah, 0D8h
	db	0B0h, 12h, 0EEh, 42h, 0ECh, 8Ah, 0E0h, 0Ch, 02h, 50h, 58h, 0EEh, 0C3h, 0B2h, 0C4h, 0B0h
	db	12h, 0EEh, 42h, 8Ah, 0C4h, 0EEh, 8Ah, 0C3h, 4Ah, 0EEh, 0C3h, 0FEh, 4Eh, 10h, 75h, 0CCh
	db	8Bh, 0F7h, 06h, 1Fh, 0F6h, 46h, 0Ch, 01h, 75h, 03h, 0E9h, 4Eh, 01h, 8Bh, 7Eh, 0Eh
	db	8Bh, 75h, 10h, 03h, 0F7h, 53h, 56h, 83h, 0C6h, 04h, 06h, 1Eh, 8Ch, 0D8h, 8Eh, 0C0h
	db	33h, 0C0h, 8Eh, 0D8h, 0A0h, 89h, 04h, 80h, 26h, 89h, 04h, 0F7h, 24h, 08h, 50h, 83h
	db	0EEh, 05h, 0E8h, 4Ch, 2Eh, 26h, 8Ah, 3Ch, 46h, 0B3h, 14h, 0E8h, 88h, 1Eh, 58h, 08h
	db	06h, 89h, 04h, 1Fh, 07h, 0E8h, 0E6h, 0EFh, 80h, 0C2h, 06h, 52h, 0E8h, 00h, 0F2h, 74h
	db	02h, 0EBh, 3Dh, 0BAh, 0C4h, 03h, 0B3h, 06h, 0B9h, 0Eh, 00h, 0E8h, 0CEh, 01h, 0B3h, 16h
	db	0B1h, 01h, 0E8h, 0C7h, 01h, 0B3h, 18h, 0B1h, 07h, 0E8h, 0C0h, 01h, 0B2h, 0CEh, 0B3h, 09h
	db	0B1h, 03h, 0E8h, 0B7h, 01h, 0B3h, 10h, 0B1h, 02h, 0E8h, 0B0h, 01h, 0E8h, 0AFh, 0EFh, 0B3h
	db	19h, 0B1h, 03h, 0E8h, 0A6h, 01h, 0B2h, 0C6h, 0E8h, 2Ah, 0EBh, 0ACh, 0EEh, 0B0h, 0FFh, 0EEh
	db	0B2h, 0C4h, 0B0h, 02h, 0E8h, 1Ch, 0EFh, 50h, 0B4h, 0Fh, 0EFh, 0B0h, 04h, 0E8h, 13h, 0EFh
	db	50h, 0B4h, 07h, 0EFh, 0B2h, 0CEh, 0B0h, 04h, 0E8h, 08h, 0EFh, 50h, 0B0h, 05h, 0E8h, 02h
	db	0EFh, 50h, 32h, 0E4h, 0EFh, 0B0h, 06h, 0E8h, 0F9h, 0EEh, 50h, 0B4h, 04h, 0EFh, 0B0h, 02h
	db	0E8h, 0F0h, 0EEh, 50h, 0B8h, 00h, 0A0h, 8Eh, 0C0h, 0BFh, 0FFh, 0FFh, 0B9h, 03h, 00h, 0B0h
	db	04h, 8Ah, 0E1h, 0EFh, 26h, 8Ah, 05h, 50h, 49h, 83h, 0F9h, 0FFh, 75h, 0F1h, 0B5h, 04h
	db	0B1h, 01h, 0B2h, 0C4h, 0B0h, 02h, 8Ah, 0E1h, 0EFh, 0ACh, 26h, 88h, 05h, 0D0h, 0E1h, 0FEh
	db	0CDh, 75h, 0F1h, 0B9h, 03h, 00h, 0B2h, 0CEh, 0B0h, 04h, 8Ah, 0E1h, 0EFh, 26h, 8Ah, 05h
	db	49h, 83h, 0F9h, 0FFh, 75h, 0F2h, 0B2h, 0C4h, 0B5h, 04h, 0B1h, 01h, 5Bh, 0B0h, 02h, 8Ah
	db	0E1h, 0EFh, 26h, 88h, 1Dh, 0D0h, 0E1h, 0FEh, 0CDh, 75h, 0F1h, 0B2h, 0CEh, 58h, 0EFh, 58h
	db	0EFh, 58h, 0EFh, 58h, 0EFh, 0B2h, 0C4h, 58h, 0EFh, 58h, 0EFh, 5Ah, 8Bh, 0FEh, 5Eh, 8Ah
	db	04h, 0EEh, 80h, 0EAh, 06h, 8Ah, 44h, 02h, 0EEh, 80h, 0FAh, 0D4h, 74h, 05h, 88h, 46h
	db	0FFh, 0EBh, 03h, 88h, 46h, 0FCh, 0B2h, 0CEh, 8Ah, 44h, 03h, 0EEh, 88h, 46h, 0FEh, 0B2h
	db	0C4h, 8Ah, 44h, 01h, 0EEh, 88h, 46h, 0FDh, 8Bh, 0F7h, 5Bh, 0F6h, 46h, 0Ch, 02h, 74h
	db	0Bh, 8Bh, 7Eh, 0Eh, 8Bh, 75h, 12h, 03h, 0F7h, 0E8h, 87h, 00h, 0F6h, 46h, 0Ch, 04h
	db	74h, 74h, 8Bh, 7Eh, 0Eh, 8Bh, 75h, 14h, 03h, 0F7h, 0BAh, 0C6h, 03h, 8Ah, 04h, 0EEh
	db	56h, 83h, 0C6h, 04h, 0BAh, 0C8h, 03h, 32h, 0C0h, 0B9h, 00h, 03h, 9Ch, 0FAh, 0E8h, 5Ah
	db	00h, 0E8h, 47h, 0FEh, 0B2h, 0C8h, 0B9h, 03h, 00h, 0B0h, 00h, 0E8h, 4Dh, 00h, 0B9h, 03h
	db	00h, 0B0h, 0Fh, 0E8h, 45h, 00h, 0B9h, 03h, 00h, 0B0h, 02h, 0E8h, 3Dh, 00h, 0E8h, 3Ch
	db	0FEh, 9Dh, 5Eh, 0FEh, 44h, 03h, 33h, 0C0h, 8Ah, 44h, 02h, 0B2h, 0C7h, 8Ah, 6Ch, 01h
	db	0Ah, 0EDh, 75h, 0Ch, 42h, 50h, 0B0h, 03h, 0F6h, 64h, 02h, 93h, 8Bh, 58h, 04h, 58h
	db	0EEh, 0B2h, 0C9h, 0FEh, 4Ch, 03h, 74h, 0Eh, 0Ah, 0EDh, 74h, 03h, 0ECh, 0EBh, 0F4h, 86h
	db	0C3h, 0EEh, 86h, 0FBh, 0EBh, 0EDh, 0C6h, 46h, 10h, 1Ch, 0C3h, 0EEh, 0FEh, 0C2h, 0F3h, 6Eh
	db	0FEh, 0CAh, 0C3h, 33h, 0C0h, 8Eh, 0C0h, 26h, 80h, 26h, 10h, 04h, 0CFh, 0ACh, 26h, 08h
	db	06h, 10h, 04h, 0BFh, 49h, 04h, 0B9h, 1Eh, 00h, 0F3h, 0A4h, 0BFh, 84h, 04h, 0B1h, 07h
	db	0F3h, 0A4h, 0BFh, 0A8h, 04h, 0A5h, 0A5h, 0BFh, 14h, 00h, 0A5h, 0A5h, 0BFh, 74h, 00h, 0A5h
	db	0A5h, 0BFh, 7Ch, 00h, 0A5h, 0A5h, 0BFh, 0Ch, 01h, 0A5h, 0A5h, 0C3h, 0ACh, 8Ah, 0E0h, 8Ah
	db	0C3h, 0EFh, 0FEh, 0C3h, 0E2h, 0F6h, 0C3h, 8Ah, 0C3h, 0E8h, 77h, 0EDh, 8Ah, 0C4h, 0AAh, 0FEh
	db	0C3h, 0E2h, 0F4h, 0C3h

LAB_1f86:
	call	GetCRTCIndex
	add	dl,6
	in	al,dx
	mov	al,ah
	mov	dl,0C0h
	out	dx,al
	inc	dx
	in	al,dx
	inc	ah
	ret

LAB_1f97:	
	db	'STB Vision',0
	db	80h,1Bh,04h,04h
	db	'-5429 VGA',0

LAB_1fb0:
	dw	LAB_1fe8
	dw	LAB_204e
	dw	LAB_2203
	dw	LAB_2237
	dw	LAB_224b
	dw	LAB_2272
	dw	LAB_22b5
	dw	LAB_234d
	dw	LAB_2495

LAB_1fc2:
	call	LAB_0f91
	jnz	LAB_1fde
	cmp	al,10h
	jnz	LAB_1fce
	jmp	LAB_5231
LAB_1fce:
	cmp	al,8
	ja	LAB_1fde
	cbw
	mov	si,ax
	SHL	si,1
	cs call	[si+LAB_1fb0]
	jmp	SHORT LAB_1fe0

LAB_1fde:
	xor	al,al
LAB_1fe0:
	cmp	al,4Fh
	jnz	LAB_1fe7
	mov	[bp+10h],ax
LAB_1fe7:
	ret

LAB_1fe8:
	push	ds
	push	di
	push	cx
	mov	cx,0Ah
	call	LAB_2544
	mov	cx,es
	mov	ds,cx
	mov	[di],WORD 4556h			; TODO
	mov	[di+2],WORD 4153h
	mov	[di+4],WORD 102h
	mov	[di+6],WORD 1F97h
	mov	[di+8],cs
	call	LAB_1427
	mov	[di+12h],ax
	mov	ax,di
	add	ax,14h
	mov	[di+0Eh],ax
	mov	[di+10h],es
	mov	di,ax
	mov	cx,14h
LAB_2021:
	mov	ax,cx
	push	es
	push	di
	call	LAB_0dd6
	mov	si,es
	mov	ds,si
	mov	si,di
	pop	di
	pop	es
	cmp	si,BYTE -1
	jz	LAB_203d
	mov	ax,[si+1]
	or	ax,ax
	jz	LAB_203d
	stosw
LAB_203d:
	inc	cx
	cmp	cl,80h
	jc	LAB_2021
	mov	ax,0FFFFh
	stosw
	pop	cx
	pop	di
	pop	ds
	mov	ax,4Fh
	ret

LAB_204e:
	push	ds
	push	di
	push	cx
	push	bx
	and	ch,7Fh
	mov	bx,cx
	mov	cx,80h
	call	LAB_2544
	mov	al,bl
	test	bx,7F80h
	jz	LAB_2067
	mov	al,0FFh
LAB_2067:
	xor	ah,ah
	push	es
	push	di
	call	LAB_0dd6
	mov	si,es
	mov	ds,si
	mov	si,di
	pop	di
	pop	es
	cmp	si,BYTE -1
	jnz	LAB_207e
	jmp	LAB_21e1

LAB_207e:
	mov	ax,[si+3]
	es mov	[di+12h],ax
	mov	ax,[si+5]
	es mov	[di+14h],ax
	mov	al,[si+7]
	es mov	[di+19h],al
	mov	al,[si+8]
	es mov	[di+16h],al
	mov	al,[si+9]
	es mov	[di+17h],al
	es mov	[di+18h],BYTE 1
	mov	al,[si+0Bh]
	xor	ah,ah
	or	al,1
	es mov	[di],ax
	mov	al,[si+0Ah]
	es mov	[di+1Bh],al
	push	ds
	mov	bx,es
	mov	ds,bx
	mov	[di+2],BYTE 7
	mov	[di+8],WORD 0A000h
	mov	[di+4],WORD 4
	pop	ds
	test	[si+1Ah],BYTE 20h
	mov	ds,bx
	jz	LAB_20d8
	mov	[di+4],WORD 10h
LAB_20d8:
	mov	[di+6],WORD 40h
	mov	[di+0Ch],WORD 22B1h
	mov	[di+0Eh],cs
	mov	[di+1Ah],BYTE 1
	mov	[di+1Eh],BYTE 1
	cbw
	mov	bx,ax
	SHL	bx,1
	cs jmp	[bx+LAB_20f7]

LAB_20f7:
	dw	LAB_2105
	dw	LAB_21e1
	dw	LAB_21e1
	dw	LAB_2161
	dw	LAB_2176
	dw	LAB_21e1
	dw	LAB_2184

LAB_2105:
	mov	[di+3],BYTE 0
	mov	[di+4],WORD 20h
	mov	[di+6],WORD 20h
	mov	[di+8],WORD 0B800h
	mov	[di+0AH],WORD 0
	test	[di],WORD 8
	jnz	LAB_2128
	mov	[di+8],WORD 0B000h
LAB_2128:
	mov	[di+0Ch],WORD 0
	mov	[di+0Eh],WORD 0
	mov	ax,[di+12h]
	div	BYTE [di+16h]
	xor	ah,ah
	mov	[di+12h],ax
	mov	ax,[di+14h]
	div	BYTE [di+17h]
	xor	ah,ah
	mov	[di+14h],ax
	mov	ax,[di+12h]
	SHL	ax,1
	mov	[di+10h],ax
	mov	bx,ax
	mov	ax,8000h
	xor	dx,dx
	div	bx
	div	BYTE [di+14h]
	mov	[di+1Dh],al
	jmp	SHORT LAB_21d9

LAB_2161:
	mov	ax,[di+12h]
	SHR	ax,3
	mov	[di+10h],ax
	call	LAB_21e9
	call	LAB_21f5
	mov	[di+18h],BYTE 4
	jmp	SHORT LAB_21d9

LAB_2176:
	mov	ax,[di+12h]
	mov	[di+10h],ax
	call	LAB_21e9
	call	LAB_21f8
	jmp	SHORT LAB_21d9

LAB_2184:
	mov	ax,[di+12h]
	SHL	ax,1
	cmp	[di+19h],BYTE 18h
	jnz	LAB_2192
	mov	ax,800h
LAB_2192:
	mov	[di+10h],ax
	call	LAB_21e9
	call	LAB_21f8
	mov	[di+1Fh],BYTE 5
	mov	[di+20h],BYTE 0Bh
	mov	[di+21h],BYTE 6
	mov	[di+22h],BYTE 5
	mov	[di+23h],BYTE 5
	cmp	[di+19h],BYTE 0Fh
	jnz	LAB_21bd
	mov	[di+20h],BYTE 0Ah
	mov	[di+21h],BYTE 5
LAB_21bd:
	cmp	[di+19h],BYTE 18h
	jnz	LAB_21d7
	mov	[di+1Fh],BYTE 8
	mov	[di+20h],BYTE 10h
	mov	[di+21h],BYTE 8
	mov	[di+22h],BYTE 8
	mov	[di+23h],BYTE 8
LAB_21d7:
	jmp	SHORT LAB_21d9
LAB_21d9:
	dec	BYTE [di+1Dh]
	mov	ax,4Fh
	jmp	SHORT LAB_21e4
LAB_21e1:
	mov	ax,14Fh
LAB_21e4:
	pop	bx
	pop	cx
	pop	di
	pop	ds
	ret

LAB_21e9:
	mov	bx,ax
	call	LAB_1427
	xor	dh,dh
	mov	dl,al
	xor	ax,ax
	ret

LAB_21f5:
	SHL	bx,2
LAB_21f8:
	div	bx
	xor	dx,dx
	div	WORD [di+14h]
	mov	[di+1Dh],al
	ret

LAB_2203:
	push	bx
	mov	ax,bx
	and	ah,80h
	test	bx,7F80h
	jz	LAB_2219
	and	bh,7Fh
	call	LAB_24af
	or	al,al
	jz	LAB_2232
LAB_2219:
	push	ax
	or	al,ah
	xor	ah,ah
	call	LAB_254b
	mov	ah,0Fh
	call	LAB_254b
	and	al,7Fh
	pop	bx
	cmp	al,bl
	jnz	LAB_2232
	mov	ax,4Fh
LAB_2230:
	pop	bx
	ret
LAB_2232:
	mov	ax,14Fh
	jmp	SHORT LAB_2230

LAB_2237:
	xor	bx,bx
	mov	ds,bx
	mov	bl,[CURR_VIDEO_MODE]
	mov	al,bl
	call	LAB_24cf
	mov	[bp+0Eh],bx
	mov	ax,4Fh
	ret

LAB_224b:
	push	cx
	mov	al,cl
	and	al,8
	SHR	al,3
	or	cl,al
	push	es
	and	cx,BYTE -9
	mov	ah,1Ch
	mov	al,dl
	call	LAB_254b
	pop	es
	cmp	al,1Ch
	jnz	LAB_226d
	mov	[bp+0Eh],bx
	mov	ax,4Fh
LAB_226b:
	pop	cx
	ret
LAB_226d:
	mov	ax,14Fh
	jmp	SHORT LAB_226b

LAB_2272:
	call	LAB_227d
	or	bh,bh
	jz	LAB_227c
	mov	[bp+0Ah],dx
LAB_227c:
	ret

LAB_227d:
	push	bx
	cmp	bl,1
	ja	LAB_22ac
	cmp	bh,1
	ja	LAB_22ac
	mov	ah,dl
	mov	dx,3CEh
	in	al,dx
	push	ax
	jz	LAB_2298
	mov	al,9
	add	al,bl
	out	dx,ax
	jmp	SHORT LAB_22a3
LAB_2298:
	mov	al,9
	add	al,bl
	call	ReadIndirectRegister
	mov	bl,ah
	xor	bh,bh
LAB_22a3:
	pop	ax
	out	dx,al
	mov	dx,bx
	mov	ax,4Fh
LAB_22aa:
	pop	bx
	ret
LAB_22ac:
	mov	ax,14Fh
	jmp	SHORT LAB_22aa

LAB_22b1:
	call	LAB_227d
	retf

LAB_22b5:
	call	GetCRTCIndex
	mov	al,13h
	call	ReadIndirectRegister
	mov	bh,ah
	call	LAB_24f0
	cmp	bl,1
	jc	LAB_22ce
	jz	LAB_22e0
LAB_22c9:
	mov	ax,14Fh
	jmp	SHORT LAB_2333
LAB_22ce:
	cmp	al,1
	jc	LAB_22c9
	jz	LAB_22f0
	cmp	al,3
	jc	LAB_22c9
	jz	LAB_22f2
	cmp	al,4
	jz	LAB_2313
	jmp	SHORT LAB_22c9

LAB_22e0:
	cmp	al,1
	jc	LAB_22c9
	jz	LAB_22f0
	cmp	al,3
	jc	LAB_22c9
	jz	LAB_22fc
	cmp	al,4
	jz	LAB_231b
LAB_22f0:
	jmp	SHORT LAB_22c9

LAB_22f2:
	mov	ax,cx
	add	ax,0Fh
	SHR	ax,1
	call	LAB_2334
LAB_22fc:
	mov	bl,bh
	xor	bh,bh
	SHL	bx,1
	push	bx
	push	bx
	SHL	bx,3
	mov	cx,bx
	pop	bx
	call	LAB_233f
	SHR	dx,2
	pop	bx
	jmp	SHORT LAB_2327
LAB_2313:
	mov	ax,cx
	add	ax,7
	call	LAB_2334
LAB_231b:
	mov	bl,bh
	xor	bh,bh
	SHL	bx,3
	mov	cx,bx
	call	LAB_233f
LAB_2327:
	mov	[bp+0Eh],bx
	mov	[bp+0Ch],cx
	mov	[bp+0Ah],dx
	mov	ax,4Fh
LAB_2333:
	ret

LAB_2334:
	SHR	ax,3
	mov	ah,al
	mov	bh,ah
	mov	al,13h
	out	dx,ax
	ret

LAB_233f:
	call	LAB_1427
	xor	dh,dh
	mov	dl,al
	xor	ax,ax
	div	bx
	mov	dx,ax
	ret

LAB_234d:
	push	bx
	call	LAB_24f0
	cmp	bl,1
	jc	LAB_2361
	jz	LAB_235e
LAB_2358:
	mov	ax,14Fh
	jmp	LAB_245b
LAB_235e:
	jmp	LAB_23f7

LAB_2361:
	cmp	al,1
	jc	LAB_2358
	jz	LAB_2371
	cmp	al,3
	jc	LAB_2358
	jz	LAB_2373
	cmp	al,4
	jz	LAB_23e6
LAB_2371:
	jmp	SHORT LAB_2358
LAB_2373:
	push	dx
	push	cx
	push	bp
	mov	bp,1
	call	LAB_238c
	pop	bp
	and	cl,7
LAB_2380:
	mov	bh,cl
	mov	bl,13h
	call	LAB_3c08
	pop	cx
	pop	dx
	jmp	LAB_2452

LAB_238c:
	mov	bx,dx
	call	GetCRTCIndex
	mov	al,13h
	call	ReadIndirectRegister
	mov	al,ah
	xor	ah,ah
	push	ax
	mov	al,1Bh
	call	ReadIndirectRegister
	test	ah,10h
	pop	ax
	jz	LAB_23a9
	or	ah,1
LAB_23a9:
	SHL	ax,1
	push	dx
	mul	bx
	mov	si,dx
	pop	dx
	push	cx
	SHR	cx,2
	cmp	bp,BYTE 1
	jnz	LAB_23bc
	SHR	cx,1
LAB_23bc:
	add	ax,cx
	adc	si,BYTE 0
	pop	cx
	mov	bl,al
	mov	al,0Ch
	out	dx,ax
	jmp	SHORT LAB_23c9
LAB_23c9:
	inc	ax
	mov	ah,bl
	out	dx,ax
	mov	ax,si
	mov	bh,al
	and	bh,2
	SHL	bh,1
	and	al,1
	or	bh,al
	mov	al,1Bh
	call	ReadIndirectRegister
	and	ah,0FAh
	or	ah,bh
	out	dx,ax
	ret
LAB_23e6:
	push	dx
	push	cx
	push	bp
	mov	bp,0
	call	LAB_238c
	pop	bp
	and	cl,3
	SHL	cl,1
	jmp	SHORT LAB_2380

LAB_23f7:
	call	GetCRTCIndex
	push	ax
	mov	al,13h
	call	ReadIndirectRegister
	mov	al,ah
	xor	ah,ah
	push	ax
	mov	al,1Bh
	call	ReadIndirectRegister
	test	ah,10h
	pop	ax
	jz	LAB_2413
	or	ah,1
LAB_2413:
	SHL	ax,1
	mov	cx,ax
	mov	al,0Ch
	call	ReadIndirectRegister
	mov	bh,ah
	inc	ax
	call	ReadIndirectRegister
	mov	bl,ah
	pop	ax
	cmp	al,1
	jc	LAB_2435
	jz	LAB_2435
	cmp	al,3
	jc	LAB_2435
	jz	LAB_2438
	cmp	al,4
	jz	LAB_2443
LAB_2435:
	jmp	LAB_2358

LAB_2438:
	call	LAB_2461
	push	ax
	SHL	cx,1
	call	LAB_247c
	jmp	SHORT LAB_244c
LAB_2443:
	call	LAB_2461
	push	ax
	call	LAB_247c
	SHR	ah,1
LAB_244c:
	add	cl,ah
	adc	ch,0
	pop	dx
LAB_2452:
	mov	[bp+0Ch],cx
	mov	[bp+0Ah],dx
	mov	ax,4Fh
LAB_245b:
	pop	bx
	mov	[bp+0Fh],BYTE 0
	ret

LAB_2461:
	push	dx
	mov	al,1Bh
	call	ReadIndirectRegister
	mov	al,ah
	and	ax,401h
	SHR	ah,1
	or	al,ah
	xor	ah,ah
	mov	dx,ax
	mov	ax,bx
	div	cx
	mov	cx,dx
	pop	dx
	ret

LAB_247c:
	SHL	cx,2
	add	dl,6
	in	al,dx
	mov	bl,dl
	mov	dl,0C0h
	mov	al,13h
	call	ReadIndirectRegister
	xchg	dl,bl
	in	al,dx
	mov	dl,bl
	mov	al,20h
	out	dx,al
	ret

LAB_2495:
	mov	ax,14Fh
	cmp	bl,1
	ja	LAB_24ae
	jz	LAB_24a6
	cmp	bh,6
	mov	bh,6
	jnz	LAB_24ae
LAB_24a6:
	mov	bh,6
	mov	[bp+0Eh],bx
	mov	ax,4Fh
LAB_24ae:
	ret

LAB_24af:
	push	es
	push	ds
	push	di
	push	si
	push	cx
	mov	ch,ah
	mov	al,0FFh
	xor	ah,ah
	call	LAB_0dd6
	xor	al,al
	cmp	di,BYTE -1
	jz	LAB_24c7
	es mov	al,[di]
LAB_24c7:
	mov	ah,ch
	pop	cx
	pop	si
	pop	di
	pop	ds
	pop	es
	ret

LAB_24cf:
	push	es
	push	ds
	push	di
	push	si
	push	ax
	xor	ah,ah
	mov	bx,ax
	call	LAB_0dd6
	cmp	di,BYTE -1
	jz	LAB_24ea
	es mov	bx,[di+1]
	or	bx,bx
	jnz	LAB_24ea
	mov	bx,ax
LAB_24ea:
	pop	ax
	pop	si
	pop	di
	pop	ds
	pop	es
	ret

LAB_24f0:
	push	dx
	push	bx
	mov	bh,ah
	mov	bl,5
	mov	dx,SEQ_INDEX
	mov	al,7
	call	ReadIndirectRegister
	test	ah,6
	jnz	LAB_2527
	mov	bl,1
	mov	dx,3CEh
	mov	al,6
	call	ReadIndirectRegister
	test	ah,1
	jz	LAB_2527
	mov	bl,2
	mov	al,5
	call	ReadIndirectRegister
	test	ah,20h
	jnz	LAB_2527
	mov	bl,3
	test	ah,40h
	jz	LAB_2527
	mov	bl,4
LAB_2527:
	mov	ax,bx
	pop	bx
	pop	dx
	ret

LAB_252c:
	push	dx
	push	bx
	mov	bh,ah
	mov	dx,SEQ_INDEX
	mov	al,1
	call	ReadIndirectRegister
	and	ah,1
	mov	al,9
	sub	al,ah
	mov	ah,bh
	pop	bx
	pop	dx
	ret

LAB_2544:
	push	di
	xor	ax,ax
	rep stosw
	pop	di
	ret

LAB_254b:
	pushf
	push	cs
	call	LAB_293d
	ret

LAB_2551:
	dw	0
LAB_2553:
	dw	0
LAB_2555:
	dw	0A000h
	dw	081Ah
	dw	07B2h
	dw	100Ah
	

;-------------------------------------------------------------------------------
; Video BIOS Installation Entry Point
;-------------------------------------------------------------------------------
; This function is called by the system BIOS to install the Video BIOS.
;
; We must return using RETF!!!
;-------------------------------------------------------------------------------
entry:
	cli
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	push	ds
	cld
	mov	bp,sp
	mov	[bp+4],WORD 0				; Clear saved BP
	mov	ds,cs:[LAB_2551]

	mov	ax,1201h				; Disable video addressing
	mov	bl,32h					; Magic value
	int	10h					; Call BIOS

	call	EnableHardware				; Enable video hardware
	call	UnlockAndInitialize			; Initialize it

	mov	dx,MISC_OUTPUT
	mov	al,23h					; Vertical sync normally low
							; Horizontl sync normally low
							; Page select: even memory
							; VCLK source: VCLK0, 25.180 MHz
							; Enable display memory
							; CRTC color mode
	out	dx,al					; Set misc output reg

	xor	al,al					; Initial video mode 40x5 text
	mov	[CURR_VIDEO_MODE],al			; Initialize video mode
	mov	[VIDEO_CONTROL],BYTE 60h		; 256K VRAM
	mov	[VIDEO_MODE_CONTROL],BYTE 0

	call	SetupInterruptVectors			; Initialize interrupt vectors
	call	DetectOtherCards			; Handle other installed cards

	mov	ax,0B07h				; Mono config:
							; (07) 80x25 mono
							; (0B) 350 line, EGA emulation,
							; default palette loading disabled,
							; gray scale summing, VGA active

	test	[VIDEO_CONTROL],BYTE 2			; Check for mono monitor
	jnz	.1					; Jump if mono

	mov	ax,903h					; Mono config:
							; (03) 80x25 color
							; (09) 350 line, EGA emulation,
							; default palette loading disabled,
							; VGA active
.1:
	mov	[VIDEO_SWITCHES],ah			; Set configuration

	xor	ah,ah					; Set video mode
	int	10h					; Call BIOS
	call	UpdateHardwareEnable			; Update enabled hardware

	or	[VIDEO_MODE_CONTROL],BYTE 10h		; Enable 400 lines

	test	[VIDEO_MODE_CONTROL],BYTE 1		; Is VGA active?
	jnz	.3					; Yes, jump

	mov	ax,[INSTALLED_HW]			; Read installed hardware
	push	ax					; Save it

	mov	bl,3					; Video mode: 80x25 color
	mov	ax,3007h				; (30) = 80x25 mono text
							; (07) = ?

	test	[VIDEO_CONTROL],BYTE 2			; Is it mono monitor?
	jz	.2					; No, jump for color

	mov	ax,2003h				; (20) = 80x25 CGA color
							; (03) = ?
	mov	bl,7					; Video mode: 80x25 mono

.2:
	and	[INSTALLED_HW],BYTE 0CFh		; Clear video mode bits
	or	[INSTALLED_HW],ah			; Set video mode bits

	xor	ah,ah
	call	LAB_2cd9

	pop	ax					; Restore saved installed hardware values

	mov	[INSTALLED_HW],ax			; Restore installed hardware value

	mov	al,bl					; Select video mode
	xor	ah,ah					; Set video mode
	int	10h					; Call video BIOS
	call	UpdateHardwareEnable			; Update enabled hardware

.3:
	mov	al,0F0h					; Feature connector bits set
	or	[VIDEO_SWITCHES],al			; Set bits

	mov	al,0Eh
	test	[VIDEO_CONTROL],BYTE 2			; Is it mono?
	jz	.4					; No, jump
	mov	al,0Fh
.4:
	call	LAB_4ecc
	call	LAB_4bc3
	call	LAB_4b84

	mov	ax,0A000h				; Video RAM segment
	mov	es,ax					; Setup addressing

	mov	ax,805h					; Set GR5:
							;  - Non 256 colors
							;  - EGA-compatible shift register
							;  - Read mode 0
							;  - Write mode 0
	mov	dx,INDEX_REG				; Graphics controller index register
	out	dx,ax					; Write it

	mov	ax,0F02h				; Set GR2: All planes enabled
	out	dx,ax					; Write it

	mov	dl,0C4h					; Address sequencer index register (SEQ_INDEX)
	out	dx,ax					; Same configuration to plane mask register

	mov	si,8000h
	call	LAB_067b

	mov	al,3
	test	[VIDEO_CONTROL],BYTE 2
	jz	.5
	mov	al,7
.5:
	call	LAB_4ecc
	call	LAB_4bc3
	cs test	[LAB_0134],BYTE 2
	jnz	.6
	xor	al,al
	mov	[VIDEO_COMB_INDEX],al
	call	LAB_02ad
.6:
	call	LAB_2683
	cmp	[VIDEO_COMB_INDEX],BYTE 0
	jnz	.7
	call	LAB_270d
.7:
	call	LAB_1426
	call	LAB_0184
	mov	dx,INDEX_REG
	mov	ax,318h
	out	dx,ax
	mov	al,1Fh
	call	ReadIndirectRegister
	and	ah,0C0h
	or	ah,22h
	mov	dl,0CEh
	mov	al,0Eh
	call	ReadIndirectRegister
	and	ah,0F9h
	out	dx,ax
	call	LAB_4edc
	mov	sp,bp
	pop	ds
	pop	es
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	retf

LAB_2683:
	test	[VIDEO_MODE_CONTROL],BYTE 1
	jnz	LAB_26b3
	mov	ax,[INSTALLED_HW]
	push	ax
	mov	bl,3
	mov	ax,3007h
	test	[VIDEO_CONTROL],BYTE 2
	jz	LAB_269f
	mov	ax,2003h
	mov	bl,7
LAB_269f:
	and	[INSTALLED_HW],BYTE 0CFh
	or	[INSTALLED_HW],ah
	xor	ah,ah
	call	LAB_2cd9
	pop	ax
	mov	[INSTALLED_HW],ax
	jmp	SHORT LAB_26cd
LAB_26b3:
	test	[VIDEO_MODE_CONTROL],BYTE 4
	jnz	LAB_26c8
	test	[VIDEO_CONTROL],BYTE 8
	jnz	LAB_26c8
	and	[VIDEO_CONTROL],BYTE 0FDh
	jmp	SHORT LAB_26cd
LAB_26c8:
	or	[VIDEO_CONTROL],BYTE 2
LAB_26cd:
	mov	ax,2009h
	mov	bl,3
	test	[VIDEO_CONTROL],BYTE 2
	jz	LAB_26de
	mov	ax,300Bh
	mov	bl,7
LAB_26de:
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],al
	and	[INSTALLED_HW],BYTE 0CFh
	or	[INSTALLED_HW],ah
	mov	ah,[VIDEO_MODE_CONTROL]
	and	ah,1
	and	[VIDEO_MODE_CONTROL],BYTE 0FEh
	push	ax
	xor	ah,ah
	mov	al,bl
	int	10h
	pop	ax
	or	[VIDEO_MODE_CONTROL],ah
	ret

LAB_2709:
	db	0Ch, 0Bh, 0Eh, 0Dh

LAB_270d:
	mov	al,[VIDEO_CONTROL]
	and	al,2
	mov	ah,[VIDEO_MODE_CONTROL]
	and	ah,1
	or	al,ah
	xor	ah,ah
	mov	bx,ax
	cs mov	al,[bx+LAB_2709]
	mov	[VIDEO_COMB_INDEX],al
	ret

;-------------------------------------------------------------------------------
; TestCursorPosition
;-------------------------------------------------------------------------------
; Tests that the text cursor position registers are able to receive values and
; read them back correctly to ensure a working status.
;
; Input:
;  DX = CRTC Index register
;
; Output:
;  On success, ZF set
;  On error, ZF clear
;  AX,BX destroyed
;-------------------------------------------------------------------------------
TestCursorPosition:
	mov	bl,0AAh				; Initial value
.testPattern:
	mov	bh,bl				; Save it
	and	bh,0Fh				; Clear high bits

	mov	al,0Eh				; CRE (cursor high)
	mov	ah,bl				; Set CRTC register value
	out	dx,ax				; Write CRE register

	inc	al				; Point to CRF (cursor low)
	out	dx,ax				; Write the same to CRF register

	mov	al,0Eh				; CRE (cursor high)
	call	ReadPort			; Read CRE

	and	ah,0Fh				; Clear high bits of read value
	cmp	ah,bh				; Does it match the expected value?
	jnz	.exit				; No, finish test

	; AL was incremented in last call to ReadPort
	call	ReadPort			; Read CRF
	and	ah,0Fh				; Clear high bits of read value
	cmp	ah,bh				; Does it match the expected value
	jnz	.exit				; No, finish text

	sub	bl,55h				; Invert test pattern
	jnc	.testPattern			; Jump if pattern left to test

	xor	bl,bl				; Indicate success
.exit:
	ret					; Return to caller

;-------------------------------------------------------------------------------
; DetectOtherCards
;-------------------------------------------------------------------------------
; Detects if there's another MDA or CGA card in the systema dn configure
; appropriately.
;
; Input:
;  Nothing
;
; Output:
;  BX,DX destroyed.
;-------------------------------------------------------------------------------
DetectOtherCards:
	push	ax				; Save register

	mov	dx,MONO_CRTC_INDEX		; Test for existing MDA card
	call	TestCursorPosition		; Do test
	jz	.color				; Set us up as color

	mov	dx,MISC_OUTPUT			; Work on misc output register (3C2)
	mov	al,0A6h				; Setup for monochrome operation:
						;  Vertical sync: normally high
						;  Horizontal sync: normally low
						;  350 lines
						;  Even pages selected
						;  VCLK source is VCLK1
						;  Enable display memory
						;  Monochrome CRTC
	out	dx,al				; Update register

	mov	dx,COLOR_CRTC_INDEX		; Test for existing CGA card
	call	TestCursorPosition		; Do test
	jz	.mono				; Set us up as monochrome

	; At this point, we know we're the only video card in the system

	mov	dx,MISC_OUTPUT			; Work on misc output register (3C2)
	mov	al,23h				; Setup for color operation:
						;  Vertical sync: normally low
						;  Horizontal sync: normally low
						;  Even pages selected
						;  VCLK source is VCLK0
						;  Enable display memory
						;  Color CRTC
	out	dx,al				; Update register

	; Setup as VGA
	mov	dx,COLOR_CRTC_INDEX
	mov	[CRTC_BASE],dx			; Set CRTC base register
	and	[INSTALLED_HW],BYTE 0CFh	; Clear video info
	or	[INSTALLED_HW],BYTE 20h		; Set video as CGA 80x25 color
	or	[VIDEO_MODE_CONTROL],BYTE 1	; VGA active

	pop	ax				; Restore register
	ret					; Return to caller

.mono:
	or	[VIDEO_CONTROL],BYTE 2		; Set mono monitor
	or	[INSTALLED_HW],BYTE 30h		; Set video as 80x25 mono
	mov	dx,MONO_CRTC_INDEX		; Set base CRTC register
	jmp	SHORT .finish

.color:
	and	[INSTALLED_HW],BYTE 0CFh	; Clear video info
	or	[INSTALLED_HW],BYTE 20h		; Set video as CGA 80x25 color
	mov	dx,COLOR_CRTC_INDEX		; Set base CRTC register

.finish:
	mov	[CRTC_BASE],dx			; Set CRTC base register
	call	LAB_026c			; Set EEPROM configuration
	pop	ax
	ret

;-------------------------------------------------------------------------------
; SetupInterruptVectors
;-------------------------------------------------------------------------------
; Setup all the interrupt vectors we need for the Video BIOS. This means
; relocating the existing video BIOS to int 42h, setting our handler to int 6Dh
; and 10h, and setting parameters to int 1Dh, 1Fh and the video save pointer.
;
; Input:
;  Nothing
;
; Output:
;  Interrupt vectors initialized
;  AX,BX,DI,ES destroyed
;--------------------------------------------------------------------------------
SetupInterruptVectors:
	cli					; Interrupts disabled
	cs mov	es,[LAB_2553]			; Target segment (0)
	mov	bx,0F000h			; System BIOS segment
	mov	di,INT_OFF_VAL(42h)		; Target interrupt vector
	mov	ax,0F065h			; VIDEO_IO in IBM BIOS (int 10h handler)
	call	.saveVector			; Save AX to ES:DI and BX to ES:DI+1

	mov	bx,cs				; Our handler's segment
	mov	di,INT_OFF_VAL(6Dh)		; Target interrupt vector
	mov	ax,LAB_293c			; Our handler's offset
	call	.saveVector			; Save it

	mov	di,INT_OFF_VAL(10h)		; Target interrupt vector
	mov	ax,LAB_293c			; Our handler's offset
	call	.saveVector			; Save it

	mov	bx,cs				; Video parameter tables segment
	mov	di,INT_OFF_VAL(1Dh)		; Target interrupt vector
	mov	ax,LAB_1b07			; Pointer to table
	call	.saveVector			; Save it

	cli					; Interrupts disabled

	cs mov	es,[LAB_2551]			; Target segment (0)
	call	GetVideoSavePointerTable	; Obtain table pointer
	mov	[VIDEO_SAVE_PTR],di		; Save it
	mov	[VIDEO_SAVE_PTR+2],cs

	cs mov	es,[2553h]			; Target segment (0)
	mov	di,INT_OFF_VAL(1Fh)		; Target interrupt vector
	mov	ax,LAB_5b6b			; Charset 80-FF
	call	.saveVector

	mov	di,INT_OFF_VAL(43h)		; Target interrupt vector
	mov	ax,LAB_576b			; Charset 00-7F
.saveVector:
	stosw					; Store offset into target
	mov	ax,bx				; Next word
	stosw					; Store segment into target
	ret					; Return to caller

;-------------------------------------------------------------------------------
; UpdateHardwareEnable
;-------------------------------------------------------------------------------
; Disable hardware unused for the current video mode, including other cards
; that may be present.
;
; Input:
;  Nothing
;
; Output:
;  AL destroyed
;-------------------------------------------------------------------------------
UpdateHardwareEnable:
	call	DisableVideo			; Video off

	push	dx
	mov	dx,MODE_SELECT_REG		; Color register
	xor	al,al				; Video signal disabled

	test	[VIDEO_CONTROL],BYTE 2		; Is it monochrome?
	jnz	.1				; Yes, disable color

	; We're color, so disable monochrome
	mov	dx,MONO_CRT_CONTROL		; Mono register
	inc	al				; High-res, output disabled

.1:
	out	dx,al				; Update hardware

	pop	dx				; Restore register
	ret					; Return to caller

;-------------------------------------------------------------------------------
; TestMemoryBank
;-------------------------------------------------------------------------------
; Tests specified memory bank and zero it.
;
; Input:
;  ES:0 = Memory bank to test and zero.
;  SI = Number of bytes
;
; Output:
;  ZF set if successful
;  ZF clear on error
;  AX,DI destroyed
;-------------------------------------------------------------------------------
TestMemoryBank:
	mov	ax,2				; Address GR2, color compare plane = 0
	mov	dx,INDEX_REG			; Graphics controller index register (3CE)
	out	dx,ax				; Write it

	mov	ax,0AA55h			; Test pattern
	jmp	SHORT .nextPattern

.blankVram:
	xor	ax,ax				; Final fill pattern (blank screen)
.nextPattern:
	xor	di,di				; Starting offset
	mov	cx,si				; Set length
	rep stosw				; Fill memory

	or	ax,ax				; Check for zero pattern
	jz	.finish				; Finish if so

	xchg	al,ah				; Exchange order in test pattern
	mov	cx,si				; Reinit the length
	repe scasw				; Verify mirrored data in next plane
	jnz	.finish				; Finish if not correct

	cmp	ax,0AA55h			; Is two passes already?
	jz	.blankVram			; Yes, fill with zeroes
	jmp	SHORT .nextPattern		; No, continue next pattern

.finish:
	mov	ax,0FF02h			; GR2[3:0]: Color compare plane = F
	out	dx,ax				; Write it
	ret					; Return to caller

LAB_284e:
	push	dx
	call	GetCRTCIndex
	add	dl,6
	in	al,dx
	mov	dl,0C0h
	in	al,dx
	mov	bh,al
	mov	al,11h
	out	dx,al
	inc	dx
	in	al,dx
	mov	bl,al
	xor	al,al
	dec	dx
	out	dx,al
	pop	dx
	push	bx
	mov	ah,14h
	mov	cx,1414h
	call	LAB_289b
	jz	LAB_2876
	xor	bl,bl
	jmp	SHORT LAB_2887
LAB_2876:
	mov	ah,4
	mov	ch,14h
	mov	cl,4
	call	LAB_289b
	jz	LAB_2885
	mov	bl,1
	jmp	SHORT LAB_2887
LAB_2885:
	mov	bl,2
LAB_2887:
	pop	cx
	call	GetCRTCIndex
	add	dl,6
	in	al,dx
	mov	dl,0C0h
	mov	al,11h
	out	dx,al
	mov	al,cl
	out	dx,al
	mov	al,ch
	out	dx,al
	ret

LAB_289b:
	push	ax
	push	cx
	xor	bx,bx
	pushf
	cli
	push	ax
	push	cx
	mov	ah,8
	call	GetCRTCIndex
	add	dx,BYTE 6
LAB_28ab:
	dec	ah
	jz	LAB_28b6
LAB_28af:
	in	al,dx
	test	al,8
	loopnz	LAB_28af
	jnz	LAB_28ab
LAB_28b6:
	in	al,dx
	test	al,8
	loopz	LAB_28b6
	pop	cx
	pop	ax
	call	LAB_4b6d
	call	GetCRTCIndex
	add	dx,BYTE 6
	xor	cx,cx
	mov	ah,0FFh
LAB_28ca:
	dec	ah
	jz	LAB_28d5
LAB_28ce:
	in	al,dx
	test	al,1
	loopz	LAB_28ce
	jz	LAB_28ca
LAB_28d5:
	mov	ah,0FFh
LAB_28d7:
	dec	ah
	jz	LAB_28e2
LAB_28db:
	in	al,dx
	test	al,1
	loopnz	LAB_28db
	jnz	LAB_28d7
LAB_28e2:
	mov	dx,3C2h
	in	al,dx
	popf
	test	al,10h
	pushf
	xor	cx,cx
	xor	ax,ax
	call	LAB_4b6d
	popf
	pop	cx
	pop	ax
	ret

LAB_28f5:
	db	00h
LAB_28f6:
	dw	LAB_29cb
	dw	LAB_306e
	dw	LAB_3117
	dw	LAB_314a
	dw	LAB_315f
	dw	LAB_3165
	dw	LAB_31a2
	dw	LAB_31ef
	dw	LAB_3620
	dw	LAB_388a
	dw	LAB_38f4
	dw	LAB_3b40
	dw	LAB_3c87
	dw	LAB_3d51
	dw	LAB_3e20
	dw	LAB_3eee
	dw	LAB_3f40
	dw	LAB_414d
	dw	LAB_437c
	dw	LAB_462e
	dw	LAB_29c2
	dw	LAB_29c2
	dw	LAB_29c2
	dw	LAB_29c2
	dw	LAB_29c2
	dw	LAB_29c2
	dw	LAB_46f1
	dw	LAB_47d4

	db	1Bh,58h,0CDh,6Dh,0CFh

LAB_2933:
	jmp	LAB_3e20
LAB_2936:
	jmp	LAB_3c87
LAB_2939:
	jmp	LAB_3d51

	; THIS IS THE INT 10H HANDLER
LAB_293c:
	sti
LAB_293d:
	cld
	cmp	ah,0Eh
	jz	LAB_2933
	cmp	ah,0Ch
	jz	LAB_2936
	cmp	ah,0Dh
	jz	LAB_2939
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	push	ds
	mov	bp,sp
	sub	sp,BYTE 4
	push	ax
	push	dx
	mov	dx,3C4h
	in	al,dx
	xchg	al,ah
	add	dl,10h
	in	al,dx
	mov	[bp-4],ax
	sub	dl,20h
	in	al,dx
	xchg	al,ah
	add	dl,1Ah
	in	al,dx
	mov	[bp-2],ax
	pop	dx
	pop	ax
	cs mov	ds,[LAB_2553]
	mov	si,ax
	mov	al,ah
	xor	ah,ah
	cmp	al,1Dh
	jnc	LAB_29bb
	SHL	ax,1
	xchg	ax,si
	cs call	[si+LAB_28f6]
LAB_2990:
	push	ax
	push	dx
	mov	dx,INDEX_REG
	mov	ax,[bp-2]
	out	dx,al
	sub	dl,1Ah
	xchg	al,ah
	out	dx,al
	add	dl,20h
	mov	ax,[bp-4]
	out	dx,al
	sub	dl,10h
	xchg	al,ah
	out	dx,al
	pop	dx
	pop	ax
	add	sp,BYTE 4
	pop	ds
	pop	es
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret
LAB_29bb:
	mov	ax,si
	call	LAB_076c
	jmp	SHORT LAB_2990

LAB_29c2:
	db	0C3h
LAB_29c3:
	db	2Ch,28h,2Dh,29h,2Ah,2Eh,1Eh,29h

LAB_29cb:
	mov	ah,al
	and	al,7Fh
	cmp	al,13h
	jbe	LAB_29d9
	call	LAB_1064
	jz	LAB_29d9
	ret
LAB_29d9:
	and	[VIDEO_CONTROL],BYTE 7Fh
	and	ah,80h
	or	[VIDEO_CONTROL],ah
	call	LAB_2ae8
	call	LAB_2c36
	jz	LAB_29f6
	and	al,0DFh
	mov	[CURR_VIDEO_MODE],al
	call	LAB_2cb4
	ret

LAB_29f6:
	mov	[CURR_VIDEO_MODE],al
	mov	al,9
	call	ReadSequencerRegister
	push	ax
	mov	al,[CURR_VIDEO_MODE]
	call	LAB_2db3
	and	[VIDEO_CONTROL],BYTE 0F3h
	call	LAB_2e65
	call	LAB_4bc3
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,13h
	ja	LAB_2a36
	mov	di,812h
	mov	cx,3
	mov	al,0Bh
LAB_2a1f:
	cs mov	ah,[di]
	call	WriteSequencerRegister
	inc	di
	add	al,10h
	cs mov	ah,[di]
	call	WriteSequencerRegister
	sub	al,0Fh
	inc	di
	loop	LAB_2a1f
	mov	al,[CURR_VIDEO_MODE]
LAB_2a36:
	call	LAB_110f
	call	LAB_4c63
	mov	dx,[CRTC_BASE]
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,4
	jc	LAB_2a56
	cmp	al,7
	jz	LAB_2a56
	cmp	al,13h
	jbe	LAB_2a86
	call	LAB_106c
	test	al,1
	jz	LAB_2a86
LAB_2a56:
	call	LAB_2f1e
	mov	ax,0Bh
	mov	bx,8
	call	LAB_2e82
	jnz	LAB_2a67
	call	LAB_2ea3
LAB_2a67:
	mov	bx,10h
	call	LAB_3060
	jz	LAB_2a9a
	es les	bx,[bx+6]
	mov	ax,es
	or	ax,bx
	jz	LAB_2a9a
	mov	ax,7
	call	LAB_2e8a
	jnz	LAB_2a9a
	call	LAB_2ed2
	jmp	SHORT LAB_2a9a
LAB_2a86:
	mov	[CURSOR_TYPE],WORD 0
	mov	ax,7
	mov	bx,0Ch
	call	LAB_2e82
	jnz	LAB_2a9a
	call	LAB_2f4e
LAB_2a9a:
	test	[VIDEO_CONTROL],BYTE 80h
	jnz	LAB_2aab
	mov	ax,[PAGE_SIZE]
	or	ax,ax
	jz	LAB_2aab
	call	LAB_300c
LAB_2aab:
	call	LAB_2f75
	call	LAB_4b25
	call	LAB_4b97
	pop	ax
	call	WriteSequencerRegister
	cs test	[LAB_1035],BYTE 20h
	jnz	LAB_2ac5
	mov	ax,0F965h
	int	15h
LAB_2ac5:
	mov	dx,SEQ_INDEX
	mov	al,1Fh
	call	ReadIndirectRegister
	and	ah,3Fh
	mov	bl,8
	cmp	ah,20h
	jc	LAB_2ad9
	mov	bl,6
LAB_2ad9:
	mov	al,16h
	call	ReadIndirectRegister
	and	ah,0F0h
	or	ah,bl
	out	dx,ax
	call	LAB_09cb
	ret

LAB_2ae8:
	mov	bl,[INSTALLED_HW]
	and	bl,30h
	test	[VIDEO_MODE_CONTROL],BYTE 1
	jz	LAB_2b44
	cmp	[CURR_VIDEO_MODE],al
	jz	LAB_2b44
	mov	ah,[VIDEO_SWITCHES]
	and	ah,0Fh
	cmp	al,7
	jz	LAB_2b82
	cmp	al,0FH
	jz	LAB_2b82
	mov	bh,al
	call	LAB_106c
	jnz	LAB_2b18
	test	al,2
	mov	al,bh
	jz	LAB_2b82
LAB_2b18:
	cs test	[LAB_0132],BYTE 1
	jz	LAB_2b23
	jmp	LAB_2bb5

LAB_2b23:
	cmp	[CRTC_BASE],WORD 3D4h
	jz	LAB_2b44
	cmp	bl,30h
	jz	LAB_2b8c
	cmp	ah,5
	jbe	LAB_2b44
	cmp	ah,8
	jbe	LAB_2b49
	cmp	ah,9
	jz	LAB_2b4d
	cmp	ah,0Bh
	jbe	LAB_2b45
LAB_2b44:
	ret

LAB_2b45:
	mov	bl,48h
	jmp	SHORT LAB_2b4f

LAB_2b49:
	mov	bl,8Bh
	jmp	SHORT LAB_2b4f

LAB_2b4d:
	mov	bl,0Bh
LAB_2b4f:
	and	[VIDEO_CONTROL],BYTE 0FDh
	and	[VIDEO_SWITCHES],BYTE 0F0h
	mov	ah,[VIDEO_MODE_CONTROL]
	not	ah
	and	ah,80h
	rol	ah,1
	or	ah,bl
	or	[VIDEO_SWITCHES],ah
	and	[VIDEO_MODE_CONTROL],BYTE 7Fh
	cs test	[LAB_0132],BYTE 1
	jz	LAB_2b44
LAB_2b77:
	and	[INSTALLED_HW],BYTE 0CFh
	or	WORD [INSTALLED_HW],BYTE 20h
	ret
LAB_2b82:
	cs test	[LAB_0132],BYTE 1
	jz	LAB_2b90
	jmp	SHORT LAB_2c0a
LAB_2b8c:
	mov	al,7
	jmp	SHORT LAB_2b44
LAB_2b90:
	cmp	[CRTC_BASE],WORD MONO_CRTC_INDEX
	jz	LAB_2c09
	cmp	bl,30h
	jnz	LAB_2bcb
	cmp	ah,5
	jbe	LAB_2bcf
	cmp	ah,8
	jbe	LAB_2bd6
	cmp	ah,9
	jz	LAB_2bf4
	cmp	ah,0Bh
	ja	LAB_2c09
	mov	bl,8
	jmp	SHORT LAB_2bf6
LAB_2bb5:
	cmp	[CRTC_BASE],WORD COLOR_CRTC_INDEX
	jz	LAB_2b77
	cmp	ah,5
	jbe	LAB_2bc7
	cmp	ah,8
	jbe	LAB_2bd6
LAB_2bc7:
	mov	bl,8
	jmp	SHORT LAB_2b4f
LAB_2bcb:
	mov	al,0
	jmp	SHORT LAB_2c09
LAB_2bcf:
	or	[VIDEO_CONTROL],BYTE 2
	jmp	SHORT LAB_2c09
LAB_2bd6:
	or	[VIDEO_CONTROL],BYTE 2
	or	[VIDEO_MODE_CONTROL],BYTE 80h
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],BYTE 0Bh
	cs test	[LAB_0132],BYTE 1
	jz	LAB_2c09
	jmp	SHORT LAB_2c30
LAB_2bf4:
	mov	bl,0Bh
LAB_2bf6:
	or	[VIDEO_CONTROL],BYTE 2
	and	[VIDEO_MODE_CONTROL],BYTE 7Fh
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],bl
LAB_2c09:
	ret

LAB_2c0a:
	cmp	[CRTC_BASE],WORD MONO_CRTC_INDEX
	jz	LAB_2c30
	cmp	ah,5
	jbe	LAB_2c1c
	cmp	ah,8
	jbe	LAB_2bd6
LAB_2c1c:
	or	[VIDEO_CONTROL],BYTE 2
	and	[VIDEO_MODE_CONTROL],BYTE 7Fh
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],BYTE 0Bh
LAB_2c30:
	or	WORD [INSTALLED_HW],BYTE 30h
	ret

LAB_2c36:
	mov	ah,[INSTALLED_HW]
	and	ah,30h
	cmp	ah,30h
	jnz	LAB_2c52
	test	[VIDEO_CONTROL],BYTE 2
	jnz	LAB_2c95
	or	[VIDEO_CONTROL],BYTE 8
	mov	al,0Eh
	jmp	SHORT LAB_2c6c

LAB_2c52:
	test	[VIDEO_CONTROL],BYTE 2
	jz	LAB_2c77
	mov	ah,8
	cmp	al,2
	jbe	LAB_2c66
	cmp	al,4
	jnc	LAB_2c66
	or	ah,4
LAB_2c66:
	or	[VIDEO_CONTROL],ah
	mov	al,8
LAB_2c6c:
	mov	[ROWS_MINUS_ONE],BYTE 18h
	mov	ah,0
	mov	[CHAR_HEIGHT],ax
	ret

LAB_2c77:
	cmp	al,0Fh
	jz	LAB_2c8c
	cmp	al,7
	jz	LAB_2c8c
	mov	bh,al
	call	LAB_106c
	jnz	LAB_2cb1
	test	al,2
	mov	al,bh
	jnz	LAB_2cb1
LAB_2c8c:
	mov	al,0
	and	[VIDEO_CONTROL],BYTE 7Fh
	jmp	SHORT LAB_2cb1
LAB_2c95:
	cmp	al,0Fh
	jz	LAB_2cb1
	cmp	al,7
	jz	LAB_2cb1
	mov	bh,al
	call	LAB_106c
	jnz	LAB_2caa
	test	al,2
	mov	al,bh
	jz	LAB_2cb1
LAB_2caa:
	mov	al,7
	and	[VIDEO_CONTROL],BYTE 7Fh
LAB_2cb1:
	cmp	al,al
	ret

LAB_2cb4:
	push	ds
	push	bp
	cs mov	ds,[LAB_2553]
	pushf
	cli
	mov	INT_OFFSET(43h),WORD LAB_576b
	mov	INT_SEGMENT(43h),cs
	popf
	mov	ds,[bp+0]
	mov	ax,[bp+10h]
	mov	dx,[bp+0Ah]
	mov	si,[bp+8]
	mov	bp,[bp+4]
	pop	bp
	pop	ds
LAB_2cd9:
	push	ds
	push	bp
	xor	bx,bx
	mov	ds,bx
	mov	dx,COLOR_CRTC_INDEX
	mov	ah,[INSTALLED_HW]
	and	ah,30h
	cmp	ah,30h
	jnz	LAB_2cf2
	mov	al,7
	mov	dl,0B4h
LAB_2cf2:
	mov	[CRTC_BASE],dx
	mov	[CURR_VIDEO_MODE],al
	mov	ah,3Fh
	cmp	al,6
	jz	LAB_2d01
	mov	ah,30h
LAB_2d01:
	mov	[CGA_PALETTE_REG],ah
	mov	ah,al
	mov	bl,al
	xor	bh,bh
	cs mov	al,[bx+LAB_1b4f]
	mov	[CURR_MODE_SELECT],al
	and	al,37h
	add	dl,4
	out	dx,al
	sub	dl,4
	mov	bl,28h
	test	ah,2
	jz	LAB_2d25
	mov	bl,50h
LAB_2d25:
	mov	[NUM_COLUMNS],bx
	mov	bx,1000h
	cmp	ah,7
	jz	LAB_2d38
	mov 	bh,40h
	cmp	ah,3
	ja	LAB_2d42
LAB_2d38:
	mov	bx,10h
	cmp	ah,1
	ja	LAB_2d42
	mov	bh,8
LAB_2d42:
	mov	[PAGE_SIZE],bx
	xor	bx,bx
	mov	[CURR_PAGE_START],bx
	mov	[CURR_PAGE],bl
	mov	cx,8
	mov	di,CURSOR_POSN
LAB_2d56:
	mov	[di],bx
	inc	di
	inc	di
	loop	LAB_2d56
	les	si,[INT_OFF_VAL(1Dh)]
	mov	bl,ah
	cmp	bl,6
	jnz	LAB_2d69
	dec	bl
LAB_2d69:
	SHR	bl,1
	SHL	bl,4
	add	si,bx
	mov	cx,10h
LAB_2d73:
	mov	al,bh
	out	dx,al
	inc	dx
	es mov	al,[si]
	inc	si
	out	dx,al
	dec	dx
	inc	bh
	loop	LAB_2d73
	es mov	bx,[si-6]
	xchg	bl,bh
	mov	[CURSOR_TYPE],bx
	call	LAB_300f
	mov	al,[CURR_MODE_SELECT]
	mov	dx,[CRTC_BASE]
	add	dl,4
	out	dx,al
	mov	al,[CGA_PALETTE_REG]
	inc	dx
	out	dx,al
	pop	bp
	pop	ds
	mov	[bp+10h],ax
	mov	al,[INSTALLED_HW]
	and	al,30h
	cmp	al,30h
	jnz	LAB_2db2
	mov	[CURSOR_TYPE],WORD 0B0Ch
LAB_2db2:
	ret


LAB_2db3:
	push	bp
	mov	bp,cs
	cmp	al,13h
	jbe	LAB_2dda
	push	bp
	call	LAB_106c
	pop	bp
	jnz	LAB_2dda
	mov	bx,LAB_576b
	test	al,1
	jnz	LAB_2dfa
	and	al,70h
	jz	LAB_2dfa
	mov	bx,LAB_5f6b
	cmp	al,20h
	jbe	LAB_2dfa
	mov	bp,cs
	mov	bx,6E9Bh
	jmp	SHORT LAB_2dfa
LAB_2dda:
	mov	bx,LAB_576b
	cmp	al,13h
	jz	LAB_2dfa
	cmp	al,8
	jc	LAB_2dfa
	mov	bx,LAB_6e9b
	jz	LAB_2dfa
	cmp	al,11h
	jnc	LAB_2dfa
	mov	bx,LAB_5f6b
	cmp	al,0Fh
	jnc	LAB_2dfa
	mov	bp,cs
	mov	bx,LAB_576b
LAB_2dfa:
	cs mov	es,[LAB_2553]
	mov	di,INT_OFF_VAL(43h)
	mov	ax,bx
	pushf
	cli
	stosw
	mov	ax,bp
	stosw
	popf
	pop	bp
	mov	ax,ds
	mov	es,ax
	mov	di,CURSOR_POSN
	mov	cx,8
	xor	ax,ax
	rep stosw
	mov	[CURR_PAGE],al
	mov	[CURR_PAGE_START],ax
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,7
	ja	LAB_2e3f
	xor	ah,ah
	mov	di,ax
	mov	al,3Fh
	cmp	di,BYTE 6
	jz	LAB_2e34
	mov	al,30h
LAB_2e34:
	mov	[CGA_PALETTE_REG],al
	cs mov	al,[di+LAB_29c3]
	mov	[CURR_MODE_SELECT],al
LAB_2e3f:
	call	LAB_4ec9
	push	si
	es lodsb
	xor	ah,ah
	mov	[NUM_COLUMNS],ax
	es lodsb
	mov	[ROWS_MINUS_ONE],al
	es lodsb
	mov	[CHAR_HEIGHT],ax
	es lodsw
	mov	[PAGE_SIZE],ax
	add	si,BYTE 0Fh
	es lodsw
	xchg	ah,al
	mov	[CURSOR_TYPE],ax
	pop	si
	ret

LAB_2e65:
	push	ds
	push	es
	push	si
	push	es
	mov	bx,4
	call	LAB_3060
	pop	ds
	jz	LAB_2e7e
	add	si,BYTE 23h
	mov	di,bx
	mov	cx,8
	rep movsw
	inc	si
	movsb
LAB_2e7e:
	pop	si
	pop	es
	pop	ds
	ret

LAB_2e82:
	call	LAB_3060
	jnz	LAB_2e8a
	or	al,0FFh
	ret

LAB_2e8a:
	push	bx
	add	bx,ax
	mov	al,[CURR_VIDEO_MODE]
LAB_2e90:
	es mov	ah,[bx]
	inc	bx
	cmp	ah,0FFh
	jz	LAB_2e9f
	cmp	al,ah
	jnz	LAB_2e90
	pop	bx
	ret

LAB_2e9f:
	or	al,0FFh
	pop	bx
	ret

LAB_2ea3:
	es mov	al,[bx+0Ah]
	push	ax
	es mov	cx,[bx+2]
	es mov	dx,[bx+4]
	es mov	si,[bx+6]
	es mov	ax,[bx+8]
	es mov	bx,[bx]
	xchg	bh,bl
	and	bl,3Fh
	mov	es,ax
	mov	al,10h
	call	LAB_4153
	pop	ax
	add	al,1
	jz	LAB_2ed1
	sub	al,1
	mov	[484h],al
LAB_2ed1:
	ret

LAB_2ed2:
	es mov	al,[bx]
	xor	ah,ah
	cmp	ax,[CHAR_HEIGHT]
	jnz	LAB_2f1d
	mov	cx,100h
	xor	dx,dx
	es mov	si,[bx+3]
	es mov	ax,[bx+5]
	es mov	bx,[bx]
	xchg	bh,bl
	and	bl,3Fh
	mov	es,ax
	mov	al,0
	push	bx
	call	LAB_4153
	mov	dx,SEQ_INDEX
	mov	al,3
	call	ReadPort
	and	ah,13h
	pop	bx
	mov	bh,bl
	and	bl,3
	mov	cl,2
	shl	bl,cl
	and	bh,4
	inc	cl
	shl	bh,cl
	or	ah,bl
	or	ah,bh
	mov	al,3
	out	dx,ax
LAB_2f1d:
	ret

LAB_2f1e:
	xor	bl,bl
	mov	al,1
	cmp	WORD [CHAR_HEIGHT],BYTE 0Eh
	jz	LAB_2f40
	mov	al,2
	cmp	WORD [CHAR_HEIGHT],BYTE 8
	jz	LAB_2f4a
	mov	al,4
	cmp	[CURR_VIDEO_MODE],BYTE 13h
	ja	LAB_2f4a
	or	bl,40h
	jmp	SHORT LAB_2f4a
LAB_2f40:
	cmp	[CURR_VIDEO_MODE],BYTE 7
	jnz	LAB_2f4a
	or	bl,80h
LAB_2f4a:
	call	LAB_4153
	ret

LAB_2f4e:
	es mov	al,[bx]
	dec	al
	mov	[ROWS_MINUS_ONE],al
	es mov	ax,[bx+1]
	mov	[CHAR_HEIGHT],ax
	es mov	ax,[bx+3]
	es mov	bx,[bx+5]
	cs mov	es,[LAB_2553]
	mov	di,INT_OFF_VAL(43h)
	pushf
	cli
	stosw
	mov	ax,bx
	stosw
	popf
	ret

LAB_2f75:
	mov	bx,10h
	call	LAB_3060
	jz	LAB_2f8f
	es les	bx,[bx+0Ah]
	mov	ax,es
	or	ax,bx
	jz	LAB_2f8f
	mov	ax,14h
	call	LAB_2e8a
	jz	LAB_2f90
LAB_2f8f:
	ret

LAB_2f90:
	test	[VIDEO_MODE_CONTROL],BYTE 8
	jnz	LAB_2ff0
	mov	dx,[CRTC_BASE]
	add	dx,BYTE 6
	in	al,dx
	push	ds
	push	bx
	es mov	ax,[bx+0Eh]
	mov	ah,al
	es lds	si,[bx+10h]
	es mov	bx,[bx+0Ch]
	or	bx,bx
	jz	LAB_2fc7
	mov	dx,PIXEL_ADDR_WR_MODE
LAB_2fb6:
	mov	al,ah
	out	dx,al
	inc	dx
	mov	cx,3
LAB_2fbd:
	lodsb
	out	dx,al
	loop	LAB_2fbd
	inc	ah
	dec	dx
	dec	bx
	jnz	LAB_2fb6
LAB_2fc7:
	pop	bx
	es mov	ax,[bx+6]
	mov	ah,al
	es lds	si,[bx+8]
	es mov	cx,[bx+4]
	jcxz	LAB_2fef
	mov	dx,ATTR_CONTROL_INDEX
LAB_2fdb:
	mov	al,ah
	out	dx,al
	jmp	SHORT LAB_2fe0
LAB_2fe0:
	lodsb
	out	dx,al
	inc	ah
	loop	LAB_2fdb
	inc	ah
	mov	al,ah
	out	dx,al
	jmp	SHORT LAB_2fed
LAB_2fed:
	lodsb
	out	dx,al
LAB_2fef:
	pop	ds
LAB_2ff0:
	es mov	al,[bx]
	or	al,al
	jz	LAB_300b
	test	al,80h
	mov	al,1Fh
	jnz	LAB_3002
	mov	ax,[CHAR_HEIGHT]
	dec	al
LAB_3002:
	mov	dx,[CRTC_BASE]
	mov	ah,al
	mov	al,14h
	out	dx,ax
LAB_300b:
	ret

LAB_300c:
	call	LAB_4b84
LAB_300f:
	mov	cx,4000h
	mov	bl,[CURR_VIDEO_MODE]
	cmp	bl,13h
	jbe	LAB_3038
	mov	al,bl
	call	LAB_106c
	jnz	LAB_3038
	mov	bl,al
	mov	bh,0B8h
	mov	ax,720h
	test	bl,2
	jnz	LAB_3030
	mov	bh,0B0h
LAB_3030:
	test	bl,1
	jnz	LAB_3054
	jmp	LAB_0612

LAB_3038:
	mov	bh,0B0h
	mov	ax,720h
	cmp	bl,7
	jz	LAB_3054
	mov	bh,0B8h
	cmp	bl,3
	jbe	LAB_3054
	xor	ax,ax
	cmp	bl,6
	jbe	LAB_3054
	mov	bh,0A0h
	mov	ch,80h
LAB_3054:
	xor	bl,bl
	mov	es,bx
	xor	di,di
	rep stosw
LAB_305c:
	call	LAB_4b97
	ret

LAB_3060:
	push	di
	les	di,[VIDEO_SAVE_PTR]
	es les	bx,[bx+di]
	mov	di,es
	or	di,bx
	pop	di
	ret

LAB_306e:
	mov	[CURSOR_TYPE],cx
	mov	dx,[CRTC_BASE]
	call	LAB_307d
	mov	[bp+10h],ax
	ret

LAB_307d:
	test	[VIDEO_CONTROL],BYTE 8
	jnz	LAB_30f5
	mov	ax,cx
	and	ah,60h
	cmp	ah,20h
	jnz	LAB_3093
	mov	cx,1E00h
	jmp	SHORT LAB_30f5

LAB_3093:
	test	[VIDEO_CONTROL],BYTE 1
	jnz	LAB_30f5
	mov	ax,cx
	and	ax,0E0E0h
	jnz	LAB_30f5
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,4
	jc	LAB_30b3
	cmp	al,7
	jz	LAB_30b3
	call	LAB_10cd
	test	al,1
	jz	LAB_30f5
LAB_30b3:
	cmp	cl,ch
	jnc	LAB_30c5
	or	cl,cl
	jz	LAB_30f5
	mov	ch,cl
	mov	cl,[CHAR_HEIGHT]
	dec	cl
	jmp	SHORT LAB_30f5
LAB_30c5:
	mov	bl,[CHAR_HEIGHT]
	mov	bh,bl
	dec	bl
	mov	al,cl
	or	al,ch
	cmp	al,bh
	jnc	LAB_30e1
	cmp	cl,bl
	jz	LAB_30f5
	dec	bl
	cmp	ch,bl
	jz	LAB_30f5
	inc	bl
LAB_30e1:
	cmp	cl,3
	jbe	LAB_30f5
	mov	al,ch
	add	al,2
	cmp	al,cl
	jnc	LAB_3108
	cmp	ch,2
	ja	LAB_3100
	mov	cl,bl
LAB_30f5:
	mov	ah,ch
	mov	al,0Ah
	out	dx,ax
	mov	ah,cl
	mov	al,0Bh
	out	dx,ax
	ret

LAB_3100:
	mov	cl,bl
	mov	ch,bh
	SHR	ch,1
	jmp	SHORT LAB_30f5
LAB_3108:
	cmp	bh,0Eh
	jc	LAB_310f
	dec	bl
LAB_310f:
	sub	ch,cl
	add	ch,bl
	mov	cl,bl
	jmp	SHORT LAB_30f5

LAB_3117:
	mov	al,bh
	xchg	bh,bl
	xor	bh,bh
	SHL	bx,1
	mov	[bx+CURSOR_POSN],dx
	cmp	[CURR_PAGE],al
	jnz	LAB_3149
LAB_3129:
	mov	al,[NUM_COLUMNS]
	mul	dh
	add	al,dl
	adc	ah,0
	mov	bx,[CURR_PAGE_START]
	SHR	bx,1
	add	bx,ax
	mov	al,0Eh
	mov	dx,[CRTC_BASE]
	mov	ah,bh
	out	dx,ax
	mov	ah,bl
	inc	al
	out	dx,ax
LAB_3149:
	ret

LAB_314a:
	xchg	bh,bl
	xor	bh,bh
	add	bx,bx
	mov	dx,[bx+CURSOR_POSN]
	mov	cx,[CURSOR_TYPE]
	mov	[bp+0Ch],cx
	mov	[bp+0Ah],dx
	ret

LAB_315f:
	xor	ax,ax
	mov	[bp+10h],ax
	ret

LAB_3165:
	xor	ah,ah
	and	al,7
	mov	di,ax
	mov	[CURR_PAGE],al
	mul	WORD [PAGE_SIZE]
	mov	[CURR_PAGE_START],ax
	mov	bx,ax
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,7
	jbe	LAB_3189
	cmp	al,13h
	jbe	LAB_318b
	call	LAB_10cd
	test	al,1
	jz	LAB_318b
LAB_3189:
	SHR	bx,1
LAB_318b:
	mov	dx,[CRTC_BASE]
	mov	al,0Ch
	mov	ah,bh
	out	dx,ax
	mov	ah,bl
	inc	al
	out	dx,ax
	SHL	di,1
	mov	dx,[di+CURSOR_POSN]
	jmp	SHORT LAB_3129

	db	0

LAB_31a2:
	sub	sp,BYTE 4
	mov	bp,sp
	mov	[bp+0],ax
	mov	[bp+2],bx
	mov	ax,cx
	cmp	[CURR_VIDEO_MODE],BYTE 7
	jbe	LAB_3223
	cmp	[CURR_VIDEO_MODE],BYTE 13h
	jz	LAB_31c2
	ja	LAB_31e1
LAB_31bf:
	jmp	LAB_345e

LAB_31c2:
	push	dx
	mov	di,ax
	and	di,0FFh
	mov	al,ah
	mul	BYTE [NUM_COLUMNS]
	mul	WORD [CHAR_HEIGHT]
	add	di,ax
	SHL	di,1
	SHL	di,1
	SHL	di,1
	pop	dx
	mov	ax,cx
	jmp	LAB_358f
LAB_31e1:
	call	LAB_10cd
	test	al,1
	mov	bl,al
	mov	ax,cx
	jnz	LAB_3223
	jmp	LAB_03e1

LAB_31ef:
	sub	sp,BYTE 4
	mov	bp,sp
	mov	[bp+0],ax
	mov	[bp+2],bx
	mov	ax,cx
	cmp	[CURR_VIDEO_MODE],BYTE 7
	jbe	LAB_3220
	cmp	[CURR_VIDEO_MODE],BYTE 13h
	jz	LAB_320f
	ja	LAB_3212
LAB_320c:
	jmp	LAB_342c
LAB_320f:
	jmp	LAB_3563

LAB_3212:
	call	LAB_10cd
	test	al,1
	mov	bl,al
	mov	ax,cx
	jnz	LAB_3220
	jmp	LAB_03ec
LAB_3220:
	mov	cx,dx
	std
LAB_3223:
	mov	si,ax
	mov	al,[INSTALLED_HW]
	and	al,30h
	cmp	al,30h
	mov	ax,0B000h
	jz	LAB_3233
	mov	ah,0B8h
LAB_3233:
	mov	es,ax
	mov	ax,si
	sub	dl,al
	sub	dh,ah
	mov	al,[bp+0]
	inc	dl
	inc	dh
	mov	ah,dh
	or	al,al
	jz	LAB_324c
	sub	ah,al
	ja	LAB_3250
LAB_324c:
	mov	al,dh
	xor	ah,ah
LAB_3250:
	push	ax
	mov	ah,[CURR_VIDEO_MODE]
	cmp	ah,3
	jbe	LAB_3267
	cmp	ah,7
	jz	LAB_3267
	cmp	ah,13h
	ja	LAB_3267
	jmp	LAB_32e9
LAB_3267:
	mov	bl,al
	mov	al,ch
	mul	byte [NUM_COLUMNS]
	add	al,cl
	adc	ah,0
	mov	di,[CURR_PAGE_START]
	SHR	di,1
	add	di,ax
	mov	al,bl
	SHL	di,1
	mov	si,di
	mov	bx,[NUM_COLUMNS]
	mul	bl
	push	ax
	SHL	ax,1
	SHL	bx,1
	cmp	[bp+1],BYTE 6
	jz	LAB_3297
	neg	ax
	neg	bx
LAB_3297:
	mov	cl,dl
	xor	ch,ch
	add	si,ax
	mov	ax,es
	mov	ds,ax
	pop	ax
	pop	dx
	cmp	cx,[NUM_COLUMNS]
	jnz	LAB_32be
	mov	bx,ax
	mov	al,cl
	mul	dh
	mov	cx,ax
	rep movsw
	mov	cx,bx
	mov	al,20h
	mov	ah,[bp+3]
	rep stosw
	jmp	SHORT LAB_32e5
LAB_32be:
	or	dh,dh
	jz	LAB_32d4
LAB_32c2:
	push	cx
	push	si
	mov	ax,di
	rep movsw
	mov	di,ax
	pop	si
	pop	cx
	add	si,bx
	add	di,bx
	dec	dh
	jnz	LAB_32c2
LAB_32d4:
	mov	al,20h
	mov	ah,[bp+3]
LAB_32d9:
	push	cx
	push	di
	rep stosw
	pop	di
	pop	cx
	add	di,bx
	dec	dl
	jnz	LAB_32d9
LAB_32e5:
	add	sp,BYTE 4
	ret

LAB_32e9:
	cmp	ah,6
	jz	LAB_32f2
	SHL	cl,1
	SHL	dl,1
LAB_32f2:
	mov	si,dx
	mov	bl,al
	mov	al,ch
	xor	ah,ah
	mov	di,140h
	mul	di
	add	al,cl
	adc	ah,0
	mov	di,[CURR_PAGE_START]
	add	di,ax
	mov	al,bl
	xor	ah,ah
	mov	dx,140h
	mul	dx
	mov	dx,si
	push	ax
	mov	bx,50h
	sub	bl,dl
	sbb	bh,0
	mov	ch,[bp+3]
	cmp	[bp+1],BYTE 7
	mov	bp,2000h
	jz	LAB_339a
	mov	cl,dl
	mov	si,di
	add	si,ax
	pop	ax
	pop	dx
	push	cx
	xor	ch,ch
	mov	ax,es
	mov	ds,ax
	or	dh,dh
	jz	LAB_336d
	SHL	dh,1
	SHL	dh,1
	mov	ax,cx
LAB_3343:
	mov	cx,ax
	SHR	cx,1
	rep movsw
	rcl	cx,1
	rep movsb
	sub	di,ax
	sub	si,ax
	add	si,bp
	add	di,bp
	mov	cx,ax
	SHR	cx,1
	rep movsw
	rcl	cx,1
	rep movsb
	sub	si,bp
	sub	di,bp
	add	si,bx
	add	di,bx
	dec	dh
	jnz	LAB_3343
	mov	cx,ax
LAB_336d:
	pop	ax
	mov	al,ah
	SHL	dl,1
	SHL	dl,1
	mov	si,cx
LAB_3376:
	mov	cx,si
	SHR	cx,1
	rep stosw
	rcl	cx,1
	rep stosb
	sub	di,si
	add	di,bp
	mov	cx,si
	SHR	cx,1
	rep	stosw
	rcl	cx,1
	rep	stosb
	sub	di,bp
	add	di,bx
	dec	dl
	jnz	LAB_3376
	add	sp,BYTE 4
	ret

LAB_339a:
	neg	ax
	neg	bx
	neg	bp
	add	di,20F0h
	cmp	[CURR_VIDEO_MODE],BYTE 6
	jz	LAB_33ac
	inc	di
LAB_33ac:
	mov	cl,dl
	mov	si,di
	add	si,ax
	pop	ax
	pop	dx
	push	cx
	xor	ch,ch
	mov	ax,es
	mov	ds,ax
	or	dh,dh
	jz	LAB_33f9
	SHL	dh,1
	SHL	dh,1
	mov	ax,cx
LAB_33c5:
	mov	cx,ax
	SHR	cx,1
	jnc	LAB_33cc
	movsb
LAB_33cc:
	jcxz	LAB_33d4
	dec	si
	dec	di
	rep movsw
	inc	si
	inc	di
LAB_33d4:
	add	si,ax
	add	di,ax
	add	si,bp
	add	di,bp
	mov	cx,ax
	SHR	cx,1
	jnc	LAB_33e3
	movsb
LAB_33e3:
	jcxz	LAB_33eb
	dec	si
	dec	di
	rep movsw
	inc	si
	inc	di
LAB_33eb:
	sub	si,bp
	sub	di,bp
	add	si,bx
	add	di,bx
	dec	dh
	jnz	LAB_33c5
	mov	cx,ax
LAB_33f9:
	pop	ax
	mov	al,ah
	SHL	dl,1
	SHL	dl,1
	mov	si,cx
LAB_3402:
	mov	cx,si
	SHR	cx,1
	jnc	LAB_3409
	stosb
LAB_3409:
	jcxz	LAB_340f
	dec	di
	rep stosw
	inc	di
LAB_340f:
	add	di,si
	add	di,bp
	mov	cx,si
	SHR	cx,1
	jnc	LAB_341a
	stosb
LAB_341a:
	jcxz	LAB_3420
	dec	di
	rep stosw
	inc	di
LAB_3420:
	sub	di,bp
	add	di,bx
	dec	dl
	jnz	LAB_3402
	add	sp,BYTE 4
	ret

LAB_342c:
	std
	mov	ax,dx
	mov	si,dx
	mov	di,ax
	and	di,0FFh
	mov	al,ah
	mul	BYTE [NUM_COLUMNS]
	mul	WORD [CHAR_HEIGHT]
	add	di,ax
	xor	ah,ah
	mov	al,[CURR_PAGE]
	mul	WORD [PAGE_SIZE]
	add	di,ax
	mov	bx,[CHAR_HEIGHT]
	dec	bx
	mov	ax,[NUM_COLUMNS]
	mul	bx
	add	di,ax
	mov	dx,si
	jmp	SHORT LAB_347f
	
LAB_345e:
	mov	si,dx
	mov	di,ax
	and	di,0FFh
	mov	al,ah
	mul	BYTE [NUM_COLUMNS]
	mul	WORD [CHAR_HEIGHT]
	add	di,ax
	xor	ah,ah
	mov	al,[CURR_PAGE]
	mul	WORD [PAGE_SIZE]
	add	di,ax
	mov	dx,si
LAB_347f:
	sub	dx,cx
	inc	dh
	inc	dl
	mov	al,[bp+0]
	mov	ah,dh
	or	al,al
	jz	LAB_3492
	sub	ah,al
	ja	LAB_3496
LAB_3492:
	mov	al,dh
	xor	ah,ah
LAB_3496:
	mov	cx,ax
	mov	si,dx
	mov	ax,105h
	mov	dx,INDEX_REG
	out	dx,ax
	mov	ax,0F02h
	mov	dx,SEQ_INDEX
	out	dx,ax
	mov	ax,cx
	push	ax
	mov	bx,[NUM_COLUMNS]
	mul	bl
	mul	WORD [CHAR_HEIGHT]
	mov	cx,ax
	mov	dx,si
	sub	bl,dl
	sbb	bh,0
	cmp	[bp+1],BYTE 7
	jnz	LAB_34c8
	neg	ax
	neg	bx
LAB_34c8:
	mov	si,di
	add	si,ax
	mov	ax,cx
	mov	cl,dl
	xor	ch,ch
	pop	dx
	cmp	cx,[NUM_COLUMNS]
	jnz	LAB_350c
	mov	bx,ax
	mov	al,cl
	mul	dh
	mul	word [CHAR_HEIGHT]
	mov	cx,ax
	mov	ax,0A000h
	mov	es,ax
	mov	ds,ax
	rep movsb
	mov	cx,bx
	mov	dx,INDEX_REG
	mov	ax,5
	out	dx,ax
	mov	ah,[bp+3]
	xor	al,al
	out	dx,ax
	inc	al
	out	dx,ax
	xor	ax,ax
	rep stosb
	out	dx,ax
	inc	al
	out	dx,ax
	add	sp,BYTE 4
	ret

LAB_350c:
	mov	al,[CHAR_HEIGHT]
	mul	dh
	push	dx
	mov	dx,ax
	mov	ax,0A000h
	mov	ds,ax
	mov	es,ax
	or	dx,dx
	jz	LAB_352c
LAB_351f:
	mov	ax,cx
	rep movsb
	mov	cx,ax
	add	si,bx
	add	di,bx
	dec	dx
	jnz	LAB_351f
LAB_352c:
	cs mov	ds,[LAB_2551]
	pop	si
	mov	dx,INDEX_REG
	mov	ax,5
	out	dx,ax
	mov	ah,[bp+3]
	xor	al,al
	out	dx,ax
	inc	al
	out	dx,ax
	mov	dx,si
	mov	al,[CHAR_HEIGHT]
	mul	dl
	mov	dx,ax
	xor	ax,ax
LAB_354d:
	mov	si,cx
	rep stosb
	add	di,bx
LAB_3553:
	mov	cx,si
	dec	dx
	jnz	LAB_354d
	mov	dx,INDEX_REG
	out	dx,ax
	inc	al
	out	dx,ax
	add	sp,BYTE 4
	ret

LAB_3563:
	std
	mov	ax,dx
	push	dx
	mov	di,ax
	and	di,0FFh
	mov	al,ah
	mul	BYTE [NUM_COLUMNS]
	mul	WORD [CHAR_HEIGHT]
	add	di,ax
	mov	bx,[CHAR_HEIGHT]
	dec	bx
	mov	ax,[NUM_COLUMNS]
	mul	bx
	add	di,ax
	SHL	di,1
	SHL	di,1
	SHL	di,1
	add	di,BYTE 6
	pop	dx
LAB_358f:
	sub	dx,cx
	inc	dh
	inc	dl
	mov	al,[bp+0]
	mov	ah,dh
	or	al,al
	jz	LAB_35a2
	sub	ah,al
	ja	LAB_35a6
LAB_35a2:
	mov	al,dh
	xor	ah,ah
LAB_35a6:
	push	ax
	mov	si,dx
	mov	bx,[NUM_COLUMNS]
	mul	bl
	mul	WORD [CHAR_HEIGHT]
	mov	dx,si
	SHL	ax,1
	SHL	ax,1
	SHL	ax,1
	push	ax
	sub	bl,dl
	sbb	bh,0
	cmp	[bp+1],BYTE 7
	jnz	LAB_35cb
	neg	ax
	neg	bx
LAB_35cb:
	mov	cl,dl
	mov	ch,0
	mov	si,di
	add	si,ax
	pop	ax
	pop	dx
	SHL	bx,1
	SHL	bx,1
	SHL	bx,1
	SHL	cx,1
	SHL	cx,1
	mov	al,[CHAR_HEIGHT]
	mul	dh
	push	dx
	mov	dx,ax
	mov	ax,0A000h
	mov	ds,ax
	mov	es,ax
	or	dx,dx
	jz	LAB_35ff
LAB_35f2:
	mov	ax,cx
	rep movsw
	mov	cx,ax
	add	si,bx
	add	di,bx
	dec	dx
	jnz	LAB_35f2
LAB_35ff:
	pop	dx
	cs mov	ds,[LAB_2551]
	mov	al,[CHAR_HEIGHT]
	mul	dl
	mov	dx,ax
	mov	al,[bp+3]
	mov	ah,al
LAB_3611:
	mov	si,cx
	rep stosw
	add	di,bx
	mov	cx,si
	dec	dx
	jnz	LAB_3611
	add	sp,BYTE 4
	ret

LAB_3620:
	call	LAB_3627
	mov	[bp+10h],ax
	ret

LAB_3627:
	mov	ah,[CURR_VIDEO_MODE]
	cmp	ah,7
	jbe	LAB_364e
	cmp	ah,0Ch
	jbe	LAB_3688
	cmp	ah,13h
	jz	LAB_366f
	ja	LAB_363f
	jmp	LAB_371d

LAB_363f:
	xchg	ah,al
	call	LAB_10cd
	xchg	ah,al
	test	ah,1
	jnz	LAB_364c
	ret

LAB_364c:
	mov	ah,3
LAB_364e:
	mov	dx,ax
	mov	ax,[INSTALLED_HW]
	and	al,30h
	cmp	al,30h
	mov	ax,0B000h
	jz	LAB_365e
	mov	ah,0B8h
LAB_365e:
	mov	es,ax
	mov	ax,dx
	cmp	ah,4
	jc	LAB_3672
	cmp	ah,7
	jz	LAB_3672
	jmp	SHORT LAB_3690
	nop
LAB_366f:
	jmp	LAB_37a8

LAB_3672:
	or	bh,bh
	jnz	LAB_3689
	mov	bx,[CURSOR_POSN]
	mov	al,[NUM_COLUMNS]
	mul	bh
	xor	bh,bh
	add	bx,ax
	SHL	bx,1
	es mov	ax,[bx]
LAB_3688:
	ret

LAB_3689:
	call	LAB_3864
	es mov	ax,[di]
	ret

LAB_3690:
	mov	al,[CURSOR_POSN+1]
	mul	BYTE [NUM_COLUMNS]
	mov	di,ax
	SHL	di,1
	SHL	di,1
	mov	al,[CURSOR_POSN]
	xor	ah,ah
	add	di,ax
	mov	ah,[CURR_VIDEO_MODE]
	cmp	ah,6
	jz	LAB_36af
	SHL	di,1
LAB_36af:
	add	di,20F0h
	cmp	ah,6
	mov	si,di
	mov	ax,es
	mov	ds,ax
	mov	cx,4
	jz	LAB_36d6
LAB_36c1:
	call	LAB_3827
	mov	bh,bl
	sub	si,2002h
	call	LAB_3827
	add	si,1FAEh
	push	bx
	loop	LAB_36c1
	jmp	SHORT LAB_36e5
LAB_36d6:
	lodsb
	mov	ah,al
	sub	si,2001h
	lodsb
	add	si,1FAFh
	push	ax
	loop	LAB_36d6
LAB_36e5:
	mov	si,sp
	mov	ax,ss
	mov	ds,ax
	mov	ax,cs
	mov	es,ax
	mov	di,LAB_576b
	mov	dx,80h
	call	LAB_383c
	jnz	LAB_3714
	cs mov	es,[LAB_2553]
	es les	di,[INT_OFF_VAL(1Fh)]
	mov	ax,es
	or	ax,di
	jz	LAB_3714
	mov	dx,80h
	call	LAB_383c
	jz	LAB_3714
	add	al,80h
LAB_3714:
	cs mov	ds,[LAB_2553]
	add	sp,BYTE 8
	ret

LAB_371d:
	mov	ax,0A000h
	mov	es,ax
	mov	al,bh
	xor	ah,ah
	SHL	ax,1
	mov	si,ax
	mov	ax,[si+CURSOR_POSN]
	mov	si,ax
	and	si,0FFh
	mov	al,ah
	mul	BYTE [NUM_COLUMNS]
	mul	WORD [CHAR_HEIGHT]
	add	si,ax
	xor	ah,ah
	mov	al,bh
	mul	WORD [PAGE_SIZE]
	add	si,ax
	mov	al,[CHAR_HEIGHT]
	dec	al
	mul	BYTE [NUM_COLUMNS]
	add	si,ax
	mov	ax,805h
	mov	dx,INDEX_REG
	out	dx,ax
	mov	cx,[CHAR_HEIGHT]
	mov	bx,[NUM_COLUMNS]
	inc	bx
LAB_3765:
	es lodsb
	mov	ah,al
	not	ah
	push	ax
	inc	sp
	sub	si,bx
	loop	LAB_3765
	mov	ax,5
	out	dx,ax
	mov	si,sp
	xor	al,al
	cs mov	es,[LAB_2553]
	es les	bx,[INT_OFF_VAL(43h)]
	mov	dx,si
	mov	di,bx
	mov	bx,[CHAR_HEIGHT]
	mov	cx,100h
LAB_378e:
	push	cx
	push	di
	mov	cx,bx
	ss repe cmpsb
	pop	di
	pop	cx
	jz	LAB_37a1
	add	di,bx
	mov	si,dx
	inc	al
	jnz	LAB_378e
LAB_37a1:
	mov	ah,5
	add	sp,[CHAR_HEIGHT]
	ret

LAB_37a8:
	mov	ax,0A000h
	mov	es,ax
	mov	ax,[CURSOR_POSN]
	mov	di,ax
	and	di,0FFh
	mov	al,ah
	mul	BYTE [NUM_COLUMNS]
	mul	WORD [CHAR_HEIGHT]
	add	di,ax
	SHL	di,1
	SHL	di,1
	SHL	di,1
	mov	al,[CHAR_HEIGHT]
	dec	al
	mul	BYTE [NUM_COLUMNS]
	mov	cl,3
	shl	ax,cl
	mov	si,di
	add	si,ax
	mov	dx,[NUM_COLUMNS]
	shl	dx,cl
	add	dx,BYTE 8
	mov	cx,[CHAR_HEIGHT]
LAB_37e6:
	mov	bl,8
	xor	ah,ah
LAB_37ea:
	es lodsb
	cmp	al,1
	cmc
	rcl	ah,1
	dec	bl
	jnz	LAB_37ea
	push	ax
	inc	sp
	sub	si,dx
	loop	LAB_37e6
	mov	si,sp
	xor	al,al
	cs mov	es,[LAB_2553]
	es les	bx,[INT_OFF_VAL(43h)]
	mov	dx,si
LAB_380b:
	mov	di,bx
	mov	cx,[CHAR_HEIGHT]
	ss repe cmpsb
	jz	LAB_3820
	add	bx,[CHAR_HEIGHT]
	mov	si,dx
	inc	al
	jnz	LAB_380b
LAB_3820:
	xor	ah,ah
	add	sp,[CHAR_HEIGHT]
	ret

LAB_3827:
	mov	dl,8
	xor	bl,bl
	lodsw
	xchg	ah,al
LAB_382e:
	SHL	ax,1
	jns	LAB_3833
	stc
LAB_3833:
	rcl	bl,1
	SHL	ax,1
	dec	dl
	jnz	LAB_382e
	ret

LAB_383c:
	mov	bx,di
	push	bp
LAB_383f:
	mov	ax,si
	mov	bp,di
	mov	cx,4
	repe cmpsw
	mov	di,bp
	jz	LAB_3858
	add	di,BYTE 8
	mov	si,ax
	dec	dx
	jnz	LAB_383f
	pop	bp
	xor	ax,ax
	ret
LAB_3858:
	sub	di,bx
	mov	cl,3
	shr	di,cl
	mov	ax,di
	or	cl,cl
	pop	bp
	ret

LAB_3864:
	mov	ah,bl
	mov	di,ax
	mov	bl,bh
	xor	bh,bh
	mov	ax,[PAGE_SIZE]
	SHR	ax,1
	mul	bx
	mov	dx,ax
	SHL	bx,1
	mov	bx,[bx+CURSOR_POSN]
	mov	al,[NUM_COLUMNS]
	mul	bh
	add	ax,dx
	xor	bh,bh
	add	ax,bx
	SHL	ax,1
	xchg	ax,di
	ret

LAB_388a:
	mov	ah,[CURR_VIDEO_MODE]
	cmp	ah,7
	jbe	LAB_38b3
	cmp	ah,0Ch
	jbe	LAB_38ea
	cmp	ah,13h
	jz	LAB_38b0
	ja	LAB_38ad
LAB_389f:
	cmp	ah,11h
	jnz	LAB_38aa
	and	bl,80h
	or	bl,3Fh
LAB_38aa:
	jmp	LAB_3a04
LAB_38ad:
	jmp	LAB_05f1
LAB_38b0:
	jmp	LAB_3abb

LAB_38b3:
	mov	dl,[INSTALLED_HW]
	and	dl,30h
	cmp	dl,30h
	mov	dx,0B000h
	jz	LAB_38c4
	mov	dh,0B8h
LAB_38c4:
	mov	es,dx
	cmp	ah,7
	jz	LAB_38d0
	cmp	ah,3
	ja	LAB_38f1
LAB_38d0:
	or	bh,bh
	jnz	LAB_38eb
	mov	ah,bl
	mov	di,ax
	mov	bx,[CURSOR_POSN]
	mov	al,[NUM_COLUMNS]
	mul	bh
	xor	bh,bh
	add	ax,bx
	SHL	ax,1
	xchg	ax,di
	rep stosw
LAB_38ea:
	ret

LAB_38eb:
	call	LAB_3864
	rep stosw
	ret
LAB_38f1:
	jmp	SHORT LAB_394c
	nop

LAB_38f4:
	mov	ah,[CURR_VIDEO_MODE]
	cmp	ah,7
	jbe	LAB_390f
	cmp	ah,0Ch
	jbe	LAB_3946
	cmp	ah,13h
	jz	LAB_38b0
	ja	LAB_390c
LAB_3909:
	jmp	LAB_3a04
LAB_390c:
	jmp	LAB_04af

LAB_390f:
	mov	dl,[INSTALLED_HW]
	and	dl,30h
	cmp	dl,30h
	mov	dx,0B000h
	jz	LAB_3920
	mov	dh,0B8h
LAB_3920:
	mov	es,dx
	cmp	ah,7
	jz	LAB_392c
	cmp	ah,3
	ja	LAB_394c
LAB_392c:
	or	bh,bh
	jnz	LAB_3947
	mov	di,ax
	mov	bx,[CURSOR_POSN]
	mov	al,[NUM_COLUMNS]
	mul	bh
	xor	bh,bh
	add	ax,bx
	SHL	ax,1
	xchg	ax,di
LAB_3942:
	stosb
	inc	di
	loop	LAB_3942
LAB_3946:
	ret

LAB_3947:
	call	LAB_3864
	jmp	SHORT LAB_3942

LAB_394c:
	mov	dx,ax
	mov	al,[CURSOR_POSN+1]
	mul	BYTE [NUM_COLUMNS]
	mov	di,ax
	SHL	di,1
	SHL	di,1
	mov	al,[CURSOR_POSN]
	xor	ah,ah
	add	di,ax
	cmp	dh,6
	jz	LAB_3969
	SHL	di,1
LAB_3969:
	mov	al,dl
	cs mov	ds,[LAB_2553]
	or	al,al
	jns	LAB_397c
	and	al,7Fh
	lds	si,[INT_OFF_VAL(1Fh)]
	jmp	SHORT LAB_3980
LAB_397c:
	lds	si,[INT_OFF_VAL(43h)]
LAB_3980:
	xor	ah,ah
	SHL	ax,1
	SHL	ax,1
	SHL	ax,1
	add	si,ax
	cmp	dh,6
	jnz	LAB_39d7
LAB_398f:
	mov	dl,4
	or	bl,bl
	js	LAB_39b5
LAB_3995:
	lodsw
	stosb
	add	di,1FFFh
	mov	al,ah
	stosb
	sub	di,1FB1h
	dec	dl
	jnz	LAB_3995
	sub	di,13Fh
	sub	si,BYTE 8
	loop	LAB_398f
	cs mov	ds,[LAB_2553]
	ret
LAB_39b5:
	lodsw
	es xor	[di],al
	add	di,2000h
	es xor	[di],ah
	sub	di,1FB0h
	dec	dl
	jnz	LAB_39b5
	sub	di,13Fh
	sub	si,BYTE 8
	loop	LAB_398f
	cs mov	ds,[LAB_2553]
	ret

LAB_39d7:
	push	bp
	mov	bh,bl
	and	bh,3
	mov	bp,cx
LAB_39df:
	mov	dh,4
LAB_39e1:
	call	LAB_3b1c
	add	di,1FFEh
	call	LAB_3b1c
	sub	di,1FB2h
	dec	dh
	jnz	LAB_39e1
	sub	di,13Eh
	sub	si,BYTE 8
	dec	bp
	jnz	LAB_39df
	cs mov	ds,[LAB_2553]
	pop	bp
	ret

LAB_3a04:
	push	bp
	mov	si,ax
	mov	bp,cx
	cs mov	es,[LAB_2555]
	mov	al,bh
	xor	ah,ah
	SHL	ax,1
	mov	di,ax
	mov	ax,[di+CURSOR_POSN]
	mov	di,ax
	and	di,0FFh
	mov	al,[NUM_COLUMNS]
	mul	ah
	mul	WORD [CHAR_HEIGHT]
	add	di,ax
	xor	ah,ah
	mov	al,bh
	mul	WORD [PAGE_SIZE]
	add	di,ax
	mov	dl,bl
	mov	cx,[CHAR_HEIGHT]
	mov	bx,[NUM_COLUMNS]
	dec	bx
	mov	ax,si
	mul	BYTE [CHAR_HEIGHT]
	lds	si,[INT_OFF_VAL(43h)]
	add	si,ax
	mov	ah,dl
	xor	al,al
	mov	dx,INDEX_REG
	out	dx,ax
	inc	al
	not	ah
	out	dx,ax
	test	ah,80h
	jz	LAB_3a89
	mov	dx,SEQ_INDEX
	mov	ax,0F02h
	out	dx,ax
LAB_3a65:
	push	si
	push	di
	mov	dx,cx
LAB_3a69:
	movsb
	add	di,bx
	loop	LAB_3a69
	mov	cx,dx
	pop	di
	pop	si
	inc	di
	dec	bp
	jnz	LAB_3a65
	mov	ax,3
	mov	dx,INDEX_REG
	out	dx,ax
	xor	ax,ax
	out	dx,ax
	inc	ax
	out	dx,ax
	cs mov	ds,[LAB_2553]
	pop	bp
	ret

LAB_3a89:
	mov	ax,1803h
	out	dx,ax
	mov	dx,SEQ_INDEX
	mov	ax,0F02h
	out	dx,ax
LAB_3a94:
	push	si
	push	di
	mov	dx,cx
LAB_3a98:
	es mov	al,[di]
	movsb
	add	di,bx
	loop	LAB_3a98
	mov	cx,dx
	pop	di
	pop	si
	inc	di
	dec	bp
	jnz	LAB_3a94
	mov	ax,3
	mov	dx,INDEX_REG
	out	dx,ax
	xor	ax,ax
	out	dx,ax
	inc	ax
	out	dx,ax
	cs mov	ds,[LAB_2553]
	pop	bp
	ret

LAB_3abb:
	push	bp
	mov	bp,cx
	mov	cx,ax
	mov	ax,0A000h
	mov	es,ax
	mov	ax,[CURSOR_POSN]
	mov	di,ax
	and	di,0FFh
	mov	al,[NUM_COLUMNS]
	mul	ah
	mul	WORD [CHAR_HEIGHT]
	add	di,ax
	SHL	di,1
	SHL	di,1
	SHL	di,1
	mov	ax,[CHAR_HEIGHT]
	mov	dx,ax
	mul	cl
	cs mov	ds,[LAB_2553]
	lds	si,[INT_OFF_VAL(43h)]
	add	si,ax
LAB_3af1:
	push	di
	push	dx
LAB_3af3:
	mov	cx,8
	mov	ah,[si]
	inc	si
LAB_3af9:
	rcl	ah,1
	mov	al,bl
	jc	LAB_3b01
	mov	al,bh
LAB_3b01:
	stosb
	loop	LAB_3af9
	add	di,138h
	dec	dx
	jnz	LAB_3af3
	pop	dx
	pop	di
	sub	si,dx
	add	di,BYTE 8
	dec	bp
	jnz	LAB_3af1
	cs mov	ds,[LAB_2553]
	pop	bp
	ret

LAB_3b1c:
	mov	dl,8
	xor	cx,cx
	lodsb
LAB_3b21:
	rcr	al,1
	jnc	LAB_3b27
	or	cl,bh
LAB_3b27:
	ror	cx,1
	ror	cx,1
	dec	dl
	jnz	LAB_3b21
	mov	ax,cx
	xchg	ah,al
	or	bl,bl
	js	LAB_3b39
	stosw
	ret
LAB_3b39:
	es xor	[di],ax
	add	di,BYTE 2
	ret

LAB_3b40:
	cmp	[CRTC_BASE],WORD MONO_CRTC_INDEX
	jz	LAB_3b99
	cmp	bh,0
	jz	LAB_3b9a
LAB_3b4d:
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,4
	jc	LAB_3b99
	cmp	al,13h
	jbe	LAB_3b5f
	call	LAB_10cd
	test	al,1
	jnz	LAB_3b99
LAB_3b5f:
	mov	bh,[CGA_PALETTE_REG]
	and	bh,0DFh
	and	bl,1
	jz	LAB_3b6e
	or	bh,20h
LAB_3b6e:
	mov	[CGA_PALETTE_REG],bh
	and	bh,10h
	or	bh,bl
	or	bx,201h
	test	[VIDEO_CONTROL],BYTE 8
	jnz	LAB_3b92
LAB_3b82:
	call	LAB_3c08
	call	LAB_3bea
	add	bh,2
	inc	bl
	cmp	bl,3
	jbe	LAB_3b82
LAB_3b92:
	mov	dx,COLOR_SELECT_REG
	mov	al,[CGA_PALETTE_REG]
	out	dx,al
LAB_3b99:
	ret

LAB_3b9a:
	mov	ah,[CGA_PALETTE_REG]
	and	ah,0E0h
	mov	bh,bl
	and	bh,1Fh
	or	ah,bh
	mov	[CGA_PALETTE_REG],ah
	mov	al,[bp+0Eh]
	and	al,8
	SHL	al,1
	and	bh,7
	or	bh,al
	mov	bl,11h
	call	LAB_3c08
	mov	bl,10h
	call	LAB_3bea
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,3
	jbe	LAB_3bdc
	cmp	al,13h
	jbe	LAB_3bd4
	call	LAB_10cd
	test	al,1
	jnz	LAB_3bdc
LAB_3bd4:
	xor	bl,bl
	call	LAB_3c08
	call	LAB_3bea
LAB_3bdc:
	mov	bl,[CGA_PALETTE_REG]
	and	bl,20h
	mov	cl,5
	shr	bl,cl
	jmp	LAB_3b4d

LAB_3bea:
	push	ax
	push	di
	push	es
	les	di,[VIDEO_SAVE_PTR]
	es les	di,[di+4]
	mov	ax,es
	or	ax,di
	jz	LAB_3c04
	mov	al,bl
	mov	ah,0
	add	di,ax
	mov	al,bh
	stosb
LAB_3c04:
	pop	es
	pop	di
	pop	ax
	ret

LAB_3c08:
	push	ax
	push	cx
	push	dx
	call	GetCRTCIndex
	add	dl,6
	xor	cx,cx
LAB_3c13:
	in	al,dx
	and	al,8
	loopz	LAB_3c13
	mov	dx,ATTR_CONTROL_INDEX
	mov	al,bl
	pushf
	cli
	out	dx,al
	mov	al,bh
	jmp	SHORT LAB_3c24
LAB_3c24:
	out	dx,al
	mov	al,20h
	out	dx,al
	popf
	pop	dx
	pop	cx
	pop	ax
	ret

LAB_3c2d:
	ja	LAB_3c49
	push	es
	push	di
	push	ax
	push	dx
	mov	di,ax
	cs mov	es,[LAB_2555]
	mov	ax,140h
	mul	dx
	add	ax,cx
	xchg	ax,di
	stosb
	pop	dx
	pop	ax
	pop	di
	pop	es
	pop	ds
	iret

LAB_3c49:
	jmp	LAB_03ff

LAB_3c4c:
	cmp	ah,4
	jc	LAB_3c80
	cmp	ah,7
	jz	LAB_3c80
	cmp	ah,8
	jnc	LAB_3c9b
	push	es
	push	di
	push	bx
	push	cx
	push	dx
	mov	bx,ax
	call	LAB_3db1
	mov	al,ah
	ror	al,cl
	not	al
	and	al,bl
	shl	al,cl
	or	bl,bl
	js	LAB_3c82
	es and	ah,[di]
	or	al,ah
	stosb
LAB_3c79:
	mov	ax,bx
	pop	dx
	pop	cx
	pop	bx
	pop	di
	pop	es
LAB_3c80:
	pop	ds
	iret

LAB_3c82:
	es xor	[di],al
	jmp	SHORT LAB_3c79

LAB_3c87:
	push	ds
	cs mov	ds,[LAB_2553]
	mov	ah,[CURR_VIDEO_MODE]
	cmp	ah,0Dh
	jc	LAB_3c4c
	cmp	ah,13h
	jnc	LAB_3c2d
LAB_3c9b:
	push	bx
	push	cx
	push	dx
	xchg	cx,bx
	mov	cl,bl
	SHR	bx,1
	SHR	bx,1
	SHR	bx,1
	or	ch,ch
	jnz	LAB_3cf7
LAB_3cac:
	mov	ch,al
	mov	ax,[NUM_COLUMNS]
	mul	dx
	add	bx,ax
	mov	dx,SEQ_INDEX
	mov	al,2
	call	ReadIndirectRegister
	or	ah,0Fh
	out	dx,ax
	mov	dx,INDEX_REG
	xor	ax,ax
	out	dx,ax
	mov	ax,0F01h
	out	dx,ax
	and	cl,7
	mov	ax,8008h
	shr	ah,cl
	out	dx,ax
	mov	ax,0A000h
	mov	ds,ax
	or	ch,ch
	js	LAB_3d01
	or	[bx],al
	mov	ah,ch
	out	dx,ax
	or	[bx],al
LAB_3ce4:
	mov	ax,0FF08h
	out	dx,ax
	xor	ax,ax
	out	dx,ax
	inc	al
	out	dx,ax
	mov	al,ch
	mov	ah,0Ch
	pop	dx
	pop	cx
	pop	bx
	pop	ds
	iret

LAB_3cf7:
	add	bx,[PAGE_SIZE]
	dec	ch
	jnz	LAB_3cf7
	jmp	SHORT LAB_3cac

LAB_3d01:
	mov	ax,1803h
	out	dx,ax
	mov	ah,ch
	xor	al,al
	out	dx,ax
	or	[bx],al
	mov	ax,3
	out	dx,ax
	jmp	SHORT LAB_3ce4
LAB_3d12:
	push	dx
	push	di
	cs mov	ds,[LAB_2555]
	mov	ax,140h
	mul	dx
	add	ax,cx
	mov	di,ax
	mov	al,[di]
	mov	ah,0Dh
	pop	di
	pop	dx
	pop	ds
	iret

LAB_3d2a:
	cmp	ah,4
	jc	LAB_3d4f
	cmp	ah,7
	jz	LAB_3d4f
	cmp	ah,8
	jnc	LAB_3d65
	push	es
	push	di
	push	cx
	push	dx
	call	LAB_3db1
	not	ah
	es and	ah,[di]
	shr	ah,cl
	mov	al,ah
	mov	ah,0Dh
	pop	dx
	pop	cx
	pop	di
	pop	es
LAB_3d4f:
	pop	ds
	iret

LAB_3d51:
	push	ds
	cs mov	ds,[LAB_2553]
	mov	ah,[CURR_VIDEO_MODE]
	cmp	ah,0Dh
	jc	LAB_3d2a
	cmp	ah,13h
	jnc	LAB_3d12
LAB_3d65:
	push	si
	push	bx
	push	cx
	push	dx
	mov	si,cx
	SHR	si,1
	SHR	si,1
	SHR	si,1
	or	bh,bh
	jnz	LAB_3da7
LAB_3d75:
	mov	ax,[NUM_COLUMNS]
	mul	dx
	add	si,ax
	and	cl,7
	mov	bl,80h
	shr	bl,cl
	cs mov	ds,[LAB_2555]
	mov	dx,INDEX_REG
	xor	cl,cl
	mov	ax,304h
LAB_3d90:
	out	dx,ax
	mov	ch,[si]
	and	ch,bl
	neg	ch
	rol	cx,1
	dec	ah
	jns	LAB_3d90
	mov	al,cl
	mov	ah,0Dh
	pop	dx
	pop	cx
	pop	bx
	pop	si
	pop	ds
	iret

LAB_3da7:
	add	si,[PAGE_SIZE]
	dec	bh
	jnz	LAB_3da7
	jmp	SHORT LAB_3d75

LAB_3db1:
	mov	ax,0B800h
	mov	es,ax
	mov	al,28h
	mul	dl
	test	al,8
	jz	LAB_3dc1
	add	ax,1FD8h
LAB_3dc1:
	mov	di,ax
	mov	al,cl
	not	al
	cmp	[CURR_VIDEO_MODE],BYTE 6
	jc	LAB_3dd6
	SHR	cx,1
	mov	ah,0FEh
	and	al,7
	jmp	SHORT LAB_3ddc
LAB_3dd6:
	mov	ah,0FCh
	SHL	al,1
	and	al,6
LAB_3ddc:
	SHR	cx,1
	SHR	cx,1
	add	di,cx
	mov	cl,al
	rol	ah,cl
	ret

LAB_3de7:
	jz	LAB_3dfb
	cmp	al,0Ah
	jz	LAB_3e55
	cmp	al,8
	jz	LAB_3e00
	cmp	al,7
	jnz	LAB_3e3e
	call	LAB_3ed5
	jmp	LAB_3ec4

LAB_3dfb:
	xor	dl,dl
	jmp	LAB_3ea1

LAB_3e00:
	dec	dl
	jns	LAB_3e07
	jmp	LAB_3ec4
LAB_3e07:
	jmp	LAB_3ea1
LAB_3e0a:
	mov	cl,[CURR_PAGE]
	xor	ch,ch
	mov	di,cx
	SHL	di,1
	mov	bh,cl
	mov	dx,[di+CURSOR_POSN]
	cmp	al,0Dh
	jbe	LAB_3de7
	jmp	SHORT LAB_3e3e

LAB_3e20:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	push	ds
	cs mov	ds,[LAB_2553]
	mov	bh,[CURR_PAGE]
	or	bh,bh
	jnz	LAB_3e0a
	mov	dx,[CURSOR_POSN]
	cmp	al,0Dh
	jbe	LAB_3de7
LAB_3e3e:
	push	dx
	xor	cx,cx
	inc	cl
	call	LAB_38f4
	pop	dx
	inc	dl
	cmp	dl,[NUM_COLUMNS]
	jnz	LAB_3ea1
	xor	dl,dl
	mov	bh,[CURR_PAGE]
LAB_3e55:
	inc	dh
	cmp	dh,[ROWS_MINUS_ONE]
	jbe	LAB_3ea1
	dec	dh
	push	dx
	call	LAB_3627
	mov	bh,ah
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,4
	jc	LAB_3e89
	cmp	al,7
	jz	LAB_3e84
	cmp	al,13h
	jbe	LAB_3e7b
	call	LAB_10cd
	test	al,1
	jnz	LAB_3e84
LAB_3e7b:
	xor	bh,bh
	cmp	[CURR_VIDEO_MODE],BYTE 6
	jbe	LAB_3e89
LAB_3e84:
	call	LAB_02f6
	jmp	SHORT LAB_3e9b
LAB_3e89:
	mov	dl,[NUM_COLUMNS]
	dec	dl
	mov	dh,[ROWS_MINUS_ONE]
	xor	cx,cx
	mov	ax,601h
	call	LAB_31a2
LAB_3e9b:
	cs mov	ds,[LAB_2553]
	pop	dx
LAB_3ea1:
	mov	al,[CURR_PAGE]
	or	al,al
	jnz	LAB_3ece
	mov	[CURSOR_POSN],dx
	mov	al,[NUM_COLUMNS]
	mul	dh
	add	al,dl
	adc	ah,0
	mov	bl,al
	mov	al,0Eh
	mov	dx,[CRTC_BASE]
	out	dx,ax
	mov	ah,bl
	inc	al
	out	dx,ax
LAB_3ec4:
	pop	ds
	pop	es
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret

LAB_3ece:
	mov	bh,al
	call	LAB_3117
	jmp	SHORT LAB_3ec4

LAB_3ed5:
	push	ax
	push	bx
	push	cx
	push	dx
	mov	al,2
	mov	cx,352h
	call	LAB_49ef
	mov	al,0
	mov	cx,19h
	call	LAB_49ef
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

LAB_3eee:
	mov	al,[VIDEO_CONTROL]
	and	al,80h
	or	al,[CURR_VIDEO_MODE]
	mov	[bp+10h],al
	mov	al,[NUM_COLUMNS]
	mov	[bp+11h],al
	mov	al,[CURR_PAGE]
	mov	[bp+0Fh],al
	ret

	db	00h

LAB_3f08:
	dw	LAB_3f51
	dw	LAB_3f4f
	dw	LAB_3f58
	dw	LAB_3f79
	dw	LAB_3f57
	dw	LAB_3f57
	dw	LAB_3f57
	dw	LAB_3fa5
	dw	LAB_3fa3
	dw	LAB_3fac
	dw	LAB_3f57
	dw	LAB_3f57
	dw	LAB_3f57
	dw	LAB_3f57
	dw	LAB_3f57
	dw	LAB_3f57
	dw	LAB_3fc6
	dw	LAB_3f57
	dw	LAB_3fcb
	dw	LAB_3fea
	dw	LAB_3f57
	dw	LAB_4021
	dw	LAB_3f57
	dw	LAB_402e
	dw	LAB_4041
	dw	LAB_4048
	dw	LAB_4052
	dw	LAB_4073

LAB_3f40:
	cmp	al,1Bh
	ja	LAB_3f57
	xor	ah,ah
	SHL	ax,1
	mov	si,ax
	cs jmp	word [si+LAB_3f08]

LAB_3f4f:
	mov	bl,11h
LAB_3f51:
	call	LAB_3c08
	call	LAB_3bea
LAB_3f57:
	ret

LAB_3f58:
	mov	cx,10h
	xor	bl,bl
	mov	si,dx
LAB_3f5f:
	es mov	bh,[si]
	inc	si
	call	LAB_3c08
	call	LAB_3bea
	inc	bl
	loop	LAB_3f5f
	es mov	bh,[si]
	call	LAB_3bea
	inc	bl
	call	LAB_3c08
	ret

LAB_3f79:
	mov	bl,10h
	call	LAB_4083
	cmp	[bp+0Eh],BYTE 0
	jz	LAB_3f94
	cmp	[bp+0Eh],BYTE 1
	jnz	LAB_3fa2
	or	bh,8
	mov	al,[CURR_MODE_SELECT]
	or	al,20h
	jmp	SHORT LAB_3f9c

LAB_3f94:
	and	bh,0F7h
	mov	al,[CURR_MODE_SELECT]
	and	al,0DFh
LAB_3f9c:
	mov	[CURR_MODE_SELECT],al
	call	LAB_3c08
LAB_3fa2:
	ret

LAB_3fa3:
	mov	bl,11h
LAB_3fa5:
	call	LAB_4083
	mov	[bp+0Fh],bh
	ret

LAB_3fac:
	mov	cx,10h
	xor	bl,bl
	mov	di,dx
LAB_3fb3:
	call	LAB_4083
	mov	al,bh
	stosb
	inc	bl
	loop	LAB_3fb3
	inc	bl
	call	LAB_4083
	mov	al,bh
	stosb
	ret

LAB_3fc6:
	mov	ah,dh
	jmp	LAB_40a6

LAB_3fcb:
	mov	si,dx
	mov	di,cx
	push	bx
	mov	bl,1
	call	LAB_0cd2
	pop	bx
LAB_3fd6:
	es lodsw
	mov	ch,ah
	mov	ah,al
	es lodsb
	mov	cl,al
	call	LAB_40cf
	call	LAB_4b65
	dec	di
	jnz	LAB_3fd6
	ret

LAB_3fea:
	or	bl,bl
	jz	LAB_400a
	mov	bl,10h
	call	LAB_4083
	mov	al,[bp+0Fh]
	and	al,0Fh
	test	bh,80h
	jnz	LAB_4002
	and	al,3
	SHL	al,2
LAB_4002:
	mov	bl,14h
	mov	bh,al
	call	LAB_3c08
	ret

LAB_400a:
	mov	bl,10h
	call	LAB_4083
	and	bh,7Fh
	cmp	[bp+0Fh],BYTE 0
	jz	LAB_401b
	or	bh,80h
LAB_401b:
	mov	bl,10h
	call	LAB_3c08
	ret

LAB_4021:
	call	LAB_40b9
	mov	[bp+0Bh],ah
	mov	[bp+0Dh],ch
	mov	[bp+0Ch],cl
	ret

LAB_402e:
	mov	di,dx
	mov	si,cx
LAB_4032:
	call	LAB_4b48
	mov	al,ah
	mov	ah,ch
	stosw
	mov	al,cl
	stosb
	dec	si
	jnz	LAB_4032
	ret

LAB_4041:
	mov	dx,DAC_MASK_REG
	mov	al,bl
	out	dx,al
	ret

LAB_4048:
	mov	dx,DAC_MASK_REG
	in	al,dx
	xor	ah,ah
	mov	[bp+0Eh],ax
	ret

LAB_4052:
	mov	bl,14h
	call	LAB_4083
	mov	cl,bh
	and	cl,0Fh
	mov	bl,10h
	call	LAB_4083
	mov	bl,1
	test	bh,80h
	jnz	LAB_406d
	mov	bl,0
	SHR	cl,2
LAB_406d:
	mov	bh,cl
	mov	[bp+0Eh],bx
	ret

LAB_4073:
	mov	si,cx
LAB_4075:
	call	LAB_4b48
	call	LAB_40d6
	dec	bx
	call	LAB_4b65
	dec	si
	jnz	LAB_4075
	ret

LAB_4083:
	push	dx
	call	GetCRTCIndex
	add	dl,6
LAB_408a:
	in	al,dx
	and	al,8
	jz	LAB_408a
	push	dx
	mov	dx,ATTR_CONTROL_INDEX
	mov	al,bl
	out	dx,al
	jmp	SHORT LAB_4098
LAB_4098:
	inc	dx
	in	al,dx
	pop	dx
	mov	bh,al
	in	al,dx
	mov	dx,ATTR_CONTROL_INDEX
	mov	al,20h
	out	dx,al
	pop	dx
	ret

LAB_40a6:
	call	LAB_40cf
	call	GetCRTCIndex
	add	dl,6
	pushf
	cli
LAB_40b1:
	in	al,dx
	and	al,8
	jz	LAB_40b1
	jmp	LAB_4b67

LAB_40b9:
	call	GetCRTCIndex
	add	dl,6
	pushf
	cli
LAB_40c1:
	in	al,dx
	and	al,8
	jz	LAB_40c1
	jmp	LAB_4b4a

LAB_40c9:
	dw	2666h
LAB_40cb:
	dw	4B85h
LAB_40cd:
	dw	0E14h

LAB_40cf:
	test	[VIDEO_MODE_CONTROL],BYTE 6
	jz	LAB_411a
LAB_40d6:
	push	bx
	push	dx
	and	ax,3F00h
	xchg	ah,al
	cs mul	WORD [LAB_40c9]
	push	dx
	push	ax
	mov	al,ch
	and	al,3Fh
	xor	ah,ah
	cs mul	WORD [LAB_40cb]
	push	dx
	push	ax
	mov	al,cl
	and	al,3Fh
	xor	ah,ah
	cs mul	WORD [LAB_40cd]
	pop	bx
	add	ax,bx
	pop	bx
	adc	dx,bx
	pop	bx
	add	ax,bx
	pop	bx
	adc	dx,bx
	add	ax,ax
	adc	dx,dx
	add	ax,8000h
	adc	dx,BYTE 0
	mov	ah,dl
	mov	cl,dl
	mov	ch,dl
	pop	dx
	pop	bx
LAB_411a:
	ret

LAB_411b:
	dw	LAB_416e
	dw	LAB_4178
	dw	LAB_4189
	dw	LAB_4195
	dw	LAB_419e
	dw	LAB_416d
	dw	LAB_416d
	dw	LAB_416d
	dw	LAB_41aa
	dw	LAB_41af
	dw	LAB_41c2
	dw	LAB_416d
	dw	LAB_41c7
	dw	LAB_416d
	dw	LAB_416d
	dw	LAB_416d
	dw	LAB_429c
	dw	LAB_42e1
	dw	LAB_42b1
	dw	LAB_42c0
	dw	LAB_42cf
	dw	LAB_416d
	dw	LAB_416d
	dw	LAB_416d
	dw	LAB_4320

LAB_414d:
	mov	si,[bp+4]
	and	bl,3Fh
LAB_4153:
	mov	ah,al
	and	al,0Fh
	and	ah,30h
	SHR	ah,1
	or	al,ah
	cmp	al,19h
	jnc	LAB_416d
	mov	ah,0
	mov	di,ax
	SHL	di,1
	cs jmp	[di+LAB_411b]
LAB_416d:
	ret

LAB_416e:
	cmp	[CURR_VIDEO_MODE],BYTE 5Fh
	jz	LAB_416d
	jmp	LAB_4a35

LAB_4178:
	mov	si,5F6Bh
	mov	ax,cs
	mov	es,ax
	xor	dx,dx
	mov	cx,100h
	mov	bh,0Eh
	jmp	LAB_4a35

LAB_4189:
	mov	si,LAB_576b
	call	LAB_4364
	mov	bh,8
	call	LAB_4a35
	ret

LAB_4195:
	mov	al,3
	mov	ah,bl
	mov	dx,SEQ_INDEX
	out	dx,ax
	ret

LAB_419e:
	mov	si,LAB_6e9b
	call	LAB_4364
	mov	bh,10h
	call	LAB_4a35
	ret

LAB_41aa:
	call	LAB_4a35
	jmp	SHORT LAB_41cc

LAB_41af:
	mov	si,LAB_5f6b
	mov	ax,cs
	mov	es,ax
	xor	dx,dx
	mov	cx,100h
	mov	bh,0Eh
	call	LAB_4a35
	jmp	SHORT LAB_41cc

LAB_41c2:
	call	LAB_4189
	jmp	SHORT LAB_41cc

LAB_41c7:
	call	LAB_419e
	jmp	SHORT LAB_41cc

LAB_41cc:
	mov	[CHAR_HEIGHT],bh
	call	GetCRTCIndex
	mov	al,15h
	call	ReadIndirectRegister
	mov	bl,ah
	mov	al,7
	call	ReadIndirectRegister
	and	ah,8
	SHR	ah,3
	mov	bh,ah
	mov	al,9
	call	ReadIndirectRegister
	mov	cl,ah
	and	ah,20h
	SHR	ah,4
	or	bh,ah
	test	cl,80h
	jz	LAB_41fd
	SHR	bx,1
LAB_41fd:
	mov	cx,bx
	mov	bx,0C8h
	cmp	cx,0D2h
	jbe	LAB_4225
	mov	bx,15Eh
	cmp	cx,168h
	jbe	LAB_4225
	mov	bx,190h
	cmp	cx,19Ah
	jbe	LAB_4225
	mov	bx,1E0h
	cmp	cx,1EAh
	jbe	LAB_4225
	mov	bx,cx
LAB_4225:
	mov	ax,bx
	xor	dx,dx
	div	WORD [CHAR_HEIGHT]
	dec	al
	mov	[ROWS_MINUS_ONE],al
	inc	al
	mov	cx,[NUM_COLUMNS]
	SHL	cx,1
	xor	ah,ah
	mul	cx
	add	ax,100h
	mov	[PAGE_SIZE],ax
	mov	dx,[CRTC_BASE]
	mov	ah,[CHAR_HEIGHT]
	dec	ah
	cmp	[CURR_VIDEO_MODE],BYTE 7
	jnz	LAB_4258
	mov	al,14h
	out	dx,ax
LAB_4258:
	mov	ch,ah
	mov	al,9
	call	ReadIndirectRegister
	and	ah,0E0h
	or	ah,ch
	out	dx,ax
	mov	ah,ch
	mov	ch,ah
	mov	cl,ah
	dec	ch
	cmp	ah,0Ch
	jbe	LAB_4276
	sub	cx,101h
LAB_4276:
	mov	[CURSOR_TYPE],cx
	mov	al,0Ah
	mov	ah,ch
	out	dx,ax
	inc	al
	mov	ah,cl
	out	dx,ax
	mov	al,[ROWS_MINUS_ONE]
	inc	al
	mul	BYTE [CHAR_HEIGHT]
	cmp	bx,0C8h
	jnz	LAB_4295
	SHL	ax,1
LAB_4295:
	dec	ax
	mov	ah,al
	mov	al,12h
	out	dx,ax
	ret

LAB_429c:
	mov	di,es
	cs mov	es,[LAB_2553]
	pushf
	cli
	es mov	[INT_OFF_VAL(1Fh)],si
	es mov	[INT_SEG_VAL(1Fh)],di
	popf
	ret

LAB_42b1:
	cs mov	es,[LAB_2553]
	mov	si,LAB_5f6b
	mov	di,cs
	mov	cx,0Eh
	jmp	SHORT LAB_42e8

LAB_42c0:
	cs mov	es,[LAB_2553]
	mov	si,LAB_576b
	mov	di,cs
	mov	cx,8
	jmp	SHORT LAB_42e8

LAB_42cf:
	cs mov	es,[LAB_2553]
	mov	si,LAB_6e9b
	mov	di,cs
	mov	cx,10h
	jmp	SHORT LAB_42e8

LAB_42de:
	db	0Dh, 18h, 2Ah

LAB_42e1:
	mov	di,es
	cs mov	es,[LAB_2553]
LAB_42e8:
	pushf
	cli
	es mov	[INT_OFF_VAL(43h)],si
	es mov	[INT_SEG_VAL(43h)],di
	popf
	cmp	bl,4
	jc	LAB_42fc
	mov	bl,3
LAB_42fc:
	dec	dl
	or	bl,bl
	jz	LAB_430b
	dec	bl
	mov	bh,0
	cs mov	dl,[bx+LAB_42de]
LAB_430b:
	mov	[CHAR_HEIGHT],cx
	mov	[ROWS_MINUS_ONE],dl
	ret

LAB_4314:
	dw	LAB_5f6b
	dw	LAB_576b
	dw	LAB_5b6b
	dw	LAB_6d6b
	dw	LAB_6e9b
	dw	LAB_7e9b

LAB_4320:
	cs mov	es,[LAB_2553]
	or	bh,bh
	jnz	LAB_4330
	es les	bx,[INT_OFF_VAL(1Fh)]
	jmp	SHORT LAB_4351

LAB_4330:
	dec	bh
	jnz	LAB_433b
	es les	bx,[INT_OFF_VAL(43h)]
	jmp	SHORT LAB_4351

LAB_433b:
	dec	bh
	cmp	bh,5
	ja	LAB_4363
	mov	ax,cs
	mov	es,ax
	mov	bl,bh
	mov	bh,0
	add	bx,bx
	cs mov	bx,[bx+LAB_4314]

LAB_4351:
	mov	[bp+4],bx
	mov	[bp+2],es
	mov	ax,[CHAR_HEIGHT]
	mov	[bp+0Ch],ax
	mov	al,[ROWS_MINUS_ONE]
	mov	[bp+0Ah],al
LAB_4363:
	ret

LAB_4364:
	mov	ax,cs
	mov	es,ax
	xor	dx,dx
	mov	cx,100h
	ret

LAB_436e:
	dw	LAB_4407
	dw	LAB_44b6
	dw	LAB_44ca
	dw	LAB_44f6
	dw	LAB_450f
	dw	LAB_4549
	dw	LAB_457d

LAB_437c:
	cmp	bl,80h
	jc	LAB_4389
	call	LAB_0929
	mov	[bp+10h],ax
	jmp	SHORT LAB_43ad

LAB_4389:
	sub	bl,10h
	jz	LAB_43ae
	sub	bl,10h
	jz	LAB_43da
	sub	bl,10h
	jc	LAB_43aa
	cmp	bl,6
	ja	LAB_43aa
	xor	bh,bh
	SHL	bx,1
	mov	[bp+10h],BYTE 12h
LAB_43a5:
	cs jmp	WORD [bx+LAB_436e]

LAB_43aa:
	call	LAB_13e0
LAB_43ad:
	ret

LAB_43ae:
	mov	ch,[VIDEO_SWITCHES]
	mov	cl,4
	mov	al,ch
	shr	ch,cl
	mov	cl,al
	and	cl,0Fh
	mov	[bp+0Ch],cx
	mov	al,[VIDEO_CONTROL]
	SHR	al,1
	and	al,1
	mov	[bp+0Fh],al
	mov	al,[VIDEO_CONTROL]
	and	al,7Fh
	mov	cl,5
	shr	al,cl
	mov	[bp+0Eh],al
	mov	[bp+10h],al
	ret

LAB_43da:
	push	ds
	cs mov	ds,[LAB_2553]
	pushf
	cli
	mov	[INT_OFF_VAL(5h)],WORD LAB_459d
	mov	[INT_SEG_VAL(5h)],cs
	popf
	pop	ds
	ret

LAB_43ef:
	dw	LAB_443d
	dw	LAB_4438
	dw	LAB_4433
	dw	LAB_444d
	dw	LAB_4467
	dw	LAB_4462
	dw	LAB_447c
	dw	LAB_4477
	dw	LAB_4491
	dw	LAB_448c
	dw	LAB_44a6
	dw	LAB_44a1

LAB_4407:
	cmp	al,2
	ja	LAB_4433
	test	[VIDEO_CONTROL],BYTE 8
	jnz	LAB_4433
	mov	bl,al
	xor	bh,bh
	SHL	bx,3
	mov	si,bx
	mov	bl,[VIDEO_CONTROL]
	and	bl,2
	mov	al,[VIDEO_MODE_CONTROL]
	and	al,1
	or	bl,al
	and	bl,3
	SHL	bx,1
	cs jmp	WORD [bx+si+LAB_43ef]

LAB_4433:
	mov	[bp+10h],BYTE 0
	ret

LAB_4438:
	or	[VIDEO_MODE_CONTROL],BYTE 80h
LAB_443d:
	and	[VIDEO_MODE_CONTROL],BYTE 0EFh
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],BYTE 8
	ret

LAB_444d:
	or	[VIDEO_MODE_CONTROL],BYTE 80h
	and	[VIDEO_MODE_CONTROL],BYTE 0EFh
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],BYTE 0Bh
	ret

LAB_4462:
	and	[VIDEO_MODE_CONTROL],BYTE 7FH
LAB_4467:
	and	[VIDEO_MODE_CONTROL],BYTE 0EFh
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],BYTE 9
	ret

LAB_4477:
	and	[VIDEO_MODE_CONTROL],BYTE 7Fh
LAB_447c:
	and	[VIDEO_MODE_CONTROL],BYTE 0EFh
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],BYTE 0Bh
	ret
	
LAB_448c:
	and	[VIDEO_MODE_CONTROL],BYTE 7Fh
LAB_4491:
	or	[VIDEO_MODE_CONTROL],BYTE 10h
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],BYTE 9
	ret

LAB_44a1:
	and	[VIDEO_MODE_CONTROL],BYTE 7Fh
LAB_44a6:
	or	[VIDEO_MODE_CONTROL],BYTE 10h
	and	[VIDEO_SWITCHES],BYTE 0F0h
	or	[VIDEO_SWITCHES],BYTE 0Bh
	ret

LAB_44b6:
	cmp	al,1
	ja	LAB_450a
	mov	al,0
	jnz	LAB_44c0
	mov	al,8
LAB_44c0:
	and	[VIDEO_MODE_CONTROL],BYTE 0F7h
	or	[VIDEO_MODE_CONTROL],al
	ret

LAB_44ca:
	cmp	al,1
	ja	LAB_450a
	jz	LAB_44e4
	mov	al,0Eh
	mov	dx,SLEEP_REG
	cs test	[LAB_1036],BYTE 8
	jz	LAB_44e2
	mov	al,1
	mov	dx,SLEEP_REG_READ
LAB_44e2:
	out	dx,al
	ret

LAB_44e4:
	xor	al,al
	mov	dx,SLEEP_REG
	cs test	[LAB_1036],BYTE 8
	jz	LAB_44f4
	mov	dx,SLEEP_REG_READ
LAB_44f4:
	out	dx,al
	ret

LAB_44f6:
	cmp	al,1
	ja	LAB_450a
	mov	al,0
	jz	LAB_4500
	mov	al,2
LAB_4500:
	and	[VIDEO_MODE_CONTROL],BYTE 0FDh
	or	[VIDEO_MODE_CONTROL],al
	ret

LAB_450a:
	mov	[bp+10h],BYTE 0
	ret

LAB_450f:
	cmp	al,1
	ja	LAB_450a
	mov	al,0
	jnz	LAB_4519
	mov	al,1
LAB_4519:
	and	[VIDEO_CONTROL],BYTE 0FEh
	or	[VIDEO_CONTROL],al
	ret

LAB_4523:
	cs mov	es,[LAB_2553]
	mov	si,INT_OFF_VAL(6Dh)
	lodsw
	push	ax
	lodsw
	push	ax
	mov	di,INT_OFF_VAL(6Dh)
	mov	si,INT_OFF_VAL(42h)
	movsw
	movsw
	mov	di,INT_OFF_VAL(42h)
	pop	si
	pop	ax
	stosw
	mov	ax,si
	stosw
	ret

LAB_4541:
	dw	LAB_455c
	dw	LAB_456d
	dw	LAB_455c
	dw	LAB_456e

LAB_4549:
	mov	[bp+10h],BYTE 0
	cmp	al,3
	ja	LAB_456d
	mov	bl,al
	xor	bh,bh
	SHL	bx,1
LAB_4557:
	cs jmp	WORD [bx+LAB_4541]

LAB_455c:
	mov	di,dx
	call	LAB_4950
	call	LAB_4523
	mov	al,1
	call	LAB_44ca
	mov	[bp+10h],BYTE 12h
LAB_456d:
	ret

LAB_456e:
	mov	si,dx
	call	LAB_4980
	mov	al,0
	call	LAB_44ca
	mov	[bp+10h],BYTE 12h
	ret

LAB_457d:
	cmp	al,1
	ja	LAB_4598
	mov	cl,5
	shl	al,cl
	mov	bl,al
	mov	dx,SEQ_INDEX
	mov	al,1
	call	ReadPort
	and	ah,0DFh
	or	ah,bl
	mov	al,1
	out	dx,ax
	ret

LAB_4598:
	mov	[bp+10h],BYTE 0
	ret

LAB_459d:
	push	ds
	PUSHA
	cs mov	ds,[LAB_2551]
	mov	al,1
	cmp	[PRINT_SCREEN_STAT],al
	jz	LAB_4619
	mov	[PRINT_SCREEN_STAT],al
	xor	dx,dx
	mov	ah,2
	int	17h
	mov	cl,0FFh
	test	ah,80h
	jz	LAB_4615
	test	ah,20h
	jnz	LAB_4615
	sti
	mov	ah,0Fh
	call	LAB_254b
	mov	cl,ah
	mov	ch,[ROWS_MINUS_ONE]
	inc	ch
	mov	ah,3
	push	cx
	call	LAB_254b
	pop	cx
	push	dx
	mov	bp,sp
	mov	dh,0FFh
	jmp	SHORT LAB_45f8

LAB_45dd:
	mov	ax,200h
	call	LAB_254b
	mov	ax,800h
	call	LAB_254b
	or	al,al
	jnz	LAB_45ef
	mov	al,20h
LAB_45ef:
	call	LAB_461c
	inc	dl
	cmp	dl,cl
	jnz	LAB_45dd
LAB_45f8:
	mov	al,0Ah
	call	LAB_461c
	mov	al,0Dh
	call	LAB_461c
	xor	dl,dl
	inc	dh
	cmp	dh,ch
	jnz	LAB_45dd
	mov	cl,0
LAB_460c:
	mov	sp,bp
	pop	dx
	mov	ax,200h
	call	LAB_254b
LAB_4615:
	mov	[PRINT_SCREEN_STAT],cl
LAB_4619:
	POPA
	pop	ds
	iret

LAB_461c:
	push	dx
	xor	ah,ah
	xor	dx,dx
	int	17h
	test	ah,25h
	pop	dx
	jz	LAB_462d
	mov	cl,0FFh
	jmp	SHORT LAB_460c
LAB_462d:
	ret

LAB_462e:
	jcxz	LAB_46a3
	cmp	al,3
	ja	LAB_46a3
	mov	ah,bh
	xchg	[CURR_PAGE],bh
	push	bx
	test	al,1
	jnz	LAB_464a
	mov	bl,ah
	xor	bh,bh
	SHL	bx,1
	mov	dx,[bx+CURSOR_POSN]
	push	dx
LAB_464a:
	mov	si,[bp+4]
	mov	cx,[bp+0Ch]
	mov	dx,[bp+0Ah]
LAB_4653:
	push	cx
	mov	bh,[bp+0Fh]
	mov	cx,dx
	call	LAB_3117
	mov	dx,cx
	mov	es,[bp+2]
	es lodsb
	cmp	al,0Dh
	jbe	LAB_46a4
LAB_4667:
	mov	bx,[bp+0Eh]
	test	[bp+10h],BYTE 2
	jz	LAB_4674
	es mov	bl,[si]
	inc	si
LAB_4674:
	push	si
	push	dx
	push	bp
	mov	cx,1
	call	LAB_388a
	cs mov	ds,[LAB_2553]
	pop	bp
	pop	dx
	inc	dl
	cmp	dl,[NUM_COLUMNS]
	jc	LAB_46c7
	inc	dh
	xor	dl,dl
	cmp	dh,[ROWS_MINUS_ONE]
	jbe	LAB_46c7
	push	dx
	mov	al,0Ah
	pushf
	push	cs
	call	LAB_3e20
	pop	dx
	dec	dh
	jmp	SHORT LAB_46c7
LAB_46a3:
	ret
LAB_46a4:
	cmp	al,7
	jz	LAB_46b6
	cmp	al,8
	jz	LAB_46b6
	cmp	al,0Ah
	jz	LAB_46b6
	cmp	al,0Dh
	jz	LAB_46b6
	jmp	SHORT LAB_4667
LAB_46b6:
	push	si
	pushf
	push	cs
	call	LAB_3e20
	mov	bl,[bp+0Fh]
	xor	bh,bh
	SHL	bx,1
	mov	dx,[bx+CURSOR_POSN]
LAB_46c7:
	pop	si
	pop	cx
	loop	LAB_4653
	test	[bp+10h],BYTE 1
	jnz	LAB_46d2
	pop	dx
LAB_46d2:
	mov	bh,[bp+0Fh]
	call	LAB_3117
	pop	bx
	xchg	[CURR_PAGE],bh
	mov	bl,[CURR_PAGE]
	xor	bh,bh
	SHL	bx,1
	mov	dx,[bx+CURSOR_POSN]
	mov	bh,bl
	SHR	bh,1
	call	LAB_3117
	ret

LAB_46f1:
	or	al,al
	jnz	LAB_4701
	call	LAB_4748
	mov	[bp+0Eh],cx
	mov	[bp+10h],WORD 1Ah
	ret

LAB_4701:
	dec	al
	jnz	LAB_4747
	mov	dl,0FFh
	mov	bx,10h
	call	LAB_3060
	jz	LAB_473e
	es les	bx,[bx+2]
	mov	ax,es
	or	ax,bx
	jz	LAB_473e
	es mov	cl,[bx]
	xor	ch,ch
	jcxz	LAB_473e
	mov	di,bx
	add	di,BYTE 4
	mov	ax,[bp+0Eh]
	repne scasw
	jz	LAB_473a
	es mov	cl,[bx]
	mov	di,bx
	add	di,BYTE 4
	xchg	ah,al
	repne scasw
	jnz	LAB_473e
LAB_473a:
	mov	dl,0Fh
	sub	dl,cl
LAB_473e:
	mov	[VIDEO_COMB_INDEX],dl
	mov	[bp+10h],WORD 1Ah
LAB_4747:
	ret

LAB_4748:
	call	LAB_4769
	jz	LAB_4768
	or	cl,cl
	jz	LAB_4766
	mov	al,[INSTALLED_HW]
	and	al,30h
	cmp	al,30h
	jz	LAB_4761
	test	cl,1
	jnz	LAB_4766
	jmp	SHORT LAB_4768
LAB_4761:
	test	cl,1
	jnz	LAB_4768
LAB_4766:
	xchg	ch,cl
LAB_4768:
	ret

LAB_4769:
	push	es
	mov	cx,0FFFFh
	mov	bx,10h
	call	LAB_3060
	jz	LAB_4793
	es les	bx,[bx+2]
	mov	ax,es
	or	ax,bx
	jz	LAB_4793
	mov	al,[VIDEO_COMB_INDEX]
	es cmp	al,[bx]
	jnc	LAB_4793
	xor	ah,ah
	SHL	ax,1
	add	ax,4
	mov	si,ax
	es mov	cx,[bx+si]
LAB_4793:
	cmp	cx,BYTE -1
	pop	es
	ret

LAB_4798:
	dw	0010h,0010h,0010h,0010h,0004h,0004h,0002h,0000h
	dw	0000h,0000h,0000h,0000h,0000h,0010h,0010h,0000h
	dw	0010h,0002h,0010h,0100h
LAB_47c0:
	db	08h,08h,08h,08h,01h,01h,01h,08h,00h,00h,00h,00h,00h,08h,04h,02h
	db	02h,01h,01h,01h

LAB_47d4:
	or	bx,bx
	jz	LAB_47dd
	mov	[bp+10h],BYTE 0
	ret
LAB_47dd:
	mov	[bp+10h],BYTE 1Bh
	mov	ax,LAB_501b
	stosw
	mov	ax,cs
	stosw
	mov	cx,0Fh
	mov	si,CURR_VIDEO_MODE
	rep movsw
	mov	al,[ROWS_MINUS_ONE]
	inc	al,
	stosb
	mov	ax,[CHAR_HEIGHT]
	stosw
	call	LAB_4748
	mov	ax,cx
	stosw
	mov	al,[CURR_VIDEO_MODE]
	xor	ah,ah
	SHL	ax,1
	mov	bx,ax
	cs mov	ax,[bx+LAB_4798]
	stosw
	SHR	bx,1
	cs mov	al,[bx+LAB_47c0]
	stosb
	mov	bl,3
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,11h
	jz	LAB_4869
	cmp	al,12h
	jz	LAB_4869
	mov	bl,0
	cmp	al,13h
	jz	LAB_4869
	cmp	al,4
	jc	LAB_4840
	cmp	al,6
	jbe	LAB_4869
	cmp	al,9
	jc	LAB_4840
	cmp	al,0Eh
	jbe	LAB_4869
	mov	bl,1
	cmp	al,10h
	jbe	LAB_4869
LAB_4840:
	mov	bl,2
	test	[VIDEO_MODE_CONTROL],BYTE 10h
	jnz	LAB_4869
	mov	bl,1
	test	[VIDEO_CONTROL],BYTE 2
	jnz	LAB_4869
	mov	ah,[VIDEO_SWITCHES]
	and	ah,0Fh
	cmp	ah,3
	jz	LAB_4869
	cmp	ah,9
	jz	LAB_4869
	cmp	al,7
	jz	LAB_4869
	mov	bl,0
LAB_4869:
	mov	al,bl
	stosb
	mov	dx,SEQ_INDEX
	mov	al,3
	call	ReadPort
	mov	al,ah
	and	al,3
	test	ah,10h
	jz	LAB_487f
	or	al,4
LAB_487f:
	stosb
	mov	al,ah
	and	al,0Ch
	SHR	al,2
	test	ah,20h
	jz	LAB_488e
	or	al,4
LAB_488e:
	stosb
	mov	bl,10h
	call	LAB_4083
	mov	al,bh
	and	al,8
	SHL	al,2
	mov	cl,4
	mov	ah,[VIDEO_MODE_CONTROL]
	and	ah,0Fh
	or	ah,al
	mov	al,[VIDEO_CONTROL]
	and	al,1
	shl	al,cl
	xor	al,10h
	or	al,ah
	stosb
	mov	al,4
	call	LAB_0f91
	jnz	LAB_48cd
	mov	al,8
	mov	dx,SEQ_INDEX
	call	ReadIndirectRegister
	and	ah,40h
	xor	ah,40h
	mov	cl,4
	shr	ah,cl
	mov	al,ah
LAB_48cd:
	or	al,11h
	stosb
	xor	ax,ax
	stosw
	mov	al,[VIDEO_CONTROL]
	mov	cl,5
	shr	al,cl
	and	al,3
	stosb
	xor	ch,ch
	push	es
	les	bx,[VIDEO_SAVE_PTR]
	es mov	ax,[bx+4]
	es or	ax,[bx+6]
	cmp	ax,1
	rcr	ch,1
	es mov	ax,[bx+8]
	es or	ax,[bx+0AH]
	cmp	ax,1
	rcr	ch,1
	es mov	ax,[bx+0Ch]
	es or	ax,[bx+0Eh]
	cmp	ax,1
	rcr	ch,1
	es les	bx,[bx+10h]
	mov	cl,4
	shr	ch,cl
	mov	ax,es
	or	ax,bx
	jz	LAB_4946
	shl	ch,cl
	mov	cl,2
	es mov	ax,[bx+0Ah]
	es or	ax,[bx+0Ch]
	cmp	ax,1
	rcr	ch,1
	mov	ax,cs
	es cmp	[bx+4],ax
	clc
	jz	LAB_4934
	cmc
LAB_4934:
	rcr	ch,1
	shr	ch,cl
	es mov	ax,[bx+6]
	es or	ax,[bx+8]
	cmp	ax,1
	adc	ch,0
LAB_4946:
	pop	es
	stosb
	mov	cx,0Dh
	xor	al,al
	rep stosb
	ret

LAB_4950:
	mov	al,[INSTALLED_HW]
	and	al,30h
	stosb
	mov	si,CURR_VIDEO_MODE
	mov	cx,0Fh
	rep movsw
	mov	si,ROWS_MINUS_ONE
	mov	cx,7
	rep movsb
	mov	si,VIDEO_SAVE_PTR
	movsw
	movsw
	mov	si,INT_OFF_VAL(5h)
	movsw
	movsw
	mov	si,INT_OFF_VAL(1Dh)
	movsw
	movsw
	mov	si,INT_OFF_VAL(1Fh)
	movsw
	movsw
	mov	si,INT_OFF_VAL(43h)
	movsw
	movsw
	ret

LAB_4980:
	and	[INSTALLED_HW],BYTE 0CFh
	es lodsb
	or	[INSTALLED_HW],al
	push	es
	push	ds
	mov	ax,ds
	mov	di,es
	xchg	ax,di
	mov	ds,ax
	mov	es,di
	mov	di,CURR_VIDEO_MODE
	mov	cx,0Fh
	rep movsw
	mov	di,ROWS_MINUS_ONE
	mov	cx,7
	rep movsb
	pop	ds
	pop	es

	es lodsw
	mov	[VIDEO_SAVE_PTR],ax
	es lodsw
	mov	[VIDEO_SAVE_PTR+2],ax

	mov	di,INT_OFF_VAL(5h)
	es lodsw
	mov	[di],ax
	es lodsw
	mov	[di+2],ax

	mov	di,INT_OFF_VAL(1Dh)
	es lodsw
	mov	[di],ax
	es lodsw
	mov	[di+2],ax

	mov	di,INT_OFF_VAL(1Fh)
	es lodsw
	mov	[di],ax
	es lodsw
	mov	[di+2],ax

	mov	di,INT_OFF_VAL(43h)
	es lodsw
	mov	[di],ax
	es lodsw
	mov	[di+2],ax

	ret

	db	0

;-------------------------------------------------------------------------------
; ReadPort
;-------------------------------------------------------------------------------
; Reads the specified register identified by its index register and index.
;
; Input:
; DX = Index Register
; AL = Index
;
; Output:
; AH = Value read
; AL incremented by one
;-------------------------------------------------------------------------------
ReadPort:
	out	dx,al
	inc	dx
	inc	al
	mov	ah,al
	in	al,dx
	dec	dx
	xchg	ah,al
	ret

LAB_49ef:
	mov	bl,al
	in	al,61h
	jmp	SHORT LAB_49f5
LAB_49f5:
	mov	bh,al
	and	al,0FCh
	or	al,bl
	or	al,1
	out	61h,al
	jmp	SHORT LAB_4a01
LAB_4a01:
	mov	al,0B6h
	out	43h,al
	jmp	SHORT LAB_4a07
LAB_4a07:
	mov	al,50h
	out	42h,al
	jmp	SHORT LAB_4a0d
LAB_4a0d:
	mov	al,5
	out	42h,al
	mov	dx,0FFFFh
LAB_4a14:
	mov	al,80h
	out	43h,al
	jmp	SHORT LAB_4a1a
LAB_4a1a:
	in	al,42h
	jmp	SHORT LAB_4a1e
LAB_4a1e:
	mov	ah,al
	in	al,42h
	xchg	ah,al
	cmp	ax,dx
	mov	dx,ax
	jc	LAB_4a14
	loop	LAB_4a14
	in	al,61h
	jmp	SHORT LAB_4a30
LAB_4a30:
	and	al,bh
	out	61h,al
	ret

LAB_4a35:
	PUSHA
	push	ds
	push	es
	call	DisableVideo
	call	LAB_0f91
	jnz	LAB_4a54
	push	dx
	push	bx
	mov	dx,SEQ_INDEX
	mov	al,0Fh
	call	ReadIndirectRegister
	mov	bx,ax
	or	ah,40h
	out	dx,ax
	pop	ax
	pop	dx
	xchg	ax,bx
	push	ax
LAB_4a54:
	push	dx
	mov	dx,SEQ_INDEX
	mov	ax,402h
	out	dx,ax
	mov	ax,704h
	out	dx,ax
	mov	dx,INDEX_REG
	mov	ax,204h
	out	dx,ax
	mov	ax,5
	out	dx,ax
	mov	ax,406h
	out	dx,ax
	pop	dx
	mov	ax,es
	mov	ds,ax
	mov	ax,0A000h
	mov	es,ax
	push	bx
	and	bl,7
	ror	bl,1
	ror	bl,1
	rcr	bl,1
	jnc	LAB_4a88
	add	bl,10h
LAB_4a88:
	SHL	bl,1
	mov	ah,bl
	mov	al,0
	mov	di,ax
	or	dx,dx
	jz	LAB_4a9b
	mov	ax,20h
	mul	dx
	add	di,ax
LAB_4a9b:
	mov	dx,20h
	sub	dl,bh
	jcxz	LAB_4aae
LAB_4aa2:
	push	cx
	mov	cl,bh
	mov	ch,0
	rep movsb
	add	di,dx
	pop	cx
	loop	LAB_4aa2
LAB_4aae:
	pop	bx
	mov	dx,SEQ_INDEX
	call	LAB_0f91
	jnz	LAB_4ab9
	pop	ax
	out	dx,ax
LAB_4ab9:
	pop	es
	pop	ds
	call	LAB_4ae7
	mov	dx,SEQ_INDEX
	mov	ax,302h
	out	dx,ax
	mov	ax,304h
	out	dx,ax
	mov	dx,INDEX_REG
	mov	ax,4
	out	dx,ax
	mov	ax,1005h
	out	dx,ax
	mov	ax,0A06h
	cmp	[CRTC_BASE],WORD MONO_CRTC_INDEX
	jz	LAB_4ae1
	mov	ah,0Eh
LAB_4ae1:
	out	dx,ax
	call	LAB_4b25
	POPA
	ret

LAB_4ae7:
	push	ax
	push	cx
	push	di
	push	si
	push	es
	mov	cx,0A000h
	mov	es,cx
	test	bl,0C0h
	jz	LAB_4b1f
	mov	cx,7
	mov	si,LAB_6d6b
	test	bl,80h
	jnz	LAB_4b06
	mov	si,LAB_7e9b
	mov	cl,8
LAB_4b06:
	cs mov	ah,[si]
	inc	si
	or	ah,ah
	jz	LAB_4b1f
	xor	al,al
	SHR	ax,3
	mov	di,ax
	push	cx
	pushf
	cli
	cs rep movsw
	popf
	pop	cx
	jmp	SHORT LAB_4b06

LAB_4b1f:
	pop	es
	pop	si
	pop	di
	pop	cx
	pop	ax
	ret

LAB_4b25:
	push	dx
	call	GetCRTCIndex
	add	dl,6
	push	dx
	in	al,dx
	mov	dx,ATTR_CONTROL_INDEX
	mov	al,20h
	out	dx,al
	pop	dx
	in	al,dx
	pop	dx
	ret

;-------------------------------------------------------------------------------
; DisableVideo
;-------------------------------------------------------------------------------
; Disables the video hardware
;
; Input:
;  Nothing
;
; Output:
;  AL destroyed
;-------------------------------------------------------------------------------
DisableVideo:
	push	dx					; Save register

	call	GetCRTCIndex				; Get Index register
	add	dx,BYTE 6				; Point to Input status register
	in	al,dx					; Read it

	xor	al,al					; Video disabled
	mov	dx,ATTR_CONTROL_INDEX
	out	dx,al					; Disable video

	pop	dx					; Restore register
	ret						; Return to caller

LAB_4b48:
	pushf
	cli
LAB_4b4a:
	mov	dx,PIXEL_ADDRESS
	mov	al,bl
	out	dx,al
	jmp	SHORT LAB_4b52
LAB_4b52:
	add	dx,BYTE 2
	in	al,dx
	jmp	SHORT LAB_4b58
LAB_4b58:
	mov	ah,al
	in	al,dx
	jmp	SHORT LAB_4b5d
LAB_4b5d:
	mov	ch,al
	in	al,dx
	mov	cl,al
	inc	bx
	popf
	ret

LAB_4b65:
	pushf
	cli
LAB_4b67:
	call	LAB_4b6d
	inc	bx
	popf
	ret

LAB_4b6d:
	mov	dx,PIXEL_ADDR_WR_MODE
	mov	al,bl
	out	dx,al
	in	al,80h
	inc	dx
	mov	al,ah
	out	dx,al
	in	al,80h
	mov	al,ch
	out	dx,al
	in	al,80h
	mov	al,cl
	out	dx,al
	ret

LAB_4b84:
	push	dx
	mov	dx,SEQ_INDEX
	in	al,dx
	push	ax
	mov	al,1
	call	ReadIndirectRegister
	or	ah,20h
	out	dx,ax
	pop	ax
	out	dx,al
	pop	dx
	ret

LAB_4b97:
	push	dx
	mov	dx,SEQ_INDEX
	in	al,dx
	push	ax
	mov	al,1
	call	ReadIndirectRegister
	and	ah,0DFh
	pushf
	cli
	out	dx,ax
	popf
	pop	ax
	out	dx,al
	pop	dx
	ret

LAB_4bad:
	call	LAB_4b84
	mov	si,100h
	xor	bx,bx
	xor	ah,ah
	xor	cx,cx
LAB_4bb9:
	call	LAB_4b65
	dec	si
	jnz	LAB_4bb9
	call	LAB_4b97
	ret

LAB_4bc3:
	push	cx
	push	dx
	call	DisableVideo
	add	si,BYTE 5
	mov	cx,4
	mov	al,1
	mov	dx,SEQ_INDEX
	call	LAB_4c59
	mov	ax,300h
	out	dx,ax
	es mov	al,[si]
	inc	si
	mov	dx,MISC_OUTPUT
	out	dx,al
	call	GetCRTCIndex
	mov	[CRTC_BASE],dx
	mov	al,11h
	call	ReadIndirectRegister
	and	ah,7Fh
	out	dx,ax
	mov	cx,19h
	mov	al,0
	call	LAB_4c59
	add	dx,BYTE 6
	in	al,dx
	xor	ah,ah
	mov	cx,10h
	mov	dx,ATTR_CONTROL_INDEX
	test	[VIDEO_MODE_CONTROL],BYTE 8
	jnz	LAB_4c17
LAB_4c0d:
	mov	al,ah
	out	dx,al
	inc	ah
	es lodsb
	out	dx,al
	loop	LAB_4c0d

LAB_4c17:
	add	ah,cl
	add	si,cx
	mov	cx,5
LAB_4c1e:
	cmp	ah,11h
	jnz	LAB_4c2c
	inc	si
	test	[VIDEO_MODE_CONTROL],BYTE 8
	jnz	LAB_4c3b
	dec	si
LAB_4c2c:
	mov	al,ah
	out	dx,al
	jmp	SHORT LAB_4c31
LAB_4c31:
	xor	al,al
	cmp	ah,14h
	jz	LAB_4c3a
	es lodsb
LAB_4c3a:
	out	dx,al
LAB_4c3b:
	inc	ah
	loop	LAB_4c1e
	xor	al,al
	mov	dx,MISC_OUTPUT_READ
	out	dx,al
	inc	al
	mov	dx,FEATURE_CONTROL
	out	dx,al
	xor	al,al
	mov	cx,9
	mov	dx,INDEX_REG
	call	LAB_4c59
	pop	dx
	pop	cx
	ret

LAB_4c59:
	es mov	ah,[si]
	inc	si
	out	dx,ax
	inc	al
	loop	LAB_4c59
	ret

LAB_4c63:
	test	[VIDEO_MODE_CONTROL],BYTE 8
	jz	LAB_4c6b
	ret
LAB_4c6b:
	mov	dx,DAC_MASK_REG
	in	al,dx
	inc	al
	jz	LAB_4c76
	mov	al,0FFh
	out	dx,al
LAB_4c76:
	xor	bx,bx
	mov	cx,808h
	mov	si,LAB_4e77
	mov	al,[CURR_VIDEO_MODE]
	cmp	al,7
	jz	LAB_4ca2
	cmp	al,0Fh
	jz	LAB_4ca2
	cmp	al,13h
	jz	LAB_4d0b
	jc	LAB_4ca4
	mov	ah,al
	call	LAB_106c
	xchg	al,ah
	test	ah,2
	jz	LAB_4ca2
	test	ah,4
	jz	LAB_4cf3
	jmp	SHORT LAB_4d0b
LAB_4ca2:
	jmp	SHORT LAB_4d07
LAB_4ca4:
	cmp	al,4
	jc	LAB_4cb6
	cmp	al,6
	jbe	LAB_4cce
	cmp	al,8
	jz	LAB_4cf3
	cmp	al,0Eh
	jbe	LAB_4cce
	jmp	SHORT LAB_4cf3
LAB_4cb6:
	test	[VIDEO_MODE_CONTROL],BYTE 10h
	jnz	LAB_4cf3
	mov	ah,[VIDEO_SWITCHES]
	and	ah,0Fh
	cmp	ah,3
	jz	LAB_4cf3
	cmp	ah,9
	jz	LAB_4cf3
LAB_4cce:
	mov	cx,20h
	mov	si,LAB_4df7
	test	[VIDEO_MODE_CONTROL],BYTE 6
	jnz	LAB_4ce4
	push	si
	push	cx
	call	LAB_4dad
	pop	cx
	pop	si
	jmp	SHORT LAB_4d03
LAB_4ce4:
	mov	cx,2001h
	mov	si,LAB_4e17
	push	si
	push	cx
	call	LAB_4d95
	pop	cx
	pop	si
	jmp	SHORT LAB_4d07

LAB_4cf3:
	mov	cx,4001h
	mov	si,LAB_4e37
	test	[489h],BYTE 6
	jnz	LAB_4d07
	jmp	LAB_4de8

LAB_4d03:
	call	LAB_4dad
	ret

LAB_4d07:
	call	LAB_4d95
	ret

LAB_4d0b:
	mov	cx,8
	mov	si,LAB_4df7
	test	[VIDEO_MODE_CONTROL],BYTE 6
	jnz	LAB_4d25
	push	cx
	call	LAB_4dad
	pop	cx
	mov	si,LAB_4e07
	call	LAB_4dad
	jmp	SHORT LAB_4d36
LAB_4d25:
	mov	cx,801h
	mov	si,LAB_4e17
	push	cx
	call	LAB_4d95
	pop	cx
	mov	si,LAB_4e27
	call	LAB_4d95
LAB_4d36:
	mov	cx,1001h
	mov	si,LAB_4e7f
	call	LAB_4d95
	mov	cx,9
	mov	si,LAB_4e8f
LAB_4d45:
	cs mov	dl,[si]
	cs mov	bh,[si+1]
	call	LAB_4d55
	add	si,BYTE 2
	loop	LAB_4d45
	ret

LAB_4d55:
	push	si
	push	cx
	mov	si,LAB_4ea1
	mov	cx,18h
LAB_4d5d:
	push	cx
	cs mov	al,[si]
	mul	bh
	add	ax,7Fh
	add	ah,dl
	mov	dh,ah
	cs mov	al,[si+10h]
	mul	bh
	add	ax,7Fh
	add	ah,dl
	mov	ch,ah
	cs mov	al,[si+8]
	mul	bh
	add	ax,7Fh
	add	ah,dl
	mov	cl,ah
	mov	ah,dh
	push	dx
	call	LAB_40cf
	call	LAB_4b65
	pop	dx
	inc	si
	pop	cx
	loop	LAB_4d5d
	pop	cx
	pop	si
	ret

LAB_4d95:
	push	cx
LAB_4d96:
	push	cx
	cs mov	ch,[si]
	mov	cl,ch
	mov	ah,ch
	call	LAB_4b65
	pop	cx
	dec	cl
	jnz	LAB_4d96
	inc	si
	pop	cx
	dec	ch
	jnz	LAB_4d95
	ret

LAB_4dad:
	cs mov	al,[si]
	call	LAB_4db7
	inc	si
	loop	LAB_4dad
	ret

LAB_4db7:
	push	cx
	xor	ah,ah
	test	al,4
	jz	LAB_4dc0
	mov	ah,2Ah
LAB_4dc0:
	test	al,20h
	jz	LAB_4dc7
	add	ah,15h
LAB_4dc7:
	xor	cx,cx
	test	al,2
	jz	LAB_4dcf
	mov	ch,2Ah
LAB_4dcf:
	test	al,10h
	jz	LAB_4dd6
	add	ch,15h
LAB_4dd6:
	test	al,1
	jz	LAB_4ddc
	mov	cl,2Ah
LAB_4ddc:
	test	al,8
	jz	LAB_4de3
	add	cl,15h
LAB_4de3:
	call	LAB_4b65
	pop	cx
	ret

LAB_4de8:
	mov	cx,40h
	xor	al,al
LAB_4ded:
	push	ax
	call	LAB_4db7
	pop	ax
	inc	al
	loop	LAB_4ded
	ret

LAB_4df7:
	db	00h, 01h, 02h, 03h, 04h, 05h, 14h, 07h, 00h, 01h, 02h, 03h, 04h, 05h, 14h, 07h
LAB_4e07:
	db	38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh, 38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh
LAB_4e17:
	db	00h, 05h, 11h, 1Ch, 08h, 0Bh, 14h, 28h, 00h, 05h, 11h, 1Ch, 08h, 0Bh, 14h, 28h
LAB_4e27:
	db	0Eh, 18h, 2Dh, 32h, 20h, 24h, 38h, 3Fh, 0Eh, 18h, 2Dh, 32h, 20h, 24h, 38h, 3Fh
LAB_4e37:
	db	00h, 05h, 11h, 1Ch, 08h, 0Bh, 25h, 28h, 02h, 07h, 1Bh, 20h, 0Fh, 14h, 28h, 2Ch
	db	0Ch, 11h, 25h, 2Ah, 14h, 1Eh, 32h, 36h, 0Fh, 13h, 27h, 2Ch, 1Bh, 20h, 34h, 39h
	db	06h, 0Bh, 1Fh, 24h, 13h, 18h, 2Ch, 30h, 09h, 0Dh, 21h, 26h, 15h, 1Ah, 2Eh, 33h
	db	13h, 17h, 2Bh, 30h, 1Fh, 24h, 38h, 3Dh, 0Eh, 18h, 2Dh, 32h, 20h, 24h, 38h, 3Fh
LAB_4e77:
	db	00h, 2Ah, 00h, 3Fh, 00h, 2Ah, 00h, 3Fh
LAB_4e7f:
	db	00h, 05h, 08h, 0Bh, 0Eh, 11h, 14h, 18h
	db	1Ch, 20h, 24h, 28h, 2Dh, 32h, 38h, 3Fh
LAB_4e8f:
	db	00h, 0FCh, 1Fh, 80h, 2Dh, 48h, 00h, 70h
	db	0Eh, 38h, 14h, 20h, 00h, 40h, 08h, 20h, 0Bh, 13h
LAB_4ea1:
	db	00h, 10h, 20h, 30h, 40h, 40h
	db	40h, 40h, 40h, 40h, 40h, 40h, 40h, 30h, 20h, 10h, 00h, 00h, 00h, 00h, 00h, 00h
	db	00h, 00h, 00h, 10h, 20h, 30h, 40h, 40h, 40h, 40h, 40h, 40h, 40h, 40h, 40h, 30h
	db	20h, 10h

LAB_4ec9:
	mov	al,[CURR_VIDEO_MODE]
LAB_4ecc:
	push	di
	push	cx
	push	bx
	mov	ch,al
	xor	bh,bh
	call	LAB_0d7f
	mov	si,di
	pop	bx
	pop	cx
	pop	di
	ret

LAB_4edc:
	xor	cl,cl
	cs cmp	[LAB_103d],BYTE 0
	jz	LAB_4ef2
	mov	si,LAB_0039
	call	LAB_4f15
	mov	si,LAB_1045
	call	LAB_4f15
LAB_4ef2:
	cs cmp	[LAB_103e],BYTE 0
	jz	LAB_4f00
	mov	si,LAB_00e2
	call	LAB_4f15
LAB_4f00:
	cs test	[LAB_0038],BYTE 4
	jz	LAB_4f0b
	call	LAB_4f0c
LAB_4f0b:
	ret

LAB_4f0c:
	mov	si,LAB_52e4
	mov	cl,1
	call	LAB_4f15
	ret

LAB_4f15:
	xor	bh,bh
LAB_4f17:
	mov	ah,0Eh
	cs lodsb
	shr	al,cl
	test	al,al
	jz	LAB_4f25
	int	10h
	jmp	SHORT LAB_4f17
LAB_4f25:
	ret

;-------------------------------------------------------------------------------
; GetVideoSavePointerTable
;-------------------------------------------------------------------------------
; Obtains a pointer to the Video Save Pointer Table
;
; Input:
;  Nothing
;
; Output:
;  CS:DI = Pointer to table
;  CX destroyed
;-------------------------------------------------------------------------------
GetVideoSavePointerTable:
	push	ds					; Save segment register
	mov	di,cs					; Setup addressing
	mov	ds,si

	cmp	di,0C000h				; First video BIOS?
	mov	cx,LAB_4f73				; First table
	jz	LAB_4f57				; Yes, we're done

	cmp	di,0E000h				; Second video BIOS?
	mov	cx,LAB_4fa7				; Second table
	jz	LAB_4f57				; Yes, we're done

	; Testing code for running from RAM?
	; Fix-up segments with our current one

	mov	cx,cs
	mov	di,LAB_4f73				; Start from first table
	mov	[di-6],cx
	mov	[di-0Ah],cx
	mov	[di+2],cx
	mov	[di+12h],cx
	mov	di,LAB_4fc3
	mov	[di+4],cx
	mov	cx,LAB_4f73				; This is our one

LAB_4f57:
	mov	di,cx					; Put to expected register
	pop	ds					; Restore segment register
	ret						; Return to caller

LAB_4f5b:
	db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 21h, 00h, 42h, 14h
	dw	0C00h
	db	07h, 19h
	dw	0C00h
	db	25h, 00h, 56h, 52h

	; Video Save Pointer Table
LAB_4f73:
istruc VideoSavePointerTbl
	AT VideoSavePointerTbl.wVideoParameterTableOff,		dw	LAB_502b
	AT VideoSavePointerTbl.wVideoParameterTableSeg,		dw	0C000h
	AT VideoSavePointerTbl.wVideoDynamicSaveAreaOff,	dw	0
	AT VideoSavePointerTbl.wVideoDynamicSaveAreaSeg,	dw	0
	AT VideoSavePointerTbl.wAlphaCharsetOverrideOff,	dw	0
	AT VideoSavePointerTbl.wAlphaCharsetOverrideSeg,	dw	0
	AT VideoSavePointerTbl.wGraphicsCharsetOverrideOff,	dw	0
	AT VideoSavePointerTbl.wGraphicsCharsetOverrideSeg,	dw	0
	AT VideoSavePointerTbl.wSecSavePointerTableOff,		dw	LAB_4fc3
	AT VideoSavePointerTbl.wSecSavePointerTableSeg,		dw	0C000h
	AT VideoSavePointerTbl.dwReserved1,			dd	0
	AT VideoSavePointerTbl.dwReserved2,			dd	0
iend

	db	00h, 00h, 00h, 00h
	db	00h, 00h, 00h, 00h, 00h, 00h, 21h, 00h, 42h, 14h, 00h, 0E0h, 07h, 19h, 00h, 0E0h
	db	25h, 00h, 56h, 52h

	; Video Save Pointer Table
LAB_4fa7:
istruc VideoSavePointerTbl
	AT VideoSavePointerTbl.wVideoParameterTableOff,		dw	LAB_502b
	AT VideoSavePointerTbl.wVideoParameterTableSeg,		dw	0E000h
	AT VideoSavePointerTbl.wVideoDynamicSaveAreaOff,	dw	0
	AT VideoSavePointerTbl.wVideoDynamicSaveAreaSeg,	dw	0
	AT VideoSavePointerTbl.wAlphaCharsetOverrideOff,	dw	0
	AT VideoSavePointerTbl.wAlphaCharsetOverrideSeg,	dw	0
	AT VideoSavePointerTbl.wGraphicsCharsetOverrideOff,	dw	0
	AT VideoSavePointerTbl.wGraphicsCharsetOverrideSeg,	dw	0
	AT VideoSavePointerTbl.wSecSavePointerTableOff,		dw	LAB_4fdd
	AT VideoSavePointerTbl.wSecSavePointerTableSeg,		dw	0E000h
	AT VideoSavePointerTbl.dwReserved1,			dd	0
	AT VideoSavePointerTbl.dwReserved2,			dd	0
iend

	; Secondary Video Save Pointer Table
LAB_4fc3:
istruc SecSavePointerTbl
	AT SecSavePointerTbl.wSize,				db	SecSavePointerTbl_size
	AT SecSavePointerTbl.wDspCombinationCodeTblOff,		dw	LAB_4ff7
	AT SecSavePointerTbl.wDspCombinationCodeTblSeg,		dw	0C000h
	AT SecSavePointerTbl.wSecAlphaCharsetOverrideOff,	dw	0
	AT SecSavePointerTbl.wSecAlphaCharsetOverrideSeg,	dw	0
	AT SecSavePointerTbl.wUsrPaletteProfileTblOff,		dw	0
	AT SecSavePointerTbl.wUsrPaletteProfileTblSeg,		dw	0
	AT SecSavePointerTbl.dwReserved1,			dd	0
	AT SecSavePointerTbl.dwReserved2,			dd	0
	AT SecSavePointerTbl.dwReserved3,			dd	0
iend

	; Secondary Video Save Pointer Table
LAB_4fdd:
istruc SecSavePointerTbl
	AT SecSavePointerTbl.wSize,				db	SecSavePointerTbl_size
	AT SecSavePointerTbl.wDspCombinationCodeTblOff,		dw	LAB_4ff7
	AT SecSavePointerTbl.wDspCombinationCodeTblSeg,		dw	0E000h
	AT SecSavePointerTbl.wSecAlphaCharsetOverrideOff,	dw	0
	AT SecSavePointerTbl.wSecAlphaCharsetOverrideSeg,	dw	0
	AT SecSavePointerTbl.wUsrPaletteProfileTblOff,		dw	0
	AT SecSavePointerTbl.wUsrPaletteProfileTblSeg,		dw	0
	AT SecSavePointerTbl.dwReserved1,			dd	0
	AT SecSavePointerTbl.dwReserved2,			dd	0
	AT SecSavePointerTbl.dwReserved3,			dd	0
iend

	; Display Combination Code Table
LAB_4ff7:
istruc DspCombinationCodeTbl
	AT DspCombinationCodeTbl.bNumEntries,			db	10h
	AT DspCombinationCodeTbl.bVersion,			db	1
	AT DspCombinationCodeTbl.bMaxCodeNumber,		db	VGA_COLOR
	AT DspCombinationCodeTbl.bReserved,			db	0
iend
DSP_COMBINATION		NO_DISPLAY,	NO_DISPLAY
DSP_COMBINATION		NO_DISPLAY,	MDA_MONO
DSP_COMBINATION		NO_DISPLAY,	CGA_COLOR
DSP_COMBINATION		CGA_COLOR,	MDA_MONO
DSP_COMBINATION		NO_DISPLAY,	EGA_COLOR
DSP_COMBINATION		EGA_COLOR,	MDA_MONO
DSP_COMBINATION		NO_DISPLAY,	EGA_MONO
DSP_COMBINATION		CGA_COLOR,	EGA_MONO
DSP_COMBINATION		NO_DISPLAY,	PGA
DSP_COMBINATION		MDA_MONO,	PGA
DSP_COMBINATION		EGA_MONO,	PGA
DSP_COMBINATION		NO_DISPLAY,	VGA_COLOR
DSP_COMBINATION		MDA_MONO,	VGA_COLOR
DSP_COMBINATION		NO_DISPLAY,	VGA_MONO
DSP_COMBINATION		CGA_COLOR,	VGA_MONO
DSP_COMBINATION		PGA,		VGA_MONO

LAB_501b:
	db	0FFh, 0E0h, 0Fh, 00h, 00h, 00h, 00h, 07h, 02h, 08h, 0FFh, 0Eh, 00h, 00h, 3Fh, 00h
LAB_502b:
	; Mode 00h
istruc VideoParameterTbl
	AT VideoParameterTbl.bNumColumns,	db	40
	AT VideoParameterTbl.bNumRowsMinusOne,	db	24
	AT VideoParameterTbl.bCharHeight,	db	8
	AT VideoParameterTbl.wBufferSize,	dw	800h
	AT VideoParameterTbl.baSeqRegs,		db	09h, 03h, 00h, 02h
	AT VideoParameterTbl.bMiscOutputReg,	db	63h
	AT VideoParameterTbl.baCRTCRegs,	db	2Dh, 27h, 28h, 90h, 2Bh
						db	0A0h, 0BFh, 1Fh, 00h, 0C7h
						db	06h, 07h, 00h, 00h, 00h
						db	00h, 9Ch, 8Eh, 8Fh, 14h
						db	1Fh, 96h, 0B9h, 0A3h, 0FFh
	AT VideoParameterTbl.baAttrContRegs,	db	00h, 01h, 02h, 03h, 04h
						db	05h, 06h, 07h, 10h, 11h
						db	12h, 13h, 14h, 15h, 16h
						db	17h, 08h, 00h, 0Fh, 00h
	AT VideoParameterTbl.baGraphContRegs,	db	00h, 00h, 00h, 00h, 00h
						db	10h, 0Eh, 00h, 0FFh
iend

	; Mode 01h
istruc VideoParameterTbl
	AT VideoParameterTbl.bNumColumns,	db	40
	AT VideoParameterTbl.bNumRowsMinusOne,	db	24
	AT VideoParameterTbl.bCharHeight,	db	8
	AT VideoParameterTbl.wBufferSize,	dw	800h
	AT VideoParameterTbl.baSeqRegs,		db	09h, 03h, 00h, 02h
	AT VideoParameterTbl.bMiscOutputReg,	db	63h
	AT VideoParameterTbl.baCRTCRegs,	db	2Dh, 27h, 28h, 90h, 2Bh
						db	0A0h, 0BFh, 1Fh, 00h, 0C7h
						db	06h, 07h, 00h, 00h, 00h
						db	00h, 9Ch, 8Eh, 8Fh, 14h
						db	1Fh, 96h, 0B9h, 0A3h, 0FFh
	AT VideoParameterTbl.baAttrContRegs,	db	00h, 01h, 02h, 03h, 04h
						db	05h, 06h, 07h, 10h, 11h
						db	12h, 13h, 14h, 15h, 16h
						db	17h, 08h, 00h, 0Fh, 00h
	AT VideoParameterTbl.baGraphContRegs,	db	00h, 00h, 00h, 00h, 00h
						db	10h, 0Eh, 00h, 0FFh
iend

	; Mode 02h
istruc VideoParameterTbl
	AT VideoParameterTbl.bNumColumns,	db	80
	AT VideoParameterTbl.bNumRowsMinusOne,	db	24
	AT VideoParameterTbl.bCharHeight,	db	8
	AT VideoParameterTbl.wBufferSize,	dw	1000h
	AT VideoParameterTbl.baSeqRegs,		db	01h, 03h, 00h, 02h
	AT VideoParameterTbl.bMiscOutputReg,	db	63h
	AT VideoParameterTbl.baCRTCRegs,	db	5Fh, 4Fh, 50h, 82h, 55h
						db	81h, 0BFh, 1Fh, 00h, 0C7h
						db	06h, 07h, 00h, 00h, 00h
						db	00h, 9Ch, 8Eh, 8Fh, 28h
						db	1Fh, 96h, 0B9h, 0A3h, 0FFh
	AT VideoParameterTbl.baAttrContRegs,	db	00h, 01h, 02h, 03h, 04h
						db	05h, 06h, 07h, 10h, 11h
						db	12h, 13h, 14h, 15h, 16h
						db	17h, 08h, 00h, 0Fh, 00h
	AT VideoParameterTbl.baGraphContRegs,	db	00h, 00h, 00h, 00h, 00h
						db	10h, 0Eh, 00h, 0FFh
iend

	; Mode 03h
istruc VideoParameterTbl
	AT VideoParameterTbl.bNumColumns,	db	80
	AT VideoParameterTbl.bNumRowsMinusOne,	db	24
	AT VideoParameterTbl.bCharHeight,	db	8
	AT VideoParameterTbl.wBufferSize,	dw	1000h
	AT VideoParameterTbl.baSeqRegs,		db	01h, 03h, 00h, 02h
	AT VideoParameterTbl.bMiscOutputReg,	db	63h
	AT VideoParameterTbl.baCRTCRegs,	db	5Fh, 4Fh, 50h, 82h, 55h
						db	81h, 0BFh, 1Fh, 00h, 0C7h
						db	06h, 07h, 00h, 00h, 00h
						db	00h, 9Ch, 8Eh, 8Fh, 28h
						db	1Fh, 96h, 0B9h, 0A3h, 0FFh
	AT VideoParameterTbl.baAttrContRegs,	db	00h, 01h, 02h, 03h, 04h
						db	05h, 06h, 07h, 10h, 11h
						db	12h, 13h, 14h, 15h, 16h
						db	17h, 08h, 00h, 0Fh, 00h
	AT VideoParameterTbl.baGraphContRegs,	db	00h, 00h, 00h, 00h, 00h
						db	10h, 0Eh, 00h, 0FFh
iend

	; Mode 04h
istruc VideoParameterTbl
	AT VideoParameterTbl.bNumColumns,	db	40
	AT VideoParameterTbl.bNumRowsMinusOne,	db	24
	AT VideoParameterTbl.bCharHeight,	db	8
	AT VideoParameterTbl.wBufferSize,	dw	4000h
	AT VideoParameterTbl.baSeqRegs,		db	09h, 03h, 00h, 02h
	AT VideoParameterTbl.bMiscOutputReg,	db	63h
	AT VideoParameterTbl.baCRTCRegs,	db	2Dh, 27h, 28h, 90h, 2Bh
						db	80h, 0BFh, 1Fh, 00h, 0C1h
						db	00h, 00h, 00h, 00h, 00h
						db	00h, 9Ch, 8Eh, 8Fh, 14h
						db	00h, 96h, 0B9h, 0A2h, 0FFh
	AT VideoParameterTbl.baAttrContRegs,	db	00h, 13h, 15h, 17h, 02h
						db	04h, 06h, 07h, 10h, 11h
						db	12h, 13h, 14h, 15h, 16h
						db	17h, 01h, 00h, 03h, 00h
	AT VideoParameterTbl.baGraphContRegs,	db	00h, 00h, 00h, 00h, 00h
						db	30h, 0Fh, 00h, 0FFh
iend

	; Mode 05h
istruc VideoParameterTbl
	AT VideoParameterTbl.bNumColumns,	db	40
	AT VideoParameterTbl.bNumRowsMinusOne,	db	24
	AT VideoParameterTbl.bCharHeight,	db	8
	AT VideoParameterTbl.wBufferSize,	dw	4000h
	AT VideoParameterTbl.baSeqRegs,		db	09h, 03h, 00h, 02h
	AT VideoParameterTbl.bMiscOutputReg,	db	63h
	AT VideoParameterTbl.baCRTCRegs,	db	2Dh, 27h, 28h, 90h, 2Bh
						db	80h, 0BFh, 1Fh, 00h, 0C1h
						db	00h, 00h, 00h, 00h, 00h
						db	00h, 9Ch, 8Eh, 8Fh, 14h
						db	00h, 96h, 0B9h, 0A2h, 0FFh
	AT VideoParameterTbl.baAttrContRegs,	db	00h, 13h, 15h, 17h, 02h
						db	04h, 06h, 07h, 10h, 11h
						db	12h, 13h, 14h, 15h, 16h
						db	17h, 01h, 00h, 03h, 00h
	AT VideoParameterTbl.baGraphContRegs,	db	00h, 00h, 00h, 00h, 00h
						db	30h, 0Fh, 00h, 0FFh
iend

	; Mode 06h
istruc VideoParameterTbl
	AT VideoParameterTbl.bNumColumns,	db	80
	AT VideoParameterTbl.bNumRowsMinusOne,	db	24
	AT VideoParameterTbl.bCharHeight,	db	8
	AT VideoParameterTbl.wBufferSize,	dw	4000h
	AT VideoParameterTbl.baSeqRegs,		db	01h, 01h, 00h, 06h
	AT VideoParameterTbl.bMiscOutputReg,	db	63h
	AT VideoParameterTbl.baCRTCRegs,	db	5Fh, 4Fh, 50h, 82h, 54h
						db	80h, 0BFh, 1Fh, 00h, 0C1h
						db	00h, 00h, 00h, 00h, 00h
						db	00h, 9Ch, 8Eh, 8Fh, 28h
						db	00h, 96h, 0B9h, 0C2h, 0FFh
	AT VideoParameterTbl.baAttrContRegs,	db	00h, 17h, 17h, 17h, 17h
						db	17h, 17h, 17h, 17h, 17h
						db	17h, 17h, 17h, 17h, 17h
						db	17h, 01h, 00h, 01h, 00h
	AT VideoParameterTbl.baGraphContRegs,	db	00h, 00h, 00h, 00h, 00h
						db	00h, 0Dh, 00h, 0FFh
iend

	; Mode 07h
istruc VideoParameterTbl
	AT VideoParameterTbl.bNumColumns,	db	80
	AT VideoParameterTbl.bNumRowsMinusOne,	db	24
	AT VideoParameterTbl.bCharHeight,	db	14
	AT VideoParameterTbl.wBufferSize,	dw	1000h
	AT VideoParameterTbl.baSeqRegs,		db	00h, 03h, 00h, 03h
	AT VideoParameterTbl.bMiscOutputReg,	db	0A6h
	AT VideoParameterTbl.baCRTCRegs,	db	5Fh, 4Fh, 50h, 82h, 55h
						db	81h, 0BFh, 1Fh, 00h, 4Dh
						db	0Bh, 0Ch, 00h, 00h, 00h
						db	00h, 83h, 85h, 5Dh, 28h
						db	0Dh, 63h, 0BAh, 0A3h, 0FFh
	AT VideoParameterTbl.baAttrContRegs,	db	00h, 08h, 08h, 08h, 08h
						db	08h, 08h, 08h, 10h, 18h
						db	18h, 18h, 18h, 18h, 18h
						db	18h, 0Eh, 00h, 0Fh, 08h
	AT VideoParameterTbl.baGraphContRegs,	db	00h, 00h, 00h, 00h, 00h
						db	10h, 0Ah, 00h, 0FFh
iend

LAB_522b:
	dw	LAB_524a
	dw	LAB_525d
	dw	LAB_52ba

LAB_5231:
	cmp	bl,2
	jbe	LAB_5239
	jmp	LAB_1fde
LAB_5239:
	mov	al,bl
	cbw
	mov	si,ax
	SHL	si,1
	add	si,522Bh
	cs call	[si]
	jmp	LAB_1fe0

LAB_524a:
	mov	ax,4Fh
	mov	[bp+0Eh],WORD 710h
	mov	[bp+2],WORD 0
	mov	[bp+6],WORD 0
	ret

LAB_525d:
	test	bh,0F8h
	jnz	LAB_526c
	cmp	bh,5
	jnc	LAB_526c
	cmp	bh,3
	jnz	LAB_5271
LAB_526c:
	mov	ax,14Fh
	jmp	SHORT LAB_52a4
LAB_5271:
	mov	dx,SEQ_INDEX
	in	al,dx
	push	ax
	mov	dl,0D4h
	in	al,dx
	push	ax
	or	bh,bh
	jz	LAB_528d
	cmp	bh,1
	jz	LAB_5292
	cmp	bh,2
	jz	LAB_5297
	call	LAB_52b6
	jmp	SHORT LAB_529a

LAB_528d:
	call	LAB_52a5
	jmp	SHORT LAB_529a
LAB_5292:
	call	LAB_52ae
	jmp	SHORT LAB_529a
LAB_5297:
	call	LAB_52b2
LAB_529a:
	pop	ax
	mov	dl,0D4h
	out	dx,al
	pop	ax
	mov	dl,0C4h
	out	dx,al
	mov	ax,bx
LAB_52a4:
	ret

LAB_52a5:
	xor	bl,bl
LAB_52a7:
	call	LAB_52dd
	mov	bx,04Fh
	ret

LAB_52ae:
	mov	bl,2
	jmp	SHORT LAB_52a7

LAB_52b2:
	mov	bl,4
	jmp	SHORT LAB_52a7

LAB_52b6:
	mov	bl,6
	jmp	SHORT LAB_52a7

LAB_52ba:
	call	LAB_52d2
	in	al,dx
	SHR	al,1
	and	al,3
	mov	bh,al
	cmp	bh,3
	jnz	LAB_52cb
	inc	bh
LAB_52cb:
	mov	ax,4Fh
	mov	[bp+0Eh],bx
	ret

LAB_52d2:
	mov	al,0Eh
	mov	dx,INDEX_REG
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0F9h
	ret

LAB_52dd:
	call	LAB_52d2
	or	al,bl
	out	dx,al
	ret

	%include "endblob.inc"
