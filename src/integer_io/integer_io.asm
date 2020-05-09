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
hello_message       db "Hello world!",0          ; Our input/output byte
HELLO_MESSAGE_LEN   equ $ - offset hello_message ; Length of message

.data?
consoleOutHandle    dd ?                         ; Our ouput handle (currently undefined)
consoleInHandle     dd ?                         ; Our input handle (currently undefined)
bytesWritten        dd ?                         ; Number of bytes written to output (currently undefined)
bytesRead           dd ?                         ; Number of bytes written to input (currently undefined)

.code
start:              call getIOHandles            ; Get the input/output handles

                    push 0                        ; Exit code zero for success
                    call ExitProcess              ; https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-exitprocess

getIOHandles:       push STD_OUTPUT_HANDLE       ; _In_ DWORD nStdHandle
                    call GetStdHandle            ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                    mov [consoleOutHandle], eax  ; Save the output handle
                    push STD_INPUT_HANDLE        ; _In_ DWORD nStdHandle
                    call GetStdHandle            ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                    mov [consoleInHandle], eax   ; Save the input handle
                    ret

readCurrentByte:    push -1                    ; _In_opt_        LPVOID  pInputControl
                    push offset bytesRead      ; _Out_           LPDWORD lpNumberOfCharsRead
                    push 1                     ; _In_            DWORD   nNumberOfCharsToRead
                    push offset ioByte         ; _Out_           LPVOID  lpBuffer
                    push consoleInHandle       ; _In_            HANDLE  hConsoleInput
                    call ReadConsole           ; https://docs.microsoft.com/en-us/windows/console/readconsole
                    mov ah, ioByte             ; Move the byte read into AH register
                    mov byte ptr [esi], ah     ; Move the AH register into our memory buffer
                    ret
                    
end start
