%ifndef __BIOSDATA_INC__
%define __BIOSDATA_INC__

;----------------------------------------
;	 ROM BIOS DATA AREAS		:
;----------------------------------------
DATA		EQU	40H
struc		BiosData
	.rs232Base	resw	4	; ADDRESSES OF RS232 ADAPTERS
	.printerBase	resw	4	; ADDRESSES OF PRINTERS
	.equipFlag	resw	1	; INSTALLED HARDWARE
	.mfgTest	resb	1	; INITIALIZATION FLAG
	.memorySize	resw	1	; MEMORY SIZE IN K BYTES
	.ioRamSize	resw	1	; MEMORY IN I/O CHANNEL
;----------------------------------------
;	   KEYBOARD DATA AREAS		:
;----------------------------------------
	.kbFlag		resb	1
	.kbFlag1	resb	1	; SECOND BYTE OF KEYBOARD STATUS

	.altInput	resb	1	; STORAGE FOR ALTERNATE KEYPAD ENTRY
	.bufferHead	resw	1	; POINTER TO HEAD OF KEYBOARD BUFFER
	.bufferTail	resw	1	; POINTER TO TAIL OF KEYBOARD BUFFER
	.kbBuffer	resw	16	; ROOM FOR 15 ENTRIES
	.kbBufferEnd:

;----- HEAD = TAIL INDICATES THAT THE BUFFER IS EMPTY

;----------------------------------------
;	DISKETTE DATA AREAS		:
;----------------------------------------
	.seekStatus	resb	1	; DRIVE RECALIBRATION STATUS
;				BIT 3-0 = DRIVE 3-0 NEEDS RECAL BEFORE
;					  NEXT SEEK IF BIT IS = 0
	.motorStatus	resb	1	; MOTOR STATUS
;				BIT 3-0 = DRIVE 3-0 IS CURRENTLY RUNNING
;				BIT 7	= CURRENT OPERATION IS A WRITE, REQUIRES DELAY
	.motorCount	resb	1	; TIME OUT COUNTER FOR DRIVE TURN OFF

	.disketteStatus	resb	1	; SINGLE BYTE OF RETURN CODE INFO FOR STATUS

	.necStatus	resb	7	; STATUS BYTES FROM NEC

;----------------------------------------
;	VIDEO DISPLAY DATA AREA 	:
;----------------------------------------
	.crtMode	resb	1	; CURRENT CRT MODE
	.crtCols	resw	1	; NUMBER OF COLUMNS ON SCREEN
	.crtLen		resw	1	; LENGTH OF REGEN IN BYTES
	.crtStart	resw	1	; STARTING ADDRESS IN REGEN BUFFER
	.cursorPosn	resw	8	; CURSOR FOR EACH OF UP TO 8 PAGES
	.cursorMode	resw	1	; CURRENT CURSOR MODE SETTING
	.activePage	resb	1	; CURRENT PAGE BEING DISPLAYED
	.addr6845	resw	1	; BASE ADDRESS FOR ACTIVE DISPLAY CARD
	.crtModeSet	resb	1	; CURRENT SETTING OF THE 3X8 REGISTER
	.crtPalette	resb	1	; CURRENT PALETTE SETTING COLOR CARD

;----------------------------------------
;	   CASSETTE DATA AREA		:
;----------------------------------------
	.edgeCnt	resw	1	; TIME COUNT AT DATA EDGE
	.crcReg		resw	1	; CRC REGISTER
	.lastVal	resb	1	; LAST INPUT VALUE

;----------------------------------------
;	    TIMER DATA AREA		:
;----------------------------------------
	.timerLow	resw	1	; LOW WORD OF TIMER COUNT
	.timerHigh	resw	1	; HIGH WORD OF TIMER COUNT
	.timerOfl	resb	1	; TIMER HAS ROLLED OVER SINCE LAST READ
;COUNTS_SEC	EQU	18
;COUNTS_MIN	EQU	1092
;COUNTS_HOUR	EQU	65543
;COUNTS_DAY	EQU	1573040 = 1800B0H

;----------------------------------------
;	   SYSTEM DATA AREA		:
;----------------------------------------
	.biosBreak	resb	1	; BIT 7 = 1 IF BREAK KEY HAS BEEN DEPRESSED
	.resetFlag	resw	1	; WORD = 1234H IF KEYBOARD RESET UNDERWAY
;----------------------------------------
;	  FIXED DISK DATA AREA		:
;----------------------------------------
			resw	1
			resw	1
;----------------------------------------
;	PRINTER AND RS232 TIMEOUT CTRS	:
;----------------------------------------
	.printerTimeOut	resb	4	; PRINTER TIME OUT COUNTER
	.rs232TimeOut	resb	4	; RS232 TIME OUT COUNTER
;----------------------------------------
;	EXTRA KEYBOARD DATA AREA	:
;----------------------------------------
	.bufferStart	resb	2
	.bufferEnd	resb	2
endstruc

%endif ; !__BIOSDATA_INC__
