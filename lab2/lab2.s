bits 64
section .data
n:
	db 10

matrix:
	dq 3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64
	dq	3, 2, 1, 6, 5, 4, 9, 8, 7, 64

section .text
global _start
_start:
	mov cl, [n]
	mov r8b, [n]
	mov r9, 0
	mov rax, 1
	mul rcx
	mov rsi, 8
	mul rsi
	mov rbp, rax
	mov rax, matrix 
matrix_sort:	
	call sort
	add rax, rbp
	loop matrix_sort
	jmp exit
	
sort:
	mov r14b, r8b
	dec r14b
	mov r13b, 0 
	mov r12b, r14b
	or r12b, r12b
	jz m4
m0:	
	mov r11b, r13b ;
	inc r11b ;
m1:
	mov rbx, [rax + r11*8] ; arr[i]
	mov rdx, [rax + r11*8 - 8] ; arr[i-1]
	cmp rbx, rdx ;
%ifdef ASCENDING_ORDER  
	jnl m5
%elifdef DESCENDING_ORDER
	jl m5
%else 
	%error No instruction for sorting order
%endif			
	call swap ;if(arr[i] < arr[i-1])
m5:	
	inc r11b
	cmp r11b, r12b
	jle m1
m2:
	mov r12b, r14b
	mov r11b, r12b
m3:	
	mov rbx, [rax + r11*8]
	mov rdx, [rax + r11*8 - 8]
	cmp rbx, rdx
%ifdef ASCENDING_ORDER  
	jnl m6
%elifdef DESCENDING_ORDER
	jl m6
%else 
	%error No instruction for sorting order
%endif
	call swap
m6:		
	dec r11b
	cmp r11b, r13b
	jg m3
m4:
	mov r13b, r14b
	cmp r13b, r12b
	jl 	m0
	ret
swap:
	mov [rax + r11*8 - 8], rbx
	mov [rax + r11*8], rdx
	mov r14b, r11b
	ret	
exit:
	mov eax, 60
	mov edi, 0
	syscall	
	
