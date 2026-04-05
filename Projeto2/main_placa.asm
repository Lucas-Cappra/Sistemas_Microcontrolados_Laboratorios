.include "m328pdef.inc"

.cseg
.org 0x0000           ; A proxima instruncao em 0x0000

rjmp main

.org 0x0004

rjmp ISR_BOTOES    ; Vetor de PCINT0 (Pinos 8-13)



ler_adc:
    lds r26, ADCSRA
    ori r26, (1 << ADSC)    ; Inicia conversão
    sts ADCSRA, r26

aguarda_adc:
    lds r26, ADCSRA
    sbrc r26, ADSC          ; Espera terminar
    rjmp aguarda_adc
    
    lds r26, ADCH          ; Lê apenas os 8 bits principais
    ret




maquina_de_estados:

    cpi r19, 0
    breq init
    
    cpi r19, 1
    breq count

    cpi r19, 2
    breq min

    cpi r19, 3
    breq max_state

    cpi r19, 4
    breq step

    rjmp fim_maquina


    ; Estado Inicial(Reset)
    init:
    cbi PORTB, 1
    cbi PORTB, 2
    cbi PORTB, 3

    ;clr r20
    ;clr r24
    ldi r24, 1
    mov r28, r24
    ldi r25, 255
    ldi r27, 1


    ;inc r19
    ldi r19, 1
    rjmp fim_maquina


    ; Estado de Contagem
    count:
    sbi PORTB, 1
    cbi PORTB, 2
    sbi PORTB, 3
    
    mov r20, r28

    rcall inc_dec
    
    rjmp fim_maquina


    ; Estado de Seleção do Valor Mínimo
    min:
    ;push r20

    rcall ler_adc
    mov r24, r26
    mov r20, r24

    sbi PORTB, 1
    cbi PORTB, 2
    cbi PORTB, 3



    ;pop r20
    rjmp fim_maquina

    ; Estado de Seleção do Valor Máximo
    max_state:
    ;push r20

    rcall ler_adc
    mov r25, r26
    mov r20, r25


    cbi PORTB, 1
    sbi PORTB, 2 
    cbi PORTB, 3


    ;pop r20
    rjmp fim_maquina


    ; Estado de Seleção do Valor de Passo

    step:
    ;push r20

    rcall ler_adc
    mov r27, r26
    mov r20, r27

    cbi PORTB, 1
    cbi PORTB, 2
    sbi PORTB, 3 


    ;pop r20
    rjmp fim_maquina


    ; Fim
    fim_maquina:
    ret




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
    RET ;retorna
    ;R4, R5, R6 retorna os valores de Dezena, Centena e Unidade respectivamente.


exibir_pov:
		
	
	clr r14
	mov r16, r4

    rcall invert_bit
    swap r16
	out PORTD, r16

	; Comparação pra verificar se a centena é nula, para não mostrar no display
	cp r4, r14
	pop r19

    breq centena_zero
    sbi   PORTB, 0
    centena_zero:

	cbi PORTD, 3
	cbi PORTD, 2

	; Delay de 3 ms
	rcall delay_mili



	mov r16, r5
	mov r13, r5
	or r13, r4

	rcall invert_bit
    swap r16

	out PORTD, r16

	; Comparação para verificar se a dezena é nula, e não mostrar no display em caso positivo
	cp r13, r14
    breq dezena_zero
    sbi   PORTD, 3  

    dezena_zero:
	cbi PORTD, 2
	cbi PORTB, 0
	
	; Delay de 3 ms
	rcall delay_mili


	mov r16, r6
	rcall invert_bit
    swap r16
    out PORTD, r16
    sbi PORTD, 2
	cbi PORTD, 3
	cbi PORTB, 0

	; Delay de 3 ms
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



inc_dec:
    cpi r18, 1
    breq subtrair

somar:
    add r28, r27         ; Soma o passo
    cp  r28, r25         ; Compara com o Máximo (r25)
    brlo fim_inc         ; Se r20 < r25, está ok, sai
    breq fim_inc         ; Se r20 == r25, está no limite, sai
    mov r28, r24         ; Se passou do máximo, volta para o Mínimo (Reset)
    rjmp fim_inc

subtrair:
    sub r28, r27         ; Subtrai o passo
    cp  r28, r24         ; Compara com o Mínimo (r24)
    brsh fim_inc         ; Se r20 >= r24 (Same or Higher), está ok, sai
    mov r28, r25         ; Se ficou menor que o mínimo, pula para o Máximo

fim_inc:
    ret


exibir:

    ; Delay (~1 s)
    ldi r26, 30
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação rápida
    dec r26
    cpi r26, 0
    brne loop_pov

    ret






main:


    setup_display:
    ldi r16, 0xFC
    out DDRD, r16; 1111 1100(4 Pinos pro 7448 e 2 Pros transistores de Dezena e Unidade)

    sbi DDRB, 0 ; PB0 (Pino 8) Saída pro Transistor de Centena



    setup_rgb:

    sbi DDRB, 1 ; PB1 (Pino 9) Saida
    sbi DDRB, 2 ; PB2 (Pino 10) Saida
    sbi DDRB, 3 ; PB3 (Pino 11) Saida


    setup_AD_Converter:
    ; Canal A5 (MUX2 e MUX0), Referência AVcc (REFS0), Ajuste à Esquerda (ADLAR)
    ldi r16, (1 << REFS0) | (1 << ADLAR) | (1 << MUX2) | (1 << MUX0)
    sts ADMUX, r16
    ; Habilita ADC (ADEN) e Prescaler 128 (ADPS0,1,2)
    ldi r16, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts ADCSRA, r16
    




    SETUP_BOTOES:  ;A1, A2, A3
    cbi DDRC, 1
    sbi PORTC, 1       ; Ativa Pull-up no A1
    
    ldi r16, (1 << PCIE1)
    sts PCICR, r16     ; Grupo Port C
    ldi r16, (1 << PCINT9)
    sts PCMSK1, r16    ; Pino A1
  

    sei


    ldi r18, 0

    init_state:
    ;ldi r19, 0
    

MAIN_LOOP:
	
	; Atualiza o Estado do Sistema
    rcall maquina_de_estados

    ; Converte o numero em r20 para BCD
    rcall convert_BCD

	; Exibe de acordo com o efeito POV
    rcall exibir
    ;inc r19
    cpi r19, 5
    brlo continua
    ldi r19, 1          ; Se for 5 ou mais, volta pro zero
    
continua:

    rjmp MAIN_LOOP
