; To compile:
; del integer_io.exe
; c:\masm32\bin\ml.exe /c /coff integer_io.asm
; c:\masm32\bin\polink.exe /SUBSYSTEM:console integer_io.obj
; integer_io.exe

.386                  ; 386 Processor Instruction Set
.model flat, stdcall  ; Flat memory model and stdcall method
option casemap: none  ; Case Sensitive

include c:\\masm32\\include\\windows.inc
include c:\\masm32\\include\\kernel32.inc
include c:\\masm32\\include\\masm32.inc
includelib c:\\masm32\\lib\\kernel32.lib 
includelib c:\\masm32\\m32lib\\masm32.lib

.data
STD_OUTPUT_HANDLE   equ -11                      ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
STD_INPUT_HANDLE    equ -10                      ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
NUMBER_BUFFER_SIZE  equ 10                       ; TODO: How big? How many digits?
number_buffer       db NUMBER_BUFFER_SIZE dup(0)
cr_lf               db 13, 10
test_message        db "Enter a number", 13, 10  ; Example string
TEST_MESSAGE_LEN    equ $ - offset test_message  ; Length of message

.data?
console_out_handle  dd ?                         ; Our ouput handle (currently undefined)
console_in_handle   dd ?                         ; Our input handle (currently undefined)
bytes_written       dd ?                         ; Number of bytes written to output (currently undefined)
bytes_read          dd ?                         ; Number of bytes written to input (currently undefined)

.code
start:              call get_io_handles          ; Get the input/output handles

                    push TEST_MESSAGE_LEN
                    push offset test_message
                    call output_string

                    call input_signed_byte
                    
                    push ax
                    call output_signed_byte

                    push 0                       ; Exit code zero for success
                    call ExitProcess             ; https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-exitprocess

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; input_signed_byte()
; Result byte read in AX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

input_signed_byte:
                    push -1                     ; _In_opt_        LPVOID  pInputControl
                    push offset bytes_read      ; _Out_           LPDWORD lpNumberOfCharsRead
                    push NUMBER_BUFFER_SIZE     ; _In_            DWORD   nNumberOfCharsToRead
                    push offset number_buffer   ; _Out_           LPVOID  lpBuffer
                    push console_in_handle      ; _In_            HANDLE  hConsoleInput
                    call ReadConsole            ; https://docs.microsoft.com/en-us/windows/console/readconsole

                    mov ecx, [bytes_read]       ; Save number of characters read into ECX
                    sub ecx, 2                  ; Remove CR/LF from character-read-count
                    cmp ecx, 0                  ; If two or less characters read..
                    jle input_signed_byte       ; ..read again
                                        
                    mov esi, offset number_buffer ; Set ESI to point to number_buffer for reading
                    mov ebx, 0                  ; Set EBX to zero
                    mov eax, 0                  ; Set EAX to zero

                    cmp byte ptr [esi], '-'     ; Is first character read a minus sign?
                    jne input_signed_byte_loop  ; If not, then just process as normal
                    
                    inc esi                     ; Incremement ESI so we are past the '-' character
                    dec ecx                     ; Decremement ECX since we now have one fewer characters to process

input_signed_byte_loop:
                    mov bl, 10                  ; BL will be used to multiple AX by 10 for each digit read
                    mul bx                      ; Multiply existing value in AX by BX (10) and put result in AX (This will be zero on first iteration)

                    mov bl, byte ptr [esi]      ; Copy character from 'number_buffer' into BL
                    cmp bl, '0'                 ; Compare character with '0'..
                    jl input_signed_byte        ; ..and if it's less then that, then read again as it's not a number
                    cmp bl, '9'                 ; Compare character with '9'..
                    jg input_signed_byte        ; ..and if it's greater then that, then read again as it's not a number

                    sub bl, 30h                 ; Convert from char to number ('3' to 3)
                    
                    add ax, bx                  ; Add the number to AX
                                        
                    inc esi                     ; Incremement out pointer to 'number_buffer'
                    loop input_signed_byte_loop ; ...and do it again ECX times                                        

                    mov esi, offset number_buffer ; Set ESI to point to number_buffer for reading
                    cmp byte ptr [esi], '-'     ; Check if first character is '-'
                    jne input_signed_byte_return; If no, then just return
                    
                    not al                       ; Two's complement conversion, step 1 - Negate number
                    inc al                       ; Two's complement conversion, step 2 - Add 1 to number
                    and eax, 000000FFh           ; Check still in byte range

input_signed_byte_return:
                    ret                         ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; input_unsigned_byte()
; Result byte read in AX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

input_unsigned_byte:
                    push -1                     ; _In_opt_        LPVOID  pInputControl
                    push offset bytes_read      ; _Out_           LPDWORD lpNumberOfCharsRead
                    push NUMBER_BUFFER_SIZE     ; _In_            DWORD   nNumberOfCharsToRead
                    push offset number_buffer   ; _Out_           LPVOID  lpBuffer
                    push console_in_handle      ; _In_            HANDLE  hConsoleInput
                    call ReadConsole            ; https://docs.microsoft.com/en-us/windows/console/readconsole
                    
                    mov ecx, [bytes_read]       ; Save number of characters read into ECX
                    sub ecx, 2                  ; Remove CR/LF from character-read-count
                    cmp ecx, 0                  ; If two or less characters read..
                    jle input_unsigned_byte     ; ..read again
                                        
                    mov esi, offset number_buffer ; Set ESI to point to number_buffer for reading
                    mov ebx, 0                  ; Set EBX to zero
                    mov eax, 0                  ; Set EAX to zero
                    
input_unsigned_byte_loop:
                    mov bl, 10                  ; BL will be used to multiple AX by 10 for each digit read
                    mul bx                      ; Multiply existing value in AX by BX (10) and put result in AX (This will be zero on first iteration)

                    mov bl, byte ptr [esi]      ; Copy character from 'number_buffer' into BL
                    cmp bl, '0'                 ; Compare character with '0'..
                    jl input_unsigned_byte      ; ..and if it's less then that, then read again as it's not a number
                    cmp bl, '9'                 ; Compare character with '9'..
                    jg input_unsigned_byte      ; ..and if it's greater then that, then read again as it's not a number
                    
                    sub bl, 30h                 ; Convert from char to number ('3' to 3)
                    
                    add ax, bx                  ; Add the number to AX
                                        
                    inc esi                     ; Incremement out pointer to 'number_buffer'
                    loop input_unsigned_byte_loop ; ...and do it again ECX times                                        

                    ret                         ; Return to caller
                    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_signed_byte(BYTE: number)
; If most significat bit set then negative.
; otherwise, * Subtract 1
;              negate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_signed_byte:
                    pop ebp                      ; Pop the return address
                    pop ax                       ; Pop integer to output into AX
                    push ebp                     ; Push EBP back onto stack
                    and ax, 00FFh                ; Make sure AX is in range 0..255
                    
                    test al, al                  ; Check for most significant bit set (signifies negative number in two's-complement)
                    js output_signed_byte_is_negative_number ; Jump if SF flag is set

                    push ax                      ; Number is postive, so just push it to stack..
                    call output_unsigned_byte    ; ..and call 'output_unsigned_byte'
                    ret                          ; Return to caller
                    
output_signed_byte_is_negative_number:
                    dec al                       ; Two's complement conversion, step 1 - Subtract 1 from number
                    not al                       ; Two's complement conversion, step 2 - Negate number
                    and eax, 000000FFh           ; Check still in byte range

                    mov ecx, 0                   ; Set digits counter to zero     
                    
output_signed_byte_perform_calculation:                    
                    mov dx, 0
                    mov bx, 10                   ; Divide by 10
                    div bx                       ; Divide AX by BX                    
                                                 ; DL contains remainer, AL contains quotient
                    and edx, 000000FFh           ; Make sure EDX (remainer) is in range 0..255
                    add dl, 030h                 ; Add 30h (the letter '0' (zero)) so we map numbers to letters
                    push dx                      ; Push our letter to the stack
                    inc ecx                      ; Increment digit counter

                    cmp al, 0                    ; Check if quotient is zero
                    jne output_signed_byte_perform_calculation    ; If quotient is not zero, then we need to perform the operation again

                    mov dx, '-'                  ; Set DX to character '-'
                    push dx                      ; Push minus sign to top of stack so that it is first character displayed
                    inc ecx                      ; Increment ECX since we now have another character to pop and display
                    
                    mov edi, 0                   ; Set EDI to zero. This will point to 'number_buffer' starting at index 0
output_signed_byte_finished_calculation:
                    pop dx                       ; Read the last remainder from the stack
 
                    mov byte ptr [number_buffer + edi], dl ; Copy the letter to 'number_buffer'
                    
                    inc edi                      ; Incrememnt out pointer to 'number_buffer'
                    loop output_signed_byte_finished_calculation  ; Continue looping until ECX is zero

                    push edi                     ; At the end of the process, EDI will conveniently hold the number of characters written to 'number_buffer'. Pass it as a parameter to 'output_string'
                    push offset number_buffer
                    call output_string      
  
                    ret                          ; Return to caller


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_unsigned_byte(BYTE: number)
; Destroys: EBP, 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_unsigned_byte:
                    pop ebp                      ; Pop the return address
                    pop ax                       ; Pop integer to output into AX
                    push ebp                     ; Push EBP back onto stack

                    and ax, 00FFh                ; Make sure AX is in range 0..255                    
                    mov ecx, 0                   ; Set digits counter to zero     
                    
output_unsigned_byte_perform_calculation:                    
                    mov dx, 0
                    mov bx, 10                   ; Divide by 10
                    div bx                       ; Divide AX by BX                    
                                                 ; DL contains remainer, AL contains quotient
                    and edx, 000000FFh           ; Make sure EDX (remainer) is in range 0..255
                    add dl, 030h                 ; Add 30h (the letter '0' (zero)) so we map numbers to letters
                    push dx                      ; Push our letter to the stack
                    inc ecx                      ; Increment digit counter

                    cmp al, 0                    ; Check if quotient is zero
                    jne output_unsigned_byte_perform_calculation    ; If quotient is not zero, then we need to perform the operation again

                    mov edi, 0                   ; Set EDI to zero. This will point to 'number_buffer' starting at index 0
output_unsigned_byte_finished_calculation:
                    pop dx                       ; Read the last remainder from the stack
 
                    mov byte ptr [number_buffer + edi], dl ; Copy the letter to 'number_buffer'
                    
                    inc edi                      ; Incrememnt out pointer to 'number_buffer'
                    loop output_unsigned_byte_finished_calculation  ; Continue looping until ECX is zero

                    push edi                     ; At the end of the process, EDI will conveniently hold the number of characters written to 'number_buffer'. Pass it as a parameter to 'output_string'
                    push offset number_buffer
                    call output_string      
  
                    ret                          ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_string(DWORD: offset-of-string, DWORD: length-of-string)
; Destroys EBP, ESI, EDI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_string:
                    pop ebp                      ; Pop the return address
                    pop esi                      ; Pop length-of-string into edi
                    pop edi                      ; Pop offset-of-string into esi
                    push ebp                     ; Push EBP back to stack
                    
                    push 0                       ; _Reserved_      LPVOID  lpReserved
                    push offset bytes_written    ; _Out_           LPDWORD lpNumberOfCharsWritten
                    push edi                     ; _In_            DWORD   nNumberOfCharsToWrite
                    push esi                     ; _In_      const VOID *  lpBuffer
                    push console_out_handle      ; _In_            HANDLE  hConsoleOutput
                    call WriteConsole            ; https://docs.microsoft.com/en-us/windows/console/writeconsole

                    ret                          ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_new_line()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_new_line:
                    push 2
                    push offset cr_lf
                    call output_string
                    
                    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get_io_handles()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_io_handles:     push STD_OUTPUT_HANDLE       ; _In_ DWORD nStdHandle
                    call GetStdHandle            ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                    mov [console_out_handle], eax; Save the output handle
                    push STD_INPUT_HANDLE        ; _In_ DWORD nStdHandle
                    call GetStdHandle            ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                    mov [console_in_handle], eax ; Save the input handle
                    ret


end start
