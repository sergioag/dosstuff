; BIOS for Cirrus Logic CL-GD5428
; Copyright (c) 2024, Sergio Aguayo
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

%ifndef __EEPROM_INC__
%define __EEPROM_INC__

;-------------------------------------------------------------------------------
; WriteEEPROMCommand
;-------------------------------------------------------------------------------
; Writes a 10-bit command command to the XL93C64 EEPROM.
;
; Input:
;  AH = Starting value of the SR8 EEPROM register.
;  BX = Data to write. Only the higher 10 bits are used (15:6)
;  DX = Sequencer Data Port (3C5h)
;
; Output:
;  AL = Current state of SR8 register.
;  BX has its higher 10 bits shifted out left.
;-------------------------------------------------------------------------------
WriteEEPROMCommand:
	push	cx				; Save register

	mov	cx,0Ah				; Number of bits to write
	mov	al,ah				; Get original value of register
	or	al,33h				; Set Enable/Latch ESYNC/EVIDEO, enable EEPROM and CS high

.writeLoop:
	shl	bx,1				; Carry out bit 15
	jnc	.bitUnset			; If carried bit was 0
	or	al,8				; If carried bit was 1

.bitUnset:
	call	WritePort16Times		; Write out the bit
	or	al,4				; Set SK high
	call	WritePort16Times		; Do it

	and	al,0F3h				; Disable DI and SK
	loop	.writeLoop			; Loop while bits left

	pop	cx				; Restore register
	ret

;-------------------------------------------------------------------------------
; SaveToEEPROM
;-------------------------------------------------------------------------------
; Writes the specified configuration word to EEPROM, if support is available.
;
; Input:
;  BX = Word to write to EEPROM
;
; Output:
;  AX,BX,DX destroyed
;-------------------------------------------------------------------------------
SaveConfigToEEPROM:
	cs test	[LAB_1036],BYTE 80h		; Is EEPROM support disabled?
	jnz	.skipEEPROM			; Yes, skip this

	push	bx				; Save config word

	mov	bx,434Ch			; Data to write: EEPROM magic
	mov	ax,5000h			; Read command, address = 0
	call	WriteEEPROM			; Write to EEPROM

	pop	bx				; Retrieve config word
	mov	ax,5040h			; Read command, address = 1
	call	WriteEEPROM			; Write to EEPROM
.skipEEPROM:
	ret

;-------------------------------------------------------------------------------
; WriteEEPROMData
;-------------------------------------------------------------------------------
; Writes a data word to the EEPROM (16 bits long).
;
; Input:
;  AL = Starting SR8 value
;  BX = EEPROM data word
;  DX = Sequencer Data Port (3C5h)
;
; Output:
;  AL = Last SR8 value
;-------------------------------------------------------------------------------
WriteEEPROMData:
	push	cx				; Save register

	mov	cx,16				; Number of bits to write

.writeLoop:
	and	al,0F3h				; Disable DI and SK

	rcl	bx,1				; Carry out bit 15
	jnc	.bitUnset			; If carried bit was 0
	or	al,8				; If carried bit was 1

.bitUnset:
	call	WritePort16Times		; Write out the bit
	or	al,4				; Set SK high
	call	WritePort16Times		; Do it

	in	al,dx				; Get current status
	loop	.writeLoop			; Loop while bits left to write

	pop	cx				; Restore register
	ret

;-------------------------------------------------------------------------------
; ReadConfigFromEEPROM
;-------------------------------------------------------------------------------
; Loads the config from EEPROM, if such support is enabled, and calls the BIOS
; to indicate that it's ready.
;
; Input:
;  Nothing
;
; Output:
;  Nothing
;-------------------------------------------------------------------------------
ReadConfigFromEEPROM:
	cs test	[LAB_1036],BYTE 80h		; Is EEPROM support disabled?
	jnz	.skipEEPROM			; Yes, skip this.

	call	SelectEEPROM
	mov	bx,6000h			; EEPROM Read, Addr = 0
	call	WriteEEPROMCommand		; Write command
	call	ReadEEPROMWord			; Read the data
	push	bx				; Save the value
	call	UnselectEEPROM

	call	SelectEEPROM
	mov	bx,6040h			; EEPROM Read, Addr = 1
	call	WriteEEPROMCommand		; Write command
	call	ReadEEPROMWord			; Read data
	push	bx				; Save value
	call	UnselectEEPROM

	pop	bx				; BX = Value in EEPROM[1]
	pop	ax				; AX = Value in EEPROM[0]

	cmp	ax,434Ch			; Check magic number
	jnz	.skipEEPROM			; Skip if incorrect value

	mov	dx,SEQ_INDEX			; Address sequencer
	mov	al,9				; Address SR9, Scratchpad 0
	call	ReadIndirectRegister		; Read it into AH

	and	bl,0FCh				; Preserve everything except reserved bits
	and	ah,3				; Clear everything except reserved bits
	or	ah,bl				; Merge both values
	out	dx,ax				; Update SR9

	inc	ax				; Address SRA, Scratchpad 1
	call	ReadIndirectRegister		; Read it into AH
	and	ah,0BFh				; Preserve everything except bit 6
	and	bh,40h				; Clear everything except bit 6
	or	ah,bh				; Merge both values
	out	dx,ax				; Update SRA

.skipEEPROM:
	mov	ax,448Eh			; Indicate ready
	int	15h				; Call extension
	ret

;-------------------------------------------------------------------------------
; WriteEEPROM
;-------------------------------------------------------------------------------
; Writes an a word to EEPROM storage
;
; Input:
;  AX = Write command. Bits are:
;	15:13 = 0101 (Write command)
;	12:6 = EEPROM Address
;	5:0 = Ignored
;  BX = Data to write. All 16 bits are valid.
;
; Output:
;  AX,BX,DX destroyed
;-------------------------------------------------------------------------------
WriteEEPROM:
	push	cx
	push	bx
	push	ax

	call	SelectEEPROM

	mov	bx,4C00h			; EEPROM command: Write enable
	call	WriteEEPROMCommand		; Do it

	call	ToggleEEPROMCS

	pop	bx				; Get write command
	call	WriteEEPROMCommand		; Do it

	pop	bx				; Get data
	call	WriteEEPROMData			; Write it

	call	ToggleEEPROMCS

	xor	cx,cx
.1:
	in	al,dx				; Read SR8
	test	al,80h				; Check for BUSY
	loopz	.1

	call	UnselectEEPROM
	pop	cx
	ret

;-------------------------------------------------------------------------------
; ToggleEEPROMCS
;-------------------------------------------------------------------------------
; Sets the EEPROM for reading data from it and toggles the CS, the final state
; being high.
;
; Input:
;  AL = Initial state of SR8
;  DX = Sequencer Data Port (3C5h)
;
; Output:
;  AL = Updated SR8 value
;-------------------------------------------------------------------------------
ToggleEEPROMCS:
	and	al,0F3h				; Clear DI and SK
	call	WritePort16Times		; Update SR8

	and	al,0FEh				; CS low
	call	WritePort16Times		; Update SR8

	or	al,1				; CS high
	call	WritePort16Times		; Update SR8

	ret

;-------------------------------------------------------------------------------
; WritePort16Times
;-------------------------------------------------------------------------------
; Writes the specified I/O port 16 times with the same 8 bit value.
;
; Input:
;  DX = I/O port to write to
;  AL = Value to write. The same value is used for all writes.
;
; Output:
;  Nothing
;-------------------------------------------------------------------------------
WritePort16Times:
	push	cx
	mov	cx,10h			; Repeat count
.1:
	out	dx,al			; Write to port
	loop	.1			; Loop if still need to

	pop	cx
	ret

;-------------------------------------------------------------------------------
; ReadEEPROMWord
;-------------------------------------------------------------------------------
; Reads a 16 bit value from the EEPROM. EEPROM setup must be done beforehand
; as we will just read whatever the EEPROM wants to send us.
;
; Input:
;  AH = Starting value of the EEPROM config register
;  DX = Sequencer Data Port (3C5h)
;
; Output:
;  BX = Data read from EEPROM
;  AL destroyed. CF may be modified.
;-------------------------------------------------------------------------------
ReadEEPROMWord:
	push	cx			; Save register

	mov	cx,10h			; Move 16 bits
.1:
	mov	al,ah			; Work on a copy of the value

	and	al,40h			; Clear all except MCS16
					; SK is now low
	or	al,33h			; Set Enable/Latch ESYNC/EVIDEO, enable EEPROM and CS high
	call	WritePort16Times	; Do it

	or	al,4			; SK high
	call	WritePort16Times	; Do it

	in	al,dx			; Read EEPROM status

	rcl	al,1			; EEPROM data to carry
	rcl	bx,1			; Rotate carry into BX
	shr	al,1			; Restore positions of bits in AL

	loop	.1			; Loop until no more bits left

	pop	cx			; Restore register
	ret

;-------------------------------------------------------------------------------
; SelectEEPROM
;-------------------------------------------------------------------------------
; Selects the EEPROM chip so operation can happen with it.
;
; Input:
;  Nothing
;
; Output:
;  AH = Starting value of SR8 register
;  AL,DX destroyed
;-------------------------------------------------------------------------------
SelectEEPROM:
	mov	dx,SEQ_INDEX			; Address SR registers
	mov	al,8				; SR8: EEPROM control
	out	dx,al				; Latch it

	inc	dx				; Point to sequencer data
	in	al,dx				; Read SR8

	mov	ah,al				; Register data in AH

	or	al,20h				; Latch ESYNC and EVIDEO inputs
	call	WritePort16Times		; Do it

	or	al,12h				; Enable EEPROM interface
	call	WritePort16Times		; Do it

	or	al,1				; Select EEPROM
	call	WritePort16Times		; Do it
	ret

;-------------------------------------------------------------------------------
; UnselectEEPROM
;-------------------------------------------------------------------------------
; Unselect the EEPROM. It can no longer be controlled until it is selected again.
;
; Input:
;  AH = Starting value of SR8 register
;  DX = Sequencer Data Port (3C5h)
;
; Output:
;  AL destroyed
;-------------------------------------------------------------------------------
UnselectEEPROM:
	mov	al,ah				; Work on a copy of the value

	and	al,40h				; Clear everything except "disable MCS16 bit"
	or	al,33h				; Set latch, enable, and CS
	call	WritePort16Times		; Do it

	and	al,0FEh				; Set CS low
	call	WritePort16Times		; Do it
	call	WritePort16Times

	and	al,0EDh				; Disable EEPROM
	call	WritePort16Times		; Do it

	and	al,0DFh				; Unlatch ESYNC/EVIDEO
	call	WritePort16Times		; Do it

	mov	al,ah				; Get the original value
	out	dx,al				; Write it
	ret

%endif ; !__EEPROM_INC__
