include irvine32.inc


; CONSTANTS
BUFFER_SIZE = 1024
FIELD_DELIMETER = '/'
RECORD_DELIMETER = '@'
.data
CHOICES BYTE "PRESS (1) TO OPEN DATABASE ", 10, 13, "PRESS (2) TO Enroll new Student ", 10, 13, "PRESS (3) TO Save DATABASE ", 10, 13, "PRESS (4) TO Update Student's Grade ", 10, 13, "PRESS (5) TO Delete a Student ", 10, 13, "PRESS (6) TO Print Student", 10, 13, "PRESS (7) TO PRINT SPECIFIC STUDENT", 10, 13 0
RepeatChoice BYTE "DO you want to Enter another choice? 'y/n' ",10 ,13, 0
EnterID BYTE "ENTER STUDENT'S ID: ", 0
EnterName BYTE "ENTER STUDENT'S Name: ", 0
EnterGrade BYTE "ENTER STUDENT'S Grade: ", 0
EnterSec BYTE "ENTER STUDENT'S Section Number (1-2): ", 0
EnterKey BYTE "ENTER DATA BASE KEY: ", 0
CopiedBuffer BYTE BUFFER_SIZE DUP(?)
buffer BYTE	BUFFER_SIZE DUP(?)
encryptedBuffer BYTE 0, BUFFER_SIZE DUP(?)
filename BYTE "F:\Downloads\Irvine\Project_Template\files\check.txt", 0
DBKEY BYTE 65
fileHandle HANDLE ?
errorString BYTE "An Error Occured.", 0
successString BYTE "Saving Completed.", 0

section1 BYTE 0
section2 BYTE 0

ID BYTE ?
GRADE BYTE ?
STUDENTNAME BYTE 20 DUP(?)
SECTIONID BYTE ?

.code

main PROC
  RepeatChoices:
	mov EDX,OFFSET CHOICES
	call writeString
	;READ CHOICE
	call READINT

	cmp EAX,1
	je OPEN
	cmp EAX,2
	je ENROLL
	cmp EAX,3
	je SAVE
	cmp EAX,4
	je UPDATE
	cmp EAX,5
	je DELETE
	cmp EAX,6
	je DisplayAll
	cmp EAX,7
	je DisplayStudent
	jmp Done

OPEN:
	mov EDX,OFFSET EnterKey
	call writeString
	call readInt
	mov DBKEY,AL
	mov EDX, OFFSET filename
	call openDatabase
	jmp Done

ENROLL:
	mov EDX,OFFSET EnterID
	call writeString
	call readInt
	mov EDX, OFFSET ID
	mov [EDX],al
	mov EDX,OFFSET EnterName
	call writeString
	mov edx,offset STUDENTNAME
	mov ecx,20
	call readstring
	mov EDX,OFFSET EnterGrade
	call writeString
	call readInt
	mov EDX,OFFSET GRADE
	mov [EDX],al
	mov EDX,OFFSET EnterSec
	call writeString
	call readInt
	mov EDX,OFFSET SECTIONID
	mov [EDX],al
	call enrollStudent

	call printStudents 
	jmp Done

SAVE:
	mov EDX,OFFSET EnterKey
	call writeString
	call readInt
	mov DBKEY,AL
	mov EDX, OFFSET filename
	call saveDatabase
	jmp Done 

UPDATE:
	;READ ID
	mov EDX, OFFSET EnterID
	call writeString
	call ReadInt
	mov EBX,EAX
	;READ GRADE
	mov EDX, OFFSET EnterGrade
	call writeString
	call ReadInt
	call UpdateGrade
	jmp Done


Delete:
	call readInt
	call DeleteStudent
	call printStudents 
	jmp DONE

DisplayAll:
	call readInt
	call printStudents 
	jmp Done

DisplayStudent:
	call readInt
	call PrintStudent
	jmp Done

Done:
	mov EDX, OFFSET RepeatChoice
	call writeString
	call readChar
	cmp AL, 'y'
	je RepeatChoices
	exit
main ENDP

; --------------------------------------------------------------
; Opens: the DB File, Validate the DB key, Decrypt the data, 
;	Reads the file in "buffer" array.
; Receives:	EDX = Contains the OFFSET to the File Name String
;			AL  = Contains the DB KEY
; Parameters: FileName, DBKEY
; Returns: VOID
; --------------------------------------------------------------
openDatabase PROC USES EDX ECX EAX EBX  ; filename:ptr byte,DBKEY: byte
	mov DBKEY, AL

	; OPEN FILE
	call OpenInputFile
	mov fileHandle, EAX

	; check for errors
	cmp EAX, INVALID_HANDLE_VALUE
	jne FILE_OK
	jmp ERROR_FOUND
	
FILE_OK:
	; read the file into buffer
	mov EDX, OFFSET CopiedBuffer 
	mov ECX, LENGTHOF CopiedBuffer
	call ReadFromFile
	jnc CHECK_BUFFER_SIZE  ; Checking Reading Errors
	jmp ERROR_FOUND		   ; Error Found

CHECK_BUFFER_SIZE:
	cmp EAX, LENGTHOF CopiedBuffer  ; Check if buffer is large enough
	jg ERROR_FOUND			  ; Buffer is too small for the file
	jmp BUFFER_SIZE_OK		  

BUFFER_SIZE_OK:
	mov CopiedBuffer[EAX], 0    ; Adding Null Terminator

	; validate DB KEY	
	mov BL, DBKEY
	cmp CopiedBuffer[0], BL     ; Comparing The First Byte with the Given Key
	jne ERROR_FOUND		  ; Keys Don't Match

;copy the copied buffer to the buffer without the dbkey

mov ECX, EAX
dec ECX	
mov EDX, OFFSET buffer
mov EDI, OFFSET CopiedBuffer
inc EDI
COPY_BUFFER:
mov BL, [EDI]
cmp BL, 0
je done
mov [EDX], BL
inc EDI
inc EDX
loop COPY_BUFFER
done:
; Decrypt the buffer
	mov ECX, EAX		  ; Moving File Size to ECX
	;dec ECX				  ; Decrementing ECX to Avoid the DBKEY
	mov EDX, OFFSET buffer
	;inc EDX				  ; Incrementing EDX to Avoid the DBKEY
	mov AL, DBKey

	; TODO: Shift 1 to remove DB KEY

DECRYPT:
		xor [EDX], AL	  ; XORING Every BYTE with the DBKEY
		mov BL, [EDX]
		inc EDX
	LOOP DECRYPT
	mov EDX, OFFSET buffer
	call writeString
	call crlf
	mov EAX, fileHandle
	call CloseFile

	; mov EDX, OFFSET buffer
	; call writeString
	; call CRLF
	; TODO: Removing the First Byte from buffer
	ret

ERROR_FOUND:
	mov EAX, fileHandle
	call closeFile
	; TODO: Reset the buffer array
	mov EDX, OFFSET errorString 
	call writeString

	ret
openDatabase ENDP


;---------------------------------------------------------------
; Finds: Student by ID, and Update th grade
; Recieves: EBX = Student ID 
;			EAX = New Grade
; Parameters: ID,GRADE
; Returns: VOID
;---------------------------------------------------------------
updateGrade PROC
	mov ID, BL
	mov GRADE, AL
	
	mov EDX, OFFSET buffer
	mov ECX, BUFFER_SIZE
	mov SI, 0
	
ID_LOOP:
	; Check for the ID
	cmp [EDX],BL
	je ID_FOUND  ; ID IS FOUND
	; CONTINUE
	inc EDX
	loop ID_LOOP

	; ERROR ID IS NOT FOUND
	mov EDX, OFFSET errorString 
	call writeString
	jmp END_OF_FILE

ID_FOUND:
	inc EDX  ; Skip ID Byte
	; Skip Delimeter Byte
	inc EDX
	; mov delimeter 
	mov AL,FIELD_DELIMETER
	; Max Size of file
	mov ECX, BUFFER_SIZE
	; Skip NAME Bytes
NAME_LOOP:
	cmp [EDX], AL
	je END_OF_NAME  ; DELIMETER is FOUND, End of NAME Bytes
	inc EDX
	loop NAME_LOOP

	; ERROR FOUND
	mov EDX, OFFSET errorString 
	call writeString
	jmp END_OF_FILE

END_OF_NAME:
	inc EDX
	mov AL, GRADE
	mov [EDX], AL
	; MOV GRADE

END_OF_FILE:  ;Break the Loop
	mov ECX,1

	ret
updateGrade ENDP

;--------------------------------------------------------------
;receives ID IN AL
;PUTS '*' in the first byte in the record
;returns VOID
;--------------------------------------------------------------

DeleteStudent PROC USES EAX EBX EDI ECX ESI
;recieves ID in AL
mov EBX,EAX
call getLastIndex
mov EDI, OFFSET buffer
mov AL, RECORD_DELIMETER
cld

delete:
	cmp [EDI], ESI
	je ERROR
	cmp [EDI],BL  ;compare buffer byte with id
	je IDFOUND
	mov ECX, lengthof buffer
	repne SCASB
	je delete

;ERROR OCCURED
ERROR:
mov EDX,OFFSET errorString
call writeString
jmp DONE

;MOVE IN ID *
IDFOUND:
	mov AL,'*'
	mov [EDI], AL

DONE:
	ret
DeleteStudent ENDP


; --------------------------------------------------------------
; Saves: the Database File
; Recieves: EDX = OFFSET to the File Name String	
;			AL  = Database Key
; Returns: VOID
; --------------------------------------------------------------
saveDatabase PROC USES EAX EBX ECX EDX ESI EDI
	; Creating the DB File
	mov BL, AL  ; Saving the DB KEY Value in BL
	call CreateOutputFile

	; Checking for File Handle Errors
	cmp EAX, INVALID_HANDLE_VALUE
	jne ENCRYPT_STRING  ; No Error Found
	mov EDX, OFFSET errorString
	call writeString
	call CRLF
	ret					; Error Found

ENCRYPT_STRING:
	mov ESI, OFFSET buffer
	mov EDI, OFFSET encryptedBuffer
	mov [EDI], BL
	inc EDI
	mov ECX, LENGTHOF buffer
	call copyArray  ; Copying the buffer to encryptedBuffer for Encryption
	push EAX	    ; Saving File Handle
	mov AL, BL		; Retrieving the DB KEY Value
	mov ESI, OFFSET encryptedBuffer
	inc ESI
	call encryptString

	; Writing the DB Key String to the Database File
	pop EAX		  ; Retrieving File Handle
	mov EDX, OFFSET encryptedBuffer
	mov ECX, LENGTHOF encryptedBuffer
	push EAX      ; Saving File Handle
	call writeToFile
	mov EBX, EAX  ; Saving EAX Value (Number of Bytes Written in File)
	pop EAX		  ; Retrieving File Handle
	call closeFile
	mov EAX, EBX  ; Retrieving EAX Value (Number of Bytes Written in File)

	; Checking Write Errors
	cmp EAX, LENGTHOF encryptedBuffer
	je DONE_SAVING  ; EAX == LENGTHOF buffer (NO ERROR)
	; EAX != LENGTHOF buffer (ERROR)
	mov EDX, OFFSET errorString
	call writeString
	call CRLF
	ret
DONE_SAVING:
	mov EDX, OFFSET successString
	call writeString
	call CRLF
	ret
saveDatabase ENDP


; --------------------------------------------------------------
; Copies: the input Array to the Output Array
; Recieves: ESI = OFFSET to the Input Array
;			EDI = OFFSET to the Output Array
;			ECX = Length of the Input Array
; Returns: VOID
; --------------------------------------------------------------
copyArray PROC USES ESI EDI	ECX	EAX
COPY_LOOP:
	mov AL, [ESI]
	mov [EDI], AL
	inc ESI
	inc EDI
	LOOP COPY_LOOP
	
	ret
copyArray ENDP


; --------------------------------------------------------------
; Encrypt: the input Array by XORING each
;	BYTE with the DB KEY
; Recieves: ESI = OFFSET to the Input Array
;			AL  = DB KEY
;			ECX = LENGTH OF the Input Array
; Returns: VOID
; --------------------------------------------------------------
encryptString PROC USES ESI EAX EBX
ENCRYPT_LOOP:
	XOR [ESI], AL
	inc ESI
	LOOP ENCRYPT_LOOP

	ret
encryptString ENDP


; DllMain is required for any DLL
DllMain PROC hInstance:DWORD, fdwReason:DWORD, lpReserved:DWORD 

mov eax, 1		; Return true to caller. 
ret 				
DllMain ENDP

END main	   ; For Running EXE
; END DllMain  ; For Exporting a DLL
