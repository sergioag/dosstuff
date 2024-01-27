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

%ifndef __MACROS_INC__
%define __MACROS_INC__

%macro PUSHA 0
%ifdef V20
	pusha
%else
	push	ax
	push	cx
	push	dx
	push	bx
	push	bp
	push	si
	push	di
%endif
%endmacro

%macro POPA 0
%ifdef V20
	popa
%else
	pop	di
	pop	si
	pop	bp
	pop	bx
	pop	dx
	pop	cx
	pop	ax
%endif
%endmacro

%macro SH 3
%if %3 == 1
	%1	%2, 1
%else
	%ifdef V20
		%1	%2,%3
	%else
		%if %3 == 2
		%assign i 2
		%elif %3 == 3
		%assign i 3
		%elif %3 == 4
		%assign i 4
		%else
		%error Undefined shift count %1 %2 %3
		%endif
		%rep i
			%1	%2, 1
		%endrep
	%endif
%endif
%endmacro

%macro SHL 2
	SH shl, %1, %2
%endmacro

%macro SHR 2
	SH shr, %1, %2
%endmacro

%endif ; ! __MACROS_INC__
