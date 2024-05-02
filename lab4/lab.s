bits 64

section .data
one dd 1.0
 
neg_one dd -1.0

zero dd 0.0

after_input db "You entered values: %f, %f", 10, 0

err_value db "invalid argument, x should be less or equal to 1 in absolute value", 10, 0

fmt_my db "my log: %f", 10, 0

fmt_lib db "lig log: %f", 10, 0

fmt_x db "input x:", 10, 0

fmt_precision db "input precision:", 10, 0

fmt_for_input db "%f", 0 ;для scanf

file_name db "output.txt", 0

mode db "a", 0

err_in_file db "error happened with file", 10, 0

fmt_for_file db "n: %d, value: %f", 10, 0

curr_res dd 0.0

prev_res dd 0.0

temp_series_data dd 0.0

section .text
; в xmm1 аккумулируется частичная сумма ряда
; в xmm2 хранится частичная сумма ряд на шаг назад
; в xmm7 хранится точность вычисления
; в xmm3 хранится очередной множитель для (2n-1)!!
; в xmm4 хранится очередной множитель для (2n)!!
; в xmm6 считается очередной член ряда
; в xmm8 хранится аргумент функции
my_long_log:
	xor eax, eax; обнуляем кол-во членов ряда
	movss xmm7, xmm1
	movss xmm1, xmm0 
	movss xmm6, xmm0
	movss xmm8, xmm0
	movss xmm2, [zero]
	mov edi, 2
	cvtsi2ss xmm4, edi
	movss xmm3, [one]
.calc_difference:
	inc eax; увеличиваем счетчик членов ряда
	movss xmm11, xmm6 ;сохраняем значение предыдущего члена ряда
	ucomiss xmm6, [zero]
	jae .comp_with_precision 	
	mulss xmm6, [neg_one] 
.comp_with_precision:
	ucomiss xmm6, xmm7
	jbe .return
	movss xmm6, xmm11 ; восстанавливаем значение предыдущего члена ряда	
.calc_sum:
	mulss xmm6, [neg_one] ; умножить на -1
	mulss xmm6, xmm8 ; умножить на x 
	mulss xmm6, xmm8 ; умножить на x
	mov edi, 2
	cvtsi2ss xmm10, edi 
	cvtsi2ss xmm9, eax
	mulss xmm9, xmm10 
	subss xmm9, [one] ;сформировали нефакториальную часть знаменателя с прошлого шага
	mulss xmm6, xmm9
	mulss xmm6, xmm9
	cvtsi2ss xmm9, eax
	mulss xmm9, xmm10 
	divss xmm6, xmm9 ; сфорировали значение равно степени при x
	addss xmm9, [one] ;сформировали факториальную часть знаменателя
	divss xmm6, xmm9
	movss xmm2, xmm1 ;сохраняем предыдующую частичную сумму
	addss xmm1, xmm6
	movss [curr_res], xmm1
	movss [prev_res], xmm2
	movss [temp_series_data], xmm6
	push rax
.print_to_file:
	mov rdi, file_name
	mov rsi, mode
	mov rdx, rax
	movss xmm0, xmm6
	call write_to_file
	or rax, rax
	jl .bad_return
	pop rax
	movss xmm1, [curr_res]
	movss xmm2, [prev_res]
	movss xmm6, [temp_series_data]
	jmp .calc_difference
.return:
	movss xmm0, xmm1
	mov rax, 0
	ret	
.bad_return:
	mov rax, 1
	ret	

;в rdx передаем номер члена ряда,в rdi передаем адрес строки с именем файла
;в rsi передаем адрес строки со способом открытия файла, в xmm0 передаем значение члена ряда
write_to_file:
	push rbp
	mov rbp, rsp
	push rdx
	call fopen
	or rax, rax
	jl .bad_file
	pop rdx
	push rax
	mov rdi, rax
	mov rsi, fmt_for_file
	mov rax, 1
	push rcx
	movss xmm1, [temp_series_data]
	cvtss2sd xmm0, xmm1
	call fprintf
	pop rcx
	pop rdi
	call fclose
	or rax, rax
	jnz .bad_file
	leave
	ret
.bad_file:
	mov rdi, err_in_file
	xor rax, rax
	call printf
	mov rax, -1
	leave
	ret	
	
x equ 4
y equ x+4
z equ y+4
extern printf
extern scanf
extern logf
extern fopen
extern fclose
extern fprintf
global main
main:
	push rbp
	mov rbp, rsp
	sub rsp, z
	and rsp, -16
	mov edi, fmt_x
	xor eax, eax
	call printf
	
	mov edi, fmt_for_input
	lea rsi, [rbp-x]
	xor rax, rax
	call scanf
	movss xmm0, [rbp-x]

	xor rsi, rsi
	mov edi, fmt_precision
	xor eax, eax
	call printf
	
	mov edi, fmt_for_input
	lea rsi, [rbp-y]
	xor rax, rax
	call scanf
	movss xmm0, [rbp-y]

	xor rsi, rsi
	movss xmm2, [rbp-x]
	movss xmm3, [rbp-y]
	cvtss2sd xmm0, xmm2
	cvtss2sd xmm1, xmm3
	mov edi, after_input
	mov rax, 2
	call printf
	
	movss xmm0, [rbp-x]
	movss xmm1, [rbp-y]
	ucomiss xmm0, [one]
	ja .invalid_argument
	ucomiss xmm0, [neg_one]
	jb .invalid_argument
	
	call my_long_log
	cmp rax, 1
	je .bad_leave
	movss [rbp-z], xmm0
	mov edi, fmt_my
	movss xmm1, [rbp-z]
	cvtss2sd xmm0, xmm1
	mov eax, 1
	call printf
	
	movss xmm0, [rbp-x]
	movss xmm1, xmm0
	mulss xmm0, xmm1
	addss xmm0, [one]
	sqrtss xmm2, xmm0
	addss xmm2, xmm1
	movss xmm0, xmm2
	call logf
	movss [rbp-z], xmm0
	mov edi, fmt_lib
	mov eax, 1
	call printf
	leave
	xor eax, eax
	ret
.invalid_argument:
	mov edi, err_value
	xor eax, eax
	call printf
.bad_leave:
	leave
	mov eax, 1
	ret
