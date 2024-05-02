bits 64

section .data
buf_size equ 10

buf_len dw 0

word_count dw 0

arg1 db "ARG1="
arg1_name_len equ $-arg1
arg2 db "ARG2="
arg2_name_len equ $-arg2

err_msg db "ERROR HAPPENED", 10
err_msg_len equ $-err_msg

quote db 39
new_line db 10
space db 32

N dw 0

output_filename_len dw 0
output_filename dq 0

fd dq 0

section .bss
buf resb buf_size


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
	call open_file
	or rax, rax
	jl print_error
	mov [fd], rax
begin_string_change:	
	xor rax, rax
	xor rdi, rdi
	mov rsi, buf
	movsx rdx, word[buf_len]
	add rsi, rdx
	mov rdx, buf_size
	syscall
	or rax, rax
	jl bad_exit
	je exit
	push rdi
	push rax
	push rsi
	push rdx
	cmp word[word_count], 0
	je print_quote
m:
	pop rdx
	pop rsi
	pop rax
	pop rdi	
	movsx dx, [buf_len]
	add dx, ax
	mov [buf_len], dx
	mov al, 32
	mov rdi, buf
read_word:
	lea rcx, buf
	sub rcx, rdi
	movsx r9, word[buf_len]
	add rcx, r9 ; в rcx длина еще не обработанного буфера
	jz print_end ;по этой метке должен писаться результат в файл и переход к метке begin_string_change
	mov r8, rcx
	cld
	repne scasb
	or rcx, rcx ;достиг конца строки
	jz processing 
	inc rcx
	neg rcx
processing:
	add rcx, r8 ;сейчас в rcx длина слова	
	cmp rcx, r8
	sete r8b
	cmp byte[rdi - 1], 10
	setne r9b
	and r8b, r9b
	jnz delay_word
	push rdi
	push rax
	or r9b, r9b
	jnz call_func
	dec rcx
call_func:	
	sub rdi, rcx
	dec rdi
	call shift_and_write  
	pop rax
	pop rdi
	jmp read_word

delay_word:
	mov word[buf_len], cx
	mov rsi, rdi
	sub rsi, rcx
	mov rdi, buf
	rep movsb	
	jmp begin_string_change

print_end:
	mov rdi, [fd]
	push rdi
	mov rax, 1
	mov rsi, quote
	mov rdx, 1
	syscall ;записать открывающую кавычку
	or rax, rax
	jl print_error
	pop rdi
	push rdi
	mov rax, 1
	mov rsi, new_line
	mov rdx, 1
	syscall ;записать перевод строки
	or rax, rax
	jl print_error
	mov word[buf_len], 0
	mov word[word_count], 0
	jmp begin_string_change
	
exit:
	call close_file
	mov rax, 60
	mov rdi, 0
	syscall
	
bad_exit:
	call close_file
	mov rax, 60
	mov rdi, 1
	syscall		
	
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

open_file:
	mov rax, 2
	mov rdi, [output_filename]
	mov rsi, 2
	mov rdx, 700
	syscall ; открываем файл
	ret	

shift_and_write:
	or cx, cx
	mov rax, 0
	jz .return
	cmp word[word_count], 0
	push rcx
	push rdi
	jne .add_space
.write_shifted:
	pop rdi
	pop rcx
	xor rdx, rdx
	mov ax, word[N]
	div cx
	push rdi
	sub cx, dx
	push rcx
	xor rax, rax
	mov rsi, rdi
	add rsi, rcx
.m1:		
	add rsi, rax
	sub rdx, rax
	mov rdi, [fd]
	mov rax, 1
	syscall	
	or rax, rax
	jl .return
	cmp rax, rdx
	jl .m1 
	pop rdx
	pop rsi
	xor rax, rax
.m2:
	add rsi, rax
	sub rdx, rax
	mov rdi, [fd]
	mov rax, 1
	syscall
	or rax, rax
	jl .return
	cmp rax, rdx
	jl .m2
	inc word[word_count]
.return:	
	ret
.add_space:
	mov rdi, [fd]
	mov rax, 1
	mov rsi, space
	mov rdx, 1
	syscall
	jmp .write_shifted	

close_file:
	mov rax, 3
	mov rdi, [fd]
	syscall
	ret

print_quote: 
	mov rdi, [fd]
	mov rsi, quote
	mov rdx, 1
	mov rax, 1
	syscall
	or rax, rax
	jl print_error
	jmp m
