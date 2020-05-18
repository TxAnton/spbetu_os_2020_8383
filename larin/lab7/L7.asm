DATA SEGMENT
	IS_MEM_FREED db 0
	KEEP_PSP dw 0
	CLN dw 0
	PATH db 80h dup(0)
	PROG_NAME db "L2.COM", 0
	KEEP_SP dw 0
	KEEP_SS dw 0
	
	OVL1 db "OVL1.OVL",0
	OVL2 db "OVL2.OVL",0
	
	OVL_SEG dw 0
	
	OVL_FAR_CALL dd 0
	
	DTA db 43 dup(0)
	
	STR_RET_CODE db 13, 10, "Ret.cod:        $",0
	STR_NEW_LINE db 0DH,0AH,'$'
	STR_MEM_ERROR db 'Failed to free memory$'
	STR_MEM_SUCCESS db 'Memory freed$'
	STR_MEM_ERROR7 db 'MEM_ERR: MCB corrupted$'
	STR_MEM_ERROR8 db 'MEM_ERR: Not genough memory to execute$'
	STR_MEM_ERROR9 db 'MEM_ERR: Invalid memory block adress$'
	
	STR_SK_ERR2 db 'SK_ERR: File not found$'
	STR_SK_ERR3 db 'SK_ERR: Route not found$'
	
	STR_ALLOC_ERROR db 'Failed to allicate OVL memory$'
	STR_ALLOC_SUCCESS db 'OVL memory allocated$'
	
	
	STR_LOAD_ERROR db 'Failed to load OVL$'
	STR_LOAD_SUCCESS db 'Program loaded$'
	STR_LOAD_ERROR1 db 'LOAD_ERR: Function does not exist$'
	STR_LOAD_ERROR2 db 'LOAD_ERR: File not found$'
	STR_LOAD_ERROR3 db 'LOAD_ERR: Route not found$'
	STR_LOAD_ERROR4 db 'LOAD_ERR: Too many files opened$'
	STR_LOAD_ERROR5 db 'LOAD_ERR: No access$'
	STR_LOAD_ERROR8 db 'LOAD_ERR: Not enough memory$'
	STR_LOAD_ERROR10 db 'LOAD_ERR: Invalid environment line$'

	
	STR_END_CAUSE0 db 'Program finished normally$'
	STR_END_CAUSE1 db 'Program finished by Ctrl+Break$'
	STR_END_CAUSE2 db 'Program finished by divice error$'
	STR_END_CAUSE3 db 'Program went resident$'
	
	PARAMS			dw ? ;сегментный адрес среды
					dd ? ;сегмент и смещение командной строки
					dd ? ;сегмент и смещение первого FCB
					dd ? ;сегмент и смещение второго FCB

	DATA_END db 0
DATA ENDS

PSTACK SEGMENT STACK
	dw 128 dup(0)
PSTACK ENDS


CODE SEGMENT
	assume cs:CODE, ds:DATA, ss:PSTACK, es:NOTHING

;======================================================
PROCESS proc near
	push ax
	push cx
	push dx
	push di
	push es
	push si

	mov ax, KEEP_PSP
	mov es, ax
	mov es, es:[2Ch]
	mov si, 0
	
	
SEEK_START:
	mov ax, es:[si]
	inc si
	cmp ax, 0
	jne SEEK_START
	add si, 3
	mov di, 0
SEEK_CLN:
	mov al, es:[si]
	cmp al, 0
	je APPEND_NAME
	cmp al, '\'
	jne ADD_PATH_SYM
	mov CLN, di
ADD_PATH_SYM:
	mov BYTE PTR [PATH + di], al
	inc si
	inc di
	jmp SEEK_CLN
APPEND_NAME:
	mov di, CLN
	inc di
	add di, offset PATH
	pop si
	push si
	mov ax, ds
	mov es, ax
APPEND_SYMB:
	mov al, ds:[si]
	mov ds:[di], al
	inc di
	inc si
	cmp al, 0
	jne APPEND_SYMB

	pop si
	pop es
	pop di
	pop dx
	pop cx
	pop ax
	ret
PROCESS endp
;======================================================
FREE_MEM proc near
	push ax
	push bx
	push cx
	push dx
	push es
	
	mov ax,offset DATA_END
	mov bx,offset MEM_END
	add bx,ax
	add bx,30Fh
	mov cx,4
	shr bx,cl
	xor al,al
	mov ah,4Ah
	int 21h
	
	jnc MEM_FREED
	mov dx,offset STR_MEM_ERROR
	call PRINT
	call LN
	mov IS_MEM_FREED,0
	
	cmp ax, 7
		je MEM_ERROR7
	cmp ax, 8
		je MEM_ERROR8
	cmp ax, 9
		je MEM_ERROR9
	
	MEM_ERROR7:
		mov dx, offset STR_MEM_ERROR7
		jmp FREE_MEM_END
	MEM_ERROR8:
		mov dx, offset STR_MEM_ERROR8
		jmp FREE_MEM_END
	MEM_ERROR9:
		mov dx, offset STR_MEM_ERROR9
		jmp FREE_MEM_END
	
	MEM_FREED:
	mov IS_MEM_FREED,1
	mov dx, offset STR_MEM_SUCCESS
	FREE_MEM_END:
	call PRINT
	call LN
	
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEM endp
;======================================================	
ALLOC_OVL proc near
	push AX
	push BX
	push CX
	push DX
	push SI	
	
	;Set DTA
	xor ax, ax
	mov ah, 1Ah
	mov dx, offset DTA
	int 21h
	
	;Seek OVL in fs
	mov ah, 4Eh
	xor cx,cx
	mov dx, offset PATH
	int 21h
	jnc OVL_FOUND
	cmp ax, 2
	je SK_ERR2
	cmp ax, 3
	je SK_ERR3
	jmp ALLOC_END
		
SK_ERR2:
	mov dx, offset STR_SK_ERR2
	call PRINTLN
SK_ERR3:
	mov dx, offset STR_SK_ERR3
	call PRINTLN

OVL_FOUND:
	;Get size
	mov si, offset DTA
	add si, 1Ah
	mov bx, [SI]
	mov AX, [SI + 2]
	mov cl,4
	shr BX, cl
	mov cl,12
	shl AX, cl
	add BX, AX
	inc BX
	;Alloc
	mov AX, 4800h
	int 21h
	jnc ALLOC_SUCCESS
	mov dx,offset STR_ALLOC_ERROR
	call PRINTLN
ALLOC_SUCCESS:
	mov dx,offset STR_ALLOC_SUCCESS
	call PRINTLN
	mov OVL_SEG, ax

ALLOC_END:
	pop SI
	pop DX
	pop CX
	pop BX
	pop AX
	ret
ALLOC_OVL endp

;======================================================
LOAD_OVL proc near
	call PROCESS
	call ALLOC_OVL
	
	push AX
	push BX
	push DX
	push ES

	mov DX, offset PATH
	push DS
	pop ES
	mov BX, offset OVL_SEG
	mov AX, 4B03h
	int 21h

	jnc OVL_LOADED		
	mov DX, offset STR_LOAD_ERROR
	call PRINTLN
	cmp AX, 1
	je LOAD_ERROR1
	cmp AX, 2
	je LOAD_ERROR2
	cmp AX, 3
	je LOAD_ERROR3
	cmp AX, 4
	je LOAD_ERROR4
	cmp AX, 5
	je LOAD_ERROR5
	cmp AX, 8
	je LOAD_ERROR8
	cmp AX, 10
	je LOAD_ERROR10
LOAD_ERROR1:
	mov DX, offset STR_LOAD_ERROR1
	call PRINTLN
	jmp LOAD_ERR
LOAD_ERROR2:
	mov DX, offset STR_LOAD_ERROR2
	call PRINTLN
	jmp LOAD_ERR
LOAD_ERROR3:
	mov DX, offset STR_LOAD_ERROR3
	call PRINTLN
	jmp LOAD_ERR
LOAD_ERROR4:
	mov DX, offset STR_LOAD_ERROR4
	call PRINTLN
	jmp LOAD_ERR
LOAD_ERROR5:
	mov DX, offset STR_LOAD_ERROR5
	call PRINTLN
	jmp LOAD_ERR
LOAD_ERROR8:
	mov DX, offset STR_LOAD_ERROR8
	call PRINTLN
	jmp LOAD_ERR
LOAD_ERROR10:
	mov DX, offset STR_LOAD_ERROR10
	call PRINTLN
	jmp LOAD_ERR
OVL_LOADED:
	mov DX, offset STR_LOAD_SUCCESS
	call PRINTLN
	mov AX, OVL_SEG
	mov ES, AX
	mov WORD PTR OVL_FAR_CALL + 2, AX
		
LOAD_END:
	pop ES
	pop DX
	pop BX
	pop AX
	ret
LOAD_ERR:
	xor al,al
	mov ah,4Ch
	int 21h
LOAD_OVL endp
;======================================================
FREE_OVL proc near
	push ax
	push es
	push dx
	mov AX, OVL_SEG
	mov ES, AX
	mov AH, 49h
	int 21h
	jnc FREE_SUCCESS
	mov dx, offset STR_MEM_ERROR
	call PRINTLN
FREE_SUCCESS:
	mov dx, offset STR_MEM_SUCCESS
	call PRINTLN

	pop dx
	pop es
	pop ax
	ret
FREE_OVL endp

;======================================================	
;UTILS	
;======================================================
PRINT PROC NEAR
	PUSH ax
	MOV	AH, 09H
	INT	21H
	POP ax 
	RET
PRINT  	ENDP
;======================================================
LN PROC
	push ax
	push dx
	mov dx, offset STR_NEW_LINE
	mov ah, 9h
	int 21h
	pop dx
	pop ax
	ret
LN ENDP
;======================================================
PRINTLN PROC NEAR
	call PRINT
	call LN
	RET
PRINTLN	ENDP



;==========MAIN=====MAIN====MAIN====MAIN===============
MAIN PROC
;MAIN init
	mov  ax, DATA                        ;ds setup
	mov  ds, ax   
	mov KEEP_PSP, es


	call FREE_MEM
	
	cmp IS_MEM_FREED,1
	jne EXIT
	
	mov si,offset OVL1
	call LOAD_OVL
	call OVL_FAR_CALL
	call FREE_OVL
	
	mov si,offset OVL2
	call LOAD_OVL
	call OVL_FAR_CALL
	call FREE_OVL
EXIT:
	xor al,al
	mov ah,4Ch
	int 21h

MAIN ENDP
	
MEM_END:	
CODE ENDS





END MAIN