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

%ifndef __PORTS_INC__
%define __PORTA_INC__

POS102			equ	102h			; POS102 register (VGA subsystem enable)
MONO_CRTC_INDEX		equ	3B4h			; Monochrome CRTC Index Register
MONO_CRT_CONTROL	equ	3B8h			; Monochrome CRT Control Port
ATTR_CONTROL_INDEX	equ	3C0h			; Attribute Controller Index Register
MISC_OUTPUT		equ	3C2h			; Misc output register (write)
SLEEP_REG_READ		equ	3C3h			; Adapter Sleep Register (read only)
SEQ_INDEX		equ	3C4h			; Sequencer Index register
DAC_MASK_REG		equ	3C6h			; DAC Pixel Mask register
PIXEL_ADDRESS		equ	3C7h			; Pixel Address (read) / DAC state (write)
PIXEL_ADDR_WR_MODE	equ	3C8h			; Pixel Address Write Mode register
FEATURE_CONTROL		equ	3CAh			; Feature Control
MISC_OUTPUT_READ	equ	3CCh			; Misc output register (read)
INDEX_REG		equ	3CEh			; Graphics Controller Index register
COLOR_CRTC_INDEX	equ	3D4h			; Color CRTC Index Register
MODE_SELECT_REG		equ	3D8h			; Mode Select Register (CGA)
COLOR_SELECT_REG	equ	3D9h			; Color Select Register (CGA)
SLEEP_REG		equ	46E8h			; Adapter Sleep Register (write only)

%endif ; ! __PORTS_INC__
