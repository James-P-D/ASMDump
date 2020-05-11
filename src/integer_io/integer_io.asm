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

                    mov ah, 0
                    mov al, 123
                    push ax
                    call outputUnsignedByte

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
; outputString(BYTE: number)
; Destroys: EBP, 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

outputUnsignedByte:
                    pop ebp                      ; Pop the return address                    

                    mov ecx, 0                   ; Set digits counter to zero                    
                    pop ax                       ; Pop integer to output into eax                    
                    
outputUnsignedByte_perform_calculation:                    
                    mov dx, 0
                    mov bx, 10
                    div bx
                    
                    push dx
                    inc ecx

                    cmp al, 0                                       ; Check the quotient
                    jne outputUnsignedByte_perform_calculation

                    mov edi, 0
outputUnsignedByte_finished_calculation:
                    pop dx
                    and edx, 000000FFh
                    add dl, 030h                                    ; Check the remainder
                    ;mov byte ptr [number_buffer + ecx], dl

                    mov byte ptr [number_buffer + edi], dl
                    
                    inc edi
                    ;dec ecx
                    ;cmp ecx, 0
                    ;je outputUnsignedByte_finished_calculation
                    loop outputUnsignedByte_finished_calculation

                    push edi
                    push offset number_buffer
                    call outputString      
  
                    pop ebp                    
                    push ebp                     ; Restore return address
                    ret                          ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; outputString(DWORD: offset-of-string, DWORD: length-of-string)
; Destroys EBP, ESI, EDI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

outputString:
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
