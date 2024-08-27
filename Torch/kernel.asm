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

%define TORCHOS_VERSION '1.0.0'
%define API_VERSION		1

disk_buffer equ 24576

; Static locations for system call (syscall) vectors
os_call_vectors:
	jmp os_main			          ; 0000h -- Called from bootloader
	jmp os_print_string		      ; 0003h
	jmp os_move_cursor		      ; 0006h
	jmp os_clear_screen		      ; 0009h
	jmp os_print_horiz_line		  ; 000Ch
	jmp os_print_newline		  ; 000Fh
	jmp os_wait_for_key		      ; 0012h
	jmp os_check_for_key		  ; 0015h
	jmp os_int_to_string		  ; 0018h
	jmp os_speaker_tone		      ; 001Bh
	jmp os_speaker_off		      ; 001Eh
	jmp os_load_file		      ; 0021h
	jmp os_pause			      ; 0024h
	jmp os_fatal_error		      ; 0027h
	jmp os_draw_background		  ; 002Ah
	jmp os_string_length		  ; 002Dh
	jmp os_string_uppercase		  ; 0030h
	jmp os_string_lowercase		  ; 0033h
	jmp os_input_string		      ; 0036h
	jmp os_string_copy		      ; 0039h
	jmp os_dialog_box		      ; 003Ch
	jmp os_string_join		      ; 003Fh
	jmp os_get_file_list		  ; 0042h
	jmp os_string_compare		  ; 0045h
	jmp os_string_chomp		      ; 0048h
	jmp os_string_strip		      ; 004Bh
	jmp os_string_truncate		  ; 004Eh
	jmp os_bcd_to_int		      ; 0051h
	jmp os_get_time_string		  ; 0054h
	jmp os_get_api_version		  ; 0057h
	jmp os_file_selector		  ; 005Ah
	jmp os_get_date_string		  ; 005Dh
	jmp os_send_via_serial		  ; 0060h
	jmp os_get_via_serial		  ; 0063h
	jmp os_find_char_in_string	  ; 0066h
	jmp os_get_cursor_pos		  ; 0069h
	jmp os_print_space		      ; 006Ch
	jmp os_dump_string		      ; 006Fh
	jmp os_print_digit		      ; 0072h
	jmp os_print_1hex		      ; 0075h
	jmp os_print_2hex		      ; 0078h
	jmp os_print_4hex		      ; 007Bh
	jmp os_long_int_to_string	  ; 007Eh
	jmp os_long_int_negate		  ; 0081h
	jmp os_set_time_fmt		      ; 0084h
	jmp os_set_date_fmt		      ; 0087h
	jmp os_show_cursor		      ; 008Ah
	jmp os_hide_cursor		      ; 008Dh
	jmp os_dump_registers		  ; 0090h
	jmp os_string_strincmp		  ; 0093h
	jmp os_write_file		      ; 0096h
	jmp os_file_exists		      ; 0099h
	jmp os_create_file		      ; 009Ch
	jmp os_remove_file		      ; 009Fh
	jmp os_rename_file		      ; 00A2h
	jmp os_get_file_size		  ; 00A5h
	jmp os_input_dialog		      ; 00A8h
	jmp os_list_dialog		      ; 00ABh
	jmp os_string_reverse		  ; 00AEh
	jmp os_string_to_int		  ; 00B1h
	jmp os_draw_block		      ; 00B4h
	jmp os_get_random		      ; 00B7h
	jmp os_string_charchange	  ; 00BAh
	jmp os_serial_port_enable	  ; 00BDh
	jmp os_sint_to_string		  ; 00C0h
	jmp os_string_parse		      ; 00C3h
	jmp os_run_basic		      ; 00C6h
	jmp os_port_byte_out		  ; 00C9h
	jmp os_port_byte_in		      ; 00CCh
	jmp os_string_tokenize		  ; 00CFh

; Main kernel code
os_main:
    cli                           ; Clear interrupts
    mov ax, 0
    mov ss, ax                    ; Set stack segment & pointer
    mov sp, 0FFFh
    sti

    cld                           ;  Default direction for string operations

    mov ax, 2000h                 ; Set all segments to match where kernel is loaded
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    cmp dl, 0
    je no_change
    mov [bootdev], dl             ; Save boot device loader
    push es
    mov ah, 8                     ; Drive parameters
    int 13h
    pop es
    and cx, 3Fh                   ; Max sector number
    mov [secs_per_track], cx      ; Sector numbers start at 1
    movzx dx, dh                  ; Max head number
    add dx, 1                     ; Head numbers start at 0 - add 1 for total
    mov [sides], dx

no_change:
    mov ax, 1003h                 ; See text output with certain attributes
    mov bx, 0
    int 10h

    call os_seed_random           ; Seed random number generator

    mov ax, autorun_bin_file_name ; Checks for a file called 'autorun.bin'
    call os_file_exists
    jc no_autorun_bin             ; Skips next bit of code if 'autorun.bin' doesn't exist (Lines  133 - 137)

    mov cx, 32768                 ; Load program into RAM
    call os_load_file
    jmp execute_bin_program

no_autorun_bin:
    mov ax, autorun_bas_file_name
	call os_file_exists
	jc option_screen		      ; Skip next section if 'autorun.bas' doesn't exist

	mov cx, 32768			      ; Load program into RAM
	call os_load_file
	call os_clear_screen
	mov ax, 32768
	call os_run_basic		      ; Run the kernels BASIC interpreter

	jmp app_selector		      ; Go to the app selector menu when BASIC ends

option_screen:
    mov ax, os_init_msg		      ; Set up welcome screen
	mov bx, os_version_msg
	mov cx, 10011111b		      ; Set white text on a blue background
	call os_draw_background
    
    mov ax, dialog_string_1		  ; Ask if user wants app selector or command-line
	mov bx, dialog_string_2
	mov cx, dialog_string_3
	mov dx, 1			          ; A two-option dialog box (OK or Cancel)
	call os_dialog_box

	cmp ax, 1			          ; Start app selector
	jne near app_selector

	call os_clear_screen		  ; Clean screen and start the CLI
	call os_command_line

	jmp option_screen		      ; Offer menu/CLI choice after CLI has exited

    os_init_msg		    db 'Welcome to TorchOS', 0
	os_version_msg		db 'Version ', TORCHOS_VERSION, 0

	dialog_string_1		db 'Thanks for using out TorchOS!', 0
	dialog_string_2		db 'Please select an interface: OK for the', 0
	dialog_string_3		db 'program menu, Cancel for command line.', 0

app_selector:
	mov ax, os_init_msg		      ; Draw main screen layout
	mov bx, os_version_msg
	mov cx, 10011111b		      ; Set white text on a blue background
	call os_draw_background

	call os_file_selector		  ; Get user to select a file and store it
					
	jc option_screen		      ; Return to the CLI/menu choice screen if Esc pressed

	mov si, ax			          ; Check if user tried to run 'kernel.bin'
	mov di, kern_file_name
	call os_string_compare
	jc no_kernel_execute		  ; Show an error message if user tried to run 'kernel.bin'

	push si				          ; Save filename temporarily

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			          ; SI now points to end of filename

	dec si
	dec si
	dec si

	mov di, bin_ext
	mov cx, 3
	rep cmpsb			          ; Check if final 3 characters are 'bin'
	jne not_bin_extension		  ; Check if final 3 characters are 'bas'

	pop si				          ; Restore filename


	mov ax, si
	mov cx, 32768			      ; Where to load the program file
	call os_load_file		      ; Load filename pointed to by AX

execute_bin_program:
	call os_clear_screen		  ; Clear screen before running

	mov ax, 0			          ; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov si, 0
	mov di, 0

	call 32768			          ; Call external program code

	call os_clear_screen		  ; Clear screen
	jmp app_selector		      ; Go back to program list

no_kernel_execute:			      ; Warn about trying to executing kernel
	mov ax, kerndlg_string_1
	mov bx, kerndlg_string_2
	mov cx, kerndlg_string_3
	mov dx, 0			          ; One button for dialog box
	call os_dialog_box

	jmp app_selector		      ; Restart

not_bin_extension:
	pop si

	push si				          ; Save again in case of error/for good measure

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			          ; SI now points to end of filename

	dec si
	dec si
	dec si				          ; SI now points to start of extension

	mov di, bas_ext
	mov cx, 3
	rep cmpsb			         ; Check if final 3 characters are 'bas'
	jne not_bas_extension		 ; Error out


	pop si

	mov ax, si
	mov cx, 32768			     ; Where to load the program file
	call os_load_file		     ; Load filename pointed to by AX

	call os_clear_screen		 ; Clear screen before running

	mov ax, 32768
	mov si, 0			         ; No parameters to pass
	call os_run_basic		     ; Run BASIC interpreter on the code

	mov si, basic_finished_msg
	call os_print_string
	call os_wait_for_key

	call os_clear_screen
	jmp app_selector		     ; Go back to the program list

not_bas_extension:
	pop si

	mov ax, ext_string_1
	mov bx, ext_string_2
	mov cx, 0
	mov dx, 0			         ; One button for dialog box
	call os_dialog_box

	jmp app_selector		     ; Restart


	kern_file_name		db 'bin/kernel.bin', 0

	autorun_bin_file_name	db 'bin/autorun.bin', 0
	autorun_bas_file_name	db 'bin/autorun.bin', 0

	bin_ext			db 'bin'
	bas_ext			db 'bas'

	kerndlg_string_1	db 'Cannot load and execute TorchOS kernel!', 0
	kerndlg_string_2	db 'kernel.bin is the core of TorchOS, and', 0
	kerndlg_string_3	db 'is not a normal program.', 0

	ext_string_1		db 'Invalid filename extension! You can', 0
	ext_string_2		db 'only execute .bin or .bas programs.', 0

	basic_finished_msg	db '>>> BASIC program finished -- press any key', 0

; System variables
fmt_12_24 db 0                   ; Set 24 hour clock
fmt_date  db 0, '/'              ; Set to MM/DD/YY format

; Features
%INCLUDE "features/cli.asm"
%INCLUDE "features/disk.asm"
%INCLUDE "features/keyboard.asm"
%INCLUDE "features/math.asm"
%INCLUDE "features/misc.asm"
%INCLUDE "features/ports.asm"
%INCLUDE "features/screen.asm"
%INCLUDE "features/audio.asm"
%INCLUDE "features/string.asm"
%INCLUDE "features/basic-int.asm"
