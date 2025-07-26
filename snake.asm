section .note.GNU-stack

%define WIDTH  64
%define HEIGHT 32
%define GRID_SIZE WIDTH*HEIGHT

section .bss
		grid resb GRID_SIZE  
		pos resb 4
		orien resb 4

section .data
		clear db 27, '[2J'    ; 27 = ESC (0x1B), ANSI code
		clear_len equ $ - clear
		cursor_home db 27, '[', 'H'    ; ESC [ H
		char_hash db '#'
		char_space db ' '
		char_player db '0'
		char_nl   db 10
		timespec:
		    dq 0              ; tv_sec = 0
		    dq 75000000       ; tv_nsec = 50,000,000 ns = 50 ms

section .text
		global _start
		global _termClear
		global _writeNewLine
		global constructMap
		global printMap
		extern ft_get_keypress

_start:
		mov dword [pos], 164
		mov dword [orien], 0
_loopMain:
		mov rax, 35        ; syscall: nanosleep
    	mov rdi, timespec  ; pointer to timespec
    	mov rsi, 0         ; NULL (no remainder)
    	syscall
		call _termClear
		call constructMap
		mov eax, [pos]
		mov BYTE [r9 + rax] , 1
		call printMap
		call ft_get_keypress
		cmp rax, 100
		jne _try_left
		mov dword [orien], 4
_try_left:
		cmp rax, 97
		jne _try_up
		mov dword [orien], 2
_try_up:
		cmp rax, 119
		jne _try_down
		mov dword [orien], 1
_try_down:
		cmp rax, 115
		jne _mov_right
		mov dword [orien], 3
_mov_right:
		cmp dword [orien], 4
		jne _mov_left
		jne _mov_up
		xor rax, rax
		mov eax, dword [pos]
		mov rbx, WIDTH
		div rbx
		cmp rdx, WIDTH - 2
		je _exit
		add dword [pos], 2
		xor rdx, rdx
		xor rax, rax
		mov eax, dword [pos]
		mov rbx, 2
		div rbx
		cmp rdx, 1
		jne _loopMain
		inc dword [pos]
		jmp _loopMain
_mov_left:
		cmp dword [orien], 2
		jne _mov_up
		xor rax, rax
		mov eax, dword [pos]
		mov rbx, WIDTH
		div rbx
		cmp rdx, 1
		je _exit
		sub dword [pos], 2
		xor rdx, rdx
		xor rax, rax
		mov eax, dword [pos]
		mov rbx, 2
		div rbx
		cmp rdx, 0
		jne _loopMain
		dec dword [pos]
		jmp _loopMain
_mov_up:
		cmp dword [orien], 1
		jne _mov_down
		xor rax, rax
		mov eax, dword [pos]
		mov rbx, WIDTH
		div rbx
		cmp rax, 1
		je _exit
		sub dword [pos], WIDTH
		jmp _loopMain
_mov_down:
		cmp dword [orien], 3
		jne _loopMain
		xor rax, rax
		mov eax, dword [pos]
		mov rbx, WIDTH
		div rbx
		cmp rax, HEIGHT - 2
		je _exit
		add dword [pos], WIDTH
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
_ret:
		ret


;	Writes map to terminal
printMap: 
		xor rbx, rbx	; x = 0
_print:
		cmp rbx, GRID_SIZE
		jge _ret
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
		jne _tryPlayer
		mov rax, 1          ; sys_write
		mov rdi, 1          ; stdout
		mov rsi, char_space	; pointer to ' '
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
