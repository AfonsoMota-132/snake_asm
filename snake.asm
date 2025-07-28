section .note.GNU-stack

%define WIDTH  64
%define HEIGHT 32
%define GRID_SIZE WIDTH*HEIGHT

%define SYS_read   0
%define SYS_ioctl  16
%define SYS_getrandom 318
%define SYS_gettimeofday 96

%define TCIFLUSH      0
%define TCFLSH        0x540B

%define STDIN      0
%define TCGETS     0x5401
%define TCSETS     0x5402
%define ICANON 0x02
%define ECHO   0x08


section .bss
		grid resb GRID_SIZE  
		orien resb 4			;	where snake is looking at
		size resb 4				;	nbr of nodes of snake
		fruitPos resb 4			;	fruitPos = y * WIDTH + x
		fruitActive resb 1		;	0 = no fruit	1 = 
		fruitTime resb 8		;	Time of fruit spawn
		genTime resb 16			;	Struct for getTimeOfDay
		snake_head resd 256		;	Array of snake's body, with 2 bytes
								;	each reprensenting a node
								;	in the form of nodePos = y * WIDTH + x
		termios_oldt resb 64	;	reserving 128 (64 * 2), for termios structs
		termios_newt resb 64	;	for get_key_press
		read_buf resb 1			;	read buffer for keypress read..
		rand_byte resb 4 

section .data
		clear db 27, '[2J'    			; 27 = ESC (0x1B), ANSI code
		clear_len equ $ - clear
		cursor_home db 27, '[', 'H'		; ESC [ H
		char_hash db '#'
		char_fruit db '@'
		char_space db ' '
		char_player db 'o'
		char_up db '^'
		char_ri db '<'
		char_le db '>'
		char_do db 'V'
		char_nl   db 10
		timespec:
		    dq 0              			; tv_sec = 0
		    dq 100000000       			; tv_nsec = 50,000,000 ns = 50 ms

section .text
		global _start
		global _termClear
		global _writeNewLine
		global constructMap
		global addSnake
		global printMap
		global moveRight
		global get_key_press
		extern printf

_start:
		mov DWORD [snake_head], 1056
		mov DWORD [orien], 4
		mov DWORD [size], 3
		mov BYTE [fruitActive], 1
		mov DWORD [fruitPos], 1128
_loopMain:
		mov rax, 35        				; syscall: nanosleep
    	mov rdi, timespec  				; pointer to timespec
    	mov rsi, 0         				; NULL (no remainder)
    	syscall
		call _termClear
		call constructMap
		call addSnake
		call printMap
		call get_key_press

		cmp rax, 100
		jne _try_left
		cmp DWORD [orien], 2
		je _try_up
		mov DWORD [orien], 4
_try_left:
		cmp rax, 97
		jne _try_up
		cmp DWORD [orien], 4
		je _try_up
		mov DWORD [orien], 2
_try_up:
		cmp rax, 119
		jne _try_down
		cmp DWORD [orien], 3
		je _try_down
		mov DWORD [orien], 1
_try_down:
		cmp rax, 115
		jne _try_esc
		cmp DWORD [orien], 1
		je _try_esc
		mov DWORD [orien], 3
_try_esc:
		cmp rax, 120
		je _exit
		call moveRight
		call moveLeft
		call moveUp
		call moveDown
		cmp BYTE [fruitActive] , 1
		jne _verFruitTime
		xor rax, rax
		mov eax, DWORD [fruitPos]
		xor r8, r8
		mov r8d, [snake_head]
		cmp eax, r8d
		jne _endLoopMain
		mov BYTE [fruitActive], 0
		inc DWORD [size]	
		mov     rax, SYS_gettimeofday	; SYS_gettimeofday
		lea     rdi, [rel genTime]		; pointer to timeval struct
		xor     rsi, rsi				; NULL for timezone
		syscall
		mov rax, [genTime]
		mov [fruitTime], rax
		xor rax, rax
		call get_random_number
		add DWORD [fruitTime], 1
_verFruitTime:
		mov     rax, SYS_gettimeofday	; SYS_gettimeofday
		lea     rdi, [rel genTime]		; pointer to timeval struct
		xor     rsi, rsi				; NULL for timezone
		syscall
		mov rax, [genTime]
		cmp [fruitTime], rax
		jge _endLoopMain
		mov BYTE [fruitActive], 1
_endLoopMain:
		jmp _loopMain
_exit:
    	mov rax, 60
    	xor rdi, rdi
    	syscall

_end:
		mov rax, 60             ; syscall: exit
		xor rdi, rdi            ; status 0
		syscall

;	Usefull functions idk

;	Movements
;		Move Right
updateSnake:
		mov r9, grid
		xor rax, rax
		inc rax
_loopUpdate:
		cmp eax, dword [size]
		jge _ret
		xor r8, r8
		mov r8d, DWORD [snake_head + eax * 4]
		mov DWORD [snake_head + eax * 4], edi
		mov rdi, r8
    	inc rax
    	jmp _loopUpdate
		ret

moveRight:
		mov r9, grid
		cmp dword [orien], 4
		jne _ret
		xor rax, rax
		push rdi
		mov eax, DWORD [snake_head]
		xor rdi, rdi
		mov edi, eax
		inc eax
		cmp BYTE [r9 + rax], 2
		jne _exit
		mov DWORD [snake_head], eax
		call updateSnake
		pop rdi
		ret

moveLeft:
		mov r9, grid
		cmp dword [orien], 2
		jne _ret
		xor rax, rax
		push rdi
		mov eax, DWORD [snake_head]
		xor rdi, rdi
		mov edi, eax
		dec eax
		cmp BYTE [r9 + rax], 2
		jne _exit
		mov DWORD [snake_head], eax
		call updateSnake
		pop rdi
		ret

moveUp:
		mov r9, grid
		cmp dword [orien], 1
		jne _ret
		xor rax, rax
		push rdi
		mov eax, DWORD [snake_head]
		xor rdi, rdi
		mov edi, eax
		sub eax, WIDTH
		cmp BYTE [r9 + rax], 2
		jne _exit
		mov DWORD [snake_head], eax
		call updateSnake
		pop rdi
		ret

moveDown:
		mov r9, grid
		cmp dword [orien], 3
		jne _ret
		xor rax, rax
		push rdi
		mov eax, DWORD [snake_head]
		xor rdi, rdi
		mov edi, eax
		add eax, WIDTH
		cmp BYTE [r9 + rax], 2
		jne _exit
		mov DWORD [snake_head], eax
		call updateSnake
		pop rdi
		ret



;	Add Snake to map, from the array
addSnake:
		xor rax, rax
		mov r9, grid
		mov r8d, DWORD [snake_head + eax * 4]
		mov BYTE [r9 + r8], 0
		inc rax
_loopAdd:
		cmp eax, dword [size]
		jge _ret
		xor r8, r8
		mov r8d, DWORD [snake_head + eax * 4]
		mov BYTE [r9 + r8], 1
    	inc rax
    	jmp _loopAdd
_ret:
		ret


		je _ret
;	Construct Map from scratch without player
constructMap:
		mov r9, grid
		mov rcx, -1				; y = -1
_loop_y:
		inc rcx
		cmp rcx, HEIGHT
		jge _ret
		xor rbx, rbx			; x = 0
_loop_x:
		cmp rbx, WIDTH
		jge _loop_y				; if rbx >= WIDTH, done
		cmp rcx, 0
		je _put_wall
		cmp rcx, HEIGHT - 1
		je _put_wall
		cmp rbx, 0
		je _put_wall
		cmp rbx, WIDTH - 1
		je _put_wall
		jmp _put_space
_put_wall:
		mov r8, rcx
		imul r8, WIDTH
		add r8, rbx
		mov BYTE [r9 + r8] , 3
    	inc rbx
    	jmp _loop_x

_put_space:
		mov r8, rcx
		imul r8, WIDTH
		add r8, rbx
		mov BYTE [r9 + r8] , 2
    	inc rbx
    	jmp _loop_x


;	Writes map to terminal
printMap: 
		xor rbx, rbx	; x = 0
_print:
		cmp rbx, GRID_SIZE
		jge _ret
		cmp BYTE [fruitActive], 1
		jne _tryWall
		xor rax, rax
		mov eax, DWORD [fruitPos]
		cmp rbx, rax
		jne _tryWall
		mov rax, 1          ; sys_write
		mov rdi, 1          ; stdout
		mov rsi, char_fruit	; pointer to ' '
		mov rdx, 1          ; length 1 byte
		syscall
		jmp _afterWrite
_tryWall:
		cmp BYTE [r9 + rbx] , 3
		jne _trySpace
		mov rax, 1          ; sys_write
		mov rdi, 1          ; stdout
		mov rsi, char_hash  ; pointer to '#'
		mov rdx, 1          ; length 1 byte
		syscall
		jmp _afterWrite
_trySpace:
		cmp BYTE [r9 + rbx] , 2
		jne _tryPlayerHead
		mov rax, 1          ; sys_write
		mov rdi, 1          ; stdout
		mov rsi, char_space	; pointer to ' '
		mov rdx, 1          ; length 1 byte
		syscall
		jmp _afterWrite
_tryPlayerHead:
		cmp BYTE [r9 + rbx] , 0
		jne _tryPlayer
		mov rax, 1          ; sys_write
		mov rdi, 1          ; stdout
		cmp DWORD [orien], 1
		jne _tryPlayerHeadRi
		mov rsi, char_up ; pointer to ' '
_tryPlayerHeadRi:
		cmp DWORD [orien], 2
		jne _tryPlayerHeadLe
		mov rsi, char_ri ; pointer to ' '
_tryPlayerHeadLe:
		cmp DWORD [orien], 4
		jne _tryPlayerHeadDo
		mov rsi, char_le ; pointer to ' '
_tryPlayerHeadDo:
		cmp DWORD [orien], 3
		jne _writePlayerHead
		mov rsi, char_do ; pointer to ' '
_writePlayerHead:
		mov rdx, 1          ; length 1 byte
		syscall
		jmp _afterWrite
_tryPlayer:
		cmp BYTE [r9 + rbx] , 1
		jne _afterWrite
		mov rax, 1          ; sys_write
		mov rdi, 1          ; stdout
		mov rsi, char_player	; pointer to ' '
		mov rdx, 1          ; length 1 byte
		syscall
		jmp _afterWrite
_afterWrite:
		inc rbx
		mov rax, rbx
		and rax, WIDTH - 1
		je print_newline

		jmp _print

print_newline:
		call writeNewLine
		jmp _print




;	Just Writes a New line.... what do you expect

writeNewLine:
    	mov rax, 1
    	mov rdi, 1
    	mov rsi, char_nl
    	mov rdx, 1
    	syscall
		ret

;	Clears terminal, so i can 'refresh' with new frame
_termClear:
		mov rax, 1              ; syscall: write
		mov rdi, 1              ; fd: stdout
		mov rsi, clear          ; clear buffer
		mov rdx, clear_len      ; length
		syscall
		mov rax, 1          	; sys_write
		mov rdi, 1          	; stdout fd
		mov rsi, cursor_home
		mov rdx, 3          	; length 3 bytes
		syscall
		ret

get_key_press:
		; mov	rdi, [termios_newt]
		; mov rsi, [termios_oldt]

		;	ioctl(0, TCGETS, &termios_oldt), basically get current terminal info
		mov rax, SYS_ioctl		; SYS_ioctl system call
		mov	rdi, STDIN			; Standard Fd in
		mov rsi, TCGETS			; So it gets and doesnt set
		lea rdx, [rel termios_oldt]	; Struct where its gonna store the current values
		syscall

;		MemCpy for termios_oldt to termios_newt
		mov rcx, 64
		lea rsi, [rel termios_oldt]
		lea rdi, [rel termios_newt]
.copyLoopTermios:
		mov al, [rsi]
		mov [rdi], al
		inc rsi
		inc rdi
		loop .copyLoopTermios

;		Modify Termios_newt
;		newt.c_flag &= ~(ICANON | ECHO)
;		newt.c_flag is off by 12 bytes
		mov rax, [rel termios_newt + 12]
		and rax, ~(ICANON | ECHO)
		mov [rel termios_newt + 12], rax

;		new.c_cc is offsetted by 16, and VMIN is at +1 and VTIME 0
;		Honestly this part, idk why its working, but it is, so i wont change it
		xor rax, rax
		mov [rel termios_newt + 20], rax	; Termios_newt.c_cc[VTIME] = 1
		mov [rel termios_newt + 21], rax	; Termios_newt.c_cc[VMIN] = 0

;		Finished modifying termios_newt, just need to apply changes to terminal
		;	ioctl(0, TCSETS, &termios_oldt), basically sets current terminal info
		mov rax, SYS_ioctl		; SYS_ioctl system call
		mov	rdi, STDIN			; Standard Fd in
		mov rsi, TCSETS			; So it sets and doesnt get
		lea rdx, [rel termios_newt] ; Struct for the change
		syscall

;		Calls read(STDIN, &read_buf, 1)
		mov rax, SYS_read			; Prepare for read syscall
		mov rdi, STDIN				; Standard Fd in 
		lea rsi, [rel read_buf]		; Passing reference to read_buf
		mov rdx, 1					; Only reading a byte
		syscall

;		Modify terminal again, to revert back to old terminal
		mov rax, SYS_ioctl		; SYS_ioctl system call
		mov	rdi, STDIN			; Standard Fd in
		mov rsi, TCSETS			; So it sets and doesnt get
		lea rdx, [rel termios_oldt] ; Revert Back to old terminal
		syscall
		
;		Even if multiple keypresses at the same time/
;		too many, that overflows read buffer, it only saves the one who reads
;		at the moment
		mov     rax, SYS_ioctl       ; syscall number 16
		mov     rdi, STDIN           ; file descriptor 0 = stdin
		mov     rsi, TCFLSH          ; ioctl request: TCFLSH
		mov     rdx, TCIFLUSH        ; flush input queue
		syscall

		xor rax, rax
		movzx eax, BYTE [read_buf]
		ret

get_random_number:
    mov rax, SYS_getrandom
    lea rdi, [rel rand_byte]    ; buffer
    mov rsi, 4                  ; 4 bytes
    xor rdx, rdx                ; no flags
    syscall

    mov eax, [rand_byte]        ; get 4-byte value
    xor edx, edx
    mov ecx, 4           		; upper bound (0–4)
    div ecx                     ; eax = eax / 300, edx = remainder
    mov eax, edx                ; eax = random % 300
	add	eax, 1					; pass from (0-4) to (1-4)
    ret
