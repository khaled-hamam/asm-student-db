include irvine32.inc

; CONSTANTS
BUFFER_SIZE = 1024
FIELD_DELIMETER = '/'
RECORD_DELIMETER = '@'
.data
IDs BYTE 21 DUP(?), 0
SectionStudents BYTE BUFFER_SIZE DUP(?) , 0
CHOICES BYTE "PRESS (1) TO OPEN DATABASE ", 10, 13, "PRESS (2) TO Enroll new Student ", 10, 13, "PRESS (3) TO Save DATABASE ", 10, 13, "PRESS (4) TO Update Student's Grade ", 10, 13, "PRESS (5) TO Delete a Student ", 10, 13, "PRESS (6) TO Print Student", 10, 13, "PRESS (7) TO PRINT SPECIFIC STUDENT", 10, 13, 0
RepeatChoice BYTE "DO you want to Enter another choice? 'y/n' ",10 ,13, 0
EnterID BYTE "ENTER STUDENT'S ID: ", 0
EnterName BYTE "ENTER STUDENT'S Name: ", 0
EnterGrade BYTE "ENTER STUDENT'S Grade: ", 0
EnterSec BYTE "ENTER STUDENT'S Section Number (1-2): ", 0
EnterKey BYTE "ENTER DATA BASE KEY: ", 0
CopiedBuffer BYTE BUFFER_SIZE DUP(?)
buffer BYTE	BUFFER_SIZE DUP(?)
encryptedBuffer BYTE 0, BUFFER_SIZE DUP(?)
SECTIONFILENAME BYTE "F:\Downloads\Irvine\Project_Template\files\check.txt", 0
filename BYTE "database.txt", 0
DBKEY BYTE 65
fileHandle HANDLE ?
errorString BYTE "An Error Occured.", 0
successString BYTE "Saving Completed.", 0

section1 BYTE 0
section2 BYTE 0

ID BYTE ?
GRADE BYTE ?
STUDENTNAME BYTE 100 DUP(?)
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
	mov EDX, offset STUDENTNAME
	mov ECX, Lengthof STUDENTNAME
	call clearArray
	mov EDX,OFFSET EnterName
	call writeString

	mov EDX, OFFSET STUDENTNAME	
	mov ECX, lengthof STUDENTNAME ;clearing name 
	call clearArray

	mov edx,offset STUDENTNAME
	mov ecx, Lengthof STUDENTNAME
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
;	call readInt
	call printStudents 
	jmp Done

DisplayStudent:
	call readInt
	call generateSectionReport
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
; Function: Enroll a Student.
; Input: Student ID, Student Name, Student Grade, Student section 
; --------------------------------------------------------------
enrollStudent PROC USES EDX ECX EBX ESI EAX EDI ;sId:byte, sName:byte, intGrade:byte, sectionNum:byte
	; Validating Section Size
	mov ESI, OFFSET buffer  
	mov ECX, LENGTHOF buffer  ; Loop On BUFFER_SIZE
	mov AL, RECORD_DELIMETER  ; Get NewLine Delimeter
	; Count Number Of Students In Each Section
GET_SECTION_STUDENT_NUMBER:
		cmp [ESI], AL         ; Comparing Current OFFSET with the Record Del
		je FOUND_DELIMETER    ; Jump If Delimeter Found
		jmp CONTINUE		  
		FOUND_DELIMETER:
			mov BL, [ESI -1]  ; Copy the Byte Before Delimeter Which Contains Section ID
			cmp BL, 1         ; Compare the Section ID with First Section 
			jne SECTION_2     ; jump If Not First Section ID
			inc section1	  ; INC section1 Counter
			jmp CONTINUE      
		SECTION_2:
			inc section2      ; INC section2 Counter
		CONTINUE:
			inc ESI           ; INC Current OFFSET
	loop GET_SECTION_STUDENT_NUMBER

	mov AL, SECTIONID         ; Moving SECTIOND "INPUT"
	mov BL, section1		  ; Moving counter Of section1 
	cmp AL, 1				  ; Compare the SECTIONID with First Section
	jne SEC_2				  ; jump IF SECTIONID Not First Section
		cmp BL, 20			  ; Compare First Section with Max Students/Section
		ja err                ; Jump error IF First Section Counter Greater Than Max Students/Section
		jmp OK				  ; Continue Enroll Student
SEC_2:
	mov BL,section2           ; Moving counter Of section2
	cmp BL,20				  ; Compare second Section with Max Students/Section
	ja err					  ; Jump error IF Second Section Counter Greater Than Max Students/Section
	OK:

	; Getting Last Record Delimeter Index
	mov ECX, LENGTHOF buffer
	mov AL, RECORD_DELIMETER
	call getLastIndex
	mov AL, ID
	mov [ESI], AL
	inc ESI
	mov AL, FIELD_DELIMETER
	mov [ESI], AL
	inc ESI
	mov EDI, offset STUDENTNAME
	mov BL, 0
	mov ECX, Lengthof STUDENTNAME
	l:
		mov AL, [EDI]
		cmp [EDI], BL
		je end1
			mov EAX, [EDI]
			mov [ESI], EAX
			inc ESI
			inc EDI
	loop l
	end1:
	;add ESI,-2
	mov AL, FIELD_DELIMETER  ; Copy FIELD_DELIMETER 
	mov [ESI], AL			 ; Add FIELD_DELIMETER To Buffer
	inc ESI					 ; INC ESI To point To Byte After Delimeter
	
	mov AL, GRADE			 ; Copy GRADE
	mov [ESI], AL			 ; Add GRADE To Buffer
	inc ESI					 ; INC ESI To point To Byte After GRADE 
	
	mov AL, FIELD_DELIMETER  ; Copy FIELD_DELIMETER 
	mov [ESI], AL			 ; Add FIELD_DELIMETER To Buffer
	inc ESI					 ; INC ESI To point To Byte After Delimeter
	
	mov AL, SECTIONID		 ; Copy SECTIONID 
	mov [ESI], AL			 ; Add SECTIONID To Buffer
	inc ESI
	
	mov AL,RECORD_DELIMETER	
	mov	[ESI],AL

	jmp DONE
	err:

	DONE:
	ret
enrollStudent ENDP

printStudents PROC
	call getLastIndex
	mov EDI, ESI
	mov ESI, OFFSET buffer
	mov ECX, LENGTHOF buffer

BUFFER_LOOP:
	movzx EAX, BYTE PTR [ESI]
	call writeDec
	add ESI, 2
	mov Al,' '
	call writeChar

	mov BL, FIELD_DELIMETER
	PRINT_NAME:
		cmp [ESI], BL
		je SECTION_GRADE
		mov AL, [ESI]
		call writeChar
		inc ESI
		loop PRINT_NAME

	SECTION_GRADE:
		inc ESI
		mov AL,' '
		call writeChar
		movzx EAX, BYTE PTR [ESI]
		call writeDec
		add ESI, 2
		mov AL,' '
		call writeChar

		movzx EAX, BYTE PTR [ESI]
		call writeDec
		add ESI, 2
		mov AL,' '
		call writeChar

		mov AL,10
		call writeChar
		cmp ESI, EDI
		je RETURN
	loop BUFFER_LOOP

RETURN:
	ret
printStudents ENDP

; --------------------------------------------------------------
; Function: GetAlphabeticalGrade.
; Input: Grade as a Number 
; Returns: Alphabetical Grade in AL
; --------------------------------------------------------------
GetAlphabeticalGrade PROC USES ECX EDX
	; Number should be In EAX 
	mov ECX,100
	cmp EAX,ECX
	jnbe done
		cmp EAX,90
		jnae else1
			mov AL,'A'
			jmp done
		else1:
			cmp EAX,80
			jnae else2
				mov AL, 'B'
				jmp done
		else2:
			cmp EAX,70
			jnae else3
				mov AL,'C'
				jmp done
		else3:
			cmp EAX,60
			jnae else4
				mov AL,'D'
				jmp done
		else4:
			mov AL,'F'
			jmp done
	done:
call writeChar
	ret
GetAlphabeticalGrade ENDP 

; --------------------------------------------------------------
; Gets: The last BYTE OFFSET in the Buffer
; Recieves: VOID
; Returns: The OFFSET in the ESI
; --------------------------------------------------------------

getLastIndex PROC USES EDX EAX ECX
	mov ECX, LENGTHOF buffer
	mov EDX, offset buffer
	mov ESI, offset buffer
	mov AL, RECORD_DELIMETER
LAST_RECORD_CHECK:
	cmp [EDX], AL  ; Comparing Current OFFSET with the Record Del.
	jne CONT
	mov ESI, EDX   ; IF Equal, Save the Current OFFSET to ESI
	inc ESI		   ; INC ESI to point on the byte after the Record Del.
	CONT:
		inc EDX
	loop LAST_RECORD_CHECK
	
	ret
getLastIndex ENDP

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
	push EAX  ; Saving File Handle Value
	mov ESI, OFFSET buffer
	mov EDI, OFFSET encryptedBuffer
	mov ECX, LENGTHOF buffer
	mov AL, BL
	mov [EDI], BL  ; Copying the DB KEY to the First Byte
	inc EDI
	call encryptBuffer  ; Copying Valid Records and XORing each Byte with the Key

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
;			AL  = DB KEY
; Returns: VOID
; --------------------------------------------------------------
encryptBuffer PROC USES ESI EDI	ECX	EAX EBX

COPY_LOOP:
	mov BL, '*'
	cmp [ESI], BL
	je SKIP_RECORD
	mov BL, [ESI]
	mov [EDI], BL
	xor [EDI], AL
	inc EDI
	jmp CONTINUE

	SKIP_RECORD:
		mov BL, RECORD_DELIMETER
		cmp [ESI], BL
		je CONTINUE
		inc ESI
	LOOP SKIP_RECORD

	CONTINUE:
	inc ESI
	LOOP COPY_LOOP
	
	ret
encryptBuffer ENDP
; --------------------------------------------------------------
; Sort:	Sort section IDs
; Recieves: ESI = OFFSET to the IDs Array
; Returns: VOID
; --------------------------------------------------------------
sortIDs PROC USES EAX ECX ESI EDI
	mov ECX, lengthof IDs
	dec ECX 
	outerLoop:
		push ecx
		mov esi, offset IDs
		mov al, [esi]
		cmp al, 0
		je terminate
		innerLoop:
			mov al,[esi+1]
			cmp al, 0
			je noExchange
			mov al, [esi]
			cmp [esi+1], al
			jg noExchange
			xchg al,[esi+1]
			mov [esi],al
			noExchange:
			inc esi
		LOOP innerLoop
		pop ecx
	LOOP outerLoop
	terminate:

	mov esi , offset IDs
	
	ret 
sortIDs ENDP
;---------------------------------------------------------------------
;Recieves student's id in al
;display student's data
;---------------------------------------------------------------------
PrintStudent PROC
mov EBX,EAX
call getLastIndex
mov EDI, OFFSET buffer
mov AL, RECORD_DELIMETER
cld

ID_SEARCH:
	cmp [EDI], ESI
	je ERROR
	cmp [EDI],BL  ;compare buffer byte with id
	je IDFOUND
	mov ECX, lengthof buffer
	repne SCASB
	je ID_SEARCH

;ERROR OCCURED
ERROR:
mov EDX,OFFSET errorString
call writeString
ret

IDFOUND:
movzx EAX, byte ptr [EDI]
call writeDec  ;display ID

mov AL," "
call writeChar

inc EDI
inc EDI
mov BL, FIELD_DELIMETER
mov ecx, BUFFER_SIZE
DisplayName:
cmp [EDI], BL
je END_OF_NAME
mov AL, [EDI]
call writeChar
inc EDI
loop DisplayName
END_OF_NAME:
mov AL," "
call writeChar

inc EDI
movzx EAX,byte ptr [EDI]
call writeDec ;display grade

mov AL," "
call writeChar

inc EDI
inc EDI
movzx EAX, byte ptr[EDI]
call writeDec ;display sec id
call crlf
ret
PrintStudent ENDP
;-----------------------------------------------------------
;takes section number, get section's studetns's id, sort them,
;get sorted id's students from "buffer"
;create new file, put the buffer in it
;recieves section number in eax
;returns void
;-----------------------------------------------------------
generateSectionReport PROC USES EDX ECX EDI EBX ESI EAX
mov EDX, OFFSET IDs
mov ECX, lengthof IDs
call clearArray
mov EDX, OFFSET SectionStudents
mov ECX, lengthof SectionStudents
call clearArray
call getLastIndex
mov EDI, OFFSET buffer
mov EDX, OFFSET IDs
mov ECX, LENGTHOF IDs
;section number in eax
;esi contains last offset int buffer
getSectionIDs:
mov BL, [EDI]  ;store student's ID temp
;skip until record delimeter
push ECX
push EBX
mov ECX, lengthof buffer
mov BL, RECORD_DELIMETER
skipRecord:
cmp [EDI],BL
je END_OF_RECORD
inc EDI
loop skipRecord
;jmp ERROR
END_OF_RECORD:
pop EBX
pop ECX

dec EDI
cmp [EDI],AL
jne continue
;add id
mov [EDX], BL
inc EDX
continue:
inc EDI
inc EDI
cmp EDI,ESI  ; Check end of buffer
je SORT
loop getSectionIDs

SORT:
mov esi, offset IDs
call sortIDs

call crlf
;get students from buffer with ids
;create new file
mov EDX, OFFSET IDs
mov ECX, LENGTHOF IDs
;TODO esi contains last offset in buffer

mov ESI, OFFSET SectionStudents
mov AL, RECORD_DELIMETER

iterateIDs:
mov BL, 0
cmp [EDX], BL  ;check for end of ids
je END_OF_IDs

mov BL, [EDX]  ;store id 
push ECX
mov EDI, OFFSET buffer
mov ECX, LENGTHOF buffer

	studentSearch:
	;TODO check end of buffer
	cmp [EDI],BL  ;check if student's id == id
	je STUDENT_FOUND
	SKIP_RECORD:
		cmp [EDI],AL
		je CONTINUE_SEARCH  ;search end of record
		inc EDI
	loop SKIP_RECORD
	CONTINUE_SEARCH:
	inc EDI
	loop studentSearch

;TODO ERROR Student is not found
STUDENT_FOUND:
	mov ECX, lengthof buffer
	copyStudent:
		cmp [EDI], AL ;check for end of record
		je END_OF_RECORDs
		mov BL, [EDI] 
		mov [ESI], BL ;copy the record 
		inc ESI
		inc EDI
	loop copyStudent
;TODO ERROR end of record is not reached
END_OF_RECORDs:
	dec ESI
	dec ESI
	dec ESI
	push EAX
	movzx EAX, byte ptr[ESI]
	call GetAlphabeticalGrade
	inc ESI
	inc ESI
	mov [ESI], AL
	inc ESI
	mov BL, [EDI] 
	mov [ESI],BL ;copy record delimeter
	inc ESI
	pop EAX
	pop ECX
	inc EDX
loop iterateIDs



END_OF_IDs:

ERROR:
	mov EDX, OFFSET SECTIONFILENAME
	call CreateOutputFile

	; Checking for File Handle Errors
	cmp EAX, INVALID_HANDLE_VALUE
	jne copytofile  ; No Error Found
	mov EDX, OFFSET errorString
	call writeString
	call CRLF
	ret					; Error Found

copytofile:
	; Writing the DB Key String to the Database File
	mov EDX, OFFSET SectionStudents
	mov ECX, LENGTHOF SectionStudents
	push EAX      ; Saving File Handle
	call writeToFile
	mov EBX, EAX  ; Saving EAX Value (Number of Bytes Written in File)
	pop EAX		  ; Retrieving File Handle
	call closeFile
	mov EAX, EBX  ; Retrieving EAX Value (Number of Bytes Written in File)

	; Checking Write Errors
	cmp EAX, LENGTHOF SectionStudents
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
done:
mov EDX, OFFSET IDs
mov ECX, lengthof IDs
call clearArray

;print record
mov EDX, OFFSET SectionStudents
call writeString
mov ECX, 2
display:
movzx EAX, byte ptr[EDX]
call writeInt
inc EDX
inc EDX
push ECX
mov ECX, lengthof SectionStudents
mov BL, FIELD_DELIMETER
displayName:
cmp [EDX], BL
je END_OF_NAME
mov AL, [EDX]
call writeChar
inc EDX
loop displayName
END_OF_NAME:
call crlf
pop ECX
inc EDX
movzx eax, byte ptr[edx]
call writeInt
inc EDX
inc EDX
mov AL, [EDX]
call writeChar
call crlf
loop display

	
ret
generateSectionReport ENDP

;TODO REPLACE PROC
;-----------------------------------------------------------------------------------------
;Clear the array
;recieves array offset in EDX, lengthof array in ECX
;return void
;-----------------------------------------------------------------------------------------
clearArray PROC USES EAX
mov AL, 0
clear:
mov [EDX],AL
inc EDX
loop clear
ret
clearArray ENDP

;-----------------------------------------------------------------------------------------
;Clear the array
;recieves array offset in EDX, lengthof array in ECX
;return void
;-----------------------------------------------------------------------------------------
clearArray PROC USES EAX
mov AL, 0
clear:
mov [EDX],AL
inc EDX
loop clear
ret
clearArray ENDP


; DllMain is required for any DLL
DllMain PROC hInstance:DWORD, fdwReason:DWORD, lpReserved:DWORD 

mov eax, 1		; Return true to caller. 
ret 				
DllMain ENDP

END main	   ; For Running EXE
; END DllMain  ; For Exporting a DLL
