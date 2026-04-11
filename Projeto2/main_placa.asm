.include "m328pdef.inc"

.cseg
.org 0x0000           ; A proxima instruncao em 0x0000

rjmp main

.org 0x0005

rjmp ISR_BOTOES    ; Vetor de PCINT0 (Pinos A0-A5)





ISR_BOTOES:
    push r16
    in r16, SREG
    push r16

    S2:
    ; 1. Verifica se foi um aperto (0) ou solte (1)
    sbic PINC, 2        ; Se for 1 (soltou), pula para o fim
    rjmp S3

    ; 2. O botão foi apertado! Incrementa o estado
    ldi r17, 1
    mov r15, r17
    
    S3:
    sbic PINC, 1        ; Se for 1 (soltou), pula para o fim
    rjmp S1

    ; 2. O botão foi apertado! Incrementa o estado
    ldi r18, 1


    S1:
    sbic PINC, 3        ; Se for 1 (soltou), pula para o fim
    rjmp sair_isr

    ; 2. O botão foi apertado! Incrementa o estado
    ldi r18, 0
    
    ; --- TRAVA DE SEGURANÇA ---
    ; Fica aqui enquanto o botão estiver pressionado (0)

sair_isr:
    pop r16
    out SREG, r16
    pop r16
    reti


ler_adc:
    lds r16, ADCSRA
    ori r16, (1<<ADSC)
    sts ADCSRA, r16                 ; conversao

wait_adc:
    lds r16, ADCSRA
    sbrs r16, ADSC
    rjmp wait_adc

    lds r22, ADCL
    lds r23, ADCH
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

    ldi r19, 1

    rjmp fim_maquina


    ; Estado Inicial(Reset)
    init:
    cbi PORTC, 1
    cbi PORTC, 2
    cbi PORTC, 3

    ldi r30, 0x03
    ldi r31, 0xE7

    ldi r29, 0
    ldi r28, 0

    ldi r27, 0
    ldi r26, 0

    ldi r25, 1

    ldi r19, 1

    rjmp fim_maquina


    ; Estado de Contagem
    count:
    cbi PORTC, 1
    sbi PORTC, 2
    cbi PORTC, 3
    
    mov r20, r26
    mov r21, r27

    rcall inc_dec
    
    rjmp fim_maquina


    ; Estado de Seleção do Valor Mínimo
    min:

    rcall ler_adc
    rcall map_adc
    mov r28, r22
    mov r29, r23

    mov r20, r28
    mov r21, r29

    cbi PORTC, 1 
    sbi PORTC, 2
    sbi PORTC, 3



    rjmp fim_maquina

    ; Estado de Seleção do Valor Máximo
    max_state:

    rcall ler_adc
    rcall map_adc

    mov r30, r22
    mov r31, r23

    mov r20, r30
    mov r21, r31


    sbi PORTC, 1
    cbi PORTC, 2 
    sbi PORTC, 3


    rjmp fim_maquina


    ; Estado de Seleção do Valor de Passo

    step:
    clr r16
    rcall ler_adc
    rcall map_step
   ;mov r20, r25
    ;ldi r21, 0

    mov r25, r22
    
    mov r20, r25
    mov r21, r23


    sbi PORTC, 1
    sbi PORTC, 2
    cbi PORTC, 3 

    carrega_minimo:
    cpi r18, 1
    breq carrega_maximo
    mov r26, r28
    mov r27, r29

    carrega_maximo:
    mov r26, r30
    mov r27, r31

    rjmp fim_maquina


    ; Fim
    fim_maquina:
    ret



  convert_BCD:

    push r17
    push r16

    CLR R4        ; centenas
    CLR R5        ; dezenas
    CLR R6        ; unidades

    MOV R16, R20  ; LOW byte
    MOV R17, R21  ; HIGH byte

;========================================================
; CENTENAS (subtrai 100 = 0x0064)
;========================================================

div_centena:
    CPI R17, 0
    BRNE sub_100          ; se high > 0, pode subtrair

    CPI R16, 100
    BRLO div_dezena       ; se <100, vai para dezenas

sub_100:
    SUBI R16, 100         ; subtrai low
    SBCI R17, 0           ; subtrai carry do high
    INC R4
    RJMP div_centena

;========================================================
; DEZENAS (subtrai 10 = 0x000A)
;========================================================

div_dezena:
    CPI R17, 0
    BRNE sub_10           ; se high > 0, continua

    CPI R16, 10
    BRLO div_unidade

sub_10:
    SUBI R16, 10
    SBCI R17, 0
    INC R5
    RJMP div_dezena

;========================================================
; UNIDADES (subtrai 1)
;========================================================

div_unidade:
    CPI R17, 0
    BRNE sub_1

    CPI R16, 1
    BRLO div_sair

sub_1:
    SUBI R16, 1
    SBCI R17, 0
    INC R6
    RJMP div_unidade

div_sair:
    pop r16
    pop r17
    RET


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


map_step:
    push r17
    push r18


    ; Recebe o valor da conversão AD = r23:r22
    mov r17, r22
    mov r18, r23

    ; Desloca 6 vezes a direita
    ldi r16, 6
div_64:
    lsr r18
    ror r17
    dec r16
    cpi r16, 0
    brne div_64

    ; Volta pros registradores de valores
    mov r22, r17
    mov r23, r18

    ; Retorna o valor convertido
    pop r18
    pop r17
    ret


    
map_adc:
    ; Calcula ADC - 24*ADC/1024
    ; R23:R22 = ADC (10 bits)
    push r16
    push r17
    push r18
    push r24
    push r25


    ; calcula ADC*24
    mov r17, r22
    mov r18, r23

    ; *8
    lsl r17
    rol r18
    lsl r17
    rol r18
    lsl r17
    rol r18

    mov r24, r17
    mov r25, r18

    ; *16
    lsl r17
    rol r18

    ; soma 8*ADC + 16*ADC
    add r17, r24
    adc r18, r25

        ; divide por 1024
    ldi r16, 10
map_l2:
    lsr r18
    ror r17
    dec r16
    brne map_l2

    ; subtrai
    sub r22, r17
    sbc r23, r18


    pop r25
    pop r24
    pop r18
    pop r17
    pop r16
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
    clr r16
    cpi r18, 1
    breq subtrair 

somar:
    add r26, r25         ; Soma o passo
    adc r27, r16         ; Soma com carry

    cp  r26, r30         ; Compara com o Máximo (r25)
    cpc r27, r31

    brlo fim_inc         ; Se r20 < r25, está ok, sai
    breq fim_inc         ; Se r20 == r25, está no limite, sai
    mov r26, r28         ; Se passou do máximo, volta para o Mínimo (Reset)
    mov r27, r29
    rjmp fim_inc

subtrair:
    sub r26, r25         ; Subtrai o passo
    sbc r27, r16         ; Subtrai com carry

    cp  r26, r28         ; Compara com o Mínimo (r24)
    cpc r27, r29

    brsh fim_inc         ; Se r20 >= r24 (Same or Higher), está ok, sai
    mov r26, r30         ; Se ficou menor que o mínimo, pula para o Máximo
    mov r27, r31

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

	sbi PORTB, 1
    sbi PORTB, 2
    sbi PORTB, 3

	

    setup_AD_Converter:
    ; Canal A0 (MUX0), Referência AVcc (REFS0), Ajuste à Esquerda (ADLAR)
    ldi r16, (1 << REFS0) | (1 << ADLAR) | (1 << MUX0)
    sts ADMUX, r16
    ; Habilita ADC (ADEN) e Prescaler 128 (ADPS0,1,2)
    ldi r16, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts ADCSRA, r16
    




    SETUP_BOTOES:  ;A1, A2, A3
    cbi DDRC, 1
	cbi DDRC, 2
	cbi DDRC, 3

    sbi PORTC, 1       ; Ativa Pull-up no A1
    sbi PORTC, 2       ; Ativa Pull-up no A2
	sbi PORTC, 3       ; Ativa Pull-up no A3

    ldi r16, (1 << PCIE2)
    sts PCICR, r16     ; Grupo Port C
    ldi r16, (1 << PCINT9)
    sts PCMSK1, r16    ; Pino A1
  

    sei


    ldi r18, 0

    init_state:
    clr r19
    

MAIN_LOOP:
	
	; Atualiza o Estado do Sistema
    rcall maquina_de_estados

    ; Converte o numero em r20 e r21 para BCD
    rcall convert_BCD

	; Exibe de acordo com o efeito POV
    rcall exibir

	; Comparação da label para verificar se o botão de troca de estado foi acionado
	ldi r17, 1
    cp  r15, r17
    brne continua
    inc r19
    clr r15
    
continua:

    rjmp MAIN_LOOP
