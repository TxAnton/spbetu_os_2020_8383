DATA SEGMENT
	IS_MEM_FREED db 0
	KEEP_PSP dw 0
	CLN dw 0
	PATH db 80h dup(0)
	PROG_NAME db "L2.COM", 0
	KEEP_SP dw 0
	KEEP_SS dw 0
	
	STR_RET_CODE db 13, 10, "Ret.cod:        $",0
	STR_NEW_LINE db 0DH,0AH,'$'
	STR_MEM_ERROR db 'Failed to free memory$'
	STR_MEM_SUCCESS db 'Memory freed$'
	STR_MEM_ERROR7 db 'MEM_ERR: MCB corrupted$'
	STR_MEM_ERROR8 db 'MEM_ERR: Not genough memory to execute$'
	STR_MEM_ERROR9 db 'MEM_ERR: Invalid memory block adress$'
	
	STR_LOAD_ERROR db 'Failed to load program$'
	STR_LOAD_SUCCESS db 'Program loaded$'
	STR_LOAD_ERROR1 db 'LOAD_ERR: Invalid function nunmber$'
	STR_LOAD_ERROR2 db 'LOAD_ERR: File not found$'
	STR_LOAD_ERROR5 db 'LOAD_ERR: disk error$'
	STR_LOAD_ERROR8 db 'LOAD_ERR: Not enough memory$'
	STR_LOAD_ERROR10 db 'LOAD_ERR: Invalid environment line$'
	STR_LOAD_ERROR11 db 'LOAD_ERR: Wrong format$'
	
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
PROCESS proc near

	push ax
	push cx
	push dx
	push si
	push di
	push es

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
	mov si, offset PROG_NAME
	mov ax, ds
	mov es, ax
APPEND_SYMB:
	mov al, ds:[si]
	mov ds:[di], al
	inc di
	inc si
	cmp al, 0
	jne APPEND_SYMB

	
	pop dx
	pop si
	pop di
	pop es
	pop cx
	pop ax
	ret
PROCESS endp
;======================================================	
LOAD proc near
	push ax
	push bx
	push dx	
	
	push ds 
	push es
	mov KEEP_SP, SP
	mov KEEP_SS, ss
	
	mov ax, DATA
	mov es, ax
	mov bx, offset PARAMS
	mov dx, offset CLN
	mov [bx + 2], dx
	mov [bx + 4], ds
	mov dx, offset PATH
	mov ax, 4B00h
	int 21h
	
	mov ss, ds:KEEP_SS
	mov SP, ds:KEEP_SP
	pop es
	pop ds

	jnc LOAD_SUCCESS
	mov dx, offset STR_LOAD_ERROR
	call PRINT
	call LN
	cmp ax, 1
	je LOAD_ERROR1
	cmp ax, 2
	je LOAD_ERROR2
	cmp ax, 5
	je LOAD_ERROR5
	cmp ax, 8
	je LOAD_ERROR8
	cmp ax, 10
	je LOAD_ERROR10
	cmp ax, 11
	je LOAD_ERROR11
LOAD_ERROR1:
	mov dx, offset STR_LOAD_ERROR1
	call PRINT
	call LN
	jmp LOAD_END
LOAD_ERROR2:
	mov dx, offset STR_LOAD_ERROR2
	call PRINT
	call LN
	jmp LOAD_END
LOAD_ERROR5:
	mov dx, offset STR_LOAD_ERROR5
	call PRINT
	call LN
	jmp LOAD_END
LOAD_ERROR8:
	mov dx, offset STR_LOAD_ERROR8
	call PRINT
	call LN
	jmp LOAD_END
LOAD_ERROR10:
	mov dx, offset STR_LOAD_ERROR10
	call PRINT
	call LN
	jmp LOAD_END
LOAD_ERROR11:
	mov dx, offset STR_LOAD_ERROR11
	call PRINT
	call LN
	jmp LOAD_END
LOAD_SUCCESS:
	mov ax, 4D00h
	int 21h
	mov di, offset STR_RET_CODE
	mov [di + 10], al
	mov dx, offset STR_RET_CODE
	call PRINT
	call LN
	cmp ah, 0
	je LOAD_END0
	cmp ah, 1
	je LOAD_END1
	cmp ah, 2
	je LOAD_END2
	cmp ah, 3
	je LOAD_END3
LOAD_END0:
	mov dx, offset STR_END_CAUSE0
	call PRINT
	jmp LOAD_END
LOAD_END1:
	mov dx, offset STR_END_CAUSE1
	call PRINT
	jmp LOAD_END
LOAD_END2:
	mov dx, offset STR_END_CAUSE2
	call PRINT
	jmp LOAD_END
LOAD_END3:
	mov dx, offset STR_END_CAUSE3
	call PRINT


LOAD_END:
	pop dx
	pop bx
	pop ax	
	ret
LOAD endp
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
	call PROCESS
	call LOAD
	
EXIT:
	xor al,al
	mov ah,4Ch
	int 21h

MAIN ENDP
	
MEM_END:	
CODE ENDS





END MAIN