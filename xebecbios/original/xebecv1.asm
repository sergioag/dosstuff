$TITLE(FIXED DISK BIOS FOR IBM DISK CONTROLLER)

;-- INT 13 ------------------------------------------------------
;                                                               :
; FIXED DISK I/O INTERFACE                                      :
;                                                               :
;       THIS INTERFACE PROVIDES ACCESS TO 5 1/4" FIXED DISKS    :
;       THROUGH THE IBM FIXED DISK CONTROLLER.                  :
;                                                               :
;----------------------------------------------------------------

;----------------------------------------------------------------
;       THE  BIOS ROUTINES ARE MEANT TO BE ACCESSED THROUGH     :
;       SOFTWARE INTERRUPTS ONLY.  ANY ADDRESSES PRESENT IN     :
;       THE LISTINGS  ARE INCLUDED  ONLY FOR  COMPLETENESS,     :
;       NOT FOR REFERENCE.    APPLICATIONS WHICH  REFERENCE     :
;       ABSOLUTE  ADDRESSES    WITHIN   THE   CODE  SEGMENT     :
;       VIOLATE THE STRUCTURE AND DESIGN OF BIOS.               :
;----------------------------------------------------------------
;
; INPUT    (AH = HEX VALUE)
;
;       (AH)=00 RESET DISK (DL = 80H,81H)/ DISKETTE
;       (AH)=01 READ THE STATUS OF THE LAST DISK OPERATION INTO (AL)
;               NOTE: DL < 80H - DISKETTE
;                     DL > 80H - DISK
;       (AH)=02 READ THE DESIRED SECTORS INTO MEMORY
;       (AH)=03 WRITE THE DESIRED SECTORS FROM MEMORY
;       (AH)=04 VERIFY THE DESIRED SECTORS
;       (AH)=05 FORMAT THE DESIRED TRACK
;       (AH)=06 FORMAT THE DESIRED TRACK AND SET BAD SECTOR FLAGS
;       (AH)=07 FORMAT THE DRIVE STARTING AT THE DESIRED TRACK
;       (AH)=08 RETURN THE CURRENT DRIVE PARAMETERS
;
;       (AH)=09 INITIALIZE DRIVE PAIR CHARACTERISTICS
;               INTERRUPT 41 POINTS TO DATA BLOCK
;       (AH)=0A READ LONG
;       (AH)=0B WRITE LONG
;       NOTE: READ AND WRITE LONG ENCOMPASS 512 + 4 BYTES ECC
;       (AH)=0C SEEK
;       (AH)=0D ALTERNATE DISK RESET (SEE DL)
;       (AH)=0E READ SECTOR BUFFER
;       (AH)=0F WRITE SECTOR BUFFER,
;               (RECOMMENDED PRACTICE BEFORE FORMATTING)
;       (AH)=10 TEST DRIVE READY
;       (AH)=11 RECALIBRATE
;       (AH)=12 CONTROLLER RAM DIAGNOSTIC
;       (AH)=13 DRIVE DIAGNOSTIC
;       (AH)=14 CONTROLLER INTERNAL DIAGNOSTIC
;
;               REGISTERS USED FOR FIXED DISK OPERATIONS
;
;               (DL)    -  DRIVE NUMBER     (80H-87H FOR DISK, VALUE CHECKED)
;               (DH)    -  HEAD NUMBER      (0-7 ALLOWED, NOT VALUE CHECKED)
;               (CH)    -  CYLINDER NUMBER  (0-1023, NOT VALUE CHECKED)(SEE CL)
;               (CL)    -  SECTOR NUMBER    (1-17, NOT VALUE CHECKED)
;
;                          NOTE: HIGH 2 BITS OF CYLINDER NUMBER ARE PLACED
;                                IN THE HIGH 2 BITS OF THE CL REGISTER
;                                (10 BITS TOTAL)
;               (AL)    -  NUMBER OF SECTORS (MAXIMUM POSSIBLE RANGE 1-80H,
;                                             FOR READ/WRITE LONG 1-79H)
;                          (INTERLEAVE VALUE FOR FORMAT 1-16D)
;               (ES:BX) -  ADDRESS OF BUFFER FOR READS AND WRITES,
;                          (NOT REQUIRED FOR VERIFY)
;
; OUTPUT
;       AH = STATUS OF CURRENT OPERATION
;            STATUS BITS ARE DEFINED IN THE EQUATES BELOW
;       CY = 0  SUCCESSFUL OPERATION (AH=0 ON RETURN)
;       CY = 1  FAILED OPERATION (AH HAS ERROR REASON)
;
;       NOTE:   ERROR 11H  INDICATES THAT THE DATA READ HAD A RECOVERABLE
;               ERROR WHICH WAS CORRECTED BY THE ECC ALGORITHM.  THE DATA
;               IS PROBABLY GOOD,   HOWEVER THE BIOS ROUTINE INDICATES AN
;               ERROR TO ALLOW THE CONTROLLING PROGRAM A CHANCE TO DECIDE
;               FOR ITSELF.   THE  ERROR  MAY  NOT  RECUR  IF THE DATA IS
;               REWRITTEN. (AL) CONTAINS THE BURST LENGTH.
;
;       IF DRIVE PARAMETERS WERE REQUESTED:
;
;       DL = NUMBER OF CONSECUTIVE ACKNOWLEDGING DRIVES ATTACHED (0-2)
;               (CONTROLLER CARD ZERO TALLY ONLY)
;       DH = MAXIMUM USEABLE VALUE FOR HEAD NUMBER
;       CH = MAXIMUM USEABLE VALUE FOR CYLINDER NUMBER
;       CL = MAXIMUM USEABLE VALUE FOR SECTOR NUMBER
;            AND CYLINDER NUMBER HIGH BITS
;
;       REGISTERS WILL BE PRESERVED EXCEPT WHEN THEY ARE USED TO RETURN
;       INFORMATION.
;
;       NOTE: IF AN ERROR IF REPORTED BY THE DISK CODE, THE APPROPRIATE
;               ACTION IS TO RESET THE DISK, THEN RETRY THE OPERATION.
;
;------------------------------------------------------------------------

SENSE_FAIL      EQU     0FFH            ; SENSE OPERATION FAILED
UNDEF_ERR       EQU     0BBH            ; UNDEFINED ERROR OCCURRED
TIME_OUT        EQU     80H             ; ATTACHMENT FAILED TO RESPOND
BAD_SEEK        EQU     40H             ; SEEK OPERATION FAILED
BAD_CNTLR       EQU     20H             ; CONTROLLER HAS FAILED
DATA_CORRECTED  EQU     11H             ; ECC CORRECTED DATA ERROR
BAD_ECC         EQU     10H             ; BAD ECC ON DISK READ
BAD_TRACK       EQU     0BH             ; BAD TRACK FLAG DETECTED
DMA_BOUNDARY    EQU     09H             ; ATTEMPT TO DMA ACROSS 64K BOUNDARY
INIT_FAIL       EQU     07H             ; DRIVE PARAMETER ACTIVITY FAILED
BAD_RESET       EQU     05H             ; RESET FAILED
RECORD_NOT_FND  EQU     04H             ; REQUESTED SECTOR NOT FOUND
BAD_ADDR_MARK   EQU     02H             ; ADDRESS MARK NOT FOUND
BAD_CMD         EQU     01H             ; BAD COMMAND PASSED TO DISK I/O

;----------------------------------------
;       INTERRUPT AND STATUS AREAS      :
;----------------------------------------

DUMMY   SEGMENT AT 0
        ORG     0DH*4                   ; FIXED DISK INTERRUPT VECTOR
HDISK_INT       LABEL   DWORD
        ORG     13H*4                   ; DISK INTERRUPT VECTOR
ORG_VECTOR      LABEL   DWORD
        ORG     19H*4                   ; BOOTSTRAP INTERRUPT VECTOR
BOOT_VEC        LABEL   DWORD
        ORG     1EH*4                   ; DISKETTE PARAMETERS
DISKETTE_PARAM  LABEL   DWORD
        ORG     040H*4                  ; NEW DISKETTE INTERRUPT VECTOR
DISK_VECTOR     LABEL   DWORD
        ORG     041H*4                  ; FIXED DISK PARAMETER VECTOR
HF_TBL_VEC      LABEL   DWORD
        ORG     7C00H                   ; BOOTSTRAP LOADER VECTOR
BOOT_LOCN       LABEL   FAR
DUMMY   ENDS

DATA    SEGMENT AT 40H
        ORG     42H
CMD_BLOCK       LABEL   BYTE
HD_ERROR        DB      7 DUP(?)        ; OVERLAYS DISKETTE STATUS
        ORG     06CH
TIMER_LOW       DW      ?               ; TIMER LOW WORD
        ORG     72H
RESET_FLAG      DW      ?               ; 1234H IF KEYBOARD RESET UNDERWAY
        ORG     74H
DISK_STATUS     DB      ?               ; FIXED DISK STATUS BYTE
HF_NUM          DB      ?               ; COUNT OF FIXED DISK DRIVES
CONTROL_BYTE    DB      ?               ; CONTROL BYTE DRIVE OPTIONS
PORT_OFF        DB      ?               ; PORT OFFSET
DATA    ENDS

CODE    SEGMENT

;--------------------------------------------------------
; HARDWARE SPECIFIC VALUES                              :
;                                                       :
;  -  CONTROLLER I/O PORT                               :
;     > WHEN READ FROM:                                 :
;       HF_PORT+0 - READ DATA (FROM CONTROLLER TO CPU)  :
;       HF_PORT+1 - READ CONTROLLER HARDWARE STATUS     :
;                   (CONTROLLER TO CPU)                 :
;       HF_PORT+2 - READ CONFIGURATION SWITCHES         :
;       HF_PORT+3 - NOT USED                            :
;     > WHEN WRITTEN TO:                                :
;       HF_PORT+0 - WRITE DATA (FROM CPU TO CONTROLLER) :
;       HF_PORT+1 - CONTROLLER RESET                    :
;       HF_PORT+2 - GENERATE CONTROLLER SELECT PULSE    :
;       HF_PORT+3 - WRITE PATTERN TO DMA AND INTERRUPT  :
;                   MASK REGISTER                       :
;                                                       :
;--------------------------------------------------------

HF_PORT         EQU     0320H           ; DISK PORT
R1_BUSY         EQU     00001000B       ; DISK PORT 1 BUSY BIT
R1_BUS          EQU     00000100B       ;             COMMAND/DATA BIT
R1_IOMODE       EQU     00000010B       ;             MODE BIT
R1_REQ          EQU     00000001B       ;             REQUEST BIT

DMA_READ        EQU     01000111B       ; CHANNEL 3 (047H)
DMA_WRITE       EQU     01001011B       ; CHANNEL 3 (04BH)
DMA             EQU     0               ; DMA ADDRESS
DMA_HIGH        EQU     082H            ; PORT FOR HIGH 4 BITS OF DMA

TST_RDY_CMD     EQU     00000000B       ; CNTLR READY (00H)
RECAL_CMD       EQU     00000001B       ;       RECAL (01H)
SENSE_CMD       EQU     00000011B       ;       SENSE (03H)
FMTDRV_CMD      EQU     00000100B       ;       DRIVE (04H)
CHK_TRK_CMD     EQU     00000101B       ;       T CHK (05H)
FMTTRK_CMD      EQU     00000110B       ;       TRACK (06H)
FMTBAD_CMD      EQU     00000111B       ;       BAD   (07H)
READ_CMD        EQU     00001000B       ;       READ  (08H)
WRITE_CMD       EQU     00001010B       ;       WRITE (0AH)
SEEK_CMD        EQU     00001011B       ;       SEEK  (0BH)
INIT_DRV_CMD    EQU     00001100B       ;       INIT  (0CH)
RD_ECC_CMD      EQU     00001101B       ;       BURST (0DH)
RD_BUFF_CMD     EQU     00001110B       ;       BUFFR (0EH)
WR_BUFF_CMD     EQU     00001111B       ;       BUFFR (0FH)
RAM_DIAG_CMD    EQU     11100000B       ;       RAM   (E0H)
CHK_DRV_CMD     EQU     11100011B       ;       DRV   (E3H)
CNTLR_DIAG_CMD  EQU     11100100B       ;       CNTLR (E4H)
RD_LONG_CMD     EQU     11100101B       ;       RLONG (E5H)
WR_LONG_CMD     EQU     11100110B       ;       WLONG (E6H)

INT_CTL_PORT    EQU     20H             ; 8259 CONTROL PORT
EOI             EQU     20H             ; END OF INTERRUPT COMMAND

MAX_FILE        EQU     8
S_MAX_FILE      EQU     2

        ASSUME  CS:CODE
        ORG     0H
        DB      055H                    ; GENERIC BIOS HEADER
        DB      0AAH
        DB      16D

;----------------------------------------------------------------
; FIXED DISK I/O SETUP                                          :
;                                                               :
;  -  ESTABLISH TRANSFER VECTORS FOR THE FIXED DISK             :
;  -  PERFORM POWER ON DIAGNOSTICS                              :
;     SHOULD AN ERROR OCCUR A "1701" MESSAGE IS DISPLAYED       :
;                                                               :
;----------------------------------------------------------------

DISK_SETUP      PROC    FAR
        JMP     SHORT   L3
        DB      '5000059 (C)COPYRIGHT  IBM 1982'        ; COPYRIGHT NOTICE
L3:
        ASSUME  DS:DUMMY
        SUB     AX,AX                                   ; ZERO
        MOV     DS,AX
        CLI
        MOV     AX,WORD PTR ORG_VECTOR                  ; GET DISKETTE VECTOR
        MOV     WORD PTR DISK_VECTOR,AX                 ;  INTO INT 40H
        MOV     AX,WORD PTR ORG_VECTOR+2
        MOV     WORD PTR DISK_VECTOR+2,AX
        MOV     WORD PTR ORG_VECTOR, OFFSET DISK_IO     ; HDISK HANDLER
        MOV     WORD PTR ORG_VECTOR+2,CS
        MOV     AX, OFFSET HD_INT                       ; HDISK INTERRUPT
        MOV     WORD PTR HDISK_INT,AX
        MOV     WORD PTR HDISK_INT+2,CS
        MOV     WORD PTR BOOT_VEC,OFFSET BOOT_STRAP     ; BOOTSTRAP
        MOV     WORD PTR BOOT_VEC+2,CS
        MOV     WORD PTR HF_TBL_VEC,OFFSET FD_TBL       ; PARAMETER TBL
        MOV     WORD PTR HF_TBL_VEC+2,CS
        STI

        ASSUME  DS:DATA
        MOV     AX,DATA                 ; ESTABLISH SEGMENT
        MOV     DS,AX
        MOV     DISK_STATUS,0           ; RESET THE STATUS INDICATOR
        MOV     HF_NUM,0                ; ZERO COUNT THE DRIVES
        MOV     CMD_BLOCK+1,0           ; DRIVE ZERO, SET VALUE IN BLOCK
        MOV     PORT_OFF,0              ; ZERO CARD OFFSET

        MOV     CX,25H                  ; RETRY COUNT
L4:
        CALL    HD_RESET_1              ; RESET CONTROLLER
        JNC     L7
        LOOP    L4                      ; TRY RESET AGAIN
        JMP     ERROR_EX
L7:
        MOV     CX,1
        MOV     DX,80H

        MOV     AX,1200H                ; CONTROLLER DIAGNOSTICS
        INT     13H
        JNC     P7
        JMP     ERROR_EX
P7:
        MOV     AX,1400H                ; CONTROLLER DIAGNOSTICS
        INT     13H
        JNC     P9
        JMP     ERROR_EX
P9:
        MOV     TIMER_LOW,0             ; ZERO TIMER
        MOV     AX,RESET_FLAG
        CMP     AX,1234H                ; KEYBOARD RESET
        JNE     P8
        MOV     TIMER_LOW,401D          ; SKIP WAIT ON RESET
P8:
        IN      AL,021H                 ; TIMER
        AND     AL,0FEH                 ; ENABLE TIMER
        OUT     021H,AL                 ; START TIMER
P4:
        CALL    HD_RESET_1              ; RESET CONTROLLER
        JC      P10
        MOV     AX,1000H                ; READY
        INT     13H
        JNC     P2
P10:
        MOV     AX,TIMER_LOW
        CMP     AX,446D                 ; 25 SECONDS
        JB      P4
        JMP     ERROR_EX
P2:
        MOV     CX,1
        MOV     DX,80H

        MOV     AX,1100H                ; RECALIBRATE
        INT     13H
        JC      ERROR_EX

        MOV     AX,0900H                ; SET DRIVE PARAMETERS
        INT     13H
        JC      ERROR_EX

        MOV     AX,0C800H               ; DMA TO BUFFER
        MOV     ES,AX                   ; SET SEGMENT
        SUB     BX,BX
        MOV     AX,0F00H                ; WRITE SECTOR BUFFER
        INT     13H
        JC      ERROR_EX

        INC     HF_NUM                  ; DRIVE ZERO RESPONDED

        MOV     DX,213H                 ; EXPANSION BOX
        MOV     AL,0
        OUT     DX,AL                   ; TURN BOX OFF
        MOV     DX,321H                 ; TEST IF CONTROLLER
        IN      AL,DX                   ; ... IS IN THE SYSTEM UNIT
        AND     AL,0FH
        CMP     AL,0FH
        JE      BOX_ON
        MOV     TIMER_LOW,420D          ; CONTROLLER IS IN SYSTEM UNIT
BOX_ON:
        MOV     DX,213H                 ; EXPANSION BOX
        MOV     AL,0FFH
        OUT     DX,AL                   ; TURN BOX ON

        MOV     CX,1                    ; ATTEMPT NEXT DRIVES
        MOV     DX,81H
P3:
        SUB     AX,AX                   ; RESET
        INT     13H
        JC      POD_DONE
        MOV     AX,01100H               ; RECAL
        INT     13H
        JNC     P5
        MOV     AX,TIMER_LOW
        CMP     AX,446D                 ; 25 SECONDS
        JB      P3
        JMP     POD_DONE
P5:
        MOV     AX,0900H                ; INITIALIZE CHARACTERISTICS
        INT     13H
        JC      POD_DONE
        INC     HF_NUM                  ; TALLY ANOTHER DRIVE
        CMP     DX,(80H + S_MAX_FILE - 1)
        JAE     POD_DONE
        INC     DX
        JMP     P3

;----- POD ERROR

ERROR_EX:
        MOV     BP,0FH                  ; POD ERROR FLAG
        SUB     AX,AX
        MOV     SI,AX
        MOV     CX,F17L                 ; MESSAGE CHARACTER COUNT
        MOV     BH,0                    ; PAGE ZERO
OUT_CH:
        MOV     AL,CS:F17[SI]           ; GET BYTE
        MOV     AH,14D                  ; VIDEO OUT
        INT     10H                     ; DISPLAY CHARACTER
        INC     SI                      ; NEXT CHAR
        LOOP    OUT_CH                  ; DO MORE
        STC
POD_DONE:
        CLI
        IN      AL,021H                 ; BE SURE TIMER IS DISABLED
        OR      AL,01H
        OUT     021H,AL
        STI
        CALL    DSBL
        RET

F17     DB      '1701',0DH,0AH
F17L    EQU     $-F17

HD_RESET_1      PROC    NEAR
        PUSH    CX                      ; SAVE REGISTER
        PUSH    DX
        CLC                             ; CLEAR CARRY
        MOV     CX,0100H                ; RETRY COUNT
L6:
        CALL    PORT_1
        OUT     DX,AL                   ; RESET CARD
        CALL    PORT_1
        IN      AL,DX                   ; CHECK STATUS
        AND     AL,2                    ; ERROR BIT
        JZ      R3
        LOOP    L6
        STC
R3:
        POP     DX                      ; RESTORE REGISTER
        POP     CX
        RET
HD_RESET_1      ENDP

DISK_SETUP      ENDP

;----- INT 19 ---------------------------------------------------
;                                                               :
; INTERRUPT 19 BOOT STRAP LOADER                                :
;                                                               :
;  -  THE FIXED DISK BIOS REPLACES THE INTERRUPT 19             :
;     BOOT STRAP VECTOR WITH A POINTER TO THIS BOOT ROUTINE     :
;  -  RESET THE DEFAULT DISK AND DISKETTE PARAMETER VECTORS     :
;  -  THE BOOT BLOCK TO BE READ IN WILL BE ATTEMPTED FROM       :
;     CYLINDER 0 SECTOR 1 OF THE DEVICE.                        :
;  -  THE BOOTSTRAP SEQUENCE IS:                                :
;     > ATTEMPT TO LOAD FROM THE DISKETTE INTO THE BOOT         :
;       LOCATION (0000:7C00) AND TRANSFER CONTROL THERE         :
;     > IF THE DISKETTE FAILS THE FIXED DISK IS TRIED FOR A     :
;       VALID BOOTSTRAP BLOCK. A VALID BOOT BLOCK ON THE        :
;       FIXED DISK CONSISTS OF THE BYTES  055H 0AAH  AS THE     :
;       LAST TWO BTYES OF THE BLOCK                             :
;     > IF THE ABOVE FAILS CONTROL IS PASSED TO RESIDENT BASIC  :
;                                                               ;
;----------------------------------------------------------------

BOOT_STRAP:
        ASSUME  DS:DUMMY,ES:DUMMY
        SUB     AX,AX
        MOV     DX,AX                   ; ESTABLISH SEGMENT

;----- RESET PARAMETER VECTORS

        CLI
        MOV     WORD PTR HF_TBL_VEC, OFFSET FD_TBL
        MOV     WORD PTR HF_TBL_VEC+2, CS
        MOV     WORD PTR DISKETTE_PARAM, OFFSET DISKETTE_TBL
        MOV     WORD PTR DISKETTE_PARAM+2, CS
        STI

;----- ATTEMPT BOOTSTRAP FROM DISKETTE

        MOV     CX,3                    ; SET RETRY COUNT
H1:                                     ; IPL_SYSTEM
        PUSH    CX                      ; SAVE RETRY COUNT
        SUB     DX,DX                   ; DRIVE ZERO
        SUB     AX,AX                   ; RESET THE DISKETTE
        INT     13H                     ; FILE IO CALL
        JC      H2                      ; IF ERROR, TRY AGAIN
        MOV     AX,0201H                ; READ IN THE SINGLE SECTOR

        SUB     DX,DX
        MOV     ES,DX                   ; ESTABLISH SEGMENT
        MOV     BX,OFFSET BOOT_LOCN

        MOV     CX,1                    ; SECTOR 1, TRACK 0
        INT     13H                     ; FILE IO CALL
H2:     POP     CX                      ; RECOVER RETRY COUNT
        JNC     H4                      ; CF SET IF UNSUCCESSFUL READ
        CMP     AH,80H                  ; IF TIME OUT, NO RETRY
        JZ      H5                      ; TRY FIXED DISK
        LOOP    H1                      ; DO IT FOR RETRY TIMES
        JMP     H5                      ; UNABLE TO IPL FROM THE DISKETTE
H4:                                     ; IPL WAS SUCCESSFUL
        JMP     BOOT_LOCN

;----- ATTEMPT BOOTSTRAP FROM FIXED DISK

H5:
        SUB     AX,AX                   ; RESET DISKETTE
        SUB     DX,DX
        INT     13H
        MOV     CX,3                    ; SET RETRY COUNT
H6:                                     ; IPL_SYSTEM
        PUSH    CX                      ; SAVE RETRY COUNT
        MOV     DX,0080H                ; FIXED DISK ZERO
        SUB     AX,AX                   ; RESET THE FIXED DISK
        INT     13H                     ; FILE IO CALL
        JC      H7                      ; IF ERROR, TRY AGAIN
        MOV     AX,0201H                ; READ IN THE SINGLE SECTOR
        SUB     BX,BX
        MOV     ES,BX
        MOV     BX,OFFSET BOOT_LOCN     ; TO THE BOOT LOCATION
        MOV     DX,80H                  ; DRIVE NUMBER
        MOV     CX,1                    ; SECTOR 1, TRACK 0
        INT     13H                     ; FILE IO CALL
H7:     POP     CX                      ; RECOVER RETRY COUNT
        JC      H8
        MOV     AX,WORD PTR BOOT_LOCN+510D
        CMP     AX,0AA55H               ; TEST FOR GENERIC BOOT BLOCK
        JZ      H4
H8:
        LOOP    H6                      ; DO IT FOR RETRY TIMES

;------ UNABLE TO IPL FROM THE DISKETTE OR FIXED DISK

        INT     18H                     ; RESIDENT BASIC

DISKETTE_TBL:

        DB      11001111B               ; SRT=C, HD UNLOAD=0F - 1ST SPEC BYTE
        DB      2                       ; HD LOAD=1, MODE=DMA - 2ND SPEC BYTE
        DB      25H                     ; WAIT AFTER OPN TIL MOTOR OFF
        DB      2                       ; 512 BYTES PER SECTOR
        DB      8                       ; EOT (LAST SECTOR ON TRACK)
        DB      02AH                    ; GAP LENGTH
        DB      0FFH                    ; DTL
        DB      050H                    ; GAP LENGTH FOR FORMAT
        DB      0F6H                    ; FILL BYTE FOR FORMAT
        DB      25                      ; HEAD SETTLE TIME (MILLISECONDS)
        DB      4                       ; MOTOR START TIME (1/8 SECOND)

;----- MAKE SURE THAT ALL HOUSEKEEPING IS DONE BEFORE EXIT

DSBL    PROC    NEAR
        ASSUME  DS:DATA
        PUSH    DS                      ; SAVE SEGMENT
        MOV     AX,DATA
        MOV     DS,AX

        MOV     AH,PORT_OFF
        PUSH    AX                      ; SAVE OFFSET

        MOV     PORT_OFF,0H
        CALL    PORT_3
        SUB     AL,AL
        OUT     DX,AL                   ; RESET INT/DMA MASK
        MOV     PORT_OFF,4H
        CALL    PORT_3
        SUB     AL,AL
        OUT     DX,AL                   ; RESET INT/DMA MASK
        MOV     PORT_OFF,8H
        CALL    PORT_3
        SUB     AL,AL
        OUT     DX,AL                   ; RESET INT/DMA MASK
        MOV     PORT_OFF,0CH
        CALL    PORT_3
        SUB     AL,AL
        OUT     DX,AL                   ; RESET INT/DMA MASK
        MOV     AL,07H
        OUT     DMA+10,AL               ; SET DMA MODE TO DISABLE
        CLI                             ; DISABLE INTERRUPTS
        IN      AL,021H
        OR      AL,020H
        OUT     021H,AL                 ; DISABLE INTERRUPT 5
        STI                             ; ENABLE INTERRUPTS
        POP     AX                      ; RESTORE OFFSET
        MOV     PORT_OFF,AH
        POP     DS                      ; RESTORE SEGMENT
        RET
DSBL    ENDP

;----------------------------------------
;       FIXED DISK BIOS ENTRY POINT     :
;----------------------------------------

DISK_IO PROC    FAR
        ASSUME  DS:NOTHING,ES:NOTHING
        CMP     DL,80H                  ; TEST FOR FIXED HARD DRIVE
        JAE     HARD_DISK               ; YES, HANDLE HERE
        INT     40H                     ; DISKETTE HANDLER
RET_2:
        RET     2                       ; BACK TO CALLER
HARD_DISK:
        ASSUME  DS:DATA
        STI                             ; ENABLE INTERRUPTS
        OR      AH,AH
        JNZ     A3
        INT     40H                     ; RESET NEC WHEN AH=0
        SUB     AH,AH
        CMP     DL,(80H + S_MAX_FILE - 1)
        JA      RET_2
A3:
        CMP     AH,08                   ; GET PARAMETERS IS A SPECIAL CASE
        JNZ     A2
        JMP     GET_PARM_N
A2:
        PUSH    BX                      ; SAVE REGISTERS DURING OPERATION
        PUSH    CX
        PUSH    DX
        PUSH    DS
        PUSH    ES
        PUSH    SI
        PUSH    DI

        CALL    DISK_IO_CONT            ; PERFORM THE OPERATION

        PUSH    AX
        CALL    DSBL                    ; BE SURE DISABLES OCCURRED
        MOV     AX,DATA
        MOV     DS,AX                   ; ESTABLISH SEGMENT
        POP     AX
        MOV     AH,DISK_STATUS          ; GET STATUS FROM OPERATION
        CMP     AH,1                    ; SET THE CARRY FLAG TO INDICATE
        CMC                             ;  SUCCESS OR FAILURE
        POP     DI                      ; RESTORE REGISTERS
        POP     SI
        POP     ES
        POP     DS
        POP     DX
        POP     CX
        POP     BX
        RET     2                       ; THROW AWAY SAVED FLAGS
DISK_IO ENDP

M1      LABEL   WORD                    ; FUNCTION TRANSFER TABLE
        DW      DISK_RESET              ; 000H
        DW      RETURN_STATUS           ; 001H
        DW      DISK_READ               ; 002H
        DW      DISK_WRITE              ; 003H
        DW      DISK_VERF               ; 004H
        DW      FMT_TRK                 ; 005H
        DW      FMT_BAD                 ; 006H
        DW      FMT_DRV                 ; 007H
        DW      BAD_COMMAND             ; 008H
        DW      INIT_DRV                ; 009H
        DW      RD_LONG                 ; 00AH
        DW      WR_LONG                 ; 00BH
        DW      DISK_SEEK               ; 00CH
        DW      DISK_RESET              ; 00DH
        DW      RD_BUFF                 ; 00EH
        DW      WR_BUFF                 ; 00FH
        DW      TST_RDY                 ; 010H
        DW      HDISK_RECAL             ; 011H
        DW      RAM_DIAG                ; 012H
        DW      CHK_DRV                 ; 013H
        DW      CNTLR_DIAG              ; 014H
M1L     EQU     $-M1

SETUP_A PROC    NEAR

        MOV     DISK_STATUS,0           ; RESET THE STATUS INDICATOR
        PUSH    CX                      ; SAVE CX

;----- CALCULATE THE PORT OFFSET

        MOV     CH,DL                   ; SAVE DL
        OR      DL,1
        DEC     DL
        SHL     DL,1                    ; GENERATE OFFSET
        MOV     PORT_OFF,DL             ; STORE OFFSET
        MOV     DL,CH                   ; RESTORE DL
        AND     DL,1

        MOV     CL,5                    ; SHIFT COUNT
        SHL     DL,CL                   ; DRIVE NUMBER (0,1)
        OR      DL,DH                   ; HEAD NUMBER
        MOV     CMD_BLOCK+1,DL
        POP     CX
        RET
SETUP_A ENDP

DISK_IO_CONT    PROC    NEAR
        PUSH    AX
        MOV     AX,DATA
        MOV     DS,AX                   ; ESTABLISH SEGMENT
        POP     AX
        CMP     AH,01H                  ; RETURN STATUS
        JNZ     A4
        JMP     RETURN_STATUS
A4:
        SUB     DL,80H                  ; CONVERT DRIVE NUMBER TO 0 BASED RANGE
        CMP     DL,MAX_FILE             ; LEGAL DRIVE TEST
        JAE     BAD_COMMAND

        CALL    SETUP_A

;----- SET UP COMMAND BLOCK

        DEC     CL                      ; SECTORS 0-16 FOR CONTROLLER
        MOV     CMD_BLOCK+0,0
        MOV     CMD_BLOCK+2,CL          ; SECTOR AND HIGH 2 BITS CYLINDER
        MOV     CMD_BLOCK+3,CH          ; CYLINDER
        MOV     CMD_BLOCK+4,AL          ; INTERLEAVE / BLOCK COUNT
        MOV     AL,CONTROL_BYTE         ; CONTROL BYTE (STEP OPTION)
        MOV     CMD_BLOCK+5,AL
        PUSH    AX                      ; SAVE AX
        MOV     AL,AH                   ; GET INTO LOW BYTE
        XOR     AH,AH                   ; ZERO HIGH BYTE
        SAL     AX,1                    ; *2 FOR TABLE LOOKUP
        MOV     SI,AX                   ; PUT INTO SI FOR BRANCH
        CMP     AX,M1L                  ; TEST WITHIN RANGE
        POP     AX                      ; RESTORE AX
        JNB     BAD_COMMAND
        JMP     WORD PTR CS:[SI + OFFSET M1]
BAD_COMMAND:
        MOV     DISK_STATUS,BAD_CMD     ; COMMAND ERROR
        MOV     AL,0
        RET
DISK_IO_CONT    ENDP

;------------------------------------------------
;       RESET THE DISK SYSTEM  (AH = 000H)      :
;------------------------------------------------

DISK_RESET      PROC    NEAR
        CALL    PORT_1                  ; RESET PORT
        OUT     DX,AL                   ; ISSUE RESET
        CALL    PORT_1                  ; CONTROLLER HARDWARE STATUS
        IN      AL,DX                   ; GET STATUS
        AND     AL,2                    ; ERROR BIT
        JZ      DR1
        MOV     DISK_STATUS,BAD_RESET
        RET
DR1:
        JMP     INIT_DRV                ; SET THE DRIVE PARAMETERS
DISK_RESET      ENDP

;------------------------------------------------
;       DISK STATUS ROUTINE   (AH = 001H)       :
;------------------------------------------------

RETURN_STATUS   PROC    NEAR
        MOV     AL,DISK_STATUS          ; OBTAIN PREVIOUS STATUS
        MOV     DISK_STATUS,0           ; RESET STATUS
        RET
RETURN_STATUS   ENDP

;------------------------------------------------
;       DISK READ ROUTINE   (AH = 002H)         :
;------------------------------------------------

DISK_READ       PROC    NEAR
        MOV     AL,DMA_READ             ; MODE BYTE FOR DMA READ
        MOV     CMD_BLOCK+0,READ_CMD
        JMP     DMA_OPN
DISK_READ       ENDP

;------------------------------------------------
;       DISK WRITE ROUTINE   (AH = 003H)        :
;------------------------------------------------

DISK_WRITE      PROC    NEAR
        MOV     AL,DMA_WRITE            ; MODE BYTE FOR DMA WRITE
        MOV     CMD_BLOCK+0,WRITE_CMD
        JMP     DMA_OPN
DISK_WRITE      ENDP

;------------------------------------------------
;       DISK VERIFY   (AH = 004H)               :
;------------------------------------------------

DISK_VERF       PROC    NEAR
        MOV     CMD_BLOCK+0,CHK_TRK_CMD
        JMP     NDMA_OPN
DISK_VERF       ENDP

;------------------------------------------------
;       FORMATTING   (AH = 005H 006H 007H)      :
;------------------------------------------------

FMT_TRK PROC    NEAR                    ; FORMAT TRACK  (AH = 005H)
        MOV     CMD_BLOCK,FMTTRK_CMD
        JMP     SHORT   FMT_CONT
FMT_TRK ENDP

FMT_BAD PROC    NEAR                    ; FORMAT BAD TRACK  (AH = 006H)
        MOV     CMD_BLOCK,FMTBAD_CMD
        JMP     SHORT   FMT_CONT
FMT_BAD ENDP

FMT_DRV PROC    NEAR                    ; FORMAT DRIVE  (AH = 007H)
        MOV     CMD_BLOCK,FMTDRV_CMD
FMT_DRV ENDP

FMT_CONT:
        MOV     AL,CMD_BLOCK+2          ; ZERO OUT SECTOR FIELD
        AND     AL,11000000B
        MOV     CMD_BLOCK+2,AL
        JMP     NDMA_OPN

;------------------------------------------------
;       GET PARAMETERS   (AH = 8)               :
;------------------------------------------------

GET_PARM_N      LABEL   NEAR
GET_PARM        PROC    FAR             ; GET DRIVE PARAMETERS
        PUSH    DS                      ; SAVE REGISTERS
        PUSH    ES
        PUSH    BX

        ASSUME  DS:DUMMY
        SUB     AX,AX                   ; ESTABLISH ADDRESSING
        MOV     DS,AX
        LES     BX,HF_TBL_VEC
        ASSUME  DS:DATA
        MOV     AX,DATA
        MOV     DS,AX                   ; ESTABLISH SEGMENT

        SUB     DL,80H
        CMP     DL,MAX_FILE             ; TEST WITHIN RANGE
        JAE     G4

        CALL    SETUP_A

        CALL    SW2_OFFS
        JC      G4
        ADD     BX,AX

        MOV     AX,ES:[BX]              ; MAX NUMBER OF CYLINDERS
        SUB     AX,2                    ; ADJUST FOR 0-N
                                        ; AND RESERVE LAST TRACK
        MOV     CH,AL
        AND     AX,0300H                ; HIGH TWO BITS OF CYL
        SHR     AX,1
        SHR     AX,1
        OR      AL,011H                 ; SECTORS
        MOV     CL,AL

        MOV     DH,ES:[BX][2]           ; HEADS
        DEC     DH                      ; 0-N RANGE
        MOV     DL,HF_NUM               ; DRIVE COUNT
        SUB     AX,AX
G5:
        POP     BX                      ; RESTORE REGISTERS
        POP     ES
        POP     DS
        RET     2
G4:
        MOV     DISK_STATUS,INIT_FAIL   ; OPERATION FAILED
        MOV     AH,INIT_FAIL
        SUB     AL,AL
        SUB     DX,DX
        SUB     CX,CX
        STC                             ; SET ERROR FLAG
        JMP     G5
GET_PARM        ENDP

;--------------------------------------------------------
; INITIALIZE DRIVE CHARACTERISTICS                      :
;                                                       :
; FIXED DISK PARAMETER TABLE                            :
;                                                       :
;  -  THE TABLE IS COMPOSED OF A BLOCK DEFINED AS:      :
;                                                       :
;       (1 WORD) - MAXIMUM NUMBER OF CYLINDERS          :
;       (1 BYTE) - MAXIMUM NUMBER OF HEADS              :
;       (1 WORD) - STARTING REDUCED WRITE CURRENT CYL   :
;       (1 WORD) - STARTING WRITE PRECOMPENSATION CYL   :
;       (1 BYTE) - MAXIMUM ECC DATA BURST LENGTH        :
;       (1 BYTE) - CONTROL BYTE (DRIVE STEP OPTION)     :
;                  BIT    7 DISABLE DISK-ACCESS RETRIES :
;                  BIT    7 DISABLE ECC RETRIES         :
;                  BITS 5-3 ZERO                        :
;                  BITS 2-0 DRIVE OPTION                :
;       (1 BYTE) - STANDARD TIME OUT VALUE (SEE BELOW)  :
;       (1 BYTE) - TIME OUT VALUE FOR FORMAT DRIVE      :
;       (1 BYTE) - TIME OUT VALUE FOR CHECK DRIVE       :
;       (4 BYTES)                                       :
;                - RESERVED FOR FUTURE USE              :
;                                                       :
;        - TO DYNAMICALLY DEFINE A SET OF PARAMETERS    :
;          BUILD A TABLE OF VALUES AND PLACE THE        :
;          CORRESPONDING VECTOR INTO INTERRUPT 41.      :
;                                                       :
;       NOTE:                                           :
;               THE DEFAULT TABLE IS VECTORED IN FOR    :
;               AN INTERRUPT 19H (BOOTSTRAP)            :
;                                                       :
;                                                       :
; ON THE CARD SWITCH SETTINGS                           :
;                                                       :
;                 DRIVE 0    DRIVE 1                    :
;               -----------------------                 :
;         ON    :          /          :                 :
;               : -1-  -2- / -3-  -4- :                 :
;         OFF   :          /          :                 :
;               -----------------------                 :
;                                                       :
;                                                       ;
;       TRANSLATION TABLE                               :
;                                                       :
;       1/3  :  2/4  :  TABLE ENTRY                     :
;       ---------------------------                     :
;        ON  :   ON  :      0                           :
;        ON  :  OFF  :      1                           :
;       OFF  :   ON  :      2                           :
;       OFF  :  OFF  :      3                           :
;                                                       :
;--------------------------------------------------------

FD_TBL:

;----- DRIVE TYPE 00

        DW      0306D
        DB      02D
        DW      0306D
        DW      0000D
        DB      0BH
        DB      00H
        DB      0CH                     ; STANDARD
        DB      0B4H                    ; FORMAT DRIVE
        DB      028H                    ; CHECK DRIVE
        DB      0,0,0,0

;----- DRIVE TYPE 01

        DW      0375D
        DB      08D
        DW      0375D
        DW      0000D
        DB      0BH
        DB      05H
        DB      0CH                     ; STANDARD
        DB      0B4H                    ; FORMAT DRIVE
        DB      028H                    ; CHECK DRIVE
        DB      0,0,0,0

;----- DRIVE TYPE 02

        DW      0306D
        DB      06D
        DW      0128D
        DW      0256D
        DB      0BH
        DB      05H
        DB      0CH                     ; STANDARD
        DB      0B4H                    ; FORMAT DRIVE
        DB      028H                    ; CHECK DRIVE
        DB      0,0,0,0

;----- DRIVE TYPE 03

        DW      0306D
        DB      04D
        DW      0306D
        DW      0000D
        DB      0BH
        DB      05H
        DB      0CH                     ; STANDARD
        DB      0B4H                    ; FORMAT DRIVE
        DB      028H                    ; CHECK DRIVE
        DB      0,0,0,0

INIT_DRV        PROC    NEAR

;----- DO DRIVE ZERO

        MOV     CMD_BLOCK+0,INIT_DRV_CMD
        MOV     CMD_BLOCK+1,0
        CALL    INIT_DRV_R
        JC      INIT_DRV_OUT

;----- DO DRIVE ONE

        MOV     CMD_BLOCK+0,INIT_DRV_CMD
        MOV     CMD_BLOCK+1,00100000B
        CALL    INIT_DRV_R
INIT_DRV_OUT:
        RET
INIT_DRV        ENDP

INIT_DRV_R      PROC    NEAR
        ASSUME  ES:CODE
        SUB     AL,AL
        CALL    COMMAND                 ; ISSUE THE COMMAND
        JNC     B1
        RET
B1:
        PUSH    DS                      ; SAVE THE SEGMENT
        ASSUME  DS:DUMMY
        SUB     AX,AX
        MOV     DS,AX                   ; ESTABLISH THE SEGMENT
        LES     BX,HF_TBL_VEC
        POP     DS                      ; RESTORE SEGMENT
        ASSUME  DS:DATA
        CALL    SW2_OFFS
        JC      B3
        ADD     BX,AX

;----- SEND DRIVE PARAMETERS MOST SIGNIFICANT BYTE FIRST

        MOV     DI,1
        CALL    INIT_DRV_S
        JC      B3

        MOV     DI,0
        CALL    INIT_DRV_S
        JC      B3

        MOV     DI,2
        CALL    INIT_DRV_S
        JC      B3

        MOV     DI,4
        CALL    INIT_DRV_S
        JC      B3

        MOV     DI,3
        CALL    INIT_DRV_S
        JC      B3

        MOV     DI,6
        CALL    INIT_DRV_S
        JC      B3

        MOV     DI,5
        CALL    INIT_DRV_S
        JC      B3

        MOV     DI,7
        CALL    INIT_DRV_S
        JC      B3

        MOV     DI,8                    ; DRIVE STEP OPTION
        MOV     AL,ES:[BX + DI]
        MOV     CONTROL_BYTE,AL

        SUB     CX,CX
B5:
        CALL    PORT_1
        IN      AL,DX
        TEST    AL,R1_IOMODE            ; STATUS INPUT MODE
        JNZ     B6
        LOOP    B5
B3:
        MOV     DISK_STATUS,INIT_FAIL   ; OPERATION FAILED
        STC
        RET

B6:
        CALL    PORT_0
        IN      AL,DX
        AND     AL,2                    ; MASK ERROR BIT
        JNZ     B3
        RET
        ASSUME  ES:NOTHING
INIT_DRV_R      ENDP

;----- SEND THE BYTE OUT TO THE CONTROLLER

INIT_DRV_S      PROC    NEAR
        CALL    HD_WAIT_REQ
        JC      D1
        CALL    PORT_0
        MOV     AL,ES:[BX + DI]
        OUT     DX,AL
D1:
        RET
INIT_DRV_S      ENDP

;----------------------------------------
;       READ LONG  (AH = 0AH)           :
;----------------------------------------

RD_LONG         PROC    NEAR
        CALL    CHK_LONG
        JC      G8
        MOV     CMD_BLOCK+0,RD_LONG_CMD
        MOV     AL,DMA_READ
        JMP     SHORT   DMA_OPN
RD_LONG         ENDP

;----------------------------------------
;       WRITE LONG  (AH = 0BH)          :
;----------------------------------------

WR_LONG         PROC    NEAR
        CALL    CHK_LONG
        JC      G8
        MOV     CMD_BLOCK+0,WR_LONG_CMD
        MOV     AL,DMA_WRITE
        JMP     SHORT   DMA_OPN
WR_LONG         ENDP

CHK_LONG        PROC    NEAR
        MOV     AL,CMD_BLOCK+4
        CMP     AL,080H
        CMC
        RET
CHK_LONG        ENDP

;----------------------------------------
;       SEEK   (AH = 0CH)               :
;----------------------------------------

DISK_SEEK       PROC    NEAR
        MOV     CMD_BLOCK,SEEK_CMD
        JMP     SHORT   NDMA_OPN
DISK_SEEK       ENDP

;------------------------------------------------
;       READ SECTOR BUFFER   (AH = 0EH)         :
;------------------------------------------------

RD_BUFF PROC    NEAR
        MOV     CMD_BLOCK+0,RD_BUFF_CMD
        MOV     CMD_BLOCK+4,1           ; ONLY ONE BLOCK
        MOV     AL,DMA_READ
        JMP     SHORT   DMA_OPN
RD_BUFF ENDP

;------------------------------------------------
;       WRITE SECTOR BUFFER   (AH = 0FH)        :
;------------------------------------------------

WR_BUFF PROC    NEAR
        MOV     CMD_BLOCK+0,WR_BUFF_CMD
        MOV     CMD_BLOCK+4,1           ; ONLY ONE BLOCK
        MOV     AL,DMA_WRITE
        JMP     SHORT   DMA_OPN
WR_BUFF ENDP

;------------------------------------------------
;       TEST DISK READY   (AH = 010H)           :
;------------------------------------------------

TST_RDY PROC    NEAR
        MOV     CMD_BLOCK+0,TST_RDY_CMD
        JMP     SHORT   NDMA_OPN
TST_RDY ENDP

;------------------------------------------------
;       RECALIBRATE   (AH = 011H)               :
;------------------------------------------------

HDISK_RECAL     PROC    NEAR
        MOV     CMD_BLOCK+0,RECAL_CMD
        JMP     SHORT   NDMA_OPN
HDISK_RECAL     ENDP

;--------------------------------------------------------
;       CONTROLLER RAM DIAGNOSTICS   (AH = 012H)        :
;--------------------------------------------------------

RAM_DIAG        PROC    NEAR
        MOV     CMD_BLOCK+0,RAM_DIAG_CMD
        JMP     SHORT   NDMA_OPN
RAM_DIAG        ENDP

;------------------------------------------------
;       DRIVE DIAGNOSTICS   (AH = 013H)         :
;------------------------------------------------

CHK_DRV PROC    NEAR
        MOV     CMD_BLOCK+0,CHK_DRV_CMD
        JMP     SHORT   NDMA_OPN
CHK_DRV ENDP

;----------------------------------------------------------
;       CONTROLLER INTERNAL DIAGNOSTICS   (AH = 014H)     :
;----------------------------------------------------------

CNTRL_DIAG      PROC    NEAR
        MOV     CMD_BLOCK+0,CNTRL_DIAG_CMD
CNTRL_DIAG      ENDP

;--------------------------------------------------------
;                   SUPPORT ROUTINES                    :
;--------------------------------------------------------

NDMA_OPN:
        MOV     AL,02H
        CALL    COMMAND                 ; ISSUE THE COMMAND
        JC      G11
        JMP     SHORT   G3
G8:
        MOV     DISK_STATUS,DMA_BOUNDARY
        RET
DMA_OPN:
        CALL    DMA_SETUP               ; SET UP FOR DMA OPERATION
        JC      G8
        MOV     AL,03H
        CALL    COMMAND                 ; ISSUE THE COMMAND
        JC      G11
        MOV     AL,03H
        OUT     DMA+10,AL               ; INITIALIZE THE DISK CHANNEL
G3:
        IN      AL,021H
        AND     AL,0DFH
        OUT     021H,AL
        CALL    WAIT_INT
G11:
        CALL    ERROR_CHK
        RET

;--------------------------------------------------------
; COMMAND                                               :
;       THIS ROUTINE OUTPUTS THE COMMAND BLOCK          :
; INPUT                                                 :
;       AL = CONTROLLER DMA/INTERRUPT REGISTER MASK     :
;                                                       :
;--------------------------------------------------------

COMMAND PROC    NEAR
        MOV     SI,OFFSET CMD_BLOCK
        CALL    PORT_2
        OUT     DX,AL                   ; CONTROLLER SELECT PULSE
        CALL    PORT_3
        OUT     DX,AL
        SUB     CX,CX                   ; WAIT COUNT
        CALL    PORT_1
WAIT_BUSY:
        IN      AL,DX                   ; GET STATUS
        AND     AL,0FH
        CMP     AL,R1_BUSY OR R1_BUS OR R1_REQ
        JE      C1
        LOOP    WAIT_BUSY
        MOV     DISK_STATUS,TIME_OUT
        STC
        RET                             ; ERROR RETURN
C1:
        CLD
        MOV     CX,6                    ; BYTE COUNT
CM3:
        CALL    PORT_0
        LODSB                           ; GET THE NEXT COMMAND BYTE
        OUT     DX,AL                   ; OUT IT GOES
        LOOP    CM3                     ; DO MORE

        CALL    PORT_1                  ; STATUS
        IN      AL,DX
        TEST    AL,R1_REQ
        JZ      CM7
        MOV     DISK_STATUS,BAD_CNTLR
        STC
CM7:
        RET
COMMAND ENDP

;------------------------------------------------
;               SENSE STATUS BYTES              :
;                                               :
; BYTE 0                                        :
;       BIT    7   ADDRESS VALID, WHEN SET      :
;       BIT    6   SPARE, SET TO ZERO           :
;       BITS 5-4   ERROR TYPE                   :
;       BITS 3-0   ERROR CODE                   :
;                                               :
; BYTE 1                                        :
;       BITS 7-6   ZERO                         :
;       BIT    5   DRIVE (0-1)                  :
;       BITS 4-0   HEAD NUMBER                  :
;                                               :
; BYTE 2                                        :
;       BITS 7-5   CYLINDER HIGH                :
;       BITS 4-0   SECTOR NUMBER                :
;                                               :
; BYTE 3                                        :
;       BITS 7-0   CYLINDER LOW                 :
;                                               :
;------------------------------------------------

ERROR_CHK       PROC    NEAR
        ASSUME  ES:DATA
        MOV     AL,DISK_STATUS          ; CHECK IF THERE WAS AN ERROR
        OR      AL,AL
        JNZ     G21
        RET

;----- PERFORM SENSE STATUS

G21:
        MOV     AX,DATA
        MOV     ES,AX                   ; ESTABLISH SEGMENT
        SUB     AX,AX
        MOV     DI,AX
        MOV     CMD_BLOCK+0,SENSE_CMD
        SUB     AL,AL
        CALL    COMMAND                 ; ISSUE SENSE STATUS COMMAND
        JC      SENSE_ABORT             ; CANNOT RECOVER
        MOV     CX,4
G22:
        CALL    HD_WAIT_REQ
        JC      G24
        CALL    PORT_0
        IN      AL,DX
        MOV     ES:HD_ERROR[DI],AL      ; STORE AWAY SENSE BYTES
        INC     DI
        CALL    PORT_1
        LOOP    G22
        CALL    HD_WAIT_REQ
        JC      G24
        CALL    PORT_0
        IN      AL,DX
        TEST    AL,2
        JZ      STAT_ERR
SENSE_ABORT:
        MOV     DISK_STATUS,SENSE_FAIL
G24:
        STC
        RET
ERROR_CHK       ENDP

T_0     DW      TYPE_0
T_1     DW      TYPE_1
T_2     DW      TYPE_2
T_3     DW      TYPE_3

STAT_ERR:
        MOV     BL,ES:HD_ERROR          ; GET ERROR BYTE
        MOV     AL,BL
        AND     AL,0FH
        AND     BL,00110000B            ; ISOLATE TYPE
        SUB     BH,BH
        MOV     CL,3
        SHR     BX,CL                   ; ADJUST
        JMP     WORD PTR CS:[BX + OFFSET T_0]
        ASSUME  ES:NOTHING

TYPE0_TABLE     LABEL   BYTE
        DB      0,BAD_CNTLR,BAD_SEEK,BAD_CNTLR,TIME_OUT,0,BAD_CNTLR
        DB      0,BAD_SEEK
TYPE0_LEN       EQU     $-TYPE0_TABLE
TYPE1_TABLE     LABEL   BYTE
        DB      BAD_ECC,BAD_ECC,BAD_ADDR_MARK,0,RECORD_NOT_FND
        DB      BAD_SEEK,0,0,DATA_CORRECTED,BAD_TRACK
TYPE1_LEN       EQU     $-TYPE1_TABLE
TYPE2_TABLE     LABEL   BYTE
        DB      BAD_CMD,BAD_ADDR_MARK
TYPE2_LEN       EQU     $-TYPE2_TABLE
TYPE3_TABLE     LABEL   BYTE
        DB      BAD_CNTLR,BAD_CNTLR,BAD_ECC
TYPE3_LEN       EQU     $-TYPE3_TABLE

;----- TYPE 0 ERROR

TYPE_0:
        MOV     BX,OFFSET TYPE0_TABLE
        CMP     AL,TYPE0_LEN            ; CHECK IF ERROR IS DEFINED
        JAE     UNDEF_ERR_L
        XLAT    CS:TYPE0_TABLE          ; TABLE LOOKUP
        MOV     DISK_STATUS,AL          ; SET ERROR CODE
        RET

;----- TYPE 1 ERROR

TYPE_1:
        MOV     BX,OFFSET TYPE1_TABLE
        MOV     CX,AX
        CMP     AL,TYPE1_LEN            ; CHECK IF ERROR IS DEFINED
        JAE     UNDEF_ERR_L
        XLAT    CS:TYPE1_TABLE          ; TABLE LOOKUP
        MOV     DISK_STATUS,AL          ; SET ERROR CODE
        AND     CL,08H                  ; CORRECTED ECC
        CMP     CL,08H
        JNZ     G30

;----- OBTAIN ECC ERROR BURST LENGTH

        MOV     CMD_BLOCK+0,RD_ECC_CMD
        SUB     AL,AL
        CALL    COMMAND
        JC      G30
        CALL    HD_WAIT_REQ
        JC      G30
        CALL    PORT_0
        IN      AL,DX
        MOV     CL,AL
        CALL    HD_WAIT_REQ
        JC      G30
        CALL    PORT_0
        IN      AL,DX
        TEST    AL,01H
        JZ      G30
        MOV     DISK_STATUS,BAD_CNTLR
        STC
G30:
        MOV     AL,CL
        RET

;----- TYPE 2 ERROR

TYPE_2:
        MOV     BX,OFFSET TYPE2_TABLE
        CMP     AL,TYPE2_LEN            ; CHECK IF ERROR IS DEFINED
        JAE     UNDEF_ERR_L
        XLAT    CS:TYPE1_TABLE          ; TABLE LOOKUP
        MOV     DISK_STATUS,AL          ; SET ERROR CODE
        RET

;----- TYPE 3 ERROR

TYPE_3:
        MOV     BX,OFFSET TYPE3_TABLE
        CMP     AL,TYPE3_LEN
        JAE     UNDEF_ERR_L
        XLAT    CS:TYPE3_TABLE
        MOV     DISK_STATUS,AL
        RET

UNDEF_ERR_L:
        MOV     DISK_STATUS,UNDEF_ERR
        RET

HD_WAIT_REQ     PROC    NEAR
        PUSH    CX
        SUB     CX,CX
        CALL    PORT_1
L1:
        IN      AL,DX
        TEST    AL,R1_REQ
        JNZ     L2
        LOOP    L1
        MOV     DISK_STATUS,TIME_OUT
        STC
L2:
        POP     CX
        RET
HD_WAIT_REQ     ENDP

;--------------------------------------------------------
; DMA_SETUP                                             :
;       THIS ROUTINE SETS UP FOR DMA OPERATIONS.        :
; INPUT                                                 :
;       (AL) = MODE BYTE FOR THE DMA                    :
;       (ES:BX) = ADDRESS TO READ/WRITE THE DATA        :
; OUTPUT                                                :
;       (AX) DESTROYED                                  :
;--------------------------------------------------------
DMA_SETUP       PROC    NEAR
        PUSH    AX
        MOV     AL,CMD_BLOCK+4
        CMP     AL,81H                  ; BLOCK COUNT OUT OF RANGE
        POP     AX
        JB      J1
        STC
        RET
J1:
        PUSH    CX                      ; SAVE THE REGISTER
        CLI                             ; NO MORE INTERRUPTS
        OUT     DMA+12,AL               ; SET THE FIRST/LAST F/F
        PUSH    AX
        POP     AX
        OUT     DMA+11,AL               ; OUTPUT THE MODE BYTE
        MOV     AX,ES                   ; GET THE ES VALUE
        MOV     CL,4                    ; SHIFT COUNT
        ROL     AX,CL                   ; ROTATE LEFT
        MOV     CH,AL                   ; GET THE HIGHEST NYBBLE OF ES TO CH
        AND     AL,0F0H                 ; ZERO THE LOW NYBBLE FROM SEGMENT
        ADD     AX,BX                   ; TEST FOR CARRY FROM ADDITION
        JNC     J33
        INC     CH                      ; CARRY MEANS HIGH 4 BITS MUST BE INC
J33:
        PUSH    AX                      ; SAVE START ADDRESS
        OUT     DMA+6,AL                ; OUTPUT LOW ADDRESS
        MOV     AL,AH
        OUT     DMA+6,AL                ; OUTPUT HIGH ADDRESS
        MOV     AL,CH                   ; GET HIGH 4 BITS
        AND     AL,0FH
        OUT     DMA_HIGH,AL             ; OUTPUT THE HIGH 4 BITS TO PAGE REG

;------ DETERMINE COUNT

        MOV     AL,CMD_BLOCK+4          ; RECOVER BLOCK COUNT
        SHL     AL,1                    ; MULTIPLY BY 512 BYTES PER SECTOR
        DEC     AL                      ;   AND DECREMENT VALUE BY ONE
        MOV     AH,AL
        MOV     AL,0FFH

;------ HANDLE READ AND WRITE LONG (516D BYTE BLOCKS)

        PUSH    AX                      ; SAVE REGISTER
        MOV     AL,CMD_BLOCK+0          ; GET COMMAND
        CMP     AL,RD_LONG_CMD
        JE      ADD4
        CMP     AL,WR_LONG_CMD
        JE      ADD4
        POP     AX                      ; RESTORE REGISTER
        JMP     SHORT   J20
ADD4:
        POP     AX                      ; RESTORE REGISTER
        MOV     AX,516D                 ; ONE BLOCK (512) PLUS 4 BYTES ECC
        PUSH    BX
        SUB     BH,BH
        MOV     BL,CMD_BLOCK+4
        PUSH    DX
        MUL     BX                      ; BLOCK COUNT TIMES 516
        POP     DX
        POP     BX
        DEC     AX                      ; ADJUST
J20:

        PUSH    AX                      ; SAVE COUNT VALUE
        OUT     DMA+7,AL                ; LOW BYTE OF COUNT
        MOV     AL,AH
        OUT     DMA+7,AL                ; HIGH BYTE OF COUNT
        STI                             ; INTERRUPTS BACK ON
        POP     CX                      ; RECOVER COUNT VALUE
        POP     AX                      ; RECOVER ADDRESS VALUE
        ADD     AX,CX                   ; ADD, TEST FOR 64K OVERFLOW
        POP     CX                      ; RECOVER REGISTER
        RET                     ; RETURN TO CALLER, CFL SET BY ABOVE IF ERROR
DMA_SETUP       ENDP

;------------------------------------------------
; WAIT_INT                                      :
;       THIS ROUTINE WAITS FOR THE FIXED DISK   :
;       CONTROLLER TO SIGNAL THAT AN INTERRUPT  :
;       HAS OCCURRED.                           :
;------------------------------------------------
WAIT_INT        PROC    NEAR
        STI                             ; TURN ON INTERRUPTS
        PUSH    BX                      ; PRESERVE REGISTERS
        MOV     CX
        PUSH    ES
        PUSH    SI
        PUSH    DS
        ASSUME  DS:DUMMY
        SUB     AX,AX
        MOV     DS,AX                   ; ESTABLISH SEGMENT
        LES     SI,HF_TBL_VEC
        ASSUME  DS:DATA
        POP     DS

;----- SET TIMEOUT VALUES

        SUB     BH,BH
        MOV     BL,BYTE PTR ES:[SI][9]          ; STANDARD TIME OUT
        MOV     AH,CMD_BLOCK
        CMP     AH,FMTDRV_CMD
        JNZ     W5
        MOV     BL,BYTE PTR ES:[SI][0AH]        ; FORMAT DRIVE
        JMP     SHORT   W4
W5:     CMP     AH,CHR_DRV_CMD
        JNZ     W4
        MOV     BL,BYTE PTR ES:[SI][0BH]        ; CHECK DRIVE
W4:
        SUB     CX,CX

;----- WAIT FOR INTERRUPT

W1:
        CALL    PORT_1
        IN      AL,DX
        AND     AL,020H
        CMP     AL,020H                 ; DID INTERRUPT OCCUR
        JZ      W2
        LOOP    W1                      ; INNER LOOP
        DEC     BX
        JNZ     W1                      ; OUTER LOOP
        MOV     DISK_STATUS,TIME_OUT
W2:
        CALL    PORT_0
        IN      AL,DX
        AND     AL,2                    ; ERROR BIT
        OR      DISK_STATUS,AL          ; SAVE
        CALL    PORT_3                  ; INTERRUPT MASK REGISTER
        XOR     AL,AL                   ; ZERO
        OUT     DX,AL                   ; RESET MASK
        POP     SI                      ; RESTORE REGISTERS
        POP     ES
        POP     CX
        POP     BX
        RET
WAIT_INT        ENDP

HD_INT  PROC    NEAR
        PUSH    AX
        MOV     AL,EOI                  ; END OF INTERRUPT
        OUT     INT_CTL_PORT,AL
        MOV     AL,07H                  ; SET DMA MODE TO DISABLE
        OUT     DMA+10,AL
        IN      AL,021H
        OR      AL,020H
        OUT     021H,AL
        POP     AX
        IRET
HD_INT  ENDP

;----------------------------------------
; PORTS                                 :
;       GENERATE PROPER PORT VALUE      :
;       BASED ON THE PORT OFFSET        :
;----------------------------------------

PORT_0  PROC    NEAR
        MOV     DX,HF_PORT              ; BASE VALUE
        PUSH    AX
        SUB     AH,AH
        MOV     AL,PORT_OFF             ; ADD IN THE OFFSET
        ADD     DX,AX
        POP     AX
        RET
PORT_0  ENDP

PORT_1  PROC    NEAR
        CALL    PORT_0
        INC     DX                      ; INCREMENT TO PORT ONE
        RET
PORT_1  ENDP

PORT_2  PROC    NEAR
        CALL    PORT_1
        INC     DX                      ; INCREMENT TO PORT TWO
        RET
PORT_2  ENDP

PORT_3  PROC    NEAR
        CALL    PORT_2
        INC     DX                      ; INCREMENT TO PORT THREE
        RET
PORT_3  ENDP

;------------------------------------------------
; SW2_OFFS                                      :
;       DETERMINE PARAMETER TABLE OFFSET        :
;       USING CONTROLLER PORT TWO AND           :
;       DRIVE NUMBER SPECIFIER (0-1)            :
;------------------------------------------------

SW2_OFFS        PROC    NEAR
        CALL    PORT_2
        IN      AL,DX                   ; READ PORT 2
        PUSH    AX
        CALL    PORT_1
        IN      AL,DX
        AND     AL,2                    ; CHECK FOR ERROR
        POP     AX
        JNZ     SW2_OFFS_ERR
        MOV     AH,CMD_BLOCK+1
        AND     AH,00100000B            ; DRIVE 0 OR 1
        JNZ     SW2_AND
        SHR     AL,1                    ; ADJUST
        SHR     AL,1
SW2_AND:
        AND     AL,011B                 ; ISOLATE
        MOV     CL,4
        SHL     AL,CL                   ; ADJUST
        SUB     AH,AH
        RET
SW2_OFFS_ERR:
        STC
        RET
SW2_OFFS        ENDP

        DB      '08/16/82'              ; RELEASE MARKER

END_ADDRESS     LABEL   BYTE
CODE    ENDS
        END