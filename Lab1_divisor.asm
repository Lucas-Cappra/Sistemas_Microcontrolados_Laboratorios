;
; AssemblerApplication1.asm
;
; Created: 16/03/2026 17:00:42
; Author : Tired
;


inicio:

	LDI R16, 222
	MOV R0,R16 //copia R16 para R0

	LDI R16, 100
	MOV R1, R16 //copia R1 para dividir por centena

	LDI R16, 10
	MOV R2, R16 //copia R2 para dividir por dezena
	
	LDI R16, 1
	MOV R3, R16 //copia R3 para dividir por unidade
	RCALL dividir
loop:
	RJMP loop

dividir:
	CLR R4 //limpa R4
	CLR R5 //limpa R5
	CLR R6 //limpa R6
	MOV R7,R0 //preserva R0

div_centena:
	SUB R7,R1
	BRLO div_dezena //Desvia se R7<R1
	INC R4
	RJMP div_centena

div_dezena:
	SUB R7,R2
	BRLO div_unidade //Desvia se R7<R2
	INC R5
	RJMP div_dezena

div_unidade:
	SUB R7,R3
	BRLO div_sair //Desvia se R7<R3
	INC R6
	RJMP div_unidade

div_sair:	
	MOV R8,R7
	RET //retorna


//R4, R5, R6 retorna os valores de Dezena, Centena e Unidade respectivamente.

