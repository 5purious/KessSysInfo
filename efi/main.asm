;;
;;  MIT License
;;
;;  Copyright (c) 2022 Ian Marco Moffett
;;
;;  Permission is hereby granted, free of charge, to any person obtaining a copy
;;  of this software and associated documentation files (the "Software"), to deal
;;  in the Software without restriction, including without limitation the rights
;;  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;;  copies of the Software, and to permit persons to whom the Software is
;;  furnished to do so, subject to the following conditions:
;;
;;  The above copyright notice and this permission notice shall be included in all
;;  copies or substantial portions of the Software.
;;
;;  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;;  SOFTWARE.
;;

format pe64 dll efi
entry main
 
section ".text" code executable readable
 
include "uefi.inc"
 
main:
    ; Initialize UEFIlib.
    InitializeLib
    jc @f

@@:
    ;; Reset ConOut.
    uefi_call_wrapper ConOut, Reset, ConOut, 1

    ;; Write start message.
    uefi_call_wrapper ConOut, OutputString, ConOut, start_msg
    uefi_call_wrapper ConOut, OutputString, ConOut, entry0

@@:
    uefi_call_wrapper ConIn, ReadKeyStroke, ConIn, key
    cmp dword [key.scancode], 0
    jz @b

    mov eax, [key.scancode]

    cmp eax, 3
    je CHECK_AND_EXECUTE_ENTRY
    cmp eax, 2                  ;; DOWN.
    je DOWN
    cmp eax, 1                  ;; UP.
    je UP

    jmp @b


;; Cycle centry (current entry) down and re-draw current entry.
DOWN:
    mov al, [centry]
    cmp al, 1                   ;; MAX_ENTRY (CHANGE THIS BEFORE ADDING MORE ENTRIES).
    jge @b
    inc al
    mov [centry], al

    ;; Checking current entry.
    cmp al, 1                       ;; ENTRY 1.
    je S_ENTRY1

    jmp @b


;; Cycle centry (current entry) down and re-draw current entry.
UP:
    mov al, [centry]
    cmp al, 0                   ;; MIN_ENTRY.
    jle @b
    dec al
    mov [centry], al

    ;; Checking current entry.
    cmp al, 1                       ;; ENTRY 1.
    je S_ENTRY1
    cmp al, 0
    je S_ENTRY0
    jmp @b

;; Switch to entry 1.
S_ENTRY1: 
    ;; Reset ConOut.
    mov rax, entry1
    call RESET_SCREEN
    uefi_call_wrapper ConOut, OutputString, ConOut, entry1
    jmp @b

S_ENTRY0:
    mov rax, entry0
    call RESET_SCREEN
    uefi_call_wrapper ConOut, OutputString, ConOut, entry0
    jmp @b



;; This shutsdown the system.
SHUTDOWN:
    uefi_call_wrapper RuntimeServices, ResetSystem, 2, 0, 0, 0
    cli
    hlt

REBOOT:
    uefi_call_wrapper RuntimeServices, ResetSystem, 1, 0, 0, 0
    cli
    hlt


RESET_SCREEN: 
    ;; Reset ConOut.
    uefi_call_wrapper ConOut, Reset, ConOut, 1
    uefi_call_wrapper ConOut, OutputString, ConOut, start_msg
    retq

CHECK_AND_EXECUTE_ENTRY:
    mov al, [centry]
    cmp al, 0
    je SHUTDOWN
    cmp al, 1
    je REBOOT
    jmp @b



section ".data" data readable writeable

key:
key.scancode: dw 0
key.unicode: du 0

;; Entries: 
;; 0: Quit.
;; 1: Reboot.
centry: db 0

start_msg du "KessSysInfo v0.0.5", 0xD, 0xA, 0
entry0: du "-> Shutdown", 0xD, 0xA, 0
entry1: du "-> Reboot", 0xD, 0xA, 0
selected_entry: dd 0
