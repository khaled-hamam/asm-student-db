include irvine32.inc

.data
;put your static data
.code

main PROC
    call dumpregs
    exit
main ENDP

; DllMain is required for any DLL
DllMain PROC hInstance:DWORD, fdwReason:DWORD, lpReserved:DWORD 

mov eax, 1		; Return true to caller. 
ret 				
DllMain ENDP

END main	   ; For Running EXE
; END DllMain  ; For Exporting a DLL
