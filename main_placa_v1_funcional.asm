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

	mov r16, r4
    rcall invert_bit
    swap r16
	out PORTD, r16
	sbi PORTB, 0
	cbi PORTD, 3
	cbi PORTD, 2
	rcall delay_mili



	mov r16, r5
	rcall invert_bit
    swap r16
	out PORTD, r16
	sbi PORTD, 3
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


invert_bits:
    ldi r18, 8
    clr r17   

    reverse_loop:
        rol r16

        ror r17

        dec r18

    brne reverse_loop
ret

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

inc_pointer:
    adiw r26, 1             ; Incrementa o ponteiro X (r27:r26)

    ldi r18, low(fim_lista) ; Carrega o byte baixo do endereço de fim
    ldi r19, high(fim_lista) ; Carrega o byte alto do endereço de fim

    cp  r26, r18            ; Compara a parte baixa
    cpc r27, r19            ; Compara a parte alta com o Carry do anterior
    
    ; IF
    brne fim_inc            ; Se NÃO for igual ao fim, sai da função
    
    ; --- ELSE (Reset para o início da lista, Exibição Rotativa) ---
    ldi r26, low(lista)     
    ldi r27, high(lista)     

fim_inc:
    ret

main:
    
    ; Definindo PORTD como saída
    ldi r16, 0xFC
    out DDRD, r16; 0001 1110

    sbi DDRB, 0 ; PB0 (Pino 8) Saída

   ; Elemento Inicial da Lista L(0)
    ldi r30, low(lista<<1)
    ldi r31, high(lista<<1)
    
    ; Registrador X para transferência entre FLASH e RAM
    mov r26, r30
    mov r27, r31
	
MAIN_LOOP:
    
	lpm r20, Z+

	rcall convert_BCD

	ldi r25, 30
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação rápida

    dec r25
    brne loop_pov
	
		
	;rcall inc_pointer

    rjmp MAIN_LOOP  
rjmp main


lista:
    .db 3, 5, 8, 13, 21, 34, 55, 89, 134, 223
fim_lista:
