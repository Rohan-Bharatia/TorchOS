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

; Generate PC speaker tone (call os_speaker_off to turn off)
os_speaker_tone:
	pusha

	mov cx, ax ; Store note value for now

	mov al, 182
	out 43h, al
	mov ax, cx ; Set up frequency
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h ; Switch PC speaker on
	or al, 03h
	out 61h, al

	popa
	ret

; Turn off PC speaker
os_speaker_off:
	pusha

	in al, 61h
	and al, 0FCh
	out 61h, al

	popa
	ret
