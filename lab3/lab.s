bits 64

section .bss
res resb 1024
buf resb 1024
r_w resb 1024
l_w resb 1024

section .data
err_msg db "Some error happened", 10
err_msg_len equ $-err_msg
quote db 39
q_l equ 1
buf_len dw 0
res_len dw 0
N dw 3
r_w_l dw 0
l_w_l dw 0
word_count dw 0

section .text
global _start
_start:
	mov rax, 0
	mov rdi, 0
	mov rsi, buf
	mov rdx, 1024
	syscall
	or rax, rax
	jl error
	je exit
	cmp byte[buf + 1*rax - 1], 10
	jne error
	xor r15, r15
	mov word[buf_len], ax
	mov r14, rax
	dec r14
m1:	
	cmp r15w, r14w
	jl m8
	call print
	jmp _start
m8:	 
	mov bl, byte[buf + 1*r15]
	cmp bl, 9
	je m7
	cmp bl, 32
	je m7
	jmp word_begin
m7:
	inc r15
	jmp m1	
error:
	mov rax, 1
	mov rdi, 1
	mov rsi, err_msg
	mov rdx, err_msg_len
	syscall
	mov rax, 60
	mov rdi, 1
	syscall		
print:
	mov rax, 1
	mov rdi, 1
	mov rsi, quote
	mov rdx, q_l
	syscall
	mov rax, 1
	mov rdi, 1
	movsx rdx, word[res_len]
	mov rsi, res
	syscall
	mov rax, 1
	mov rdi, 1
	mov rsi, quote
	mov rdx, q_l
	syscall
	mov byte[quote], 10
	mov rax, 1
	mov rdi, 1
	mov rsi, quote
	mov rdx, q_l	
	syscall
	mov word[res_len], 0
	mov word[quote], 39
	ret
word_begin:
	mov rdi, buf
	add rdi, r15 ;запомнили указатель на начало слова
	mov rsi, 1
	inc r15
m2:	
	mov bl, byte[buf + 1*r15]
	cmp bl, 10
	je next
	cmp bl, 9
	je next
	cmp bl, 32
	je next
	inc rsi
	inc r15
	jmp m2
next:	
	call shift
	jmp write_to_res
shift:
	push rbx
	mov ax, word[N]
	cwd
	div si
	mov [l_w_l], dx
	sub si, dx
	mov [r_w_l], si
	xor r8, r8
	xor rcx, rcx
	movsx rcx, word[l_w_l]
	mov r9, rdi
	movsx r10, word[r_w_l]
	add r9, r10
.write_left:
	mov bl, [r9 + 1*r8]
	mov byte[l_w + 1*r8], bl
	inc r8
	loop .write_left
	mov r9, rdi
	xor r8, r8
	movsx rcx, word[r_w_l]
.write_right:
	mov bl, [r9 + 1*r8]		
	mov byte[r_w + 1*r8], bl
	inc r8
	loop .write_right
	pop rbx
	ret
write_to_res:
	mov rax, res
	movsx rcx, word[res_len]
	add rax, rcx
	cmp word[word_count], 0
	jne m6
m5:	
	movsx rcx, word[l_w_l]
	xor r8, r8
m3:
	mov r10b, [l_w + 1*r8]
	mov byte[rax + 1*r8], r10b
	inc r8
	inc word[res_len]
	loop m3
	add rax, r8
	xor r8, r8
	movsx rcx, word[r_w_l]
m4:
	mov r10b, [r_w + 1*r8]
	mov byte[rax + 1*r8], r10b
	inc r8
	inc word[res_len]
	loop m4	
	mov word[word_count], 1
	jmp m1

m6:
	mov byte[rax], 32
	inc rax
	inc word[res_len]
	jmp m5	
exit:
	call print
	mov rax, 60
	mov rdi, 0
	syscall
