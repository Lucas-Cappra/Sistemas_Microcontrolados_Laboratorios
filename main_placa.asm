.include "m328pdef.inc"

.cseg
.org 0x0000           ; A proxima instruncao em 0x0000

rjmp main


convert_BCD:

  dividir:
    CLR R4 ;limpa R4
    CLR R5 ;limpa R5
    CLR R6 ;limpa R6
    MOV R16, R20 ;preserva R0
    

  div_centena:
    CPI R16, 0x64
    BRLO div_dezena ;Desvia se R7<R1
    SUBI R16, 0x64
    INC R4
    rjmp div_centena
    
    
  div_dezena:
    CPI R16, 0x0A
    BRLO div_unidade
    SUBI R16, 0x0A
    INC R5
    rjmp div_dezena ;Desvia se R7<R1

  div_unidade:
    CPI R16, 0x01
    BRLO div_sair
    SUBI R16, 0x01
    INC R6
    rjmp div_unidade ;Desvia se R7<R1
  ;div_unidade:

    
  div_sair:
    ;MOV R6, R16
    RET ;retorna
    ;R4, R5, R6 retorna os valores de Dezena, Centena e Unidade respectivamente.


exibir_pov:


	ldi r19, 0
	mov r16, r4

    rcall invert_bit
    swap r16
	out PORTD, r16

	cp r4, r19

    breq centena_zero
    sbi   PORTB, 0
    centena_zero:

	cbi PORTD, 3
	cbi PORTD, 2
	rcall delay_mili



	mov r16, r5
	mov r17, r5
	or r17, r4

	rcall invert_bit
    swap r16

	out PORTD, r16
	cpi r17, 0
    breq dezena_zero
    sbi   PORTD, 3  

    dezena_zero:
	cbi PORTD, 2
	cbi PORTB, 0
	rcall delay_mili


	mov r16, r6
	rcall invert_bit
    swap r16
    out PORTD, r16
    sbi PORTD, 2
	cbi PORTD, 3
	cbi PORTB, 0

	rcall delay_mili
   
    
    ret



delay_mili:
   clr     r21         
   ldi     r22, 0
   ldi     r23, 1


delay_loop_mili:
    dec     r22         
    brne    delay_loop_mili  
    dec     r21         
    brne    delay_loop_mili  
    dec     r23         
    brne    delay_loop_mili  
    ret

; Função de Inverter os Bits
invert_bit:
    cpi r16, 1
    brne value_2
    ldi r16, 8
    rjmp fim

    value_2: 
    cpi r16, 2
    brne value_3
    ldi r16, 4
    rjmp fim

    value_3: 
    cpi r16, 3
    brne value_4
    ldi r16, 0x0C
    rjmp fim

    value_4:
    cpi r16, 4
    brne value_5
    ldi r16, 2
    rjmp fim

    value_5:
    cpi r16, 5
    brne value_6
    ldi r16, 0x0A
    rjmp fim

    value_6:
    cpi r16, 6
    brne value_7
    rjmp fim

    value_7:
    cpi r16, 7
    brne value_8
    ldi r16, 0x0E
    rjmp fim

    value_8:
    cpi r16, 8
    brne value_9
    ldi r16, 1
    rjmp fim

    value_9:
    cpi r16, 9
    rjmp fim

    fim:
    ret


main:
    
    ; Definindo PORTD como saída
    ldi r16, 0xFC
    out DDRD, r16; 0001 1110

    sbi DDRB, 0 ; PB0 (Pino 8) Saída

   ; Elemento Inicial da Lista L(0)
	inicio_lista:
	ldi r24, 0
    ldi r30, low(lista<<1)
    ldi r31, high(lista<<1)

	
MAIN_LOOP:
	
	; Carregamento do Valor do Endereço Z da flash em r20
	lpm r20, Z+

	; Comparação do contador para verificar se alcançou o fim da lista
	cpi r24, 10	
	breq inicio_lista
	inc r24

	; Conversor BIN -> BCD
	rcall convert_BCD
	
	; Delay de ~1s
	ldi r25, 30
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação 
    dec r25
	cpi r25, 0
    brne loop_pov
	
    rjmp MAIN_LOOP  
rjmp main


lista:
    .db 3, 5, 8, 13, 21, 34, 55, 89, 134, 223
fim_lista:
