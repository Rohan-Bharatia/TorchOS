section .data
    file_pattern  db '*.*', 0       ; Pattern to search all files
    backup_folder db 'backup1', 0   ; Starting backup folder (simulated)
    current_file  db 128 dup(0)     ; Buffer to store current file name
    backup_file   db 128 dup(0)     ; Buffer for backup file path

section .text
start:
    call list_files                 ; List files in the directory
    call check_backup_folder        ; Check if the backup folder exists
    call copy_all_files             ; Copy all files to the backup folder

    ret

; List all files in the directory
list_files:
    mov dx, file_pattern

    ret

; check if the backup folder exists
check_backup_folder:
    ret

; Copy all files to the backup folder
copy_all_files:
    mov si, current_file            ; Current file name
    mov di, backup_file             ; Destination file in backup folder

    ret                             ; Close files
