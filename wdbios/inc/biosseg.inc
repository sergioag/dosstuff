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

%ifndef __BIOSSEG_INC__
%define __BIOSSEG_INC__

INT_0AH_IRQ2_OFFSET	EQU	28H
INT_0AH_IRQ2_SEGMENT	EQU	2AH
INT_0DH_IRQ5_OFFSET	EQU	34H
INT_0DH_IRQ5_SEGMENT	EQU	36H
INT_13H_VECTOR		EQU	4CH
INT_13H_OFFSET		EQU	4CH
INT_13H_SEGMENT		EQU	4EH
INT_19H_OFFSET		EQU	64H
INT_19H_SEGMENT		EQU	66H
INT_40H_OFFSET		EQU	100H
INT_40H_SEGMENT		EQU	102H
INT_41H_VECTOR		EQU	104H
INT_41H_OFFSET		EQU	104H
INT_41H_SEGMENT		EQU	106H
INT_46H_OFFSET		EQU	118H
INT_46H_SEGMENT		EQU	11AH
INT_47H_OFFSET		EQU	11CH
INT_47H_SEGMENT		EQU	11EH

;----- Start of fixed disk data - second controller -----
SECOND_DISK_AREA	EQU	120H
INT_48H_OFFSET		EQU	120H
SECOND_FIXED_DISKS	EQU	121H		; Contains the number of drives
						; for the second controller
INT_48H_SEGMENT		EQU	122H

;----- End of fixed disk data - second controller -----

DISK_AREA_PTR		EQU	442H		; During interrupt handling, contains
						; address of active drive's data area,
						; either FIRST_DISK_AREA or
						; SECOND_DISK_AREA
LAB_0000_0442		EQU	442H
LAB_0000_0443		EQU	443H

SAVED_INT13H_CX		EQU	444H		; Input value of CX during Int 13H call
SAVED_INT13H_CL		EQU	444H
SAVED_INT13H_CH		EQU	445H
SAVED_INT13H_AL		EQU	446H		; Input value of AL during Int 13H call
LAB_0000_0447		EQU	447H
TIMER_TICKS		EQU	46CH		; Updated every 55ms by timer handler
POST_RESET_FLAG		EQU	472H		; Specifies action of BIOS at POST
						; 0000: Cold boot (full test)
						; 1234: Warm boot (skips memory test)

;----- Start of fixed disk data - first controller -----
FIRST_DISK_AREA		EQU	474H
LAST_OPERATION_FIXED_DISK EQU	474H
TOTAL_FIXED_DISKS	EQU	475H		; Contains the total number of
						; fixed disks, for both controllers

;----- End of fixed disk data - first controller ------

BOOT_SECTOR_OFFSET	EQU	7C00H
BOOT_SECTOR_MAGIC_OFF	EQU	7DFEH

%endif ; ! __BIOSSEG_INC__
