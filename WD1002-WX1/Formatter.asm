LAB_c800_0b71:
	PUSH	SS
	POP	ES
	MOV	BP,0
	MOV	[BP+116H],SP
	MOV	DI,0330H
	ADD	DI,BP
	MOV	[BP+129H],DI
	DEC	DI
	MOV	[BP+12BH],DI
	MOV	DI,SP
	SUB	DI,12CH
	CMP	DI,[BP+129H]
	JA	LAB_c800_0b98
	MOV	DI,[BP+12BH]
LAB_c800_0b98:
	MOV	[BP+12DH],DI
	MOV	DI,100H
	ADD	DI,BP
	XOR	AL,AL
	MOV	CX,23H
	REP 	STOSB
	CALL	FUN_c800_0fe1
	PUSH	SS
	POP	DS
	CALL	FUN_c800_1061
	MOV	BYTE [BP+110H],53H
	MOV	AX,[BP+114H]
	MOV	DL,AH
	OR	DL,80H
	MOV	AX,1
	INT	13H
	XOR	AX,AX
	MOV	DS,AX
	PUSH	CS
	POP	AX
	MOV	BX,0476H
	CMP	AH,0C8H
	JZ	LAB_c800_0bd4
	MOV	BX,0122H
LAB_c800_0bd4:
	AND	WORD [BX],7F7FH
	PUSH	ES
	PUSH	SS
	POP	ES
	MOV	BX,100H
	MOV	AX,1601H
	INT	13H
	POP	ES
	CALL	FUN_c800_0c11
	MOV	DX,LAB_c800_1dd5
	JC	LAB_c800_0bef
	MOV	DX,LAB_c800_1d4b
LAB_c800_0bef:
	PUSH	CS
	POP	DS
	MOV	AH,9
	INT	21H
LAB_c800_0bf5:
	MOV	AH,6
	MOV	DL,0FFH
	INT	21H
	JNZ	LAB_c800_0bf5
	MOV	DX,LAB_c800_1d5f
	MOV	AH,9
	INT	21H
LAB_c800_0c04:
	MOV	AH,6
	MOV	DL,0FFH
	INT	21H
	JZ	LAB_c800_0c04
	JMP	0FFFFH:00000H
	
FUN_c800_0c11:
	CALL	FUN_c800_0f3e
	JC	LAB_c800_0c64
	CALL	FUN_c800_0c65
	MOV	AX,[BP+129H]
	CMP	AX,[BP+12BH]
	JA	LAB_c800_0c26
	CALL	FUN_c800_0eb1
LAB_c800_0c26:
	TEST	BYTE [BP+0123H],30H
	JZ	LAB_c800_0c64
	MOV	AX,0
	MOV	CX,100H
	MOV	DI,130H
	ADD	DI,BP
	CLD
	REP	STOSW
	MOV	DI,02DDH
	MOV	SI,100H
	MOV	CX,11H
	REP	ES MOVSB
	MOV	CX,1
	MOV	DL,[BP+115H]
	ADD	DL,80H
	MOV	DH,0
	MOV	AX,301H
	MOV	BX,130H
	ADD	BX,BP
	MOV	WORD ES:[BX+01FEH],0AABBH
	INT	13H
LAB_c800_0c64:
	RET

FUN_c800_0c65:
	AND	BYTE [BP+012FH],0EFH
	XOR	AX,AX
	MOV	DS,AX
	MOV	AX,[BP+109H]
	AND	AX,AX
	JZ	LAB_c800_0c77
	DEC	AX
LAB_c800_0c77:
	MOV	[BP+111H],AX
	MOV	AL,[BP+102H]
	AND	AL,AL
	JZ	LAB_c800_0c85
	DEC	AL

LAB_c800_0c85:
	MOV	[BP+113H],AL
	MOV	DX,LAB_c800_1aff
	CALL	FUN_c800_1166
	JNZ	LAB_c800_0ca2

LAB_c800_0c91:
	MOV	BYTE SS:[019EH],80H
	CALL	FUN_c800_0cad
	MOV	DX,LAB_c800_1d2b
	CALL	FUN_c800_1166
	JZ	LAB_c800_0c91
LAB_c800_0ca2:
	TEST	BYTE [BP+12FH],10H
	JZ	LAB_c800_0cac
	CALL	FUN_c800_0d72
LAB_c800_0cac:
	RET


FUN_c800_0cad:
	MOV	DX,LAB_c800_1b30
	CALL	FUN_c800_1170
	MOV	SS:[11CH],SP
	CALL	FUN_c800_1324
LAB_c800_0cbb:
	CMP	DH,8
	JZ	LAB_c800_0cca
	CALL	FUN_c800_0ccb
	JC	LAB_c800_0cca
	CALL	FUN_c800_1416
	JMP	SHORT LAB_c800_0cbb
LAB_c800_0cca:
	RET

FUN_c800_0ccb:
	CALL	FUN_c800_12af
	MOV	SS:[19FH],BX
	CALL	FUN_c800_1416
	CALL	FUN_c800_12c9
	MOV	SS:[1A2H],BL
	MOV	BYTE SS:[1A1H],1
	PUSH	CX
	PUSH	SI
	CALL	FUN_c800_1334
	JC	LAB_c800_0cf4
	CALL	FUN_c800_0cf7
	OR	BYTE [BP+12FH],10H
	CLC
LAB_c800_0cf4:
	POP	SI
	POP	CX
	RET

FUN_c800_0cf7:
	CALL	FUN_c800_0d1d
	JNZ	LAB_c800_0d0a
LAB_c800_0cfc:
	MOV	AL,SS:[19EH]
	CMP	AL,SS:[DI]
	JZ	LAB_c800_0d1c
	CALL	FUN_c800_0d23
	JZ	LAB_c800_0cfc
LAB_c800_0d0a:
	CALL	FUN_c800_0d41
	MOV	CX,5
	MOV	SI,19EH
	CLD
	PUSH	ES
	POP	DS
	PUSH	ES
	PUSH	SS
	POP	ES
	REP	MOVSB
	POP	ES
LAB_c800_0d1c:
	RET

FUN_c800_0d1d:
	MOV	DI,[BP+129H]
	JMP	SHORT LAB_c800_0d26

FUN_c800_0d23:
	ADD	DI,BYTE 5
LAB_c800_0d26:
	CMP	DI,[BP+12BH]
	JA	LAB_c800_0d40
	MOV	AX,SS:[19FH]
	CMP	AX,SS:[DI+1]
	JNZ	LAB_c800_0d3e
	MOV	AX,SS:[1A1H]
	CMP	AX,SS:[DI+3]
LAB_c800_0d3e:
	JG	FUN_c800_0d23
LAB_c800_0d40:
	RET

FUN_c800_0d41:
	MOV	AX,DI
	MOV	SI,[BP+12BH]
	MOV	DI,SI
	ADD	DI,BYTE 5
	JC	LAB_c800_0d68
	CMP	DI,[BP+12DH]
	JA	LAB_c800_0d68
	MOV	[BP+12BH],DI
	MOV	CX,SI
	INC	CX
	SUB	CX,AX
	PUSH	ES
	PUSH	SS
	POP	ES
	STD
	REP	SS MOVSB
	POP	ES
	MOV	DI,AX
	RET

LAB_c800_0d68:
	MOV	DX,LAB_c800_1c72
	MOV	SP,[BP+116H]
	JMP	LAB_c800_0bef

FUN_c800_0d72:
	MOV	DX,LAB_c800_1c37
	MOV	SI,[BP+129H]
	CMP	SI,[BP+12BH]
	JA	LAB_c800_0d83
	CALL	FUN_c800_0d86
	RET
LAB_c800_0d83:
	JMP	FUN_c800_0eaa

FUN_c800_0d86:
	MOV	AL,80H
	CALL	FUN_c800_0e23
	JNC	LAB_c800_0dae
LAB_c800_0d8d:
	MOV	DX,LAB_c800_1bba
	CALL	FUN_c800_0eaa
	MOV	BYTE SS:[128H],18H
LAB_c800_0d99:
	CALL	FUN_c800_0dba
	CALL	FUN_c800_0e18
	JNC	LAB_c800_0dae
	SUB	BYTE SS:[128H],1
	JNZ	LAB_c800_0d99
	CALL	FUN_c800_0daf
	JMP	SHORT LAB_c800_0d8d
LAB_c800_0dae:
	RET

FUN_c800_0daf:
	MOV	DX,LAB_c800_1d00
	CALL	FUN_c800_0eaa
	MOV	AH,1
	INT	21H
	RET

FUN_c800_0dba:
	CALL	FUN_c800_0e09
LAB_c800_0dbd:
	CALL	FUN_c800_0e34
	CALL	FUN_c800_0e4a
	CMP	DI,156H
	JA	LAB_c800_0df8
	CALL	FUN_c800_0e18
	JNC	LAB_c800_0df8
	MOV	DI,156H
	JMP	SHORT LAB_c800_0dbd

LAB_c800_0dd3:
	CALL	FUN_c800_0e09

LAB_c800_0dd6:
	CALL	FUN_c800_0e34
	MOV	AL,SS:[SI+3]
	AND	AL,3FH
	XOR	AH,AH
	INC	DI
	CALL	FUN_c800_0e74
	CALL	FUN_c800_0e4a
	CMP	DI,156H
	JA	LAB_c800_0df8
	CALL	FUN_c800_0e1c
	JNC	LAB_c800_0df8
	MOV	DI,156H
	JMP	SHORT LAB_c800_0dd6

LAB_c800_0df8:
	MOV	DX,130H
	PUSH	ES
	POP	DS
	MOV	BYTE [DI],24H
	CALL	FUN_c800_0eac
	MOV	DX,LAB_c800_1970
	CALL	FUN_c800_0eaa

FUN_c800_0e09:
	MOV	AL,20H
	MOV	CX,50H
	MOV	DI,130H
	CLD
	REP	STOSB
	MOV	DI,130H
	RET

FUN_c800_0e18:
	MOV	AL,80H
	JMP	SHORT LAB_c800_0e1e
FUN_c800_0e1c:
	MOV	AL,40H				; Unused?

LAB_c800_0e1e:
	ADD	SI,BYTE 5
	JC	LAB_c800_0e31

FUN_c800_0e23:
	CMP	SI,[BP+12BH]
	JA	LAB_c800_0e31
	TEST	SS:[SI],AL
	JZ	LAB_c800_0e1e
	JMP	LAB_c800_115a

LAB_c800_0e31:
	JMP	LAB_c800_114b

FUN_c800_0e34:
	MOV	AX,SS:[SI+1]
	ADD	DI,BYTE 0
	CALL	FUN_c800_0e74
	MOV	AL,SS:[SI+4]
	AND	AL,1FH
	XOR	AH,AH
	INC	DI
	JMP	SHORT FUN_c800_0e74
	NOP

FUN_c800_0e4a:
	PUSH	ES
	PUSH	SI
	MOV	BL,SS:[SI]
	AND	BL,0FH
	XOR	BH,BH
	SHL	BX,1
	MOV	SI,CS:[BX+LAB_c800_18ae]
	MOV	CL,CS:[SI]
	XOR	CH,CH
	INC	SI
	CMP	DI,156H
	MOV	DI,161H
	JA	LAB_c800_0e6d
	MOV	DI,13BH

LAB_c800_0e6d:
	CLD
	REP	CS MOVSB
	POP	SI
	POP	ES
	RET

FUN_c800_0e74:
	MOV	BX,0EA4H
LAB_c800_0e77:
	CMP	AX,CS:[BX]
	JGE	LAB_c800_0e87
	ADD	BX,BYTE 2
	CMP	BX,0EAAH
	JC	LAB_c800_0e77
	JMP	SHORT LAB_c800_0e9a

LAB_c800_0e87:
	XOR	DX,DX
	DIV	WORD CS:[BX]
	CALL	FUN_c800_0e9d
	MOV	AX,DX
	ADD	BX,BYTE 2
	CMP	BX,0EAAH
	JC	LAB_c800_0e87

LAB_c800_0e9a:
	JMP	SHORT FUN_c800_0e9d
	NOP

FUN_c800_0e9d:
	OR	AL,30H
	MOV	ES:[DI],AL
	INC	DI
	RET

	DW	03E8H
	DW	0064H
	DW	000AH

FUN_c800_0eaa:
	PUSH	CS
	POP	DS

FUN_c800_0eac:
	MOV	AH,9
	INT	21H
	RET

FUN_c800_0eb1:
	MOV	SI,[BP+129H]
LAB_c800_0eb5:
	CMP	SI,[BP+12BH]
	JA	LAB_c800_0efd
	TEST	BYTE SS:[SI],0C0H
	JZ	LAB_c800_0ef8
	MOV	AL,[BP+122H]
	NOT	AL
	AND	AL,30H
	CMP	AL,30H
	JZ	LAB_c800_0efe
	XOR	AL,10H
	JZ	LAB_c800_0efe
	MOV	AL,SS:[SI+2]
	MOV	CL,6
	SHL	AL,CL
	MOV	CL,AL
	MOV	CH,SS:[SI+1]
	MOV	DH,SS:[SI+4]
	ADD	CL,SS:[SI+3]
LAB_c800_0ee7:
	MOV	DL,[BP+115H]
	OR	DL,80H
	MOV	AX,0601H
	INT	13H
	JNC	LAB_c800_0ef8
	JMP	LAB_c800_0fcb

LAB_c800_0ef8:
	ADD	SI,BYTE 5
	JMP	SHORT LAB_c800_0eb5

LAB_c800_0efd:
	RET

LAB_c800_0efe:
	MOV	CL,[BP+102H]
	XOR	CH,CH
	PUSH	CX
	MOV	AX,SS:[SI+1]
	MUL	CX
	MOV	DL,SS:[SI+4]
	XOR	DH,DH
	ADD	AX,DX
	MOV	CX,1AH
	MUL	CX
	MOV	CL,SS:[SI+3]
	ADD	AX,CX
	MOV	CX,11H
	DIV	CX
	POP	CX
	PUSH	DX
	XOR	DX,DX
	DIV	CX
	MOV	CH,AL
	MOV	CL,6
	SHL	AH,CL
	MOV	CL,AH
	MOV	DH,DL
	POP	AX
	AND	AL,AL
	JNZ	LAB_c800_0f3a
	INC	AL

LAB_c800_0f3a:
	OR	CL,AL
	JMP	SHORT LAB_c800_0ee7

FUN_c800_0f3e:
	MOV	AX,CS
	MOV	DS,AX
	MOV	DX,LAB_c800_14c0
	MOV	AH,9
	INT	21H
	MOV	AX,[BP+114H]
	OR	AL,AL
	JNZ	LAB_c800_0f53
	MOV	AL,3
LAB_c800_0f53:
	AND	AH,7
	PUSH	AX
	ADD	AH,43H
	MOV	DL,AH
	MOV	AH,2
	INT	21H
	MOV	DX,LAB_c800_1d39
	MOV	AH,9
	INT	21H
	POP	AX
	PUSH	AX
	MOV	AH,AL
	AND	AL,0FH
	DAA
	AND	AH,0F0H
	JZ	LAB_c800_0f76
	ADD	AL,16H
	DAA

LAB_c800_0f76:
	CALL	FUN_c800_14a2
	CALL	FUN_c800_115c
	PUSH	CS
	POP	DS
	CMP	AL,79H
	JZ	LAB_c800_0f89
	CMP	AL,59H
	JZ	LAB_c800_0f89
	POP	AX
	STC
	RET

LAB_c800_0f89:
	MOV	DX,LAB_c800_1899
	MOV	AH,9
	INT	21H
	MOV	AX,0
	MOV	CX,100H
	MOV	DI,130H
	CLD
	REP	STOSW
	POP	AX
	PUSH	AX
	MOV	DL,AH
	ADD	DL,80H
	MOV	AH,0FH
	PUSH	ES
	XOR	BX,BX
	MOV	ES,BX
	MOV	BX,130H
	INT	13H
	POP	ES
	MOV	BH,AH
	JC	LAB_c800_0fca
	POP	AX
	MOV	DL,AH
	ADD	DL,80H
	SUB	DH,DH
	PUSH	DX
	MOV	CX,1
	MOV	AH,7
	INT	13H
	MOV	BH,AH
	JC	LAB_c800_0fca
	POP	AX
	RET

LAB_c800_0fca:
	POP	AX

LAB_c800_0fcb:
	MOV	DX,LAB_c800_1dba
	MOV	SP,[BP+116H]
	MOV	AH,9
	INT	21H
	MOV	AL,BH
	CALL	FUN_c800_14a2
	MOV	DX,LAB_c800_1970
	JMP	LAB_c800_0bef

FUN_c800_0fe1:
	MOV	DL,80H
	MOV	AH,20H
	INT	13H
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX
	MOV	SI,[DISK_AREA_PTR]
	POP	DS
	CALL	READ_HARDWARE_CONFIG
	MOV	[BP+122H],AL
	MOV	WORD [BP+114H],3
	NOT	AL
	AND	AL,30H
	JZ	LAB_c800_100a
	MOV	WORD [BP+114H],4
LAB_c800_100a:
	MOV	DX,LAB_c800_14e7
	PUSH	CS
	POP	DS
	MOV	AH,9
	INT	21H
	MOV	DL,[BP+115H]
	ADD	DL,43H
	MOV	AH,2
	INT	21H
	MOV	DX,LAB_c800_1544
	CALL	FUN_c800_1170
	JCXZ	LAB_c800_1035
	CALL	FUN_c800_1324
	CALL	FUN_c800_1251
	CALL	FUN_c800_1334
	JC	LAB_c800_100a
	MOV	[BP+115H],BL
LAB_c800_1035:
	MOV	DX,LAB_c800_1571
	PUSH	CS
	POP	DS
	MOV	AH,9
	INT	21H
	MOV	DL,[BP+114H]
	ADD	DL,30H
	MOV	AH,2
	INT	21H
	MOV	DX,LAB_c800_158a
	CALL	FUN_c800_1170
	JCXZ	LAB_c800_1060
	CALL	FUN_c800_1324
	CALL	FUN_c800_1277
	CALL	FUN_c800_1334
	JC	LAB_c800_1035
	MOV	[BP+114H],BL

LAB_c800_1060:
	RET

FUN_c800_1061:
	MOV	WORD [BP+111H],800H
	MOV	BYTE [BP+113H],10H
	MOV	AL,[BP+122H]
	NOT	AL
	AND	AL,30H
	XOR	AL,10H
	JZ	LAB_c800_1084
	MOV	DX,LAB_c800_15bb
	CALL	FUN_c800_1166
	MOV	AL,30H
	JZ	LAB_c800_1084
	XOR	AL,AL

LAB_c800_1084:
	AND	BYTE [BP+123H],8FH
	OR	[BP+123H],AL
	TEST	BYTE [BP+123H],10H
	JNZ	LAB_c800_109a
	CALL	FUN_c800_10c9
	JMP	SHORT LAB_c800_109d
	NOP

LAB_c800_109a:
	CALL	FUN_c800_10b3

LAB_c800_109d:
	MOV	WORD [BP+100H],0
	CALL	FUN_c800_111c
	MOV	DI,0
	MOV	CX,SS:[11AH]
	MOV	[BP+100H],CX
	RET

FUN_c800_10b3:
	MOV	DX,LAB_c800_15f5
	CALL	FUN_c800_1170
	JCXZ	LAB_c800_110e
	CALL	FUN_c800_1190
	JC	FUN_c800_10b3
	MOV	AX,[BP+109H]
	MOV	SS:[180H],AX
	RET

FUN_c800_10c9:
	MOV	AL,[BP+122H]
	MOV	AH,AL
	NOT	AH
	AND	AH,30H
	MOV	SI,43H
	JZ	LAB_c800_10dc
	MOV	SI,85H

LAB_c800_10dc:
	TEST	BYTE [BP+115H],1
	JZ	LAB_c800_10e7
	SHR	AL,1
	SHR	AL,1

LAB_c800_10e7:
	AND	AX,3
	MOV	CL,4
	SHL	AX,CL
	CLD
	ADD	SI,AX
	PUSH	DS
	PUSH	ES
	MOV	AX,CS
	MOV	DS,AX
	MOV	AX,SS
	MOV	ES,AX
	MOV	CX,11H
	MOV	DI,100H
	REP	MOVSB
	MOV	AX,[BP+109H]
	MOV	SS:[11AH],AX
	POP	ES
	POP	DS
	RET

LAB_c800_110e:
	MOV	DX,LAB_c800_1dd5
	XOR	AX,AX
	MOV	ES,AX
	MOV	SP,[BP+116H]
	JMP	LAB_c800_0bef

FUN_c800_111c:
	MOV	AX,[BP+109H]
	MOV	SS:[11AH],AX
	CALL	FUN_c800_112f
	JC	LAB_c800_114d
	AND	BYTE [BP+123H],0DFH
	RET

FUN_c800_112f:
	TEST	BYTE [BP+115H],1
	JNZ	LAB_c800_114b
	TEST	BYTE [BP+123H],20H
	JZ	LAB_c800_114b
	MOV	DX,LAB_c800_17e6
	CALL	FUN_c800_115f
	CMP	AL,79H
	JZ	LAB_c800_115a
	CMP	AL,59H
	JZ	LAB_c800_115a

LAB_c800_114b:
	CLC
	RET

LAB_c800_114d:
	MOV	DX,LAB_c800_181e
	CALL	FUN_c800_1170
	JCXZ	FUN_c800_111c
	CALL	FUN_c800_11f3
	JC	LAB_c800_114d

LAB_c800_115a:
	STC
	RET

FUN_c800_115c:
	MOV	DX,LAB_c800_1970

FUN_c800_115f:
	CALL	FUN_c800_1170
	MOV	AL,ES:[SI]
	RET

FUN_c800_1166:
	CALL	FUN_c800_115f
	CMP	AL,79H
	JZ	LAB_c800_116f
	CMP	AL,59H

LAB_c800_116f:
	RET

FUN_c800_1170:
	PUSH	CS
	POP	DS
	MOV	AH,9
	INT	21H
	MOV	BYTE SS:[130H],50H
	PUSH	ES
	POP	DS
	MOV	DX,130H
	MOV	AH,0AH
	INT	21H
	MOV	SI,132H
	MOV	CL,SS:[131H]
	XOR	CH,CH
	RET

FUN_c800_1190:
	MOV	SS:[11CH],SP
	CALL	FUN_c800_1324
	CALL	FUN_c800_12af
	CMP	BX,400H
	JLE	LAB_c800_11a7
	OR	BYTE SS:[123H],40H

LAB_c800_11a7:
	MOV	[BP+109H],BX
	CALL	FUN_c800_1416
	CALL	FUN_c800_12c9
	MOV	[BP+102H],BL
	CALL	FUN_c800_1416
	MOV	BX,[BP+109H]
	INC	BX
	MOV	[BP+105H],BX
	CALL	FUN_c800_12aa
	MOV	[BP+103H],BX
	CALL	FUN_c800_1416
	MOV	BX,[BP+105H]
	CALL	FUN_c800_12aa
	MOV	[BP+105H],BX
	CALL	FUN_c800_1416
	MOV	BX,0BH
	CALL	FUN_c800_12f9
	MOV	[BP+107H],BL
	CALL	FUN_c800_1416
	MOV	BX,5
	CALL	FUN_c800_1311
	MOV	[BP+108H],BL
	JMP	FUN_c800_1334

FUN_c800_11f3:
	MOV	SS:[11CH],SP
	CALL	FUN_c800_1324
	MOV	BYTE SS:[119H],0
	MOV	WORD SS:[11AH],0
	MOV	BYTE SS:[118H],2
	XOR	DI,DI
LAB_c800_1210:
	CALL	FUN_c800_12af
	ADD	SS:[11AH],BX
	MOV	ES:[DI+1F70H],BX
	INC	BYTE SS:[119H]
	MOV	BX,[BP+109H]
	CMP	BX,SS:[11AH]
	JGE	LAB_c800_1232
	MOV	AL,0
	CALL	FUN_c800_1478
LAB_c800_1232:
	CALL	FUN_c800_1416
	CMP	DH,8
	JZ	LAB_c800_1246
	DEC	BYTE SS:[118H]
	JZ	LAB_c800_1249
	ADD	DI,[BP+1AH]
	JMP	SHORT LAB_c800_1210

LAB_c800_1246:
	JMP	FUN_c800_1334

LAB_c800_1249:
	MOV	AL,4
	CALL	FUN_c800_1486
	JMP	FUN_c800_1334

FUN_c800_1251:
	MOV	SS:[11CH],SP
	MOV	SS:[120H],SI
	SUB	AL,43H
	JC	LAB_c800_126f
	MOV	BL,AL
	INC	BL
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX
	CMP	BL,[TOTAL_FIXED_DISKS]
	POP	DS
	JBE	LAB_c800_1274
LAB_c800_126f:
	MOV	AL,2
	CALL	FUN_c800_1478
LAB_c800_1274:
	DEC	BL
	RET

FUN_c800_1277:
	MOV	SS:[11CH],SP
	CALL	FUN_c800_13b2
	CMP	BX,BYTE 0
	JZ	LAB_c800_1298
	MOV	AL,[BP+122H]
	NOT	AL
	AND	AL,30H
	JZ	LAB_c800_1293
	CMP	BX,BYTE 19H
	JMP	SHORT LAB_c800_1296

LAB_c800_1293:
	CMP	BX,BYTE 10H

LAB_c800_1296:
	JBE	LAB_c800_12a9

LAB_c800_1298:
	MOV	AL,[BP+122H]
	NOT	AL
	AND	AL,30H
	MOV	AL,6
	JZ	LAB_c800_12a6
	MOV	AL,8

LAB_c800_12a6:
	CALL	FUN_c800_1478

LAB_c800_12a9:
	RET

FUN_c800_12aa:
	TEST	DH,1
	JZ	LAB_c800_12c8

FUN_c800_12af:
	CALL	FUN_c800_13b2
	CMP	BX,[BP+111H]
	JLE	LAB_c800_12be
	MOV	AL,12H
	CALL	FUN_c800_1478
	RET

LAB_c800_12be:
	TEST	BYTE SS:[123H],40H
	JZ	LAB_c800_12c8
	SHR	BX,1

LAB_c800_12c8:
	RET

FUN_c800_12c9:
	CALL	FUN_c800_13b2
	CMP	BL,[BP+113H]
	JLE	LAB_c800_12d8
	MOV	AL,14H
	CALL	FUN_c800_1478
	RET

LAB_c800_12d8:
	TEST	BYTE SS:[123H],40H
	JZ	LAB_c800_12e5
	SHL	BL,1
	AND	BL,1FH

LAB_c800_12e5:
	RET

LAB_c800_12e6:
	CALL	FUN_c800_13b2
	CMP	BX,BYTE 1
	JL	LAB_c800_12f3
	CMP	BX,BYTE 11H
	JLE	LAB_c800_12f8

LAB_c800_12f3:
	MOV	AL,10H
	CALL	FUN_c800_1478

LAB_c800_12f8:
	RET


FUN_c800_12f9:
	TEST	DH,1
	JZ	LAB_c800_1310
	CALL	FUN_c800_13b2
	CMP	BX,BYTE 5
	JZ	LAB_c800_1310
	CMP	BX,BYTE 0BH
	JZ	LAB_c800_1310
	MOV	AL,0EH
	CALL	FUN_c800_1478

LAB_c800_1310:
	RET


FUN_c800_1311:
	TEST	DH,2
	JZ	LAB_c800_1323
	CALL	FUN_c800_13e5
	TEST	BL,0F8H
	JZ	LAB_c800_1323
	MOV	AL,0AH
	CALL	FUN_c800_1478

LAB_c800_1323:
	RET


FUN_c800_1324:
	PUSH	CX
	XOR	AL,AL
	MOV	CX,1AH
	MOV	DI,184H
	REP	STOSB
	POP	CX
	DEC	SI
	JMP	FUN_c800_1422

FUN_c800_1334:
	CLC
	MOV	CX,SS:[184H]
	JCXZ	LAB_c800_1343
	CALL	FUN_c800_1344
	CALL	FUN_c800_1385
	STC
LAB_c800_1343:
	RET

FUN_c800_1344:
	MOV	CX,4EH
	MOV	AX,2020H
	MOV	DI,132H
	REP	STOSB
	MOV	CX,SS:[184H]
	XOR	DI,DI
LAB_c800_1356:
	MOV	SI,SS:[DI+187H]
	MOV	BYTE ES:[SI],5EH
	ADD	DI,BYTE 3
	LOOP	LAB_c800_1356
	MOV	BYTE ES:[SI+1],24H
	PUSH	CS
	POP	DS
	MOV	DX,LAB_c800_1970
	MOV	AH,9
	INT	21H
	PUSH	ES
	POP	DS
	MOV	DX,132H
	MOV	AH,9
	INT	21H
	PUSH	CS
	POP	DS
	MOV	DX,LAB_c800_1970
	MOV	AH,9
	INT	21H
	RET

FUN_c800_1385:
	MOV	CX,SS:[184H]
	XOR	SI,SI
	MOV	DL,30H

LAB_c800_138e:
	INC	DL
	MOV	AH,2
	INT	21H
	PUSH	DX
	MOV	AL,SS:[SI+186H]
	XOR	AH,AH
	MOV	DI,AX
	MOV	DX,CS:[DI+LAB_c800_0b59]
	MOV	AX,CS
	MOV	DS,AX
	MOV	AH,9
	INT	21H
	POP	DX
	ADD	SI,BYTE 3
	LOOP	LAB_c800_138e
	RET

FUN_c800_13b2:
	MOV	SS:[120H],SI
	TEST	DH,1
	JZ	LAB_c800_13e2
	MOV	BL,DL
	XOR	BH,BH
LAB_c800_13c0:
	CALL	FUN_c800_142b
	TEST	DH,1
	JZ	LAB_c800_13e1
	XOR	DH,DH
	MOV	AX,BX
	MOV	BX,DX
	MUL	WORD CS:[MULTIPLIER]
	JO	LAB_c800_13db
	JS	LAB_c800_13db
	ADD	BX,AX
	JNO	LAB_c800_13c0

LAB_c800_13db:
	CALL	FUN_c800_140d
	MOV	BX,7FFFH

LAB_c800_13e1:
	RET

LAB_c800_13e2:
	JMP	LAB_c800_146b

FUN_c800_13e5:
	MOV	SS:[120H],SI
	TEST	DH,2
	JZ	LAB_c800_146b
	XOR	BX,BX
LAB_c800_13f1:
	OR	BL,DL
	CALL	FUN_c800_142b
	TEST	DH,2
	JZ	LAB_c800_140c
	PUSH	CX
	MOV	CL,4
	SHL	BX,CL
	POP	CX
	TEST	BH,0FFH
	JZ	LAB_c800_13f1
	CALL	FUN_c800_140d
	MOV	BX,7FFFH

LAB_c800_140c:
	RET


FUN_c800_140d:
	CALL	FUN_c800_142b
	TEST	DH,0CH
	JNZ	FUN_c800_140d
	RET

FUN_c800_1416:
	CALL	FUN_c800_1425
	CMP	DL,2CH
	JNZ	LAB_c800_1421
	CALL	FUN_c800_1422
LAB_c800_1421:
	RET

FUN_c800_1422:
	CALL	FUN_c800_142b

FUN_c800_1425:
	CMP	DL,20H
	JZ	FUN_c800_1422
	RET

FUN_c800_142b:
	JCXZ	LAB_c800_1464
	INC	SI
	MOV	AL,ES:[SI]
	DEC	CX
	CMP	AL,61H
	JC	LAB_c800_1438
	SUB	AL,20H

LAB_c800_1438:
	MOV	DH,3
	MOV	DL,AL
	SUB	DL,30H
	CMP	AL,30H
	JL	LAB_c800_1447
	CMP	AL,39H
	JLE	LAB_c800_146a

LAB_c800_1447:
	MOV	DH,2
	ADD	DL,0F9H
	CMP	AL,41H
	JL	LAB_c800_1456
	CMP	AL,46H
	JLE	LAB_c800_146a
	JMP	SHORT LAB_c800_146b

LAB_c800_1456:
	MOV	DL,AL
	MOV	DH,4
	CMP	AL,20H
	JZ	LAB_c800_146a
	CMP	AL,2CH
	JZ	LAB_c800_146a
	JMP	SHORT LAB_c800_146b

LAB_c800_1464:
	XOR	DL,DL
	MOV	DH,8
	XOR	AL,AL

LAB_c800_146a:
	RET

LAB_c800_146b:
	MOV	AL,0CH
	CALL	FUN_c800_1486
	MOV	SP,SS:[11CH]
	JMP	FUN_c800_1334


FUN_c800_1478:
	XCHG	SS:[120H],SI
	CALL	FUN_c800_1486
	XCHG	SS:[120H],SI
	RET

FUN_c800_1486:
	MOV	DI,SS:[184H]
	ADD	DI,DI
	ADD	DI,SS:[184H]
	MOV	SS:[DI+186H],AL
	MOV	SS:[DI+187H],SI
	INC	WORD SS:[184H]
	RET

FUN_c800_14a2:
	PUSH	AX
	MOV	CL,4
	SHR	AL,CL
	CALL	FUN_c800_14ae
	POP	AX
	JMP	SHORT FUN_c800_14ae
	NOP

FUN_c800_14ae:
	AND	AL,0FH
	ADD	AL,90H
	DAA
	ADC	AL,40H
	DAA
	MOV	DL,AL
	MOV	AH,2
	INT	21H
	RET

MULTIPLIER:
	DW	10
	DB	11H				; Unknown

LAB_c800_14c0:
	DB	13,10,'Press "y" to begin formatting drive $'
LAB_c800_14e7:
	DB	13,10,'Super Bios Formatter Rev. 2.4 (C) Copyright Western Digital Corp. 1987'
	DB	13,10,10,'Current Drive is $'
LAB_c800_1544:
	DB	':, Select new Drive or RETURN for current.',13,10,'$'
LAB_c800_1571:
	DB	13,10,'Current Interleave is $'
LAB_c800_158a:
	DB	', Select new Interleave or RETURN for current.',13,10,'$'
LAB_c800_15bb:
	DB	13,10,'Are you dynamically configuring the drive - answer Y/N $'
LAB_c800_15f5:
	DB	13,10,'Key in disk characteristics as follows:ccc h rrr ppp ee o'
	DB	13,10,'where'
	DB	13,10,'ccc = total number of cylinders (1-4 digits)'
	DB	13,10,'h = number of heads (1-2 digits)'
	DB	13,10,'rrr = starting reduced write cylinder (1-4 digits)'
	DB	13,10,'ppp = write precomp cylinder (1-4 digits)'
	DB	13,10,'ee = max correctable error burst length (1-2 digits)'
	DB	13,10,'     range = 5 to 11 bits, default = 11 bits'
	DB	13,10,' o = CCB option byte, step rate select (1 hex digit)'
	DB	13,10,'     range = 0 to 7, default = 5'
	DB	13,10,'     refer to controller and drive specification for step rates'
	DB	13,10,'$'
LAB_c800_17e6:
	DB	13,10,'Are you virtually configuring the drive - answer Y/N $'
LAB_c800_181e:
	DB	13,10,'Key in cylinder number for virtual drive split as vvvv ...'
	DB	13,10,'where vvvv = number of cylinders for drive C: (1-4 digits)'
	DB	13,10,'$'
LAB_c800_1899:
	DB	13,10,'Formatting . . .'
	DB	13,10,'$'

LAB_c800_18ae:
	DW	LAB_c800_1962
	DW	LAB_c800_1939
	DW	LAB_c800_1914
	DW	LAB_c800_18d8
	DW	LAB_c800_1903
	DW	LAB_c800_1951
	DW	LAB_c800_18ee
	DW	LAB_c800_192b
	DW	LAB_c800_18c2
	DW	LAB_c800_18ee

LAB_c800_18c2:
	DB	LAB_c800_18c3_END - LAB_c800_18c3
LAB_c800_18c3:
	DB	'CORRECTABLE ECC ERROR'
LAB_c800_18c3_END	EQU	$

LAB_c800_18d8:
	DB	LAB_c800_18d9_END - LAB_c800_18d9
LAB_c800_18d9:
	DB	'FLAGGED AS BAD SECTOR'
LAB_c800_18d9_END	EQU	$

LAB_c800_18ee:
	DB	LAB_c800_18ef_END - LAB_c800_18ef
LAB_c800_18ef:
	DB	'FLAGGED AS BAD TRACK'
LAB_c800_18ef_END	EQU	$

LAB_c800_1903:
	DB	LAB_c800_1904_END - LAB_c800_1904
LAB_c800_1904:
	DB	'MISSING ID FIELD'
LAB_c800_1904_END	EQU	$

LAB_c800_1914:
	DB	LAB_c800_1915_END - LAB_c800_1915
LAB_c800_1915:
	DB	'MISSING DATA ADDR MARK'
LAB_c800_1915_END	EQU	$

LAB_c800_192b:
	DB	LAB_c800_193b_END - LAB_c800_193b
LAB_c800_193b:
	DB	'PROGRAM ERROR'
LAB_c800_193b_END	EQU	$

LAB_c800_1939:
	DB	LAB_c800_193a_END - LAB_c800_193a
LAB_c800_193a:
	DB	'UNCORRECTABLE ECC ERROR'
LAB_c800_193a_END	EQU	$

LAB_c800_1951:
	DB	LAB_c800_1952_END - LAB_c800_1952
LAB_c800_1952:
	DB	'UNREADABLE TRACK'
LAB_c800_1952_END	EQU	$

LAB_c800_1962:
	DB	LAB_c800_1963_END - LAB_c800_1963
LAB_c800_1963:
	DB	'USER-SUPPLIED'
LAB_c800_1963_END	EQU	$

LAB_c800_1970:
	DB	13,10,'$'
LAB_c800_1973:
	DB	': Aggregate virtual size exceeds disk cylinder size',13,10,'$'
LAB_c800_19a9:
	DB	': Invalid drive',13,10,'$'
LAB_c800_19bb:
	DB	': Too many virtual drives',13,10,'$'
LAB_c800_19d7:
	DB	': Interleave factor must be 1 - 16',13,10,'$'
LAB_c800_19fc:
	DB	': Interleave factor must be 1 - 25',13,10,'$'
LAB_c800_1a21:
	DB	': Invalid CCB option value',13,10,'$'
LAB_c800_1a3e:
	DB	': Illegal character',13,10,'$'
LAB_c800_1a54:
	DB	': Error burst length must be 5 or 11',13,10,'$'
LAB_c800_1a7b:
	DB	': Sector number must be 1-17',13,10,'$'
LAB_c800_1a9a:
	DB	': Cylinder size exceeds maximum',13,10,'$'
LAB_c800_1abc:
	DB	': Number of heads exceeds maximum',13,10,'$'
LAB_c800_1ae0:
	DB	' : pool size exceeds maximum',13,10,'$'
LAB_c800_1aff:
	DB	13,10,'Do you want to format bad tracks - answer Y/N $'
LAB_c800_1b30:
	DB	13,10,'Key in bad track list as follows: ccc h ...'
	DB	13,10,'where '
	DB	13,10,'ccc = bad track cylinder no (1-4 digits)'
	DB	13,10,'h = bad track head number (1-2 digits)'
	DB	13,10,'$'
LAB_c800_1bba:
	DB	13,10,'                               BAD TRACK MAP'
	DB	13,10,'TRACK ADDR          PROBLEM          TRACK ADDR          PROBLEM          '
	DB	13,10,'$'
LAB_c800_1c37:
	DB	13,10,'The surface analysis processor detected no disk errors'
	DB	13,10,'$'
LAB_c800_1c72:
	DB	13,10,'Dynamic memory space exhausted - cannot complete surface analysis'
	DB	13,10,'$'
LAB_c800_1cb8:
	DB	13,10,'Too many disk errors - cannot complete alt track/sector assignments'
	DB	13,10,'$'
LAB_c800_1d00:
	DB	13,10,' Screen full - hit any key to continue'
	DB	13,10,'$'
LAB_c800_1d2b:
	DB	13,10,'More ? Y/N $'
LAB_c800_1d39:
	DB	' with interleave $'
LAB_c800_1d4b:
	DB	13,10,'Format Successful$'
LAB_c800_1d5f:
	DB	13,10,10,'System will now restart'
	DB	13,10,10,7,'Insert DOS diskette in drive A:'
	DB	13,10,'Press any key when ready.  $'
LAB_c800_1dba:
	DB	13,10,'Error---completion code $'
LAB_c800_1dd5:
	DB	13,10,'Nothing Done Exit$'