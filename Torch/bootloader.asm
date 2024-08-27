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

BITS 16

jmp short bootloader_start           ; Jump past disk description section
nop                                  ; Pad out before disk description

; Disk description table
OEM_label		   db "TorchBOOT"    ; Disk label
bytes_per_sector   dw 512		     ; Bytes per sector
sectors_per_cluser db 1		         ; Sectors per cluster
reserved_for_boot  dw 1		         ; Reserved sectors for boot record
number_of_FATs	   db 2		         ; Number of copies of the FAT
root_dir_entries   dw 224		     ; Number of entries in root dir
logical_sectors	   dw 2880		     ; Number of logical sectors
medium_byte		   db 0F0h		     ; Medium descriptor byte
sectors_per_FAT	   dw 9		         ; Sectors per FAT
secs_per_track     dw 18		     ; Sectors per track (36/cylinder)
sides			   dw 2		         ; Number of sides & heads
hidden_sectors	   dd 0		         ; Number of hidden sectors
large_sectors	   dd 0		         ; Number of LBA sectors
drive_no		   dw 0		         ; Drive
signature		   db 41		     ; Drive signature
volume_ID		   dd 00000000h	     ; Volume ID
volume_label	   db "TorchOS     " ; Volume Label *must be 11 chars*
file_system		   db "FAT12   "	 ; File system type *don't change*

; Main bootloader code
bootloader_start:
    mov ax, 07C0h			         ; Setup 4 kilobytes of stack space above buffer
	add ax, 544			             ; 8 kilobyte buffer = 512 paragraphs + 32 paragraphs (loader)
	cli				                 ; Disable interrupts while changing stack
	mov ss, ax
	mov sp, 4096
	sti				                 ; Restore interrupts

	mov ax, 07C0h			         ; Set data segment to where it's loaded
	mov ds, ax
    
	cmp dl, 0
	je no_change
	mov [bootdev], dl		         ; Save boot device number
	mov ah, 8			             ; Get drive parameters
	int 13h
	jc fatal_disk_error
	and cx, 3Fh			             ; Maximum sector number
	mov [secs_per_track], cx
	movzx dx, dh			         ; Maximum head number
	add dx, 1
	mov [sides], dx

no_change:                           ; Needed for some older BIOSes
    mov eax, 0

floppy_ok:				             ; Ready to read first block of data
	mov ax, 19			             ; Root dir starts at logical sector 19
	call l2hts

	mov si, buffer			         ; Set ES:BX to point to buffer
	mov bx, ds
	mov es, bx
	mov bx, si

	mov ah, 2			             ; Parameters for int 13h: read floppy sectors
	mov al, 14			             ; Read 14 floppy sectors

	pusha				             ; Prepare for loop entry

read_root_dir:
	popa				             ; In case registers are altered by int 13h
	pusha

	stc				                 ; A few BIOSes do not set properly on error
	int 13h				             ; Read sectors using BIOS

	jnc search_dir			         ; If read went well, skip ahead
	call reset_floppy		         ; If read went bad, reset floppy controller and try again
	jnc read_root_dir		         ; Floppy reset

	jmp reboot			             ; Fatal double error

search_dir:
	popa

	mov ax, ds						 ; Root dir is now in [buffer]
	mov es, ax						 ; Set DI to this info
	mov di, buffer

	mov cx, word [root_dir_entries]	 ; Search all (224) entries
	mov ax, 0						 ; Searching at offset 0


next_root_entry:
	xchg cx, dx						 ; Use CX in the inner loop

	mov si, kern_filename			 ; Start searching for kernel filename
	mov cx, 11
	rep cmpsb
	je found_file_to_load			 ; Pointer DI will be at offset 11

	add ax, 32						 ; Increment searched entries by 1 (32 bytes per entry)

	mov di, buffer					 ; Point to next entry
	add di, ax

	xchg dx, cx						 ; Get original CX back
	loop next_root_entry

	mov si, file_not_found		  	 ; Bail out
	call print_string
	jmp reboot

found_file_to_load:					 ; Fetch cluster and load FAT into RAM
	mov ax, word [es:di + 0Fh]	 	 ; Offset 26, contains 1st cluster
	mov word [cluster], ax

	mov ax, 1						 ; Sector 1 = first sector of first FAT
	call l2hts

	mov di, buffer					 ; ES:BX points to our buffer
	mov bx, di

	mov ah, 2						 ; int 13h parameters: read (FAT) sectors
	mov al, 9						 ; All 9 sectors of 1st FAT

	pusha							 ; Prepare to enter loop


read_fat:
	popa							 ; In case registers are altered by int 13h
	pusha

	stc
	int 13h							 ; Read sectors using the BIOS

	jnc read_fat_ok					 ; If read went well, skip ahead
	call reset_floppy				 ; If read went bad, reset floppy controller and try again
	jnc read_fat					 ; Floppy reset

fatal_disk_error:
	mov si, disk_error				 ; Print error message and reboot
	call print_string
	jmp reboot						 ; Fatal double error


read_fat_ok:
	popa

	mov ax, 2000h					 ; Segment where the kernel will be loaded
	mov es, ax
	mov bx, 0

	mov ah, 2						 ; int 13h floppy read parameters
	mov al, 1

	push ax							 ; Save in case it's lost

load_file_sector:
	mov ax, word [cluster]			 ; Convert sector to logical
	add ax, 31

	call l2hts						 ; Make appropriate parameters for int 13h

	mov ax, 2000h					 ; Set buffer past what we've already read
	mov es, ax
	mov bx, word [pointer]

	pop ax							 ; Save in case lost
	push ax

	stc
	int 13h

	jnc calculate_next_cluster		 ; If there's no error

	call reset_floppy				 ; If there is an error, reset floppy and retry
	jmp load_file_sector

calculate_next_cluster:
	mov ax, [cluster]
	mov dx, 0
	mov bx, 3
	mul bx
	mov bx, 2
	div bx							 ; DX = [cluster] mod 2
	mov si, buffer
	add si, ax						 ; AX = word in FAT for the 12 bit entry
	mov ax, word [ds:si]

	or dx, dx						 ; If DX = 0 [cluster] is even and if DX = 1 then it's odd

	jz even							 ; If [cluster] is even, drop last 4 bits of word

odd:
	shr ax, 4						 ; Shift out first 4 bits (they belong to another entry)
	jmp short next_cluster_cont


even:
	and ax, 0FFFh					 ; Mask out final 4 bits

next_cluster_cont:
	mov word [cluster], ax			 ; Store cluster

	cmp ax, 0FF8h					 ; FF8h = end of file marker in FAT12
	jae end

	add word [pointer], 512			 ; Increase buffer pointer 1 sector length
	jmp load_file_sector


end:								 ; We've got the file to load
	pop ax							 ; Clean up the stack (AX was pushed earlier)
	mov dl, byte [bootdev]			 ; Provide kernel with boot device info

	jmp 2000h:0000h					 ; Jump to entry point of loaded kernel

; Bootloader subroutines
reboot:
	mov ax, 0
	int 16h							 ; Wait for keystroke
	mov ax, 0
	int 19h							 ; Reboot the system


print_string:						 ; Output string in SI to screen
	pusha

	mov ah, 0Eh						 ; int 10h teletype function

.repeat:
	lodsb							 ; Get char from string
	cmp al, 0
	je .done						 ; If char is zero, end of string
	int 10h							 ; If char is nonzero, print it
	jmp short .repeat

.done:
	popa
	ret


reset_floppy:						 ; IN: [bootdev] = boot device; OUT: carry set on error
	push ax
	push dx
	mov ax, 0
	mov dl, byte [bootdev]
	stc
	int 13h
	pop dx
	pop ax
	ret


l2hts:								 ; Calculate head, track, and sector settings for int 13h
	push bx
	push ax

	mov bx, ax						 ; Save logical sector

	mov dx, 0						 ; First the sector
	div word [secs_per_track]
	add dl, 01h						 ; Physical sectors start at 1
	mov cl, dl						 ; Sectors belong in CL for int 13h
	mov ax, bx

	mov dx, 0						 ; Calculate the head
	div word [secs_per_track]
	mov dx, 0
	div word [sides]
	mov dh, dl						 ; Head/side
	mov ch, al						 ; Track

	pop ax
	pop bx

	mov dl, byte [bootdev]			 ; Set correct device

	ret

; Variables & strings
kern_filename	db "KERNEL  BIN"	 ; TorchOS kernel filename

disk_error		db "Floppy error! Press any key...", 0
file_not_found	db "kernel.bin not found!", 0

bootdev	db 0 					 	 ; Boot device number
cluster	dw 0 					 	 ; Cluster of the file to load
pointer	dw 0 					 	 ; Pointer into Buffer, for loading kernel

; Boot sector end/buffer start
times 510-($-$$) db 0 				 ; remainder of boot sector with zeros
dw 0AA55h							 ; Boot signature *Don't change*

buffer:								 ; Disk buffer begins (8 kilobytes after this, stack starts)
	