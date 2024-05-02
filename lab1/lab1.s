bits 64
; ((d+b)(a-c) + (e+b)(e-b))/b^2
section .data
res:
	dq	0
a:
	dd	464
b:
	dd	9469
c:
	dq	295246
d:
	dw  3564
e:
	db	-53
section .text
global _start
_start:
		mov eax, [b]
		or eax, eax ;проверка на ноль знаменателя
		jz error
		movsx r8, word[d] ;считываем d
		cdqe ;считываем b
		add rax, r8 ;выполняем операцию (d+b), результат может быть больше 32 бит
		; поэтому все изначально писал в 64 бита
		movsx r10, dword[a] ;считываем a
		mov r11, [c] ;считываем с
		sub r10, r11 ; выполняем операцию (а-с)
		jo error ;результат операции может превысить 64 бита, тогда выставится флаг OF
		imul r10 ;выполняем операцию (d+b)(a-c), (a-c) лежит в r10, (d+b) лежит в rax
		push rdx ;запоминаем старшую часть результат умножения в стеке
		push rax ;запоминаем младшую часть результат умножения в стеке
		movsx rax, byte[e] ;считываем e
		movsx rbx, dword[b] ;считваем b
		sub rax, rbx ;выполняем операцию (e-b)
		movsx rdi, byte[e] ;считываем e
		add rdi, rbx ;выполняем операцию (e+b)
		imul rdi ;выполняем операцию (e-b)(e+b), (e-b) лежит в rax, (e+b) лежит в rdi
		; из-за размерностей операндов в rdx никогда не запишется ничего кроме знака полученного результата
		pop rdi ; достаем из стека младшую часть результата операции (d+b)(a-c)
		add rax, rdi ;складываем младшие части
		pop rsi; достаем из стека старшую часть результата операции (d+b)(a-c)
		adc rdx, rsi ; делаем сложение с переносом на случай если при сложении младших частей был перенос
		jo error ; если в старшей части результат не поместился в 64 бита, то исключение
		imul rbx, rbx ; выполняем операцию b*b - считаем знаменатель
		idiv rbx ; выполняем деление числителя(rdx:rax) на знаменатель(rbx) 
		mov [res], rax ;частное записываем в res
		mov eax, 60
		mov edi, 0
		syscall
error:
		mov eax, 60
		mov edi, 1
		syscall
		