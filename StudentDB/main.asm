include irvine32.inc

; CONSTANTS
BUFFER_SIZE = 1024
FIELD_DELIMETER = '/'
RECORD_DELIMETER = '@'
.data
IDs BYTE 21 DUP(?), 0
SectionStudents BYTE BUFFER_SIZE DUP(?) , 0
convertedNum BYTE 3 DUP(?), 0
NO_STUDENTS_ERROR BYTE "THERE IS NO STUDENTS IN THIS SECTION", 0
CHOICES BYTE "PRESS (1) TO OPEN DATABASE ", 10, 13, "PRESS (2) TO Enroll new Student ", 10, 13, "PRESS (3) TO Save DATABASE ", 10, 13, "PRESS (4) TO Update Student's Grade ", 10, 13, "PRESS (5) TO Delete a Student ", 10, 13, "PRESS (6) TO Print Student", 10, 13, "PRESS (7) TO PRINT SPECIFIC STUDENT", 10, 13, "Press (8) To Generate Section Report", 10, 13, 0
RepeatChoice BYTE "Do you want to Enter another choice? 'y/n' ",10 ,13, 0
EnterID BYTE "ENTER STUDENT'S ID: ", 0
EnterName BYTE "ENTER STUDENT'S Name: ", 0
EnterGrade BYTE "ENTER STUDENT'S Grade: ", 0
EnterSec BYTE "ENTER STUDENT'S Section Number (1-2): ", 0
EnterKey BYTE "ENTER DATA BASE KEY: ", 0
EnterSecNum BYTE "ENTER SECTION NUMBER: ", 0
CopiedBuffer BYTE BUFFER_SIZE DUP(?)
buffer BYTE	BUFFER_SIZE DUP(?)
encryptedBuffer BYTE 0, BUFFER_SIZE DUP(?)
SECTION1FILENAME BYTE "Section1.txt", 0
SECTION2FILENAME BYTE "Section2.txt", 0
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

	; call printStudents 
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
mov AL, FIELD_DELIMETER

delete:
	cmp EDI, ESI	;check end of buffer
	je ERROR
	cmp [EDI],BL  ;compare buffer byte with id
	je IDFOUND
	;skip to next record
	inc EDI		;skip ID	
	inc EDI		;skip Delimeter
	skipName:
		cmp [EDI], AL ;check end of name
		je CONTINUE
		inc EDI
	jmp skipName
	CONTINUE:
		add EDI, 6
	jmp delete

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
	mov ECX, LENGTHOF buffer
	mov EDI, offset buffer
	call getLastIndex
	cmp ESI, EDI
	je ok
GET_SECTION_STUDENT_NUMBER:
	cmp ESI,EDI
	je CALCULATE
	add EDI, 2
	mov AL, FIELD_DELIMETER
	SKIP_NAME:
		mov BL, [EDI]
		cmp [EDI], AL
		je CONTINUE
		inc EDI
	jmp SKIP_NAME
CONTINUE:
	add EDI,3
	mov BL,[EDI]
	cmp BL,1
	jne SECTION_2
	inc section1
	jmp CONT
SECTION_2:
	inc section2
CONT:
	add EDI, 3
	loop GET_SECTION_STUDENT_NUMBER
CALCULATE:
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
	mov AL, 13
	mov AL, 10
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
	
	mov AL, 13
	mov AL, 10
	mov	[ESI],AL

	jmp DONE
	err:

	DONE:
	;mov EDX, offset buffer 
	;call writestring
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

getLastIndex PROC USES EDX EAX ECX EDI
	mov ECX, LENGTHOF buffer
	mov EDX, offset buffer
	mov ESI, offset buffer
LAST_RECORD_CHECK:
	mov EDI, ESI
	mov AL, FIELD_DELIMETER
	add ESI, 2
SKIP_NAME:
		cmp [ESI], AL
		je CONTINUE
		inc ESI
		dec ECX
		cmp ECX, 0
		je RETURN
	jmp SKIP_NAME
CONTINUE:
	add ESI, 6
	sub ECX, 5
	loop LAST_RECORD_CHECK
RETURN:
	mov ESI, EDI
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
	mov BL, '*'  ; Checking for a Deleted Record
	cmp [ESI], BL
	je SKIP_RECORD  ; If Deleted Skip to the Next Record Delimeter
	; XORing the Byte with the DB Key
	mov BL, [ESI]
	mov [EDI], BL
	xor [EDI], AL
	inc EDI  ; Incrementing the encryptedBuffer OFFSET
	jmp CONTINUE

	SKIP_RECORD:
		add ESI, 2
		SKIP_NAME:
			mov BL, FIELD_DELIMETER
			cmp [ESI], BL
			je CONTINUE_SKIP  ; Next field is found
			inc ESI
			dec ECX
		jmp SKIP_NAME
	
	CONTINUE_SKIP:
		add ESI, 5
		sub ECX, 5

	CONTINUE:
	inc ESI
	cmp ECX, 0
	je RETURN  ; Checking if ECX Reached the End during Record Skipping
	LOOP COPY_LOOP
	
RETURN:
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
;display student's data
;Recieves student's id in AL
;RETURN VOID
;---------------------------------------------------------------------
PrintStudent PROC
mov EBX,EAX
call getLastIndex
mov EDI, OFFSET buffer
mov AL, FIELD_DELIMETER

ID_SEARCH:
	cmp EDI, ESI		;check end of buffer
	je ERROR
	cmp [EDI],BL  ;compare buffer byte with id
	je IDFOUND

	add EDI,2
	skipName:
		cmp [EDI], AL	;check end of name
		je CONTINUE
		inc EDI
	jmp skipName

	CONTINUE:	
		add EDI, 5
jmp ID_SEARCH

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
;RECIEVES section number in eax
;RETURNS void
;-----------------------------------------------------------
generateSectionReport PROC USES EDX ECX EDI EBX ESI EAX
push EAX  ;store section number

mov EDX, OFFSET IDs
mov ECX, lengthof IDs
call clearArray

mov EDX, OFFSET SectionStudents
mov ECX, lengthof SectionStudents
call clearArray

;get last offset in the buffer
call getLastIndex
mov EDI, OFFSET buffer
mov EDX, OFFSET IDs

;get all section IDs
getSectionIDs:
	mov BL, [EDI]  ;store student's ID temp

	;skip until record delimeter
	;push ECX
	push EBX
	;mov ECX, lengthof buffer
	mov BL, FIELD_DELIMETER
	skipRecord:
		add EDI,2  ;skip id
		skipName:
			cmp [EDI], BL  ;check end of name
			je CNT
			inc EDI
		jmp skipName
		CNT:
		 add EDI, 3	;skip grade

END_OF_RECORD:
		pop EBX

		cmp [EDI], AL 
		jne continue	;student is not from the required section
		;ADD Student ID in IDs array
		mov [EDX], BL
		inc EDX	
		continue:
			;skip 2 bytes to the begining of the next record
			add EDI, 3
			cmp EDI,ESI  ; Check end of buffer
			je SORT
jmp getSectionIDs

SORT:
	mov esi, offset IDs
	mov BL,0
	cmp [ESI], BL	
	je NO_STUDENTS_FOUND  ; no students in the section
	call sortIDs	
	jmp getStudents

	NO_STUDENTS_FOUND:	  ;display error msg, break the PROC
		mov EDX, OFFSET NO_STUDENTS_ERROR
		call writeString 
		call crlf
		pop EAX
		ret

;get students by sorted IDs
getStudents:
	mov EDX, OFFSET IDs
	mov ECX, LENGTHOF IDs
	;TODO esi contains last offset in buffer

	mov ESI, OFFSET SectionStudents

	iterateIDs:
	mov AL, FIELD_DELIMETER
	mov BL, 0
	cmp [EDX], BL  ;check ids termination
	je END_OF_IDs

	mov BL, [EDX]  ;store ID 
	;push ECX		;store outer loop counter
	
	;iterate over "buffer" until reach ID record
	mov EDI, OFFSET buffer

		studentSearch:
		;TODO check end of buffer
		cmp [EDI], BL  ;check if student's id == id
		je STUDENT_FOUND

		SKIP_RECORD:
			add EDI, 2  ;SKIP ID
			skip:
				cmp [EDI], AL  ;CHECK END OF NAME
				je END_OF_NAME
				inc EDI
			jmp skip
	END_OF_NAME:
		add EDI, 6

		CONTINUE_SEARCH:
			;inc EDI		;skip record Delimter
		loop studentSearch

	STUDENT_FOUND:
		;mov ID to convert it into string
		movzx EAX, byte ptr[EDI]
		inc EDI ;skip ID byte
		inc EDI ;skip delmieter byte
		push ESI
		mov ESI , OFFSET convertedNum
		call parseNumberString	
		pop ESI
		mov EBX, ECX
		mov EBX, OFFSET convertedNum
		;copy string ID into sectionStudents array
		copyID:
			mov AL, [EBX]
			mov [ESI], AL
			inc ESI
		loop copyID
		;ADD delimeter
		mov AL,' '
		mov [ESI],AL
		mov AL, FIELD_DELIMETER
		inc ESI

		;copy student name into sectionStudents array
		mov ECX, lengthof buffer	
		copyName:
			cmp AL, [EDI] ;check end of name
			je COPY
			mov BL, [EDI]
			mov [ESI], BL
			inc ESI
			inc EDI
		loop copyName

	COPY:
		;ADD Delimeter
		mov AL, ' '
		mov [ESI], AL	
		inc ESI
		inc EDI

		;copy numeric grade
		push ESI
		;convert numeric grade into string
		movzx EAX, byte ptr [EDI]	
		mov ESI, OFFSET convertedNum	
		call parseNumberString 
		pop ESI
		mov EBX, OFFSET convertedNum
		copyGrade:
			mov AL,[EBX]
			mov [ESI], AL	
			inc ESI
		loop copyGrade
	
		mov AL,' '
		mov [ESI], AL
		inc ESI

		;get alphabetic grade
		movzx EAX, byte ptr[EDI]
		call GetAlphabeticalGrade
		; al contains alphabetic grade
		;copy alphabetic grade
		mov [ESI], AL
		inc ESI
		
		;ADD new line
		mov AL, 13
		mov [ESI],AL
		inc ESI
		mov AL, 10
		mov [ESI],AL
		inc ESI	

		pop ECX
		inc EDX
		dec ECX
		mov EBX,0
		cmp EBX, ECX	;check end of IDs array
	jne iterateIDs

END_OF_IDs:

GET_FILE_NAME:
	pop EAX		;Required Section Number
	cmp AL, 1	
	je Sec1
	jmp Sec2
	Sec1:
		mov EDX, OFFSET SECTION1FILENAME
		jmp CreateNewFile
	Sec2:
		mov EDX, OFFSET SECTION2FILENAME	
	
	CreateNewFile:
	call CreateOutputFile
	; Checking for File Handle Errors
	cmp EAX, INVALID_HANDLE_VALUE
	jne copytofile  ; No Error Found
	mov EDX, OFFSET errorString
	call writeString
	call CRLF
	ret					; Error Found

copytofile:
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

CLEAR_ARRAYS:
mov EDX, OFFSET IDs
mov ECX, lengthof IDs
call clearArray

mov EDX, OFFSET SectionStudents
mov ECX, lengthof SectionStudents
call clearArray

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


; --------------------------------------------------------------
; Parse: the integer value to string Database File
; Recieves: ESI = OFFSET to the empty number string	
;			EAX  = Integer Value
; Returns: VOID
; --------------------------------------------------------------
parseNumberString PROC USES ESI EAX
	mov ECX, 0
	push ESI  ; Saving the OFFSET Value
	PARSING_LOOP:
		mov EDX, 0
		mov EBX, 10
		div EBX                  ; Dividing by 10 to get the Last Digit
		add ECX, 1               ; Counting Digits
		mov EBX, EDX
		mov [ESI], BL            ; Moving the Remainder to [ESI]
		mov BL, '0'
		add [ESI], BL			 ; Adding 0 ASCII Value to the Digit
		mov BL, [ESI]
		inc ESI 
		cmp EAX, 0				 ; Checking the End of Value
	jne PARSING_LOOP

	pop ESI   ; Retrieving the OFFSET Value
	mov EDI, ESI
	mov EBX, ECX  ; Saving the ECX Value 
	; Reversing the String
	mov EAX, 0
	PUSH_STACK:
		mov AL, [ESI]
		push EAX
		inc ESI
	LOOP PUSH_STACK
	
	mov ECX, EBX  ; Retrieving the Value of ECX
	mov ESI, EDI  ; Retrieving the Value of ESI
	POP_STACK:
		pop EAX
		mov [ESI], AL
		inc ESI
	LOOP POP_STACK

	ret
parseNumberString ENDP


; DllMain is required for any DLL
DllMain PROC hInstance:DWORD, fdwReason:DWORD, lpReserved:DWORD 

mov eax, 1		; Return true to caller. 
ret 				
DllMain ENDP

END main	   ; For Running EXE
; END DllMain  ; For Exporting a DLL
