bits 64

section .data
word db "hello"
word_len dw 5
shift dw 3
left times 3 db 0


section .text
global _start
_start:
	mov rdi, word
	movsx rsi, word[word_len]
	movsx rdx, word[shift]
	call shift_word
	mov rsi, rax
	movsx rdx, word[word_len]
	mov rax, 1
	mov rdi, 1
	syscall
shift_word:
	
