#define __SFR_OFFSET 0   // Ajuste obrigatório no GCC para os comandos OUT e IN funcionarem
#include <avr/io.h>      // Biblioteca padrão do GCC com os registradores do ATmega328


; X: r26 - r27 (Count)
; Y: r28 - r29 (Min)
; Z: r30 - r31 (Max)
; r25: (Step<15) 


.section .text
.global main
.global __vector_3    ; Nome oficial do PCINT0 para o Compilador GCC (Endereço 0x06)



main:


    ; Definindo PORTD como saída
    ldi r16, 0xFE
    out DDRD, r16 ; 1111 1110

    sbi DDRB, 0 ; PB0 (Pino 8) Saída
    sbi DDRB, 1 ; PB1 (Pino 9) Saída
    sbi DDRB, 2 ; PB2 (Pino 10) Saída

    cbi DDRB, 3 ; PB3 (Pino 11) Entrada
    cbi DDRB, 4 ; PB4 (Pino 12) Entrada
    cbi DDRB, 5 ; PB5 (Pino 13) Entrada

    sbi PORTB, 3
    sbi PORTB, 4
    sbi PORTB, 5



    setup_rgb:
    ; Configura PC0, PC1 e PC2 como saídas
    ldi r16, (1 << DDC1) | (1 << DDC2) | (1 << DDC3)
    out DDRC, r16


    setup_AD_Converter:
    ; Canal A3 (MUX1 e MUX0), Referência AVcc (REFS0), Ajuste à Esquerda (ADLAR)
    ldi r16, (1 << REFS0) | (1 << MUX2) | (1 << MUX0)
    sts ADMUX, r16
    ; Habilita ADC (ADEN) e Prescaler 128 (ADPS0,1,2)
    ldi r16, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts ADCSRA, r16
    

    setup_interrupt:
    ; --- 2. HABILITAR O GRUPO DE INTERRUPÇÃO (PCICR) ---
    ; O bit PCIE0 habilita o grupo dos pinos 8-13 (Port B)
    ldi r16, (1 << PCIE0)
    sts PCICR, r16

    ; --- 3. HABILITAR O PINO ESPECÍFICO (PCMSK0) ---
    ; O bit PCINT2 corresponde ao pino PB2 (Pino 10 do Arduino)
    ldi r16, (1 << PCINT3) | (1 << PCINT4) | (1 << PCINT5)
    sts PCMSK0, r16

    sei

    init_state:
    clr r19
    

loop:

    rcall maquina_de_estados

    ; Converte o numero em r20 para BCD
    rcall convert_BCD

    rcall exibir
    ldi r17, 1
    cp  r15, r17
    brne continua
    inc r19
    clr r15


continua:
    
    rjmp loop



__vector_3:
    push r16
    in r16, SREG
    push r16

    S2:
    ; 1. Verifica se foi um aperto (0) ou solte (1)
    sbic PINB, 3        ; Se for 1 (soltou), pula para o fim
    rjmp S3

    ; 2. O botão foi apertado! Incrementa o estado
    ldi r17, 1
    mov r15, r17
    
    S3:
    sbic PINB, 4        ; Se for 1 (soltou), pula para o fim
    rjmp S1

    ; 2. O botão foi apertado! Incrementa o estado
    ldi r18, 1


    S1:
    sbic PINB, 5        ; Se for 1 (soltou), pula para o fim
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


exibir_pov:

    push r17
    push r16

    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior
    
    ; Comparação para ascender a centena apenas se L(i) > 100
    cp r4, r16
    breq centena_zero    ; Verificação se existe digito da centena
    cbi   PORTB, 2

    centena_zero:       
    mov r16, r4         // Pega o valor 0-9 da Centena
    rcall decodificar
    lsl r16

    out PORTD, r16
    sbi   PORTB, 2 

    rcall delay_mili


    ; Dezena
    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior

    ; Comparação para ascender a dezena apenas se L(i) > 10

    mov r17, r5
    or r17, r4
    cp r17, r16
    breq dezena_zero    ; Verificação se existe digito da dezena
    cbi   PORTB, 1  

    dezena_zero:
    mov r16, r5         // Pega o valor 0-9 da Dezena
    rcall decodificar
    lsl r16

    out PORTD, r16
    sbi   PORTB, 1  
    rcall delay_mili
  


    ; Unidade
    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior

    cbi   PORTB, 0    
    mov r16, r6         // Pega o valor 0-9 da Unidade
    rcall decodificar
    lsl r16

    out PORTD, r16
    sbi   PORTB, 0      
    rcall delay_mili

    pop r16
    pop r17
    ret


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
    sbi PORTC, 1
    cbi PORTC, 2
    sbi PORTC, 3
    
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

    sbi PORTC, 1 
    cbi PORTC, 2
    cbi PORTC, 3



    rjmp fim_maquina

    ; Estado de Seleção do Valor Máximo
    max_state:

    rcall ler_adc
    rcall map_adc

    mov r30, r22
    mov r31, r23

    mov r20, r30
    mov r21, r31


    cbi PORTC, 1
    sbi PORTC, 2 
    cbi PORTC, 3


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


    cbi PORTC, 1
    cbi PORTC, 2
    sbi PORTC, 3 

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


delay_mili:
  ; Emula um for Triplo com objetivo de fazer um delay
   push r21
   push r22
   push r23

   clr     r21         
   ldi     r22, 10
   ldi     r23, 2 


delay_loop_mili:
    dec     r22         
    brne    delay_loop_mili  
    dec     r21         
    brne    delay_loop_mili  
    dec     r23         
    brne    delay_loop_mili  

    pop r23
    pop r22
    pop r21
    ret




decodificar:
    push ZL
    push ZH
    push r17

    ; 1. Carrega a parte alta e baixa do endereço inicial da Tabela 7SEG
    ldi ZL, lo8(tabela_7seg)
    ldi ZH, hi8(tabela_7seg)

    ; 2. SOMA o dígito (0-9) diretamente para obter o numero correspondente
    ;  BCD-> abcdfeg
    add ZL, r16
    clr r17
    adc ZH, r17

    ; 3. Coloca em r16 o "desenho" do numero de acordo com a tabela
    lpm r16, Z

    ; 4. Desocupa os Registradores e Retorna
    pop r17
    pop ZH
    pop ZL
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
    ldi r24, 15
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação rápida
    dec r24
    cpi r24, 0
    brne loop_pov

    ret


.section .progmem.data

.align 2
tabela_7seg:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x00

//        gfe dcba 
// 3F -> 0011 1111 -> 0 0000 0000
// 06 -> 0000 0110 -> 1 0000 0001
// 5B -> 0101 1011 -> 2 0000 0010
// 4F -> 0100 1111  -> 3 0000 0011 
// 66 -> 0110 0110  -> 4 0000 0100
// 6D -> 0010 1101  -> 5 0000 0101
// 07 -> 0111 1101  -> 6 0000 0110
// 7F -> 0110 1111  -> 7 0000 0111
// 00 -> 






