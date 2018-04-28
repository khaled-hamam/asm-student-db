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

; DllMain is required for any DLL
DllMain PROC hInstance:DWORD, fdwReason:DWORD, lpReserved:DWORD 

mov eax, 1		; Return true to caller. 
ret 				
DllMain ENDP

END main	   ; For Running EXE
; END DllMain  ; For Exporting a DLL
