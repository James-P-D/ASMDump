; To compile:
; del string_output.exe
; c:\masm32\bin\ml.exe /c /coff string_output.asm
; c:\masm32\bin\polink.exe /SUBSYSTEM:console string_output.obj
; string_output.exe
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

test_message        db "Test message!", 13, 10   ; Example string
TEST_MESSAGE_LEN    equ $ - offset test_message  ; Length of message

.data?
consoleOutHandle    dd ?                         ; Our ouput handle (currently undefined)
consoleInHandle     dd ?                         ; Our input handle (currently undefined)
bytesWritten        dd ?                         ; Number of bytes written to output (currently undefined)
bytesRead           dd ?                         ; Number of bytes written to input (currently undefined)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.code
start:              call getIOHandles            ; Get the input/output handles

                    push TEST_MESSAGE_LEN
                    push offset test_message
                    call outputString

                    push 0                        ; Exit code zero for success
                    call ExitProcess              ; https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-exitprocess

getIOHandles:       push STD_OUTPUT_HANDLE       ; _In_ DWORD nStdHandle
                    call GetStdHandle            ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                    mov [consoleOutHandle], eax  ; Save the output handle
                    push STD_INPUT_HANDLE        ; _In_ DWORD nStdHandle
                    call GetStdHandle            ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                    mov [consoleInHandle], eax   ; Save the input handle
                    ret

; outputString(offset-of-string, length-of-string)
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
end start
