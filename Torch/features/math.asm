; +-----------------------------------------------------------------------+
; |                     GNU GENERAL PUBLIC LICENSE                        |
; |                        Version 3, 29 June 2007                        |
; |                                                                       |
; | Copyright (C) 2007 Free Software Foundation, Inc. < https://fsf.org/> |
; | Everyone is permitted to copy and distribute verbatim copies          |
; | of this license document, but changing it is not allowed.             |
; |                                                                       |
; |  								  ...                                 |
; |                                                                       |
; | 					Copyright (C) 2024 Rohan Bharatia                 |
; +-----------------------------------------------------------------------+

; Return a random integer between low and high
os_get_random:
    push dx
	push bx
	push ax

	sub bx, ax     ; Requires a number between 0 and (high - low)
	call .generate_random
	mov dx, bx
	add dx, 1
	mul dx
	mov cx, dx

	pop ax
	pop bx
	pop dx
	add cx, ax     ; Add the low offset back
	ret

.generate_random:
	push dx
	push bx

	mov ax, [os_random_seed]
	mov dx, 0x7383 ; The magic number (similar to random.org)
	mul dx		   ; DX:AX = AX * DX
	mov [os_random_seed], ax

	pop bx
 	pop dx
	ret

; Converts binary coded decimal number to an integer
os_bcd_to_int:
    pusha

	mov bl, al	   ; Store entire number for now

	and ax, 0Fh	   ; Zero-out high bits
	mov cx, ax	   ; CH/CL = lower BCD number, zero extended

	shr bl, 4	   ; Move higher BCD number into lower bits, zero fill msb
	mov al, 10
	mul bl		   ; AX = 10 * BL

	add ax, cx	   ; Add lower BCD to 10 * higher
	mov [.tmp], ax

	popa
	mov ax, [.tmp] ; And return it in AX
	ret

	.tmp	dw 0

; Multiply value in DX:AX by -1
os_long_int_negate:
	neg ax
	adc dx, 0
	neg dx
	ret
