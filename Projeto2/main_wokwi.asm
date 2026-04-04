#define __SFR_OFFSET 0   // Ajuste obrigatório no GCC para os comandos OUT e IN funcionarem
#include <avr/io.h>      // Biblioteca padrão do GCC com os registradores do ATmega328

.global main             ; Diz ao compilador onde o programa começa

.section .vectors
.org 0x0000
    rjmp main          ; Vetor de Reset (Pino 1)

.org 0x0006
    rjmp ISR_PINO10    ; Vetor de PCINT0 (Pinos 8-13)

.section .text         ; Garante que o código comece fora da tabela de vetores


; r20: Registrador que Armazena o Valor Atual: 
; r27: Registrador do Passo
; r24 Registrador que Armazena o Valor Mínimo da Contagem;
; r25 Registrador que Armazena o Valor Máximo da Contagem;



ISR_PINO10:
    push r16            ; Salva o r16 que estava sendo usado no MAIN_LOOP
    in r16, SREG        ; Lê o status da CPU (Flags, Carry, etc) para o r16
    push r16            ; Salva esse status na pilha

    ; --- Lógica da Interrupção ---
    sbic PINB, 3        ; Se o pino 11 estiver em 1 (pressionado), NÃO pula
    inc r19             ; Incrementa o estado da máquina

    ; --- Restauração (Ordem Inversa) ---
    pop r16             ; Recupera o valor do SREG da pilha
    out SREG, r16       ; Devolve o status original para a CPU
    pop r16             ; Recupera o valor original do r16 do MAIN_LOOP
    reti                ; Retorna


convert_BCD:


  dividir:
    CLR R4 //limpa R4
    CLR R5 //limpa R5
    CLR R6 //limpa R6
    MOV R16, R20 //preserva R0
    

  div_centena:
    CPI R16, 0x64
    BRLO div_dezena //Desvia se R16<R100
    SUBI R16, 0x64
    INC R4
    rjmp div_centena
    
    
  div_dezena:
    CPI R16, 0x0A
    BRLO div_unidade //Desvia se R16<10
    SUBI R16, 0x0A
    INC R5
    rjmp div_dezena 

  div_unidade:
    CPI R16, 0x01
    BRLO div_sair //Desvia se R16<1
    SUBI R16, 0x01
    INC R6
    rjmp div_unidade 

    
  div_sair:
    RET //retorna
    //R4, R5, R6 retorna os valores de Dezena, Centena e Unidade respectivamente.


exibir_pov:


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

    ret


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

    ;push r19
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

    ;pop r19

    ; Estado Inicial(Reset)
    init:
    cbi PORTC, 1
    cbi PORTC, 2
    cbi PORTC, 3

    clr r20
    ;clr r24
    ldi r24, 1
    mov r20, r24
    ldi r25, 255
    ldi r27, 1
    inc r19
    ;ldi r19, 0
    rjmp fim_maquina


    ; Estado de Contagem
    count:
    sbi PORTC, 1
    cbi PORTC, 2
    sbi PORTC, 3
    
    ;mov r20, r19
    rcall convert_BCD
    rcall exibir
    rcall inc_dec;
    rjmp fim_maquina


    ; Estado de Seleção do Valor Mínimo
    min:
    push r20

    rcall ler_adc
    mov r24, r26
    mov r20, r24

    sbi PORTC, 1 
    cbi PORTC, 2
    cbi PORTC, 3

    rcall convert_BCD

    rcall exibir

    pop r20
    rjmp fim_maquina

    ; Estado de Seleção do Valor Máximo
    max_state:
    push r20

    rcall ler_adc
    mov r25, r26
    mov r20, r25


    cbi PORTC, 1
    sbi PORTC, 2 
    cbi PORTC, 3

    rcall convert_BCD

    rcall exibir

    pop r20
    rjmp fim_maquina


    ; Estado de Seleção do Valor de Passo

    step:
    push r20

    rcall ler_adc
    mov r27, r26
    mov r20, r27

    cbi PORTC, 1
    cbi PORTC, 2
    sbi PORTC, 3 
    rcall convert_BCD

    rcall exibir

    pop r20
    rjmp fim_maquina


    ; Fim
    fim_maquina:
    ret


delay_mili:
  ; Emula um for Triplo com objetivo de fazer um delay
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
    cpi r18, 1
    breq subtrair

somar:
    add r20, r27         ; Soma o passo
    cp  r20, r25         ; Compara com o Máximo (r25)
    brlo fim_inc         ; Se r20 < r25, está ok, sai
    breq fim_inc         ; Se r20 == r25, está no limite, sai
    mov r20, r24         ; Se passou do máximo, volta para o Mínimo (Reset)
    rjmp fim_inc

subtrair:
    sub r20, r27         ; Subtrai o passo
    cp  r20, r24         ; Compara com o Mínimo (r24)
    brsh fim_inc         ; Se r20 >= r24 (Same or Higher), está ok, sai
    mov r20, r25         ; Se ficou menor que o mínimo, pula para o Máximo

fim_inc:
    ret


exibir:

    ; Delay (~1 s)
    ldi r26, 15
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação rápida
    dec r26
    cpi r26, 0
    brne loop_pov

    ret



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

.section .progmem.data





main:
; --- INICIALIZAÇÃO DA PILHA ---
    ldi r16, lo8(RAMEND)
    out SPL, r16
    ldi r16, hi8(RAMEND)
    out SPH, r16
    sei
    

    ; Definindo PORTD como saída
    ldi r16, 0xFE
    out DDRD, r16 ; 1111 1110

    sbi DDRB, 0 ; PB0 (Pino 8) Saída
    sbi DDRB, 1 ; PB1 (Pino 9) Saída
    sbi DDRB, 2 ; PB2 (Pino 10) Saída

    cbi DDRB, 3 ; PB3 (Pino 11) Entrada
    cbi DDRB, 4 ; PB4 (Pino 12) Entrada
    cbi DDRB, 5 ; PB5 (Pino 13) Entrada

    cbi PORTB, 3


    ; --- 2. HABILITAR O GRUPO DE INTERRUPÇÃO (PCICR) ---
    ; O bit PCIE0 habilita o grupo dos pinos 8-13 (Port B)
    ldi r16, (1 << PCIE0)
    sts PCICR, r16

    ; --- 3. HABILITAR O PINO ESPECÍFICO (PCMSK0) ---
    ; O bit PCINT2 corresponde ao pino PB2 (Pino 10 do Arduino)
    ldi r16, (1 << PCINT3)
    sts PCMSK0, r16


    setup_rgb:
    ; Configura PC0, PC1 e PC2 como saídas
    ldi r16, (1 << DDC1) | (1 << DDC2) | (1 << DDC3)
    out DDRC, r16


    setup_AD_Converter:
    ; Canal A3 (MUX1 e MUX0), Referência AVcc (REFS0), Ajuste à Esquerda (ADLAR)
    ldi r16, (1 << REFS0) | (1 << ADLAR) | (1 << MUX2) | (1 << MUX0)
    sts ADMUX, r16
    ; Habilita ADC (ADEN) e Prescaler 128 (ADPS0,1,2)
    ldi r16, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts ADCSRA, r16
    

    ldi r18, 0

    init_state:
    ldi r19, 0
    

MAIN_LOOP:


    ; Converte o numero em r20 para BCD
    ;rcall convert_BCD

    rcall maquina_de_estados
    ;inc r19
    cpi r19, 5
    brlo continua
    ldi r19, 1          ; Se for 5 ou mais, volta pro zero
continua:

    rjmp MAIN_LOOP

