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

; Waits for keypress and returns it
os_wait_for_key:
    pusha

	mov ax, 0
	mov ah, 10h		   ; BIOS call to wait for key
	int 16h

	mov [.tmp_buf], ax ; Store keypress

	popa			   ; Restore all other registers
	mov ax, [.tmp_buf]
	ret

	.tmp_buf	dw 0

; Scans keyboard for input, and doesn't waits
os_check_for_key:
    pusha

	mov ax, 0
	mov ah, 1		   ; BIOS call to check for key
	int 16h

	jz .nokey		   ; If no key, skip to end

	mov ax, 0		   ; If key, get it from buffer
	int 16h

	mov [.tmp_buf], ax ; Store resulting keypress

	popa			   ; Restore all other registers
	mov ax, [.tmp_buf]
	ret

.nokey:
	popa
	mov ax, 0		   ; Zero result if no key pressed
	ret

	.tmp_buf	dw 0
