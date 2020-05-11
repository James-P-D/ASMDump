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
;number_buffer       db NUMBER_BUFFER_SIZE dup(0)
number_buffer       db '_________________________'

test_string         db '0123456789'
cr_lf               db 13, 10

.data?
consoleOutHandle    dd ?                         ; Our ouput handle (currently undefined)
consoleInHandle     dd ?                         ; Our input handle (currently undefined)
bytesWritten        dd ?                         ; Number of bytes written to output (currently undefined)
bytesRead           dd ?                         ; Number of bytes written to input (currently undefined)

.code
start:              call getIOHandles            ; Get the input/output handles

                    mov al, 255
                    push ax
                    call output_unsigned_byte

                    push 0                       ; Exit code zero for success
                    call ExitProcess             ; https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-exitprocess

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; getIOHandles()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getIOHandles:       push STD_OUTPUT_HANDLE       ; _In_ DWORD nStdHandle
                    call GetStdHandle            ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                    mov [consoleOutHandle], eax  ; Save the output handle
                    push STD_INPUT_HANDLE        ; _In_ DWORD nStdHandle
                    call GetStdHandle            ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                    mov [consoleInHandle], eax   ; Save the input handle
                    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_unsigned_byte(BYTE: number)
; Destroys: EBP, 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_unsigned_byte:
                    pop ebp                      ; Pop the return address                    

                    mov ecx, 0                   ; Set digits counter to zero                    
                    pop ax                       ; Pop integer to output into AX
                    and ax, 00FFh                ; Make sure AX is in range 0..255
                    
output_unsigned_byte_perform_calculation:                    
                    mov dx, 0
                    mov bx, 10                   ; Divide by 10
                    div bx                       ; Divide AX by BX                    
                                                 ; DL contains remainer, AL contains quotient
                    and edx, 000000FFh           ; Make sure EDX (remainer) is in range 0..255
                    push dx                      ; Push our digit to the stack
                    inc ecx                      ; Increment digit counter

                    cmp al, 0                    ; Check if quotient is zero
                    jne output_unsigned_byte_perform_calculation    ; If quotient is not zero, then we need to perform the operation again

                    mov edi, 0                   ; Set EDI to zero. This will point to 'number_buffer' starting at index 0
output_unsigned_byte_finished_calculation:
                    pop dx                       ; Read the last remainder from the stack
                    add dl, 030h                 ; Add 30h (the letter '0' (zero)) so we map numbers to letters

                    mov byte ptr [number_buffer + edi], dl ; Copy the letter to 'number_buffer'
                    
                    inc edi                      ; Incrememnt out pointer to 'number_buffer'
                    loop output_unsigned_byte_finished_calculation  ; Continue looping until ECX is zero

                    push edi                     ; At the end of the process, EDI will conveniently hold the number of characters written to 'number_buffer'. Pass it as a parameter to 'output_string'
                    push offset number_buffer
                    call output_string      
  
                    pop ebp                    
                    push ebp                     ; Restore return address
                    ret                          ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_string(DWORD: offset-of-string, DWORD: length-of-string)
; Destroys EBP, ESI, EDI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_string:
                    pop ebp                      ; Pop the return address
                    pop esi                      ; Pop length-of-string into edi
                    pop edi                      ; Pop offset-of-string into esi
                    
                    push 0                       ; _Reserved_      LPVOID  lpReserved
                    push offset bytesWritten     ; _Out_           LPDWORD lpNumberOfCharsWritten
                    push edi                     ; _In_            DWORD   nNumberOfCharsToWrite
                    push esi                     ; _In_      const VOID *  lpBuffer
                    push consoleOutHandle        ; _In_            HANDLE  hConsoleOutput
                    call WriteConsole            ; https://docs.microsoft.com/en-us/windows/console/writeconsole

                    push ebp                     ; Restore return address
                    ret                          ; Return to caller


;readCurrentByte:    push -1                    ; _In_opt_        LPVOID  pInputControl
;                    push offset bytesRead      ; _Out_           LPDWORD lpNumberOfCharsRead
;                    push 1                     ; _In_            DWORD   nNumberOfCharsToRead
;                    push offset ioByte         ; _Out_           LPVOID  lpBuffer
;                    push consoleInHandle       ; _In_            HANDLE  hConsoleInput
;                    call ReadConsole           ; https://docs.microsoft.com/en-us/windows/console/readconsole
;                    mov ah, ioByte             ; Move the byte read into AH register
;                    mov byte ptr [esi], ah     ; Move the AH register into our memory buffer
;                    ret
                    
end start
