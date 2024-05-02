bits 64

section .data
arg1 db "ARG1="
arg1_name_len equ $-arg1
arg2 db "ARG2="
arg2_name_len equ $-arg2

err_msg db "NO ENV VAR OR INVALID VALUE"
err_msg_len equ $-err_msg

N dw 0

output_filename_len dw 0
output_filename dq 0
 
section .text
global _start
_start:
	mov rdi, rsp
	mov rax, [rdi]
	inc rax
	mov rcx, 8
	mul rcx
	add rdi, rax
	push rdi
read_env:
	mov rsi, arg1
	call read_arg
	or rax, rax
	jl print_error
	mov word[N], ax
	pop rdi
	mov rsi, arg2
	call read_arg
	or rax, rax
	jl print_error
	mov [output_filename], rax
	jmp exit

print_error:
	mov rax, 1
	mov rdi, 1
	mov rsi, err_msg
	mov rdx, err_msg_len
	syscall
	jmp exit

convert_to_number:
	xor rax, rax
	mov rcx, 10
	xor r8, r8
.m1:
	mov r8b, byte[rdi]
	or r8b, r8b
	jnz .m2
	ret
.m2:	
	sub r8b, 48
	cmp r8b, 0
	jl .m3
	cmp r8b, 9
	jg .m3
	mul rcx
	add rax, r8
	add rdi, 1
	jmp .m1
.m3:
	mov rax, -1
	ret

read_arg:
	mov r9, rdi
	cmp rsi, arg1
	sete r10b
	mov r11, rsi
.begin:
	mov rsi, r11
	add r9, 8
	mov rdx, [r9]
	or rdx, rdx
	jz .bad_exit
	mov rdi, rdx
	cld
	or r10b, r10b
	jnz .set_first_arg_len
	mov rcx, arg2_name_len
.cmp_strings:
	repe cmpsb
	jnz .begin
	or r10b, r10b
	jnz .handle_first_argument
.handle_second_argument:
	mov rax, rdi
	xor rcx, rcx
.count_symbols:
	mov r10b, byte[rdi]
	inc rcx
	inc rdi
	or r10b, r10b
	jnz .count_symbols
	dec rcx
	cmp rcx, 1024
	jg .bad_exit
	mov [output_filename_len], rcx
	ret	
.handle_first_argument:
	call convert_to_number
	ret
.set_first_arg_len:
	mov rcx, arg1_name_len
	jmp .cmp_strings
.bad_exit:
	mov rax, -1
	ret

exit:
	mov rdi, 0
	mov rax, 60
	syscall
