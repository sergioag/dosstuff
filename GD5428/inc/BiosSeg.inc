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

%ifndef __BIOSSEG_INC__
%define __BIOSSEG_INC__

INSTALLED_HW		equ		410h

CURR_VIDEO_MODE		EQU		449h
NUM_COLUMNS		EQU		44Ah
PAGE_SIZE		EQU		44Ch
CURR_PAGE_START		EQU		44Eh
CURSOR_POSN		EQU		450h
CURSOR_TYPE		EQU		460h
CURR_PAGE		EQU		462h
CRTC_BASE		EQU		463h
CURR_MODE_SELECT	EQU		465h
CGA_PALETTE_REG		EQU		466h
RESET_FLAG		equ		472h
ROWS_MINUS_ONE		EQU		484h
CHAR_HEIGHT		EQU		485h
VIDEO_CONTROL		EQU		487h
VIDEO_SWITCHES		EQU		488h
VIDEO_MODE_CONTROL	EQU		489h
VIDEO_COMB_INDEX	EQU		48Ah
VIDEO_SAVE_PTR		EQU		4A8h
PRINT_SCREEN_STAT	EQU		500h

%endif ; ! __BIOSSEG_INC__
