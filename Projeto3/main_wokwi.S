
#define __SFR_OFFSET 0   // Ajuste obrigatório no GCC para os comandos OUT e IN funcionarem

#include <avr/io.h>      // Biblioteca padrão do GCC com os registradores do ATmega328

#define TRIG 4
#define ECHO 5 


; X: r30 - r31 (Actual Measure)
; EPROMM
; State Register: r24

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



    setup_sensor:
    ; Configura PC0 e PC5 como entradas para o 
    sbi DDRC, TRIG
    cbi DDRC, ECHO

    cbi PORTC, ECHO

    ;=============================
    ; CONFIGURA TIMER1 (importante para o uso com o sensor ultrassônico pois usa 16bits, melhor resolução)
    ; Prescaler = 8 (0.5us por tick)
    ;=============================
    LDI R16, 0x00
    STS TCCR1A, R16

    LDI R16, (1<<CS11)
    STS TCCR1B, R16
    

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
    ldi r24, 0
    

loop:

    rcall maquina_de_estados

    ; Converte o numero em r20 para BCD
    rcall convert_BCD

    rcall exibir
continua:
    ;inc r19
    
    rjmp loop



__vector_3:
    push r16
    in r16, SREG
    push r16

    S2:
    ; Vai pro Estado de Salvar na Memória 
    sbic PINB, 3        ; Se for 1 (soltou), pula para o fim
    rjmp S3
    cpi r24, 1
    brne S3
    ldi r24, 3
    
    ; Vai pro Estado de Exibir
    S3:
    sbic PINB, 4        ; Se for 1 (soltou), pula para o fim
    rjmp S1
    cpi r24, 1
    brne S1
    ldi r24, 4

    ; Vai pro Estado de Medir uma Nova Distância
    S1:
    sbic PINB, 5        ; Se for 1 (soltou), pula para o fim
    rjmp sair_isr

    ; 2. O botão foi apertado! Incrementa o estado
    ldi r24, 2


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



maquina_de_estados:

    cpi r24, 0
    breq init
    
    cpi r24, 1
    breq wait

    cpi r24, 2
    breq measure

    cpi r24, 3
    breq store

    cpi r24, 4
    breq show

    ldi r24, 1

    rjmp fim_maquina


    ; Estado Inicial(Reset)
    init:
    cbi PORTC, 1
    sbi PORTC, 2
    sbi PORTC, 3

    ldi r20, 0x00
    ldi r21, 0x00

    ldi r24, 1


    rjmp fim_maquina


    ; Estado de Contagem
    wait:
    sbi PORTC, 1
    cbi PORTC, 2
    sbi PORTC, 3

    

    rjmp fim_maquina


    measure:
    cbi PORTC, 1
    cbi PORTC, 2
    sbi PORTC, 3

    rcall trigger_pulse
    rcall measure_echo
    rcall convert_cm 

    mov r20, r30
    mov r21, r31

    ldi r24, 1
    
    rjmp fim_maquina


    ; Estado de Seleção do Valor Mínimo
    store:
    sbi PORTC, 1 
    cbi PORTC, 2
    cbi PORTC, 3

    rcall SALVAR

    ldi r24, 1
    rjmp fim_maquina

    ; Estado de Seleção do Valor Máximo
    show:
    cbi PORTC, 1
    sbi PORTC, 2 
    cbi PORTC, 3

    rcall LER

    ldi r24, 1

    rjmp fim_maquina


    ; Fim
    fim_maquina:
    ret


//LER 16 bits (r21:r20)


LER:

EE_WAIT3:
    sbic EECR, EEPE
    rjmp EE_WAIT3

    ; lê LSB
    ldi r16, 0x00
    out EEARL, r16
    sbi EECR, EERE
    in r20, EEDR

    ; lê MSB
    ldi r16, 0x01
    out EEARL, r16
    sbi EECR, EERE
    in r21, EEDR

    ret
//SALVAR 


SALVAR:

EE_WAIT1:
    sbic EECR, EEPE
    rjmp EE_WAIT1

    ; salva LSB
    ldi r16, 0x00
    out EEARL, r16
    out EEDR, r20

    sbi EECR, EEMPE
    sbi EECR, EEPE

EE_WAIT2:
    sbic EECR, EEPE
    rjmp EE_WAIT2

    ; salva MSB
    ldi r16, 0x01
    out EEARL, r16
    out EEDR, r21

    sbi EECR, EEMPE
    sbi EECR, EEPE

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


measure_echo:

;----------------------------------------
; Espera ECHO subir
;----------------------------------------
wait_high:
    SBIS PINC, ECHO
    RJMP wait_high

    ; Zera Timer1
    LDI R16, 0
    STS TCNT1H, R16
    STS TCNT1L, R16

;----------------------------------------
; Espera ECHO descer
;----------------------------------------
wait_low:
    SBIS PINC, ECHO
    RJMP read_timer
    RJMP wait_low

;----------------------------------------
; Lê valor do Timer1
;----------------------------------------
read_timer:

    ; IMPORTANTE: ler LOW primeiro
    LDS R20, TCNT1L
    LDS R21, TCNT1H

    RET


trigger_pulse:

    SBI PORTC, TRIG
    RCALL delay_10us
    CBI PORTC, TRIG

    RET


convert_cm:

    CLR R30          ; resultado
    CLR R31
    CLR R1
    CLR R28
div_loop:

    ; se valor < 116 → terminou
    LDI R23, 116
    CP R20, R23
    CPC R21, R1      ; R1 = 0 sempre

    BRLO div_end

    ; subtrai 116
    SUBI R20, 116
    SBCI R21, 0

    ADIW R30, 1
    adc R21, R28
    RJMP div_loop

div_end:
    RET




delay_10us:

    LDI R18, 40
d1:
    NOP
    DEC R18
    BRNE d1

    RET


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




exibir:

    ; Delay (~1 s)
    ldi r25, 15
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação rápida
    dec r25
    cpi r25, 0
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






