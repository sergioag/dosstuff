%ifndef __RS232_INC__
%define __RS232_INC__

;-----INT 14-------------------------------------------------------------
; RS232_IO								:
;	THIS ROUTINE PROVIDES BYTE STREAM I/O TO THE COMMUNICATIONS	:
;	PORT ACCORDING TO THE PARAMETERS:				:
;	(AH)=0	INITIALIZE THE COMMUNICATIONS PORT			:
;		(AL) HAS PARAMETERS FOR INITIALIZATION			:
;									:
;	7	6	5	4	3	2	1	0	:
;	----- BAUD RATE --	-PARITY--     STOPBIT	--WORD LENGTH-- :
;	000 - 110		X0 - NONE	0 - 1	 10 - 7 BITS	:
;	001 - 150		01 - ODD	1 - 2	 11 - 8 BITS	:
;	010 - 300		11 - EVEN				:
;	011 - 600							:
;	100 - 1200							:
;	101 - 2400							:
;	110 - 4800							:
;	111 - 9600							:
;									:
;	ON RETURN, CONDITIONS SET AS IN CALL TO COMMO STATUS (AH=3)	:
;	(AH)=1	SEND THE CHARACTER IN (AL) OVER THE COMMO LINE		:
;		(AL) REGISTER IS PRESERVED				:
;		ON EXIT, BIT 7 OF AH IS SET IF THE ROUTINE WAS UNABLE	:
;			TO TRANSMIT THE BYTE OF DATA OVER THE LINE.	:
;			IF BIT 7 OF AH IS NOT SET, THE REMAINDER OF AH	:
;			IS SET AS IN A STATUS REQUEST, REFLECTING THE	:
;			CURRENT STATUS OF THE LINE.			:
;	(AH)=2	RECEIVE A CHARACTER IN (AL) FROM COMMO LINE BEFORE	:
;			RETURNING TO CALLER				:
;		ON EXIT, AH HAS THE CURRENT LINE STATUS, AS SET BY THE	:
;			THE STATUS ROUTINE, EXCEPT THAT THE ONLY BITS	:
;			LEFT ON ARE THE ERROR BITS (7,4,3,2,1)		:
;			IF AH HAS BIT 7 ON (TIME OUT) THE REMAINING	:
;			BITS ARE NOT PREDICTABLE.			:
;			THUS, AH IS NON ZERO ONLY WHEN AN ERROR 	:
;			OCCURRED.					:
;	(AH)=3	RETURN THE COMMO PORT STATUS IN (AX)			:
;		AH CONTAINS THE LINE CONTROL STATUS			:
;		BIT 7 = TIME OUT					:
;		BIT 6 = TRANS SHIFT REGISTER EMPTY			:
;		BIT 5 = TRAN HOLDING REGISTER EMPTY			:
;		BIT 4 = BREAK DETECT					:
;		BIT 3 = FRAMING ERROR					:
;		BIT 2 = PARITY ERROR					:
;		BIT 1 = OVERRUN ERROR					:
;		BIT 0 = DATA READY					:
;		AL CONTAINS THE MODEM STATUS				:
;		BIT 7 = RECEVED LINE SIGNAL DETECT			:
;		BIT 6 = RING INDICATOR					:
;		BIT 5 = DATA SET READY					:
;		BIT 4 = CLEAR TO SEND					:
;		BIT 3 = DELTA RECEIVE LINE SIGNAL DETECT		:
;		BIT 2 = TRAILING EDGE RING DETECTOR			:
;		BIT 1 = DELTA DATA SET READY				:
;		BIT 0 = DELTA CLEAR TO SEND				:
;									:
;	(DX) = PARAMETER INDICATING WHICH RS232 CARD (0,1 ALLOWED)	:
;									:
; DATA AREA RS232_BASE CONTAINS THE BASE ADDRESS OF THE 8250 ON THE	:
;	CARD LOCATION 400H CONTAINS UP TO 4 RS232 ADDRESSES POSSIBLE	:
;	DATA AREA LABEL RS232_TIM_OUT (BYTE) CONTAINS OUTER LOOP COUNT	:
;	VALUE FOR TIMEOUT (DEFAULT=1)					:
; OUTPUT								:
;	AX MODIFIED ACCORDING TO PARMS OF CALL				:
;	ALL OTHERS UNCHANGED						:
;------------------------------------------------------------------------
	TIMES	0E729H-($-$$) DB 0FFh
A1:					; TABLE OF INIT VALUE
	DW	1047			; 110 BAUD
	DW	768			; 150
	DW	384			; 300
	DW	192			; 600
	DW	96			; 1200
	DW	48			; 2400
	DW	24			; 4800
	DW	12			; 9600

RS232_IO:

;----- VECTOR TO APPROPRIATE ROUTINE

	STI				; INTERRUPTS BACK ON
	PUSH	DS			; SAVE SEGMENT
	PUSH	DX
	PUSH	SI
	PUSH	DI
	PUSH	CX
	PUSH	BX
	MOV	SI,DX			; RS232 VALUE TO SI
	MOV	DI,DX
	SHL	SI,1			; WORD OFFSET
	CALL	DDS
	MOV	DX,[SI+BiosData.rs232Base]	; GET BASE ADDRESS
	OR	DX,DX			; TEST FOR 0 BASE ADDRESS
	JZ	A3			; RETURN
	OR	AH,AH			; TEST FOR (AH)=0
	JZ	A4			; COMMUN INIT
	DEC	AH			; TEST FOR (AH)=1
	JZ	A5			; SEND AL
	DEC	AH			; TEST FOR (AH)=2
	JZ	A12			; RECEIVE INTO AL
A2:
	DEC	AH			; TEST FOR (AH)=3
	JNZ	A3
	JMP	A18			; COMMUNICATION STATUS
A3:					; RETURN FROM RS232
	POP	BX
	POP	CX
	POP	DI
	POP	SI
	POP	DX
	POP	DS
	IRET				; RETURN TO CALLER, NO ACTION

;----- INITIALIZE THE COMMUNICATIONS PORT

A4:
	MOV	AH,AL			; SAVE INIT PARMS IN AH
	ADD	DX,BYTE 3		; POINT TO 8250 CONTROL REGISTER
	MOV	AL,80H
	OUT	DX,AL			; SET DLAB=1

;----- DETERMINE BAUD RATE DIVISOR

	MOV	DL,AH			; GET PARMS TO DL
	MOV	CL,4
	ROL	DL,CL
	AND	DX,0EH			; ISOLATE THEM
	MOV	DI,A1			; BASE OF TABLE
	ADD	DI,DX			; PUT INTO INDEX REGISTER
	MOV	DX,[SI+BiosData.rs232Base]	; POINT TO HIGH ORDER OF DIVISOR
	INC	DX
	CS MOV	AL,[DI+1]		; GET HIGH ORDER OF DIVISOR
	OUT	DX,AL			; SET MS OF DIV TO 0
	DEC	DX
	CS MOV	AL,[DI]			; GET LOW ORDER OF DIVISOR
	OUT	DX,AL			; SET LOW OF DIVISOR
	ADD	DX,BYTE 3
	MOV	AL,AH			; GET PARMS BACK
	AND	AL,01FH 		; STRIP OFF THE BAUD BITS
	OUT	DX,AL			; LINE CONTROL TO 8 BITS
	DEC	DX
	DEC	DX
	MOV	AL,0
	OUT	DX,AL			; INTERRUPT ENABLES ALL OFF
	JMP	SHORT A18		; COM_STATUS

;----- SEND CHARACTER IN (AL) OVER COMMO LINE

A5:
	PUSH	AX			; SAVE CHAR TO SEND
	ADD	DX,BYTE 4		; MODEM CONTROL REGISTER
	MOV	AL,3			; DTR AND RTS
	OUT	DX,AL			; DATA TERMINAL READY, REQUEST TO SEND
	INC	DX			; MODEM STATUS REGISTER
	INC	DX
	MOV	BH,30H			; DATA SET READY & CLEAR TO SEND
	CALL	WAIT_FOR_STATUS 	; ARE BOTH TRUE
	JE	A9			; YES, READY TO TRANSMIT CHAR
A7:
	POP	CX
	MOV	AL,CL			; RELOAD DATA BYTE
A8:
	OR	AH,80H			; INDICATE TIME OUT
	JMP	SHORT A3		; RETURN
A9:					; CLEAR_TO_SEND
	DEC	DX			; LINE STATUS REGISTER
A10:					; WAIT_SEND
	MOV	BH,20H			; IS TRANSMITTER READY
	CALL	WAIT_FOR_STATUS 	; TEST FOR TRANSMITTER READY
	JNZ	A7			; RETURN WITH TIME OUT SET
A11:					; OUT_CHAR
	SUB	DX,BYTE 5		; DATA PORT
	POP	CX			; RECOVER IN CX TEMPORARILY
	MOV	AL,CL			; MOVE CHAR TO AL FOR OUT, STATUS IN AH
	OUT	DX,AL			; OUTPUT CHARACTER
	JMP	SHORT A3		; RETURN

;----- RECEIVE CHARACTER FROM COMMO LINE

A12:
	ADD	DX,BYTE 4		; MODEM CONTROL REGISTER
	MOV	AL,1			; DATA TERMINAL READY
	OUT	DX,AL
	INC	DX			; MODEM STATUS REGISTER
	INC	DX
A13:					; WAIT_DSR
	MOV	BH,20H			; DATA SET READY
	CALL	WAIT_FOR_STATUS 	; TEST FOR DSR
	JNZ	A8			; RETURN WITH ERROR
A15:					; WAIT_DSR_END
	DEC	DX			; LINE STATUS REGISTER
A16I:					; WAIT_RECV
	MOV	BH,1			; RECEIVE BUFFER FULL
	CALL	WAIT_FOR_STATUS 	; TEST FOR REC. BUFF. FULL
	JNZ	A8			; SET TIME OUT ERROR
A17:					; GET_CHAR
	AND	AH,00011110B		; TEST FOR ERROR CONDITIONS ON RECV CHAR
	MOV	DX,[SI+BiosData.rs232Base]	; DATA PORT
	IN	AL,DX			; GET CHARACTER FROM LINE
	JMP	A3			; RETURN

;----- COMMO PORT STATUS ROUTINE

A18:
	MOV	DX,[SI+BiosData.rs232Base]
	ADD	DX,BYTE 5		; CONTROL PORT
	IN	AL,DX			; GET LINE CONTROL STATUS
	MOV	AH,AL			; PUT IN AH FOR RETURN
	INC	DX			; POINT TO MODEM STATUS REGISTER
	IN	AL,DX			; GET MODEM CONTROL STATUS
	JMP	A3			; RETURN
;----------------------------------------
; WAIT FOR STATUS ROUTINE		:
;					:
; ENTRY:				:
;	BH=STATUS BIT(S) TO LOOK FOR,	:
;	DX=ADDR. OF STATUS REG		:
; EXIT: 				:
;	ZERO FLAG ON  = STATUS FOUND	:
;	ZERO FLAG OFF = TIMEOUT.	:
;	AH=LAST STATUS READ		:
;----------------------------------------
WAIT_FOR_STATUS:
	MOV	BL,[DI+BiosData.rs232TimeOut]	; LOAD OUTER LOOP COUNT
WFS0:
	SUB	CX,CX
WFS1:
	IN	AL,DX			; GET STATUS
	MOV	AH,AL			; MOVE TO AH
	AND	AL,BH			; ISOLATE BITS TO TEST
	CMP	AL,BH			; EXACTLY = TO MASK
	JE	WFS_END 		; RETURN WITH ZERO FLAG ON
	LOOP	WFS1			; TRY AGAIN
	DEC	BL
	JNZ	WFS0
	OR	BH,BH			; SET ZERO FLAG OFF
WFS_END:
	RET


%endif ; !__RS232_INC__