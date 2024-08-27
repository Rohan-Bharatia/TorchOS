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

; Send byte to a port
os_port_byte_out:
	pusha

	out dx, al

	popa
	ret

; Receive byte from a port
os_port_byte_in:
	pusha

	in al, dx
	mov word [.tmp], ax

	popa
	mov ax, [.tmp]
	ret

	.tmp dw 0

; Set up the serial port for transmitting data
os_serial_port_enable:
	pusha

	mov dx, 0		  ; Configure serial port 1
	cmp ax, 1
	je .slow_mode

	mov ah, 0
	mov al, 11100011b ; 9600 baud, no parity, 8 data bits, 1 stop bit
	jmp .finish

.slow_mode:
	mov ah, 0
	mov al, 10000011b ; 1200 baud, no parity, 8 data bits, 1 stop bit	

.finish:
	int 14h

	popa
	ret

; Send a byte via the serial port
os_send_via_serial:
	pusha

	mov ah, 01h
	mov dx, 0		  ; COM1

	int 14h

	mov [.tmp], ax

	popa

	mov ax, [.tmp]

	ret

	.tmp dw 0

; Get a byte from the serial port
os_get_via_serial:
	pusha

	mov ah, 02h
	mov dx, 0		  ; COM1

	int 14h

	mov [.tmp], ax

	popa

	mov ax, [.tmp]

	ret

	.tmp dw 0
