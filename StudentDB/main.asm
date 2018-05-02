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
Grades BYTE 21 DUP(?), 0
section1 BYTE 0
section2 BYTE 0
ID BYTE ?
GRADE BYTE ?
STUDENTNAME BYTE 100 DUP(?)
SECTIONID BYTE ?


.code
; --------------------------------------------------------------
; openDatabase PROC
;
; Opens: the DB File, Validate the DB key, Decrypt the data, 
;	Reads the file into the "buffer" array.
; Receives:	openFileName = Contains the OFFSET to the File Name String
;			openDBKey  = Contains the DB KEY
; Returns: VOID
; --------------------------------------------------------------
openDatabase PROC USES EDX ECX EAX EBX openFileName: PTR BYTE, openDBKey: BYTE
	; OPEN FILE
	mov EDX, openFileName
	call OpenInputFile
	mov fileHandle, EAX
	; check for errors
	cmp EAX, INVALID_HANDLE_VALUE
	jne FILE_OK
	jmp ERROR_FOUND
	
FILE_OK:
	; read the file into buffer
	push EDX
	push ECX
	mov EDX, OFFSET CopiedBuffer  
	mov ECX, LENGTHOF CopiedBuffer
	call clearArray  ; Clearing the encryptedBuffer Array
	pop ECX
	pop EDX

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
	mov BL, openDBKey
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
		mov [EDX], BL
		inc EDI
		inc EDX
	loop COPY_BUFFER
done:
; Decrypt the buffer
	mov ECX, EAX		      ; Moving File Size to ECX
	;dec ECX				  ; Decrementing ECX to Avoid the DBKEY
	mov EDX, OFFSET buffer
	;inc EDX				  ; Incrementing EDX to Avoid the DBKEY
	mov AL, openDBKey
	; TODO: Shift 1 to remove DB KEY
DECRYPT:
		xor [EDX], AL	  ; XORING Every BYTE with the DBKEY
		mov BL, [EDX]
		inc EDX
	LOOP DECRYPT
	;mov EDX, OFFSET buffer
	;call writeString
	;call crlf
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
	;call writeString
	;call CRLF
	ret
openDatabase ENDP


;---------------------------------------------------------------
; updateGrade PROC
;
; Finds: Student by ID, and Update the grade
; Recieves: updateStudentID = Student ID 
;			updateStudentGrade = New Grade
; Returns: VOID
;---------------------------------------------------------------
updateGrade PROC USES EBX EAX EDX ECX ESI updateStudentID: BYTE, updateStudentGrade: BYTE
	movzx EBX, updateStudentID
	mov EDX, OFFSET buffer
	call getLastIndex
	push EAX
	mov AL, FIELD_DELIMETER
SEARCH_ID:
	cmp EDX, ESI
	je ERROR_FOUND
	cmp [EDX], BL
	je ID_FOUND	
	add EDX, 2	;skip ID
	skipName:
		cmp [EDX], AL  ;CHECK end of name
		je CONTINUE 
		inc EDX
	jmp skipName
	CONTINUE:
		add EDX, 6
jmp SEARCH_ID
ERROR_FOUND:
	; ERROR ID IS NOT FOUND
	mov EDX, OFFSET errorString 
	;call writeString
	;call crlf
	pop EAX
	jmp END_OF_FILE
ID_FOUND:
	pop EAX
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
	;call writeString
	;call crlf
	jmp END_OF_FILE
END_OF_NAME:
	inc EDX
	mov AL, updateStudentGrade
	mov [EDX], AL
	; MOV GRADE
END_OF_FILE:  ;Break the Loop
	ret
updateGrade ENDP


;---------------------------------------------------------------
; deleteStudent PROC
;
; Finds: Student by ID, and delete the record by putting '*'
;		 in the id field
; Recieves: deleteID = Student ID 
; Returns: VOID
;---------------------------------------------------------------
deleteStudent PROC USES EAX EBX EDI ECX ESI deleteID: BYTE
movzx EBX, deleteID
call getLastIndex
mov EDI, OFFSET buffer
mov AL, FIELD_DELIMETER
delete:
	cmp EDI, ESI	;check end of buffer
	je ERROR
	cmp [EDI], BL  ;compare buffer byte with id
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
	;call writeString
	jmp DONE
	;MOVE IN ID *
IDFOUND:
	mov AL,'*'
	mov [EDI], AL
DONE:
	ret
deleteStudent ENDP


; --------------------------------------------------------------
; EnrollStudent PROC
;
; Add: the new student record to the buffer string
; Receives:	enrollID = Student ID
;			enrollName = Student Name String
;			enrollNameSize = Length of Student Name String
;			enroll Grade = Student Grade
;			enrollSection = Student Section
; Returns: VOID
; --------------------------------------------------------------
enrollStudent PROC USES EDX ECX EBX ESI EAX EDI enrollID: BYTE, enrollName: PTR BYTE, enrollNameSize: BYTE, enrollGrade: BYTE, enrollSection: BYTE
	; Validating Section Size
	mov ECX, LENGTHOF buffer
	mov EDI, offset buffer
	call getLastIndex
	cmp ESI, EDI
	je ok
GET_SECTION_STUDENT_NUMBER:
	cmp ESI, EDI
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
	add EDI, 3
	mov BL, [EDI]
	cmp BL, 1
	jne SECTION_2
	inc section1
	jmp CONT
SECTION_2:
	inc section2
CONT:
	add EDI, 3
	loop GET_SECTION_STUDENT_NUMBER
CALCULATE:
	mov AL, enrollSection     ; Moving Section Number "INPUT"
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
	mov ECX, LENGTHOF buffer
	call getLastIndex
	mov AL, enrollID
	mov [ESI], AL
	inc ESI
	mov AL, FIELD_DELIMETER
	mov [ESI], AL
	inc ESI
	mov EDI, enrollName
	mov BL, 0
	; TODO: Fixing the Length of enrollName
	movzx ECX, enrollNameSize
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
	
	mov AL, enrollGrade		 ; Copy GRADE
	mov [ESI], AL			 ; Add GRADE To Buffer
	inc ESI					 ; INC ESI To point To Byte After GRADE 
	
	mov AL, FIELD_DELIMETER  ; Copy FIELD_DELIMETER 
	mov [ESI], AL			 ; Add FIELD_DELIMETER To Buffer
	inc ESI					 ; INC ESI To point To Byte After Delimeter
	
	mov AL, enrollSection	 ; Copy SECTIONID 
	mov [ESI], AL			 ; Add SECTIONID To Buffer
	inc ESI
	
	mov AL, 13
	mov [ESI], AL
	inc ESI
	mov AL, 10
	mov	[ESI],AL
	jmp DONE
	err:
	DONE:
	mov EDX, offset buffer 
	;call writestring
	ret
enrollStudent ENDP


; --------------------------------------------------------------
; printStudentsBuffer PROC
;
; Searches: for all the students data and putting them in the
;			recieved array
; Receives:	studentsBuffer = Students Buffer String OFFSER
; Returns: studentsBuffer = Student Records Data
; --------------------------------------------------------------
printStudentsBuffer PROC USES EDI ESI ECX EAX EDX EBX studentsBuffer: PTR BYTE
	call getLastIndex
	mov EDX, studentsBuffer
	mov EDI, ESI
	mov ESI, OFFSET buffer
	mov BL, FIELD_DELIMETER
 
BUFFER_LOOP:
		cmp ESI, EDI  ;END OF BUFFER
		je RETURN
		mov Al, [ESI]  ;mov ID
		mov [EDX], AL	
		inc EDX
		add ESI, 2
 
		mov [EDX], BL	; mov Delimeter
		inc EDX
 
SKIP_NAME:
		cmp [ESI], BL	;CHECK END OF NAME
		je CONTINUE
		mov AL,[ESI]
		mov [EDX], AL
		inc EDX
		inc ESI
	jmp SKIP_NAME
 
CONTINUE:
	inc ESI
 
	;mov Delimeter
	mov [EDX], BL
	inc EDX
 
	movzx EAX, byte ptr [ESI]	;mov Grade
	mov [EDX], AL
	inc EDX
	add ESI, 2	
 
	;mov Delimeter
	mov [EDX], BL
	inc EDX
	
	call getAlphabeticalGrade
	mov [EDX], AL ;mov alphabetic grade
	inc EDX

	;mov Delimeter
	mov [EDX], BL
	inc EDX

	mov Al, [ESI]	;mov Section Number
	mov [EDX], AL
	inc EDX
	add ESI, 3
 
	mov [EDX], BL	;mov Field Delimeter
	inc EDX
	
	jmp BUFFER_LOOP
 
RETURN:
	ret
printStudentsBuffer ENDP


; --------------------------------------------------------------
; getAlphabeticalGrade PROC
;
; Matches: the student grade with the Alphabetical Grade
; Receives:	AL = Student Numeric Grade
; Returns: AL = Student Alphabetial Grade
; --------------------------------------------------------------
getAlphabeticalGrade PROC USES ECX EDX
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
	ret
getAlphabeticalGrade ENDP 


; --------------------------------------------------------------
; getLastIndex PROC
;
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
; saveDatabase PROC
;
; Saves: the Database File
; Recieves: saveFileName = OFFSET to the File Name String	
;			saveDBKey  = Database Key
; Returns: VOID
; --------------------------------------------------------------
saveDatabase PROC USES EAX EBX ECX EDX ESI EDI saveFileName: PTR BYTE, saveDBKey: BYTE
	; Creating the DB File
	mov BL, saveDBKey  ; Saving the DB KEY Value in BL
	mov EDX, saveFileName
	call CreateOutputFile
	; Checking for File Handle Errors
	cmp EAX, INVALID_HANDLE_VALUE
	jne ENCRYPT_STRING  ; No Error Found
	mov EDX, OFFSET errorString
	;call writeString
	;call CRLF
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
	;call writeString
	;call CRLF
	ret
DONE_SAVING:
	mov EDX, OFFSET successString
	;call writeString
	;call CRLF
	ret
saveDatabase ENDP


; --------------------------------------------------------------
; encryptBuffer PROC
;
; Copies: the input Array to the Output Array
; Recieves: ESI = OFFSET to the Input Array
;			EDI = OFFSET to the Output Array
;			ECX = Length of the Input Array
;			AL  = DB KEY
; Returns: VOID
; --------------------------------------------------------------
encryptBuffer PROC USES ESI EDI	ECX	EAX EBX
push EDX
push ECX
mov EDX, OFFSET encryptedBuffer  
mov ECX, LENGTHOF encryptedBuffer
call clearArray  ; Clearing the encryptedBuffer Array
pop ECX
pop EDX
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
; sortIDs PROC
;
; Sorts: the section IDs in IDs array
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


; --------------------------------------------------------------
; printStudent PROC
;
; Searches: the buffer for a specific student id and desplays
;           the student data
; Recieves: printStudentID = Student ID
;			studentData = OFFSET to a student record array
; Returns: studentData = the student record data
; --------------------------------------------------------------
printStudent PROC USES EBX EAX EDI ESI EDX ECX printStudentID: BYTE, studentData: PTR BYTE
movzx EBX, printStudentID 
call getLastIndex
mov EDI, OFFSET buffer
mov AL, FIELD_DELIMETER

ID_SEARCH:
	cmp EDI, ESI		;check end of buffer
	je ERROR
	cmp [EDI], BL  ;compare buffer byte with id
	je IDFOUND

	add EDI,2
	skipName:
		cmp [EDI], AL	;check end of name
		je CONTINUE
		inc EDI
	jmp skipName

	CONTINUE:	
		add EDI, 6
jmp ID_SEARCH

;ERROR OCCURED
ERROR:
mov EDX,OFFSET errorString
;call writeString
ret

IDFOUND:
	mov EDX, studentData
	movzx EAX, byte ptr[EDI]
	mov ESI, OFFSET convertedNum
	call parseNumberString

	copyID:
			mov AL, [ESI]
			mov [EDX], AL
			inc ESI
			inc EDX
	loop copyID

	mov AL," "
	mov [EDX], AL
	inc EDX

	inc EDI
	inc EDI
	mov BL, FIELD_DELIMETER
	mov ecx, BUFFER_SIZE
	DisplayName:
		cmp [EDI], BL
		je END_OF_NAME
		mov AL, [EDI]
		mov [EDX], AL	
		inc EDX
		inc EDI
	loop DisplayName

	END_OF_NAME:
		mov AL," "
		mov [EDX], AL
		inc EDX
		inc EDI

	movzx EAX, byte ptr [EDI]
	push EAX
	mov ESI, OFFSET convertedNum
	call parseNumberString

	copyGrade:
			mov AL, [ESI]
			mov [EDX], AL
			inc ESI
			inc EDX
	loop copyGrade

		mov AL," "
		mov [EDX], AL	
		inc EDX
		
		pop EAX
		call getAlphabeticalGrade
		mov [EDX], AL
		inc EDX

		mov AL," "
		mov [EDX], AL	
		inc EDX

	inc EDI
	inc EDI

	movzx EAX, byte ptr [EDI]
	mov ESI, OFFSET convertedNum
	call parseNumberString

	copySecNum:
			mov AL, [ESI]
			mov [EDX], AL
			inc ESI
			inc EDX
	loop copySecNum


	ret
printStudent ENDP


; --------------------------------------------------------------
; generateSectionReport PROC
;
; Gets: the section's student IDs, sort them, matches the IDs
;		with the students record, and creating a new File with the
;       Section Data.
; Recieves: reportSection  = Section Number
;			reportFileName = OFFSER to the File Name String 
; Returns: void
; --------------------------------------------------------------
generateSectionReport PROC USES EDX ECX EDI EBX ESI EAX reportSection: BYTE, reportFileName: PTR BYTE
movzx EAX, reportSection
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
		;call writeString 
		;call crlf
		ret
;get students by sorted IDs
getStudents:
	mov EDX, OFFSET IDs
	mov ECX, LENGTHOF IDs
	;TODO esi contains last offset in buffer
	mov ESI, OFFSET SectionStudents
	iterateIDs:
	mov AL, FIELD_DELIMETER
	mov BL, [EDX]
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
		push ECX
		push ESI
		mov ESI , OFFSET convertedNum
		call parseNumberString	
		pop ESI
		;mov EBX, ECX
		mov EBX, OFFSET convertedNum
		;copy string ID into sectionStudents array
		copyID:
			mov AL, [EBX]
			mov [ESI], AL
			inc ESI
		loop copyID
			POP ecx
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
		push ECX
		push ESI
		;convert numeric grade into string
		movzx EAX, byte ptr [EDI]	
		mov ESI, OFFSET convertedNum	
		call parseNumberString 
		pop ESI
		mov EBX, OFFSET convertedNum
		copyGrade:
			mov AL, [EBX]
			mov [ESI], AL	
			inc ESI
			inc EBX
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
		add EDI,5
	jne iterateIDs
END_OF_IDs:
GET_FILE_NAME:
	mov EDX, reportFileName
	CreateNewFile:
	call CreateOutputFile
	; Checking for File Handle Errors
	cmp EAX, INVALID_HANDLE_VALUE
	jne copytofile  ; No Error Found
	mov EDX, OFFSET errorString
	;call writeString
	;call CRLF
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
	;call writeString
	;call CRLF
	ret
DONE_SAVING:
	mov EDX, OFFSET successString
	;call writeString
	;call CRLF
CLEAR_ARRAYS:
mov EDX, OFFSET IDs
mov ECX, lengthof IDs
call clearArray
mov EDX, OFFSET SectionStudents
mov ECX, lengthof SectionStudents
call clearArray
ret
generateSectionReport ENDP


; --------------------------------------------------------------
; clearArray
;
; Clears: the array by filling it with 0
; Recieves: EDX = array OFFSET
;           ECX = array Length
; Returns: void
; --------------------------------------------------------------
clearArray PROC USES EAX EDX
mov AL, 0
clear:
mov [EDX],AL
inc EDX
loop clear
ret
clearArray ENDP


; --------------------------------------------------------------
; parseNumberString PROC
;
; Parse: the integer value to string Database File
; Recieves: ESI = OFFSET to the empty number string	
;			EAX = Integer Value
; Returns:  ECX = Length of the Number String
; --------------------------------------------------------------
parseNumberString PROC USES ESI EAX EBX EDI EDX
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
	mov EDI, ESI  ; Saving the ESI OFFSET Value
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
 
	mov ECX, EBX  ; Returning the Length of the String in ECX
	ret
parseNumberString ENDP


; --------------------------------------------------------------
; sortGrades PROC
;
; Sorts: the students grades array
; Recieves: ESI = OFFSET to the Grades Array
; Returns: VOID
; --------------------------------------------------------------
sortGrades PROC USES EAX ECX EDI ESI
	mov ECX, lengthof Grades
	dec ECX 
	outerLoop:
		push ECX
		mov ESI, offset Grades
		mov AL, [ESI]
		cmp AL, 0
		je terminate
		innerLoop:
			mov AL,[ESI+1]
			cmp AL, 0
			je noExchange
			mov AL, [ESI]
			cmp AL, [ESI+1]
			jg noExchange
			xchg AL,[ESI+1]
			mov [ESI],AL
			noExchange:
			inc ESI
		LOOP innerLoop
		pop ECX
	LOOP outerLoop
	terminate:
	ret 
sortGrades ENDP


; --------------------------------------------------------------
; top5Students PROC
;
; Sorts: the student grades descendingly, get sorted Students Records
;        by the Grades from "buffer", Displays the Top 5 Students
; Recieves: studentsData = OFFSET to the studentsData array to be Filled
; Returns: studentsData = The Top 5 Students Data Records
; --------------------------------------------------------------
top5Students PROC USES EAX EBX ECX EDX ESI EDI studentsData: PTR BYTE
	mov EDX, offset CopiedBuffer
	mov ECX, lengthof CopiedBuffer
	call clearArray
	mov EDI, offset buffer
	mov EDX, offset CopiedBuffer
	mov ECX, lengthof CopiedBuffer
	call getLastIndex
	copyBuffer:
		cmp ESI, EDI
		je stop
		mov AL, [EDI]
		mov [EDX], AL	
		inc EDX
		inc EDI	
	LOOP copyBuffer
	stop:
	
	mov EDX, offset Grades
	mov ECX, lengthof Grades
	call clearArray
	call getLastIndex
	mov EDI, offset buffer
	mov EDX, offset Grades
	mov ECX, lengthof Grades
	cmp EDI, ESI		;check if end of buffer
	je SORT
	getGrades:
		push ECX
		mov BL, FIELD_DELIMETER
		mov ECX, lengthof CopiedBuffer
		reachGrade:
			mov AL, 0
			cmp [EDI], AL
			je SORT
			add EDI, 2
			mov BL, FIELD_DELIMETER
			skipName:
				mov AL, [EDI]
				cmp [EDI], BL
				je CNT
				inc EDI
			jmp skipName
			CNT:
				mov BL, [EDI+1]
				mov [EDX], BL
				inc EDX
				add EDI, 6
		LOOP reachGrade
		cmp EDI, ESI		;check if end of buffer
		je SORT
		pop ECX
	loop getGrades
	SORT:
	pop ECX
	mov ESI, offset Grades
	mov BL, 0
	cmp [ESI], BL
	je NO_STUDENTS_FOUND
	call sortGrades
	jmp getStudents
	NO_STUDENTS_FOUND:	  ;display error msg, break the PROC
		mov EDX, OFFSET NO_STUDENTS_ERROR
		;call writeString 
		;call crlf
		ret
getStudents:	
	;Display Students from Buffer with Grades
	mov ECX, 5

	mov EDX, offset Grades
	mov ESI, studentsData
	iterateGrades:
		push ECX
		mov BL, 0
		cmp [EDX], BL  ;check for end of Grades
		je END_OF_Grades
		mov ECX, lengthof CopiedBuffer
		mov EDI, offset CopiedBuffer
		mov BL, [EDX]	; store student's grade
			iterateAllRecords:
				mov AL, [EDI]
				push EAX
				mov AL, Field_Delimeter
				SKIP_RECORD:
					add EDI, 2 ;Skip ID
					skip:
						cmp [EDI], AL
						je END_OF_NAME
						inc EDI
					jmp skip	
			END_OF_NAME:
				pop EAX
				cmp [EDI+1], BL
				je StudentFound
				add EDI, 6
			loop iterateAllRecords
			
			StudentFound:		
			;Print Student's Data
				mov EBX,EAX
				mov EDI, OFFSET buffer
				mov AL, FIELD_DELIMETER
				ID_SEARCH:
					cmp [EDI],BL  ;compare buffer byte with id
					je IDFOUND
					add EDI,2
					skipN:
						cmp [EDI], AL	;check end of name
						je CONTINUE
						inc EDI
					jmp skipN
					CONTINUE:	
						add EDI, 6
				jmp ID_SEARCH
				IDFOUND:
					movzx EAX, byte ptr [EDI]
					mov [ESI], EAX
					inc ESI
					mov AL,FIELD_DELIMETER
					mov [ESI], AL
					inc ESI
					add EDI, 2
					mov BL, FIELD_DELIMETER
					mov ecx, BUFFER_SIZE
					DisplayName:
						cmp [EDI], BL
						je END_OFNAME
						mov AL, [EDI]
						mov [ESI], AL
						inc ESI
						inc EDI
					loop DisplayName
					END_OFNAME:
						mov AL,FIELD_DELIMETER
						mov [ESI], AL
						inc ESI
						inc EDI

						movzx EAX,byte ptr [EDI]
						mov [ESI], EAX		;display grade
						inc ESI

						mov AL, FIELD_DELIMETER
						mov [ESI], AL
						inc ESI

						movzx EAX,byte ptr [EDI]
						call getAlphabeticalGrade
						mov [ESI], EAX
						inc ESI

						mov AL, FIELD_DELIMETER
						mov [ESI], AL
						inc ESI
					add EDI, 2

					movzx EAX, byte ptr[EDI]
					mov [ESI], EAX
					inc ESI
					mov AL, FIELD_DELIMETER
					mov [ESI], AL
					inc ESI
					
					INC EDX
	pop ECX
	dec ECX
	jne iterateGrades

	END_OF_Grades:
	pop ECX
	ret
top5Students ENDP


; DllMain is required for any DLL
DllMain PROC hInstance:DWORD, fdwReason:DWORD, lpReserved:DWORD 
mov eax, 1		; Return true to caller. 
ret 				
DllMain ENDP

END DllMain  ; For Exporting a DLL